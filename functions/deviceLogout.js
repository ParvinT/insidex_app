// functions/deviceLogout.js
//
// Device Logout Notification System for InsideX
// Sends push notification to old device when user logs in from a new device
// Called directly from Flutter app via Cloud Functions callable

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// ============================================================
// LOCALIZED NOTIFICATION CONTENT
// ============================================================

const DEVICE_LOGOUT_TEXTS = {
  en: {
    title: "New Login Detected",
    body: "Your account was signed in from another device. If this wasn't you, please change your password.",
  },
  tr: {
    title: "Yeni Cihaz Girişi",
    body: "Hesabınıza başka bir cihazdan giriş yapıldı. Siz değilseniz şifrenizi değiştirin.",
  },
  ru: {
    title: "Новый вход в аккаунт",
    body: "В ваш аккаунт вошли с другого устройства. Если это не вы, смените пароль.",
  },
  hi: {
    title: "नया लॉगिन",
    body: "आपके खाते में दूसरे डिवाइस से लॉगिन हुआ। अगर यह आप नहीं थे, तो पासवर्ड बदलें।",
  },
};

/**
 * Get localized content for device logout notification.
 * Falls back to English if language is not supported.
 */
function getDeviceLogoutContent(lang) {
  return DEVICE_LOGOUT_TEXTS[lang] || DEVICE_LOGOUT_TEXTS.en;
}

// ============================================================
// CALLABLE CLOUD FUNCTION
// ============================================================

const sendDeviceLogoutNotification = functions.https.onCall(
  async (data, context) => {
    // Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to call this function."
      );
    }

    const { oldToken, platform, language } = data;

    // Validate required fields
    if (!oldToken || typeof oldToken !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "oldToken is required and must be a string."
      );
    }

    if (!platform || !["ios", "android"].includes(platform)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        'platform must be "ios" or "android".'
      );
    }

    const lang =
      language && ["en", "tr", "ru", "hi"].includes(language)
        ? language
        : "en";

    const content = getDeviceLogoutContent(lang);
    const callerUid = context.auth.uid;

    console.log(
      `Sending device logout notification: uid=${callerUid}, platform=${platform}, lang=${lang}`
    );

    try {
      const message = {
        token: oldToken,
        notification: {
          title: content.title,
          body: content.body,
        },
        data: {
          type: "device_logout",
          timestamp: Date.now().toString(),
        },
        android: {
          priority: "high",
          notification: {
            channelId: "insidex_general",
            icon: "ic_notification",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              "content-available": 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log(`Device logout notification sent successfully: ${response}`);

      return { success: true, messageId: response };
    } catch (error) {
      // Handle invalid/expired token gracefully
      if (
        error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered"
      ) {
        console.warn(
          `Old device token is invalid or expired: ${error.code}. Skipping notification.`
        );
        return { success: false, reason: "token_expired" };
      }

      console.error("Error sending device logout notification:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send device logout notification."
      );
    }
  }
);

module.exports = {
  sendDeviceLogoutNotification,
};