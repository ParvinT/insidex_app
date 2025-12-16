// functions/index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

// Import email templates
const { 
  getOtpTemplate, 
  getWelcomeTemplate, 
  getPasswordResetTemplate,
  normalizeLanguage 
} = require("./templates");

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

        // Get language (default to 'en')
        const lang = normalizeLanguage(mailData.lang);
        console.log(`Processing ${mailData.type} email in language: ${lang}`);

        if (mailData.type === "otp") {
          // OTP Email
          const template = getOtpTemplate(lang);
          const userName = mailData.userName || 'User';
          const code = mailData.code || '';
          
          mailOptions.subject = template.subject;
          mailOptions.html = template.html(userName, code);
          
          console.log(`Sending OTP email to ${mailData.to} (${lang})`);
        } else if (mailData.type === "welcome") {
          // Welcome Email
          const template = getWelcomeTemplate(lang);
          const userName = mailData.userName || mailData.template?.data?.userName || 'User';
          
          mailOptions.subject = template.subject;
          mailOptions.html = template.html(userName);
          
          console.log(`Sending welcome email to ${mailData.to} (${lang})`);
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
  const { email, lang: requestLang } = data;
  
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
    
    // 4. Get user's preferred language or use request language
    const userLang = userDoc.exists ? userDoc.data().preferredLanguage : null;
    const lang = normalizeLanguage(userLang || requestLang);
    
    // 5. Get email template
    const template = getPasswordResetTemplate(lang);
    
    const mailOptions = {
      from: process.env.ZOHO_FROM,
      to: email,
      subject: template.subject,
      html: template.html(userName, resetLink)
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
