// functions/subscriptionEmails.js
//
// Subscription Email System for InsideX
// Handles RevenueCat webhook events via Firebase Extension
//
// Architecture:
// ┌─────────────────────────────────────────────────────────────┐
// │  RevenueCat Webhook → Firebase Extension                    │
// │                           │                                 │
// │                           ▼                                 │
// │              revenuecat_events/{eventId}                    │
// │                           │                                 │
// │                           ▼                                 │
// │           onRevenueCatEvent (this file)                     │
// │                           │                                 │
// │                           ▼                                 │
// │                    mail_queue → sendEmailFromQueue          │
// └─────────────────────────────────────────────────────────────┘

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Import subscription email templates
const { 
  getSubscriptionStartedTemplate,
  getTrialEndingTemplate,
  getSubscriptionExpiredTemplate,
  getPaymentFailedTemplate,
  getPlanChangedTemplate,
  normalizeLanguage 
} = require("./templates");

// ============================================================
// CONSTANTS
// ============================================================

// RevenueCat event types we care about
const EVENT_TYPES = {
  INITIAL_PURCHASE: 'INITIAL_PURCHASE',
  RENEWAL: 'RENEWAL',
  PRODUCT_CHANGE: 'PRODUCT_CHANGE',
  CANCELLATION: 'CANCELLATION',
  UNCANCELLATION: 'UNCANCELLATION',
  EXPIRATION: 'EXPIRATION',
  BILLING_ISSUE: 'BILLING_ISSUE',
  SUBSCRIBER_ALIAS: 'SUBSCRIBER_ALIAS',
};

// Product ID to plan name mapping
const PRODUCT_NAMES = {
  'insidex_lite_monthly': { en: 'Lite Monthly', tr: 'Lite Aylık', ru: 'Lite Ежемесячный', hi: 'Lite मासिक' },
  'insidex_standard_monthly': { en: 'Standard Monthly', tr: 'Standard Aylık', ru: 'Standard Ежемесячный', hi: 'Standard मासिक' },
  'insidex_standard_yearly': { en: 'Standard Yearly', tr: 'Standard Yıllık', ru: 'Standard Годовой', hi: 'Standard वार्षिक' },
};

// ============================================================
// HELPER FUNCTIONS
// ============================================================

/**
 * Get user data from Firestore
 * @param {string} userId - Firebase UID (from app_user_id)
 * @returns {Promise<{email: string, name: string, lang: string} | null>}
 */
async function getUserData(userId) {
  try {
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();
    
    if (!userDoc.exists) {
      console.log(`User not found: ${userId}`);
      return null;
    }
    
    const data = userDoc.data();
    return {
      email: data.email,
      name: data.name || 'User',
      lang: normalizeLanguage(data.preferredLanguage),
    };
  } catch (error) {
    console.error(`Error getting user data: ${error}`);
    return null;
  }
}

/**
 * Get localized plan name
 * @param {string} productId - RevenueCat product ID
 * @param {string} lang - Language code
 * @returns {string}
 */
function getPlanName(productId, lang = 'en') {
  if (!productId) return 'InsideX';
  
  
  const cleanProductId = productId.split(':')[0];
  
  const plan = PRODUCT_NAMES[cleanProductId];
  if (!plan) {
    console.log(`Unknown product ID: ${productId}, cleaned: ${cleanProductId}`);
    return cleanProductId;
  }
  
  return plan[lang] || plan.en || cleanProductId;
}

/**
 * Get tier from product ID
 * @param {string} productId 
 * @returns {string}
 */
function getTierFromProductId(productId) {
  if (productId.includes('standard')) return 'standard';
  if (productId.includes('lite')) return 'lite';
  return 'free';
}

/**
 * Format timestamp to readable date
 * @param {number} timestampMs - Timestamp in milliseconds
 * @param {string} lang - Language code
 * @returns {string}
 */
