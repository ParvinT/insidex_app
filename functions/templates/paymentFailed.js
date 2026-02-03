// functions/templates/paymentFailed.js

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

const paymentFailedTemplates = {
  en: {
    subject: 'Action required: Payment failed for InsideX',
    html: (userName, planName) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Payment Failed</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Payment failed</h1>
      <p class="text">Hi ${userName},</p>
      <p class="text">We couldn't process your payment for ${planName}.</p>
      <div class="alert-box">
        <p class="alert-text">To avoid losing access to premium features, please update your payment method in your App Store or Google Play account settings.</p>
      </div>
      <p class="text">If you believe this is an error, please contact your bank or payment provider.</p>
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
    subject: 'İşlem gerekli: InsideX ödemeniz başarısız oldu',
    html: (userName, planName) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Ödeme Başarısız</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Ödeme başarısız oldu</h1>
      <p class="text">Merhaba ${userName},</p>
      <p class="text">${planName} için ödemenizi işleyemedik.</p>
      <div class="alert-box">
        <p class="alert-text">Premium özelliklere erişiminizi kaybetmemek için lütfen App Store veya Google Play hesap ayarlarından ödeme yönteminizi güncelleyin.</p>
      </div>
      <p class="text">Bunun bir hata olduğunu düşünüyorsanız lütfen bankanız veya ödeme sağlayıcınızla iletişime geçin.</p>
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
    subject: 'Требуется действие: ошибка оплаты InsideX',
    html: (userName, planName) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Ошибка оплаты</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">Ошибка оплаты</h1>
      <p class="text">Здравствуйте, ${userName}!</p>
      <p class="text">Нам не удалось обработать ваш платеж за ${planName}.</p>
      <div class="alert-box">
        <p class="alert-text">Чтобы не потерять доступ к премиум-функциям, обновите способ оплаты в настройках App Store или Google Play.</p>
      </div>
      <p class="text">Если вы считаете, что это ошибка, свяжитесь с вашим банком или платежным провайдером.</p>
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
    subject: 'कार्रवाई आवश्यक: InsideX भुगतान विफल',
    html: (userName, planName) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>भुगतान विफल</title>
  <style>${baseStyles}</style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">InsideX</div>
    </div>
    <div class="content">
      <h1 class="title">भुगतान विफल</h1>
      <p class="text">नमस्ते ${userName},</p>
      <p class="text">हम ${planName} के लिए आपका भुगतान संसाधित नहीं कर सके।</p>
      <div class="alert-box">
        <p class="alert-text">प्रीमियम सुविधाओं तक पहुंच न खोने के लिए, कृपया App Store या Google Play खाता सेटिंग्स में अपनी भुगतान विधि अपडेट करें।</p>
      </div>
      <p class="text">यदि आपको लगता है कि यह एक त्रुटि है, तो कृपया अपने बैंक या भुगतान प्रदाता से संपर्क करें।</p>
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

const getPaymentFailedTemplate = (lang = 'en') => {
  return paymentFailedTemplates[lang] || paymentFailedTemplates.en;
};

module.exports = { getPaymentFailedTemplate };