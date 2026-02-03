// functions/templates/trialEnding.js

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

const trialEndingTemplates = {
  en: {
    subject: 'Your InsideX trial ends tomorrow',
    html: (userName, planName, expiryDate) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Trial Ending Soon</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Your trial ends tomorrow</h1>
      <p class="text">Hi ${userName},</p>
      <p class="text">Your ${planName} free trial ends on <strong>${expiryDate}</strong>.</p>
      <div class="highlight-box">
        <p class="highlight-text">To keep your access to all premium features, your subscription will automatically continue after the trial.</p>
      </div>
      <p class="text">If you don't want to continue, you can cancel anytime from your App Store or Google Play settings.</p>
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
    subject: 'InsideX deneme süreniz yarın bitiyor',
    html: (userName, planName, expiryDate) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Deneme Süresi Bitiyor</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Deneme süreniz yarın bitiyor</h1>
      <p class="text">Merhaba ${userName},</p>
      <p class="text">${planName} ücretsiz deneme süreniz <strong>${expiryDate}</strong> tarihinde sona eriyor.</p>
      <div class="highlight-box">
        <p class="highlight-text">Premium özelliklere erişiminizi korumak için deneme süresinin ardından aboneliğiniz otomatik olarak devam edecek.</p>
      </div>
      <p class="text">Devam etmek istemiyorsanız App Store veya Google Play ayarlarından istediğiniz zaman iptal edebilirsiniz.</p>
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
    subject: 'Ваш пробный период InsideX заканчивается завтра',
    html: (userName, planName, expiryDate) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Пробный период заканчивается</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Ваш пробный период заканчивается завтра</h1>
      <p class="text">Здравствуйте, ${userName}!</p>
      <p class="text">Ваш бесплатный пробный период ${planName} заканчивается <strong>${expiryDate}</strong>.</p>
      <div class="highlight-box">
        <p class="highlight-text">Чтобы сохранить доступ ко всем премиум-функциям, ваша подписка автоматически продолжится после окончания пробного периода.</p>
      </div>
      <p class="text">Если вы не хотите продолжать, вы можете отменить подписку в настройках App Store или Google Play.</p>
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
    subject: 'आपका InsideX परीक्षण कल समाप्त हो रहा है',
    html: (userName, planName, expiryDate) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>परीक्षण समाप्त हो रहा है</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">आपका परीक्षण कल समाप्त हो रहा है</h1>
      <p class="text">नमस्ते ${userName},</p>
      <p class="text">आपका ${planName} निःशुल्क परीक्षण <strong>${expiryDate}</strong> को समाप्त हो रहा है।</p>
      <div class="highlight-box">
        <p class="highlight-text">सभी प्रीमियम सुविधाओं तक पहुंच बनाए रखने के लिए, परीक्षण के बाद आपकी सदस्यता स्वचालित रूप से जारी रहेगी।</p>
      </div>
      <p class="text">यदि आप जारी नहीं रखना चाहते, तो App Store या Google Play सेटिंग्स से कभी भी रद्द कर सकते हैं।</p>
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

const getTrialEndingTemplate = (lang = 'en') => {
  return trialEndingTemplates[lang] || trialEndingTemplates.en;
};

module.exports = { getTrialEndingTemplate };