function formatDate(timestampMs, lang = 'en') {
  if (!timestampMs) return '';
  
  const date = new Date(timestampMs);
  
  const locales = {
    en: 'en-US',
    tr: 'tr-TR',
    ru: 'ru-RU',
    hi: 'hi-IN',
  };
  
  return date.toLocaleDateString(locales[lang] || 'en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

/**
 * Check if we should send email for this event
 * Prevents duplicate emails and spam
 * @param {string} eventId 
 * @param {string} eventType 
 * @param {string} userId 
 * @returns {Promise<boolean>}
 */
async function shouldSendEmail(eventId, eventType, userId) {
  try {
    // Check if we already processed this event
    const processedRef = admin.firestore()
      .collection('processed_subscription_emails')
      .doc(eventId);
    
    const processed = await processedRef.get();
    if (processed.exists) {
      console.log(`Event already processed: ${eventId}`);
      return false;
    }
    
    // For certain events, check cooldown (prevent spam)
    if (eventType === EVENT_TYPES.BILLING_ISSUE) {
      // Only send billing issue email once per 24 hours
      const oneDayAgo = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 24 * 60 * 60 * 1000)
      );
      
      const recentBillingEmails = await admin.firestore()
        .collection('mail_queue')
        .where('userId', '==', userId)
        .where('type', '==', 'payment_failed')
        .where('createdAt', '>', oneDayAgo)
        .limit(1)
        .get();
      
      if (!recentBillingEmails.empty) {
        console.log(`Billing issue email cooldown for user: ${userId}`);
        return false;
      }
    }
    
    return true;
  } catch (error) {
    console.error(`Error checking shouldSendEmail: ${error}`);
    return true; // Default to sending if check fails
  }
}

/**
 * Mark event as processed
 * @param {string} eventId 
 * @param {string} eventType 
 * @param {string} userId 
 */
