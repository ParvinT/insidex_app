// functions/pushNotifications.js
//
// Push Notification System for InsideX
// Sends targeted push notifications via FCM topics + individual user tokens
//
// Supported Audience Types:
// - all: All users (topic: all_users)
// - language: By language (topic conditions)
// - tier: By subscription tier (topic conditions)
// - platform: By platform (topic conditions)
// - custom: Combined filters (topic conditions)
// - individual: Single user via FCM token (from users/{uid}/activeDevice)

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// ============================================================
// CONSTANTS
// ============================================================

const VALID_LANGUAGES = ["en", "tr", "ru", "hi"];
const VALID_TIERS = ["all", "free", "lite", "standard"];
const VALID_PLATFORMS = ["all", "ios", "android"];
const MAX_CONDITION_LENGTH = 5;

// ============================================================
// HELPERS
// ============================================================

/**
 * Build FCM topic condition string from target parameters.
 */
function buildTopicCondition(target) {
  if (!target || target.audience === "all") {
    return null;
  }

  const conditions = [];

  // Language filter
  if (target.languages && target.languages.length > 0) {
    const filtered = target.languages.filter((l) =>
      VALID_LANGUAGES.includes(l)
    );
    if (filtered.length === 1) {
      conditions.push(`'lang_${filtered[0]}' in topics`);
    } else if (filtered.length > 1) {
      const langCondition = filtered
        .map((l) => `'lang_${l}' in topics`)
        .join(" || ");
      conditions.push(`(${langCondition})`);
    }
  }

  // Tier filter
  if (target.tiers && target.tiers.length > 0) {
    const filtered = target.tiers.filter(
      (t) => VALID_TIERS.includes(t) && t !== "all"
    );
    if (filtered.length === 1) {
      conditions.push(`'tier_${filtered[0]}' in topics`);
    } else if (filtered.length > 1) {
      const tierCondition = filtered
        .map((t) => `'tier_${t}' in topics`)
        .join(" || ");
      conditions.push(`(${tierCondition})`);
    }
  }

  // Platform filter
  if (target.platforms && target.platforms.length > 0) {
    const filtered = target.platforms.filter(
      (p) => VALID_PLATFORMS.includes(p) && p !== "all"
    );
    if (filtered.length === 1) {
      conditions.push(`'platform_${filtered[0]}' in topics`);
    } else if (filtered.length > 1) {
      const platformCondition = filtered
        .map((p) => `'platform_${p}' in topics`)
        .join(" || ");
      conditions.push(`(${platformCondition})`);
    }
  }

  if (conditions.length === 0) {
    return null;
  }

  if (conditions.length > MAX_CONDITION_LENGTH) {
    console.warn(
      `Condition exceeds ${MAX_CONDITION_LENGTH} topics, truncating`
    );
    conditions.length = MAX_CONDITION_LENGTH;
  }

  return conditions.join(" && ");
}

/**
 * Get localized content with English fallback.
 */
function getLocalizedContent(titles, bodies, lang) {
  return {
    title: titles[lang] || titles.en || "InsideX",
    body: bodies[lang] || bodies.en || "",
  };
}

/**
 * Validate push notification document data.
 */
function validateNotificationData(data) {
  if (!data) {
    return { valid: false, error: "No data provided" };
  }

  if (!data.titles || Object.keys(data.titles).length === 0) {
    return { valid: false, error: "At least one title is required" };
  }

  if (!data.bodies || Object.keys(data.bodies).length === 0) {
      return { valid: false, error: "At least one body is required" };
  }

  if (!data.target || !data.target.audience) {
    return { valid: false, error: "Target audience is required" };
  }

  const validAudiences = [
    "all",
    "language",
    "tier",
    "platform",
    "custom",
    "individual",
  ];
  if (!validAudiences.includes(data.target.audience)) {
    return {
      valid: false,
      error: `Invalid audience: ${data.target.audience}`,
    };
  }

  if (data.target.audience === "individual" && !data.target.userId) {
    return { valid: false, error: "userId is required for individual target" };
  }

  return { valid: true, error: null };
}

/**
 * Send notification to individual user via FCM token.
 */
