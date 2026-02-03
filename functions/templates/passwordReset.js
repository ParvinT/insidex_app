// functions/templates/passwordReset.js
// Password reset email templates (en, tr, ru, hi)

const baseStyles = `
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    line-height: 1.6;
    color: #1a1a1a;
    background-color: #f5f5f5;
    margin: 0;
    padding: 20px;
  }
  .container {
    max-width: 480px;
    margin: 0 auto;
    background: #ffffff;
    border-radius: 8px;
    overflow: hidden;
  }
  .header {
    padding: 32px 40px 24px;
    text-align: center;
  }
  .logo {
    font-size: 24px;
    font-weight: 700;
    color: #1a1a1a;
    letter-spacing: -0.5px;
  }
  .content {
    padding: 0 40px 32px;
  }
  .title {
    font-size: 20px;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 16px;
  }
  .text {
    font-size: 15px;
    color: #666666;
    margin: 0 0 24px;
  }
  .button-wrapper {
    text-align: center;
    margin: 0 0 24px;
  }
  .button {
    display: inline-block;
    background: #1a1a1a;
    color: #ffffff !important;
    text-decoration: none;
    padding: 14px 32px;
    border-radius: 6px;
    font-size: 15px;
    font-weight: 600;
  }
  .link-text {
    font-size: 13px;
    color: #999999;
    margin: 0 0 8px;
  }
  .link {
    font-size: 12px;
    color: #666666;
    word-break: break-all;
  }
  .divider {
    height: 1px;
    background: #e5e5e5;
    margin: 24px 0;
  }
  .footer-note {
    font-size: 13px;
    color: #999999;
    margin: 0;
  }
  .footer {
    padding: 24px 40px;
    text-align: center;
    border-top: 1px solid #e5e5e5;
  }
  .copyright {
    font-size: 12px;
    color: #999999;
    margin: 0;
  }
`;

const passwordResetTemplates = {
  en: {
    subject: 'Reset your InsideX password',
    html: (userName, resetLink) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset Password</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Reset your password</h1>
      <p class="text">Hello ${userName}, we received a request to reset your password. Click the button below to create a new password.</p>
      <div class="button-wrapper">
        <a href="${resetLink}" class="button">Reset Password</a>
      </div>
      <p class="link-text">Or copy and paste this link:</p>
      <p class="link">${resetLink}</p>
      <div class="divider"></div>
      <p class="footer-note">If you didn't request a password reset, you can safely ignore this email. Your password will remain unchanged.</p>
    </div>
    <div class="footer">
      <p class="copyright">&copy; ${new Date().getFullYear()} InsideX. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
    `
  },

  tr: {
    subject: 'InsideX şifrenizi sıfırlayın',
    html: (userName, resetLink) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Şifre Sıfırlama</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Şifrenizi sıfırlayın</h1>
      <p class="text">Merhaba ${userName}, şifrenizi sıfırlamak için bir istek aldık. Yeni bir şifre oluşturmak için aşağıdaki butona tıklayın.</p>
      <div class="button-wrapper">
        <a href="${resetLink}" class="button">Şifreyi Sıfırla</a>
      </div>
      <p class="link-text">Veya bu linki kopyalayıp yapıştırın:</p>
      <p class="link">${resetLink}</p>
      <div class="divider"></div>
      <p class="footer-note">Şifre sıfırlama talebinde bulunmadıysanız, bu e-postayı güvenle yok sayabilirsiniz. Şifreniz değişmeden kalacaktır.</p>
    </div>
    <div class="footer">
      <p class="copyright">&copy; ${new Date().getFullYear()} InsideX. Tüm hakları saklıdır.</p>
    </div>
  </div>
</body>
</html>
    `
  },

  ru: {
    subject: 'Сбросить пароль InsideX',
    html: (userName, resetLink) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Сброс пароля</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Сбросить пароль</h1>
      <p class="text">Здравствуйте ${userName}, мы получили запрос на сброс пароля. Нажмите кнопку ниже, чтобы создать новый пароль.</p>
      <div class="button-wrapper">
        <a href="${resetLink}" class="button">Сбросить пароль</a>
      </div>
      <p class="link-text">Или скопируйте и вставьте эту ссылку:</p>
      <p class="link">${resetLink}</p>
      <div class="divider"></div>
      <p class="footer-note">Если вы не запрашивали сброс пароля, просто проигнорируйте это письмо. Ваш пароль останется прежним.</p>
    </div>
    <div class="footer">
      <p class="copyright">&copy; ${new Date().getFullYear()} InsideX. Все права защищены.</p>
    </div>
  </div>
</body>
</html>
    `
  },

  hi: {
    subject: 'अपना InsideX पासवर्ड रीसेट करें',
    html: (userName, resetLink) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>पासवर्ड रीसेट</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">अपना पासवर्ड रीसेट करें</h1>
      <p class="text">नमस्ते ${userName}, हमें आपका पासवर्ड रीसेट करने का अनुरोध मिला है। नया पासवर्ड बनाने के लिए नीचे दिए गए बटन पर क्लिक करें।</p>
      <div class="button-wrapper">
        <a href="${resetLink}" class="button">पासवर्ड रीसेट करें</a>
      </div>
      <p class="link-text">या इस लिंक को कॉपी और पेस्ट करें:</p>
      <p class="link">${resetLink}</p>
      <div class="divider"></div>
      <p class="footer-note">यदि आपने पासवर्ड रीसेट का अनुरोध नहीं किया है, तो आप इस ईमेल को सुरक्षित रूप से अनदेखा कर सकते हैं। आपका पासवर्ड अपरिवर्तित रहेगा।</p>
    </div>
    <div class="footer">
      <p class="copyright">&copy; ${new Date().getFullYear()} InsideX. सर्वाधिकार सुरक्षित।</p>
    </div>
  </div>
</body>
</html>
    `
  }
};

/**
 * Get Password Reset email template for specified language
 * @param {string} lang - Language code (en, tr, ru, hi)
 * @returns {object} - { subject, html: function(userName, resetLink) }
 */
const getPasswordResetTemplate = (lang = 'en') => {
  return passwordResetTemplates[lang] || passwordResetTemplates.en;
};

module.exports = { getPasswordResetTemplate };