async function markEventProcessed(eventId, eventType, userId) {
  try {
    await admin.firestore()
      .collection('processed_subscription_emails')
      .doc(eventId)
      .set({
        eventType,
        userId,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
  } catch (error) {
    console.error(`Error marking event processed: ${error}`);
  }
}

/**
 * Queue an email
 * @param {Object} emailData 
 */
async function queueEmail(emailData) {
  try {
    await admin.firestore().collection('mail_queue').add({
      ...emailData,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
    });
    console.log(`Email queued: ${emailData.type} to ${emailData.to}`);
  } catch (error) {
    console.error(`Error queueing email: ${error}`);
    throw error;
  }
}

// ============================================================
// EMAIL HANDLERS
// ============================================================

/**
 * Handle INITIAL_PURCHASE event
 * Sends welcome email for new subscription or trial
 * 
 * Template signature: subject(planName), html(userName, planName, expiryDate, isTrial)
 */
async function handleInitialPurchase(eventData, userData) {
  const { product_id, period_type, expiration_at_ms } = eventData;
  const { email, name, lang } = userData;
  
  const isTrial = period_type === 'TRIAL';
  const planName = getPlanName(product_id, lang);
  const expiryDate = formatDate(expiration_at_ms, lang);
  
  const template = getSubscriptionStartedTemplate(lang);
  
  await queueEmail({
    to: email,
    type: 'subscription_started',
    subject: template.subject(planName),
    html: template.html(name, planName, expiryDate, isTrial),
    userId: eventData.app_user_id,
    lang,
    metadata: {
      productId: product_id,
      isTrial,
    },
  });
  
  console.log(`Subscription started email sent to ${email} (${isTrial ? 'trial' : 'paid'})`);
}

/**
 * Handle EXPIRATION event
 * Sends notification when subscription or trial expires
 * 
 * Template signature: subject (string), html(userName, planName)
 */
async function handleExpiration(eventData, userData) {
  const { product_id } = eventData;
  const { email, name, lang } = userData;
  
  const planName = getPlanName(product_id, lang);
  
  const template = getSubscriptionExpiredTemplate(lang);
  
  await queueEmail({
    to: email,
    type: 'subscription_expired',
    subject: template.subject,
    html: template.html(name, planName),
    userId: eventData.app_user_id,
    lang,
    metadata: {
      productId: product_id,
    },
  });
  
  console.log(`Subscription expired email sent to ${email}`);
}

/**
 * Handle BILLING_ISSUE event
 * Sends urgent notification about payment failure
 * 
 * Template signature: subject (string), html(userName, planName)
 */
async function handleBillingIssue(eventData, userData) {
  const { product_id } = eventData;
  const { email, name, lang } = userData;
  
  const planName = getPlanName(product_id, lang);
  
  const template = getPaymentFailedTemplate(lang);
  
  await queueEmail({
    to: email,
    type: 'payment_failed',
    subject: template.subject,
    html: template.html(name, planName),
    userId: eventData.app_user_id,
    lang,
    metadata: {
      productId: product_id,
    },
  });
  
  console.log(`Payment failed email sent to ${email}`);
}

/**
 * Handle PRODUCT_CHANGE event
 * Sends notification about plan upgrade/downgrade
 * 
 * Template signature: subject (string), html(userName, oldPlan, newPlan, effectiveDate, isImmediate)
 */
async function handleProductChange(eventData, userData) {
  const { product_id, new_product_id, expiration_at_ms } = eventData;
  const { email, name, lang } = userData;
  
  // Determine old and new plans
  const oldPlan = getPlanName(product_id, lang);
  const newPlan = getPlanName(new_product_id || product_id, lang);
  
  // Determine if immediate or deferred
  // If expiration is in the future and different from now, it's deferred
  const now = Date.now();
  const isDeferred = expiration_at_ms && (expiration_at_ms - now > 24 * 60 * 60 * 1000);
  const effectiveDate = isDeferred ? formatDate(expiration_at_ms, lang) : '';
  const isImmediate = !isDeferred;
  
  const template = getPlanChangedTemplate(lang);
  
  await queueEmail({
    to: email,
    type: 'plan_changed',
    subject: template.subject,
    html: template.html(name, oldPlan, newPlan, effectiveDate, isImmediate),
    userId: eventData.app_user_id,
    lang,
    metadata: {
      oldProductId: product_id,
      newProductId: new_product_id,
      isDeferred,
    },
  });
  
  console.log(`Plan changed email sent to ${email} (${isDeferred ? 'deferred' : 'immediate'})`);
}

// ============================================================
// MAIN EVENT HANDLER
// ============================================================

/**
 * Main Cloud Function - triggers on RevenueCat events
 * Listens to revenuecat_events collection
 */
const onRevenueCatEvent = functions.firestore
  .document('revenuecat_events/{eventId}')
  .onCreate(async (snap, context) => {
    const eventId = context.params.eventId;
    const eventData = snap.data();
    
    console.log(`Processing RevenueCat event: ${eventId}`);
    console.log(`Event type: ${eventData.type}`);
    
    // Skip sandbox events in production (optional - uncomment if needed)
    // if (eventData.environment === 'SANDBOX') {
    //   console.log('Skipping sandbox event');
    //   return null;
    // }
    
    const eventType = eventData.type;
    const userId = eventData.app_user_id;
    
    // Check if we should process this event type
    const handledEvents = [
      EVENT_TYPES.INITIAL_PURCHASE,
      EVENT_TYPES.EXPIRATION,
      EVENT_TYPES.BILLING_ISSUE,
      EVENT_TYPES.PRODUCT_CHANGE,
    ];
    
    if (!handledEvents.includes(eventType)) {
      console.log(`Skipping unhandled event type: ${eventType}`);
      return null;
    }
    
    // Check if we should send email (dedup & cooldown)
    const shouldSend = await shouldSendEmail(eventId, eventType, userId);
    if (!shouldSend) {
      return null;
    }
    
    // Get user data
    const userData = await getUserData(userId);
    if (!userData || !userData.email) {
      console.error(`Cannot send email - no user data for: ${userId}`);
      return null;
    }
    
    try {
      // Route to appropriate handler
      switch (eventType) {
        case EVENT_TYPES.INITIAL_PURCHASE:
          await handleInitialPurchase(eventData, userData);
          break;
          
        case EVENT_TYPES.EXPIRATION:
          await handleExpiration(eventData, userData);
          break;
          
        case EVENT_TYPES.BILLING_ISSUE:
          await handleBillingIssue(eventData, userData);
          break;
          
        case EVENT_TYPES.PRODUCT_CHANGE:
          await handleProductChange(eventData, userData);
          break;
          
        default:
          console.log(`No handler for event type: ${eventType}`);
          return null;
      }
      
      // Mark event as processed
      await markEventProcessed(eventId, eventType, userId);
      
      console.log(`Successfully processed event: ${eventId}`);
      return null;
      
    } catch (error) {
      console.error(`Error processing event ${eventId}:`, error);
      
      // Log error for monitoring
      await admin.firestore().collection('subscription_email_errors').add({
        eventId,
        eventType,
        userId,
        error: error.message,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return null;
    }
  });

// ============================================================
// SCHEDULED FUNCTION - TRIAL ENDING REMINDER
// ============================================================

/**
 * Daily check for trials ending tomorrow
 * Runs every day at 10:00 AM UTC
 * 
 * Template signature: subject (string), html(userName, planName, expiryDate)
 */
const checkTrialEnding = functions.pubsub
  .schedule('0 10 * * *') // Every day at 10:00 UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('Running trial ending check...');
    
    try {
      // Calculate tomorrow's date range
      const now = new Date();
      const tomorrow = new Date(now);
      tomorrow.setDate(tomorrow.getDate() + 1);
      
      // Start and end of tomorrow
      const tomorrowStart = new Date(tomorrow);
      tomorrowStart.setHours(0, 0, 0, 0);
      
      const tomorrowEnd = new Date(tomorrow);
      tomorrowEnd.setHours(23, 59, 59, 999);
      
      console.log(`Checking trials expiring between ${tomorrowStart.toISOString()} and ${tomorrowEnd.toISOString()}`);
      
      // Query revenuecat_customers for trials ending tomorrow
      const customersSnapshot = await admin.firestore()
        .collection('revenuecat_customers')
        .get();
      
      let emailsSent = 0;
      
      for (const customerDoc of customersSnapshot.docs) {
        const userId = customerDoc.id;
        const customerData = customerDoc.data();
        
        // Check subscriptions
        const subscriptions = customerData.subscriptions;
        if (!subscriptions) continue;
        
        for (const [productId, subData] of Object.entries(subscriptions)) {
          // Check if it's a trial
          if (subData.period_type !== 'trial') continue;
          
          // Check expiration date
          const expiresDate = subData.expires_date;
          if (!expiresDate) continue;
          
          const expiresAt = new Date(expiresDate);
          
          // Check if expires tomorrow
          if (expiresAt >= tomorrowStart && expiresAt <= tomorrowEnd) {
            console.log(`Trial ending tomorrow for user: ${userId}, product: ${productId}`);
            
            // Check if we already sent this reminder
            const reminderKey = `trial_ending_${userId}_${productId}_${tomorrow.toISOString().split('T')[0]}`;
            const existingReminder = await admin.firestore()
              .collection('processed_subscription_emails')
              .doc(reminderKey)
              .get();
            
            if (existingReminder.exists) {
              console.log(`Trial ending reminder already sent: ${reminderKey}`);
              continue;
            }
            
            // Get user data
            const userData = await getUserData(userId);
            if (!userData || !userData.email) {
              console.log(`No user data for: ${userId}`);
              continue;
            }
            
            // Send trial ending email
            const { email, name, lang } = userData;
            const planName = getPlanName(productId, lang);
            const expiryDate = formatDate(expiresAt.getTime(), lang);
            
            const template = getTrialEndingTemplate(lang);
            
            await queueEmail({
              to: email,
              type: 'trial_ending',
              subject: template.subject,
              html: template.html(name, planName, expiryDate),
              userId,
              lang,
              metadata: {
                productId,
                expiryDate: expiresDate,
              },
            });
            
            // Mark as sent
            await admin.firestore()
              .collection('processed_subscription_emails')
              .doc(reminderKey)
              .set({
                type: 'trial_ending',
                userId,
                productId,
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            
            emailsSent++;
            console.log(`Trial ending email sent to ${email}`);
          }
        }
      }
      
      console.log(`Trial ending check complete. Emails sent: ${emailsSent}`);
      return null;
      
    } catch (error) {
      console.error('Error in trial ending check:', error);
      return null;
    }
  });

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  onRevenueCatEvent,
  checkTrialEnding,
};