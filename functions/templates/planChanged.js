// functions/templates/planChanged.js

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

const planChangedTemplates = {
  en: {
    subject: 'Your InsideX plan has been changed',
    html: (userName, oldPlan, newPlan, effectiveDate, isImmediate) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Plan Changed</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Your plan has been changed</h1>
      <p class="text">Hi ${userName},</p>
      <p class="text">Your subscription plan change has been confirmed.</p>
      <div style="text-align: center; margin: 24px 0;">
        <span class="plan">${oldPlan}</span>
        <span class="arrow">→</span>
        <span class="plan">${newPlan}</span>
      </div>
      ${isImmediate 
        ? `<div class="info-box"><p class="info-text">Your new plan is now active.</p></div>`
        : `<div class="info-box"><p class="info-text">Your plan will change on <strong>${effectiveDate}</strong>. Until then, you'll continue to enjoy your current plan benefits.</p></div>`
      }
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
    subject: 'InsideX planınız değiştirildi',
    html: (userName, oldPlan, newPlan, effectiveDate, isImmediate) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Plan Değiştirildi</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Planınız değiştirildi</h1>
      <p class="text">Merhaba ${userName},</p>
      <p class="text">Plan değişikliği talebiniz onaylandı.</p>
      <div style="text-align: center; margin: 24px 0;">
        <span class="plan">${oldPlan}</span>
        <span class="arrow">→</span>
        <span class="plan">${newPlan}</span>
      </div>
      ${isImmediate 
        ? `<div class="info-box"><p class="info-text">Yeni planınız şu anda aktif.</p></div>`
        : `<div class="info-box"><p class="info-text">Planınız <strong>${effectiveDate}</strong> tarihinde değişecek. O tarihe kadar mevcut plan avantajlarınızdan yararlanmaya devam edebilirsiniz.</p></div>`
      }
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
    subject: 'Ваш план InsideX изменен',
    html: (userName, oldPlan, newPlan, effectiveDate, isImmediate) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>План изменен</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Ваш план изменен</h1>
      <p class="text">Здравствуйте, ${userName}!</p>
      <p class="text">Изменение вашего плана подписки подтверждено.</p>
      <div style="text-align: center; margin: 24px 0;">
        <span class="plan">${oldPlan}</span>
        <span class="arrow">→</span>
        <span class="plan">${newPlan}</span>
      </div>
      ${isImmediate 
        ? `<div class="info-box"><p class="info-text">Ваш новый план уже активен.</p></div>`
        : `<div class="info-box"><p class="info-text">Ваш план изменится <strong>${effectiveDate}</strong>. До этого момента вы продолжите пользоваться преимуществами текущего плана.</p></div>`
      }
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
    subject: 'आपका InsideX प्लान बदल दिया गया है',
    html: (userName, oldPlan, newPlan, effectiveDate, isImmediate) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>प्लान बदला गया</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">आपका प्लान बदल दिया गया है</h1>
      <p class="text">नमस्ते ${userName},</p>
      <p class="text">आपके प्लान परिवर्तन की पुष्टि हो गई है।</p>
      <div style="text-align: center; margin: 24px 0;">
        <span class="plan">${oldPlan}</span>
        <span class="arrow">→</span>
        <span class="plan">${newPlan}</span>
      </div>
      ${isImmediate 
        ? `<div class="info-box"><p class="info-text">आपका नया प्लान अब सक्रिय है।</p></div>`
        : `<div class="info-box"><p class="info-text">आपका प्लान <strong>${effectiveDate}</strong> को बदल जाएगा। तब तक आप अपने वर्तमान प्लान के लाभों का आनंद लेते रहेंगे।</p></div>`
      }
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

const getPlanChangedTemplate = (lang = 'en') => {
  return planChangedTemplates[lang] || planChangedTemplates.en;
};

module.exports = { getPlanChangedTemplate };