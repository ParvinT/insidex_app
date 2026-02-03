// functions/templates/otp.js
// OTP verification email templates (en, tr, ru, hi)

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
  .code-box {
    background: #f5f5f5;
    border-radius: 8px;
    padding: 24px;
    text-align: center;
    margin: 0 0 24px;
  }
  .code {
    font-size: 32px;
    font-weight: 700;
    letter-spacing: 8px;
    color: #1a1a1a;
    font-family: 'SF Mono', 'Monaco', 'Courier New', monospace;
  }
  .expires {
    font-size: 13px;
    color: #999999;
    margin-top: 12px;
  }
  .divider {
    height: 1px;
    background: #e5e5e5;
    margin: 0 0 24px;
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

const otpTemplates = {
  en: {
    subject: 'Your InsideX verification code',
    html: (userName, code) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Verification Code</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Verification code</h1>
      <p class="text">Hello ${userName}, use the code below to verify your email address.</p>
      <div class="code-box">
        <div class="code">${code}</div>
        <div class="expires">Expires in 10 minutes</div>
      </div>
      <div class="divider"></div>
      <p class="footer-note">If you didn't request this code, you can safely ignore this email.</p>
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
    subject: 'InsideX doğrulama kodunuz',
    html: (userName, code) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Doğrulama Kodu</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Doğrulama kodu</h1>
      <p class="text">Merhaba ${userName}, e-posta adresinizi doğrulamak için aşağıdaki kodu kullanın.</p>
      <div class="code-box">
        <div class="code">${code}</div>
        <div class="expires">10 dakika içinde geçerliliğini yitirir</div>
      </div>
      <div class="divider"></div>
      <p class="footer-note">Bu kodu siz talep etmediyseniz, bu e-postayı güvenle yok sayabilirsiniz.</p>
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
    subject: 'Ваш код подтверждения InsideX',
    html: (userName, code) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Код подтверждения</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Код подтверждения</h1>
      <p class="text">Здравствуйте ${userName}, используйте код ниже для подтверждения вашего email.</p>
      <div class="code-box">
        <div class="code">${code}</div>
        <div class="expires">Действителен 10 минут</div>
      </div>
      <div class="divider"></div>
      <p class="footer-note">Если вы не запрашивали этот код, просто проигнорируйте это письмо.</p>
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
    subject: 'आपका InsideX सत्यापन कोड',
    html: (userName, code) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>सत्यापन कोड</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">सत्यापन कोड</h1>
      <p class="text">नमस्ते ${userName}, अपना ईमेल सत्यापित करने के लिए नीचे दिए गए कोड का उपयोग करें।</p>
      <div class="code-box">
        <div class="code">${code}</div>
        <div class="expires">10 मिनट में समाप्त हो जाएगा</div>
      </div>
      <div class="divider"></div>
      <p class="footer-note">यदि आपने यह कोड नहीं मांगा है, तो आप इस ईमेल को सुरक्षित रूप से अनदेखा कर सकते हैं।</p>
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
 * Get OTP email template for specified language
 * @param {string} lang - Language code (en, tr, ru, hi)
 * @returns {object} - { subject, html: function(userName, code) }
 */
const getOtpTemplate = (lang = 'en') => {
  return otpTemplates[lang] || otpTemplates.en;
};

module.exports = { getOtpTemplate };