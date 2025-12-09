// functions/index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

// Initialize Firebase Admin
admin.initializeApp();


// Email validation helper
function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

// Email configuration
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || "smtppro.zoho.eu",
  port: 465,               
  secure: true,            
  auth: {
    user: process.env.ZOHO_USER,     
    pass: process.env.ZOHO_PASS,        
  }
});

// Listen for new documents in mail_queue
exports.sendEmailFromQueue = functions.firestore
    .document("mail_queue/{docId}")
    .onCreate(async (snap, context) => {
      const mailData = snap.data();

      // ✅ YENİ - Email validation
      if (!mailData.to || !isValidEmail(mailData.to)) {
        console.error("Invalid email address:", mailData.to);
        await snap.ref.update({
          status: "error",
          error: "Invalid email address",
          errorAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      
      const allowedTypes = ["otp", "welcome", "password_reset", "password_reset_custom"];
      if (!allowedTypes.includes(mailData.type)) {
        console.error("Invalid email type:", mailData.type);
        await snap.ref.update({
          status: "error",
          error: "Invalid email type",
          errorAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      try {
        const mailOptions = {
          from: process.env.ZOHO_FROM,
          to: mailData.to,
        };

        // Check email type
        if (mailData.type === "otp") {
        // OTP Email
          mailOptions.subject = mailData.subject || "Your INSIDEX Verification Code";
          mailOptions.html = mailData.html;

          
          console.log(`Sending OTP email to ${mailData.to}`);
        } else if (mailData.type === "welcome") {

          console.log('Welcome email data:', mailData); // Debug log
          console.log('Template data:', mailData.template?.data);
        // Welcome Email
          mailOptions.subject = "Welcome to INSIDEX! 🎉";
           if (mailData.html) {
    mailOptions.html = mailData.html;  // firebase_service.dart'tan gelen HTML
  } else if (mailData.template?.data) {
    mailOptions.html = getWelcomeEmailHTML(mailData.template.data);
  } else {
    // Fallback
    mailOptions.html = getWelcomeEmailHTML({ userName: 'User' });
  }

          console.log(`Sending welcome email to ${mailData.to}`);
        }
        
          

        // Send email
        const info = await transporter.sendMail(mailOptions);
        console.log("Email sent successfully:", info.messageId);

        // Update document status
        await snap.ref.update({
          status: "sent",
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          messageId: info.messageId,
        });
      } catch (error) {
        console.error("Error sending email:", error);

        // Update document with error
        await snap.ref.update({
          status: "error",
          error: error.message,
          errorAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });

// Daily email limit check
exports.checkDailyEmailLimit = functions.firestore
    .document("mail_queue/{docId}")
    .onCreate(async (snap, context) => {
      const mailData = snap.data();

      // Bugünün başlangıcı
      const startOfDay = new Date();
      startOfDay.setHours(0, 0, 0, 0);

      // Bugün gönderilen email sayısını kontrol et
      const todayEmails = await admin.firestore()
          .collection("mail_queue")
          .where("to", "==", mailData.to)
          .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(startOfDay))
          .get();

      // Günlük limit: 10 email per kullanıcı
      if (todayEmails.size > 10) {
        console.log(`Daily limit exceeded for ${mailData.to}: ${todayEmails.size} emails`);

        // Bu emaili iptal et
        await snap.ref.update({
          status: "cancelled",
          error: "Daily email limit exceeded",
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Security log
        await admin.firestore().collection("security_logs").add({
          type: "daily_limit_exceeded",
          email: mailData.to,
          count: todayEmails.size,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });

// Clean up old OTP codes (run every hour)
exports.cleanupOldOTPs = functions.pubsub
    .schedule("every 1 hours")
    .onRun(async (context) => {
      const now = admin.firestore.Timestamp.now();
      const oneHourAgo = new Date(now.toMillis() - 60 * 60 * 1000);

      try {
        const snapshot = await admin.firestore()
            .collection("otp_verifications")
            .where("createdAt", "<", oneHourAgo)
            .get();

        const batch = admin.firestore().batch();
        snapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });

        await batch.commit();
        console.log(`Deleted ${snapshot.size} old OTP records`);
      } catch (error) {
        console.error("Error cleaning up OTPs:", error);
      }
    });

// Rate limiting for OTP creation
exports.rateLimitOTP = functions.firestore
    .document("otp_verifications/{email}")
    .onCreate(async (snap, context) => {
      const email = context.params.email;
      const data = snap.data();

      try {
      // Son 1 saat içinde bu email için kaç OTP oluşturulmuş kontrol et
        const oneHourAgo = admin.firestore.Timestamp.fromDate(
            new Date(Date.now() - 60 * 60 * 1000),
        );

        // Bu email için mevcut OTP'leri say
        const recentAttempts = await admin.firestore()
            .collection("otp_verifications")
            .where("email", "==", email)
            .where("createdAt", ">", oneHourAgo)
            .get();

        // 1 saatte 5'ten fazla deneme varsa
        if (recentAttempts.size > 5) {
          console.log(`Rate limit exceeded for ${email} - ${recentAttempts.size} attempts`);

          // Bu OTP'yi sil
          await snap.ref.delete();

          // Log tut
          await admin.firestore().collection("security_logs").add({
            type: "rate_limit_exceeded",
            email: email,
            attempts: recentAttempts.size,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            action: "otp_deleted",
          });

          return;
        }

        console.log(`OTP created for ${email} - attempt ${recentAttempts.size}/5`);
      } catch (error) {
        console.error("Error in rate limiting:", error);
      }
    });

// Helper function for welcome email HTML
function getWelcomeEmailHTML(data) {
  return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 0;
            background: #f5f5f5;
        }
        .container { 
            max-width: 600px;
            margin: 20px auto;
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px 30px;
            text-align: center;
        }
        .content {
            padding: 40px 30px;
        }
        .button {
            display: inline-block;
            padding: 12px 30px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #888;
            font-size: 14px;
            background: #f8f9fa;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1 style="margin: 0;">Welcome to INSIDEX!</h1>
            <p style="margin: 10px 0 0 0;">Your Journey to Inner Peace Begins Here</p>
        </div>
        
        <div class="content">
            <h2>Hello ${data.userName}! 👋</h2>
            
            <p>Thank you for joining INSIDEX. Your account has been successfully created!</p>
            
            <p>Best regards,<br>
            <strong>The INSIDEX Team</strong></p>
        </div>
        
        <div class="footer">
            <p>© 2025 INSIDEX. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
  `;
}


// Send email helper function
async function sendEmail({ to, subject, html }) {
  const mailOptions = {
    from: process.env.ZOHO_FROM,
    to: to,
    subject: subject,
    html: html
  };
  
  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('Email sent:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending email:', error);
    throw error;
  }
}


exports.onFeedbackCreated = functions.firestore
  .document('feedback/{feedbackId}')
  .onCreate(async (snap, context) => {
    const feedback = snap.data();
    
    const emailHtml = `
      <h2>New Feedback Received</h2>
      <p><strong>Type:</strong> ${feedback.type}</p>
      <p><strong>Title:</strong> ${feedback.title}</p>
      <p><strong>Rating:</strong> ${feedback.rating}/5</p>
      <p><strong>Message:</strong></p>
      <p>${feedback.message}</p>
      <p><strong>User Email:</strong> ${feedback.email || 'Not provided'}</p>
      <p><strong>User ID:</strong> ${feedback.userId || 'Guest'}</p>
      <hr>
      <p><small>Submitted at: ${new Date().toLocaleString()}</small></p>
    `;
    
    await sendEmail({
      to: process.env.FEEDBACK_EMAIL,
      subject: `[INSIDEX Feedback] ${feedback.type}: ${feedback.title}`,
      html: emailHtml,
    });
});

// Custom Password Reset with Link
exports.customPasswordReset = functions.https.onCall(async (data, context) => {
  const { email } = data;
  
  if (!email || !isValidEmail(email)) {
    throw new functions.https.HttpsError('invalid-argument', 'Valid email required');
  }
  
  try {
    // 1. Kullanıcı var mı kontrol et
    console.log('Checking user existence...');
    const userRecord = await admin.auth().getUserByEmail(email);
    console.log('User found:', userRecord.uid);
    
    // 2. Reset linki oluştur (Firebase Admin SDK)
    console.log('Generating reset link...');
    const resetLink = await admin.auth().generatePasswordResetLink(email);
    console.log('Reset link generated');
    
    // 3. Kullanıcı adını al
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userRecord.uid)
      .get();
    
    const userName = userDoc.exists ? userDoc.data().name : 'User';
    
    // 4. Email HTML'i oluştur
    const emailHtml = `
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 0; background: #f5f5f5; }
        .container { max-width: 600px; margin: 20px auto; background: white; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px; text-align: center; border-radius: 10px 10px 0 0; }
        .header h1 { color: white; margin: 0; font-size: 32px; }
        .content { padding: 40px; }
        .reset-button { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white !important; padding: 15px 40px; text-decoration: none; border-radius: 50px; display: inline-block; font-weight: 600; margin: 20px 0; }
        .warning-box { background: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .link-box { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; word-break: break-all; font-size: 12px; color: #666; }
        .footer { background: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #666; border-radius: 0 0 10px 10px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>INSIDEX</h1>
            <p style="color: white; margin: 10px 0 0 0;">Password Reset Request</p>
        </div>
        <div class="content">
            <h2>Hi ${userName}! 👋</h2>
            <p>You requested to reset your password. Click the button below to create a new password:</p>
            
            <div style="text-align: center;">
                <a href="${resetLink}" class="reset-button">Reset My Password</a>
            </div>
            
            <div class="warning-box">
                <strong>⚠️ Security Notice:</strong>
                <ul style="margin: 10px 0; padding-left: 20px;">
                    <li>This link expires in 1 hour</li>
                    <li>Never share this link with anyone</li>
                    <li>If you didn't request this, ignore this email</li>
                </ul>
            </div>
            
            <p style="color: #666; font-size: 14px;">Or copy this link:</p>
            <div class="link-box">${resetLink}</div>
        </div>
        <div class="footer">
            <p>© 2025 INSIDEX. All rights reserved.</p>
            <p>You received this because a password reset was requested for your account.</p>
        </div>
    </div>
</body>
</html>
    `;
    
    // 5. Email'i gönder
    const mailOptions = {
      from: process.env.ZOHO_FROM,
      to: email,
      subject: '🔐 Reset Your INSIDEX Password',
      html: emailHtml
    };
    
    try {
  const info = await transporter.sendMail(mailOptions);
  console.log('Password reset email sent:', info.messageId);
} catch (mailError) {
  console.error('Failed to send email:', mailError);
  throw new functions.https.HttpsError('internal', 'Failed to send email: ' + mailError.message);
}
    
    // 6. Log tut
    await admin.firestore().collection('password_reset_logs').add({
      email: email,
      userId: userRecord.uid,
      requestedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'sent'
    });
    
    return { success: true, message: 'Password reset email sent!' };
    
  } catch (error) {
    console.error('Password reset error:', error);
    
    if (error.code === 'auth/user-not-found') {
      throw new functions.https.HttpsError('not-found', 'No account found with this email');
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to send reset email');
  }
});

exports.checkEmailExists = functions.https.onCall(async (data, context) => {
  const { email } = data;
  
  console.log('checkEmailExists called for:', email);
  
  // Validation
  if (!email || !isValidEmail(email)) {
    throw new functions.https.HttpsError('invalid-argument', 'Valid email required');
  }
  
  try {
    // 1. Check Firebase Auth
    try {
      await admin.auth().getUserByEmail(email);
      console.log('Email found in Firebase Auth');
      return { 
        exists: true, 
        location: 'firebase_auth' 
      };
    } catch (authError) {
      if (authError.code !== 'auth/user-not-found') {
        console.error('Firebase Auth error:', authError);
        throw authError;
      }
      console.log('Email not in Firebase Auth');
    }
    
    // 2. Check Firestore users collection
    const userQuery = await admin.firestore()
      .collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();
      
    if (!userQuery.empty) {
      console.log('Email found in Firestore users');
      return { 
        exists: true, 
        location: 'firestore_users' 
      };
    }
    
    console.log('Email not found anywhere');
    return { exists: false };
    
  } catch (error) {
    console.error('Error checking email:', error);
    throw new functions.https.HttpsError('internal', 'Failed to check email');
  }
});
