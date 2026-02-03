// functions/templates/subscriptionExpired.js

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
  .info-box {
    background: #f8f9fa;
    border-radius: 8px;
    padding: 20px;
    margin: 0 0 24px;
  }
  .info-row {
    display: flex;
    justify-content: space-between;
    padding: 8px 0;
    border-bottom: 1px solid #e9ecef;
  }
  .info-row:last-child {
    border-bottom: none;
  }
  .info-label {
    font-size: 14px;
    color: #666666;
  }
  .info-value {
    font-size: 14px;
    font-weight: 600;
    color: #1a1a1a;
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

const subscriptionExpiredTemplates = {
  en: {
    subject: 'Your InsideX subscription has ended',
    html: (userName, planName) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Subscription Ended</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Your subscription has ended</h1>
      <p class="text">Hi ${userName},</p>
      <p class="text">Your ${planName} subscription has expired. You now have access to demo sessions only.</p>
      <p class="text">We'd love to have you back anytime.</p>
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
    subject: 'InsideX aboneliğiniz sona erdi',
    html: (userName, planName) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Abonelik Sona Erdi</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Aboneliğiniz sona erdi</h1>
      <p class="text">Merhaba ${userName},</p>
      <p class="text">${planName} aboneliğiniz sona erdi. Artık yalnızca demo oturumlara erişebilirsiniz.</p>
      <p class="text">Sizi tekrar aramızda görmekten mutluluk duyarız.</p>
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
    subject: 'Ваша подписка InsideX закончилась',
    html: (userName, planName) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Подписка закончилась</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Ваша подписка закончилась</h1>
      <p class="text">Здравствуйте, ${userName}!</p>
      <p class="text">Срок действия вашей подписки ${planName} истек. Теперь вам доступны только демо-сессии.</p>
      <p class="text">Мы будем рады видеть вас снова.</p>
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
    subject: 'आपकी InsideX सदस्यता समाप्त हो गई है',
    html: (userName, planName) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>सदस्यता समाप्त</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">आपकी सदस्यता समाप्त हो गई है</h1>
      <p class="text">नमस्ते ${userName},</p>
      <p class="text">आपकी ${planName} सदस्यता समाप्त हो गई है। अब आपके पास केवल डेमो सत्रों तक पहुंच है।</p>
      <p class="text">हमें आपको वापस पाकर खुशी होगी।</p>
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

const getSubscriptionExpiredTemplate = (lang = 'en') => {
  return subscriptionExpiredTemplates[lang] || subscriptionExpiredTemplates.en;
};

module.exports = { getSubscriptionExpiredTemplate };