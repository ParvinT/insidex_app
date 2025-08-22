// functions/index.js

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Initialize Firebase Admin
admin.initializeApp();

// Email configuration
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,     
    pass: process.env.GMAIL_PASS        
  }
});

// Listen for new documents in mail_queue
exports.sendEmailFromQueue = functions.firestore
  .document('mail_queue/{docId}')
  .onCreate(async (snap, context) => {
    const mailData = snap.data();
    
    try {
      let mailOptions = {
        from: process.env.GMAIL_FROM, 
        to: mailData.to,
      };

      // Check email type
      if (mailData.type === 'otp') {
        // OTP Email
        mailOptions.subject = mailData.subject || 'Your INSIDEX Verification Code';
        mailOptions.html = mailData.html;
        
        console.log(`Sending OTP email to ${mailData.to}`);
        
      } else if (mailData.type === 'welcome') {
        // Welcome Email
        mailOptions.subject = 'Welcome to INSIDEX! 🎉';
        mailOptions.html = getWelcomeEmailHTML(mailData.template.data);
        
        console.log(`Sending welcome email to ${mailData.to}`);
      }

      // Send email
      const info = await transporter.sendMail(mailOptions);
      console.log('Email sent successfully:', info.messageId);

      // Update document status
      await snap.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: info.messageId
      });

    } catch (error) {
      console.error('Error sending email:', error);
      
      // Update document with error
      await snap.ref.update({
        status: 'error',
        error: error.message,
        errorAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });

// Clean up old OTP codes (run every hour)
exports.cleanupOldOTPs = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const oneHourAgo = new Date(now.toMillis() - 60 * 60 * 1000);
    
    try {
      const snapshot = await admin.firestore()
        .collection('otp_verifications')
        .where('createdAt', '<', oneHourAgo)
        .get();
      
      const batch = admin.firestore().batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });
      
      await batch.commit();
      console.log(`Deleted ${snapshot.size} old OTP records`);
      
    } catch (error) {
      console.error('Error cleaning up OTPs:', error);
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