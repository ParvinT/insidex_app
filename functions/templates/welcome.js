// functions/templates/welcome.js
// Welcome email templates (en, tr, ru, hi)

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
  .features {
    margin: 0 0 24px;
    padding: 0;
    list-style: none;
  }
  .features li {
    font-size: 14px;
    color: #666666;
    padding: 8px 0;
    border-bottom: 1px solid #f0f0f0;
  }
  .features li:last-child {
    border-bottom: none;
  }
  .divider {
    height: 1px;
    background: #e5e5e5;
    margin: 0 0 24px;
  }
  .signature {
    font-size: 14px;
    color: #666666;
    margin: 0;
  }
  .signature strong {
    color: #1a1a1a;
  }
  .footer {
    padding: 24px 40px;
    text-align: center;
    border-top: 1px solid #e5e5e5;
  }
  .support {
    font-size: 13px;
    color: #999999;
    margin: 0 0 8px;
  }
  .support a {
    color: #666666;
    text-decoration: none;
  }
  .copyright {
    font-size: 12px;
    color: #999999;
    margin: 0;
  }
`;

const welcomeTemplates = {
  en: {
    subject: 'Welcome to InsideX',
    html: (userName) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to InsideX</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Welcome to InsideX</h1>
      <p class="text">Hello ${userName}, your account has been created successfully. Start your journey with HypnoTrack audio sessions designed to transform your wellbeing.</p>
      <div class="divider"></div>
      <p class="signature">Best regards,<br><strong>The InsideX Team</strong></p>
    </div>
    <div class="footer">
      <p class="support">Questions? <a href="mailto:support@insidexapp.com">support@insidexapp.com</a></p>
      <p class="copyright">&copy; ${new Date().getFullYear()} InsideX. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
    `
  },

  tr: {
    subject: 'InsideX\'e hoş geldiniz',
    html: (userName) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>InsideX'e Hoş Geldiniz</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">InsideX'e hoş geldiniz</h1>
      <p class="text">Merhaba ${userName}, hesabınız başarıyla oluşturuldu. Yaşamınızı dönüştürmek için tasarlanmış Hipnotrek ses seanslarıyla yolculuğunuza başlayın.</p>
      <div class="divider"></div>
      <p class="signature">Saygılarımızla,<br><strong>InsideX Ekibi</strong></p>
    </div>
    <div class="footer">
      <p class="support">Sorularınız mı var? <a href="mailto:support@insidexapp.com">support@insidexapp.com</a></p>
      <p class="copyright">&copy; ${new Date().getFullYear()} InsideX. Tüm hakları saklıdır.</p>
    </div>
  </div>
</body>
</html>
    `
  },

  ru: {
    subject: 'Добро пожаловать в InsideX',
    html: (userName) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Добро пожаловать в InsideX</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Добро пожаловать в InsideX</h1>
      <p class="text">Здравствуйте ${userName}, ваш аккаунт успешно создан. Начните свой путь с аудиосессий Гипнотрек, созданных для улучшения вашего самочувствия.</p>
      <div class="divider"></div>
      <p class="signature">С уважением,<br><strong>Команда InsideX</strong></p>
    </div>
    <div class="footer">
      <p class="support">Вопросы? <a href="mailto:support@insidexapp.com">support@insidexapp.com</a></p>
      <p class="copyright">&copy; ${new Date().getFullYear()} InsideX. Все права защищены.</p>
    </div>
  </div>
</body>
</html>
    `
  },

  hi: {
    subject: 'InsideX में आपका स्वागत है',
    html: (userName) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>InsideX में आपका स्वागत है</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">InsideX में आपका स्वागत है</h1>
      <p class="text">नमस्ते ${userName}, आपका खाता सफलतापूर्वक बनाया गया है। अपनी भलाई को बदलने के लिए डिज़ाइन किए गए हिप्नोट्रैक ऑडियो सत्रों के साथ अपनी यात्रा शुरू करें।</p>
      <div class="divider"></div>
      <p class="signature">सादर,<br><strong>InsideX टीम</strong></p>
    </div>
    <div class="footer">
      <p class="support">प्रश्न हैं? <a href="mailto:support@insidexapp.com">support@insidexapp.com</a></p>
      <p class="copyright">&copy; ${new Date().getFullYear()} InsideX. सर्वाधिकार सुरक्षित।</p>
    </div>
  </div>
</body>
</html>
    `
  }
};

/**
 * Get Welcome email template for specified language
 * @param {string} lang - Language code (en, tr, ru, hi)
 * @returns {object} - { subject, html: function(userName) }
 */
const getWelcomeTemplate = (lang = 'en') => {
  return welcomeTemplates[lang] || welcomeTemplates.en;
};

module.exports = { getWelcomeTemplate };