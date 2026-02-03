// functions/templates/subscriptionStarted.js

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
    margin: 0 0 16px;
  }
  .divider {
    height: 1px;
    background: #e5e5e5;
    margin: 24px 0;
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

const subscriptionStartedTemplates = {
  en: {
    subject: (planName) => `Welcome to InsideX ${planName}`,
    html: (userName, planName, expiryDate, isTrial) => `
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
      <h1 class="title">Welcome to InsideX ${planName}</h1>
      <p class="text">Hi ${userName},</p>
      <p class="text">Your ${planName} subscription is now active.</p>
      ${isTrial 
        ? `<p class="text">Your 7-day free trial has started. Your trial ends on <strong>${expiryDate}</strong>.</p>`
        : `<p class="text">Thank you for subscribing. Your next billing date is <strong>${expiryDate}</strong>.</p>`
      }
      <p class="text">If you have any questions, reply to this email.</p>
      <div class="divider"></div>
      <p class="signature">Best regards,<br><strong>InsideX Team</strong></p>
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
    subject: (planName) => `InsideX ${planName} Planına Hoş Geldiniz`,
    html: (userName, planName, expiryDate, isTrial) => `
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
      <h1 class="title">InsideX ${planName} Planına Hoş Geldiniz</h1>
      <p class="text">Merhaba ${userName},</p>
      <p class="text">${planName} aboneliğiniz aktif edildi.</p>
      ${isTrial 
        ? `<p class="text">7 günlük ücretsiz deneme süreniz başladı. Deneme süreniz <strong>${expiryDate}</strong> tarihinde sona erecek.</p>`
        : `<p class="text">Abone olduğunuz için teşekkürler. Bir sonraki ödeme tarihiniz: <strong>${expiryDate}</strong>.</p>`
      }
      <p class="text">Sorularınız varsa bu e-postayı yanıtlayabilirsiniz.</p>
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
    subject: (planName) => `Добро пожаловать в InsideX ${planName}`,
    html: (userName, planName, expiryDate, isTrial) => `
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
      <h1 class="title">Добро пожаловать в InsideX ${planName}</h1>
      <p class="text">Здравствуйте, ${userName}!</p>
      <p class="text">Ваша подписка ${planName} активирована.</p>
      ${isTrial 
        ? `<p class="text">Ваш 7-дневный бесплатный период начался. Пробный период заканчивается <strong>${expiryDate}</strong>.</p>`
        : `<p class="text">Спасибо за подписку. Следующая дата оплаты: <strong>${expiryDate}</strong>.</p>`
      }
      <p class="text">Если у вас есть вопросы, ответьте на это письмо.</p>
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
    subject: (planName) => `InsideX ${planName} में आपका स्वागत है`,
    html: (userName, planName, expiryDate, isTrial) => `
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
      <h1 class="title">InsideX ${planName} में आपका स्वागत है</h1>
      <p class="text">नमस्ते ${userName},</p>
      <p class="text">आपकी ${planName} सदस्यता सक्रिय हो गई है।</p>
      ${isTrial 
        ? `<p class="text">आपका 7 दिन का निःशुल्क परीक्षण शुरू हो गया है। परीक्षण <strong>${expiryDate}</strong> को समाप्त होगा।</p>`
        : `<p class="text">सदस्यता के लिए धन्यवाद। अगली बिलिंग तिथि: <strong>${expiryDate}</strong>।</p>`
      }
      <p class="text">कोई प्रश्न हो तो इस ईमेल का जवाब दें।</p>
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

const getSubscriptionStartedTemplate = (lang = 'en') => {
  return subscriptionStartedTemplates[lang] || subscriptionStartedTemplates.en;
};

module.exports = { getSubscriptionStartedTemplate };