async function sendToIndividual(docId, data) {
  const { titles, bodies, target } = data;
  const customData = data.data || {};
  const userId = target.userId;

  const userDoc = await admin
    .firestore()
    .collection("users")
    .doc(userId)
    .get();

  if (!userDoc.exists) {
    throw new Error(`User not found: ${userId}`);
  }

  const userData = userDoc.data();
  const activeDevice = userData.activeDevice;

  if (!activeDevice || !activeDevice.token) {
    throw new Error(`No active device/token for user: ${userId}`);
  }

  const fcmToken = activeDevice.token;
  const userLang = userData.preferredLanguage || "en";
  const content = getLocalizedContent(titles, bodies, userLang);

  const message = {
    token: fcmToken,
    notification: {
      title: content.title,
      body: content.body,
    },
    data: {
      ...customData,
      notificationId: docId,
      type: data.notificationType || "general",
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
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  const response = await admin.messaging().send(message);
  console.log(`Individual message sent to ${userId}: ${response}`);

  return { successCount: 1, failureCount: 0 };
}

/**
 * Send notification via FCM topics.
 */
async function sendViaTopic(docId, data) {
  const { titles, bodies, target } = data;
  const customData = data.data || {};

  const condition = buildTopicCondition(target);
  const useTopicDirectly = condition === null;

  let successCount = 0;
  let failureCount = 0;

  if (useTopicDirectly) {
    const content = getLocalizedContent(titles, bodies, "en");

    const message = {
      topic: "all_users",
      notification: {
        title: content.title,
        body: content.body,
      },
      data: {
        ...customData,
        notificationId: docId,
        type: data.notificationType || "general",
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
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log(`Topic message sent: ${response}`);
    successCount = 1;
  } else if (
    target.audience === "language" &&
    target.languages &&
    target.languages.length > 0
  ) {
    for (const lang of target.languages) {
      if (!VALID_LANGUAGES.includes(lang)) continue;

      const content = getLocalizedContent(titles, bodies, lang);
      let msgCondition = `'lang_${lang}' in topics`;

      if (target.tiers && target.tiers.length > 0) {
        const tierFilters = target.tiers
          .filter((t) => VALID_TIERS.includes(t) && t !== "all")
          .map((t) => `'tier_${t}' in topics`);
        if (tierFilters.length > 0) {
          msgCondition += ` && ${tierFilters.join(" && ")}`;
        }
      }

      if (target.platforms && target.platforms.length > 0) {
        const platformFilters = target.platforms
          .filter((p) => VALID_PLATFORMS.includes(p) && p !== "all")
          .map((p) => `'platform_${p}' in topics`);
        if (platformFilters.length > 0) {
          msgCondition += ` && ${platformFilters.join(" && ")}`;
        }
      }

      const message = {
        condition: msgCondition,
        notification: {
          title: content.title,
          body: content.body,
        },
        data: {
          ...customData,
          notificationId: docId,
          type: data.notificationType || "general",
          lang: lang,
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
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      try {
        const response = await admin.messaging().send(message);
        console.log(`Sent to lang_${lang}: ${response}`);
        successCount++;
      } catch (sendError) {
        console.error(`Failed to send to lang_${lang}: ${sendError}`);
        failureCount++;
      }
    }
  } else {
    const targetLangs =
      target.languages && target.languages.length > 0
        ? target.languages.filter((l) => VALID_LANGUAGES.includes(l))
        : ["en"];

    for (const lang of targetLangs) {
      const content = getLocalizedContent(titles, bodies, lang);

      const message = {
        condition: condition,
        notification: {
          title: content.title,
          body: content.body,
        },
        data: {
          ...customData,
          notificationId: docId,
          type: data.notificationType || "general",
          lang: lang,
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
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      try {
        const response = await admin.messaging().send(message);
        console.log(`Condition message sent (${lang}): ${response}`);
        successCount++;
      } catch (sendError) {
        console.error(`Failed condition send (${lang}): ${sendError}`);
        failureCount++;
      }
    }
  }

  return { successCount, failureCount };
}

// ============================================================
// MAIN CLOUD FUNCTION
// ============================================================

const onPushNotificationCreated = functions.firestore
  .document("push_notifications/{docId}")
  .onCreate(async (snap, context) => {
    const docId = context.params.docId;
    const data = snap.data();

    console.log(`Processing push notification: ${docId}`);

    const validation = validateNotificationData(data);
    if (!validation.valid) {
      console.error(`Invalid notification data: ${validation.error}`);
      await snap.ref.update({
        status: "error",
        error: validation.error,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return null;
    }

    try {
      const { target } = data;
      let result;

      if (target.audience === "individual") {
        result = await sendToIndividual(docId, data);
      } else {
        result = await sendViaTopic(docId, data);
      }

      await snap.ref.update({
        status: result.successCount > 0 ? "sent" : "failed",
        successCount: result.successCount,
        failureCount: result.failureCount,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await admin.firestore().collection("push_notification_logs").add({
        notificationId: docId,
        titles: data.titles,
        bodies: data.bodies,
        target,
        condition:
          target.audience === "individual"
            ? `individual:${target.userId}`
            : buildTopicCondition(target) || "topic:all_users",
        successCount: result.successCount,
        failureCount: result.failureCount,
        createdBy: data.createdBy || "unknown",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        `Push notification ${docId} completed: ${result.successCount} success, ${result.failureCount} failures`
      );
      return null;
    } catch (error) {
      console.error(`Error processing notification ${docId}:`, error);

      await snap.ref.update({
        status: "error",
        error: error.message,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    }
  });

module.exports = {
  onPushNotificationCreated,
};