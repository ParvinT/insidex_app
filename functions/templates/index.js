// functions/templates/index.js
// Export all email templates

const { getOtpTemplate } = require('./otp');
const { getWelcomeTemplate } = require('./welcome');
const { getPasswordResetTemplate } = require('./passwordReset');

// Supported languages
const SUPPORTED_LANGUAGES = ['en', 'tr', 'ru', 'hi'];
const DEFAULT_LANGUAGE = 'en';

/**
 * Validate and normalize language code
 * @param {string} lang - Language code
 * @returns {string} - Valid language code or default
 */
const normalizeLanguage = (lang) => {
  if (!lang || typeof lang !== 'string') {
    return DEFAULT_LANGUAGE;
  }
  const normalized = lang.toLowerCase().trim();
  return SUPPORTED_LANGUAGES.includes(normalized) ? normalized : DEFAULT_LANGUAGE;
};

module.exports = {
  getOtpTemplate,
  getWelcomeTemplate,
  getPasswordResetTemplate,
  normalizeLanguage,
  SUPPORTED_LANGUAGES,
  DEFAULT_LANGUAGE
};