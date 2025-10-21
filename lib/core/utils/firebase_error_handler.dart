// lib/core/utils/firebase_error_handler.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Firebase error kodlarını kullanıcı dostu mesajlara çeviren helper
/// Backend servislerden dönen error code'ları UI'da context ile çevirir
class FirebaseErrorHandler {
  // Prevent instantiation
  FirebaseErrorHandler._();

  /// Firebase error code'unu context ile çeviriye çevirir
  ///
  /// Kullanım:
  /// ```dart
  /// final result = await FirebaseService.changePassword(...);
  /// if (!result['success']) {
  ///   final message = FirebaseErrorHandler.getErrorMessage(
  ///     result['code'] ?? 'unknown',
  ///     context,
  ///   );
  ///   showDialog(message);
  /// }
  /// ```
  static String getErrorMessage(String? code, BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Null veya empty code kontrolü
    if (code == null || code.isEmpty) {
      return l10n.unexpectedErrorOccurred;
    }

    switch (code) {
      // Password errors
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.currentPasswordIncorrect;

      case 'same-password':
        return l10n.newPasswordSameAsCurrent;

      case 'weak-password':
        return l10n.weakPassword;

      case 'password-too-weak':
        return l10n.passwordTooWeak;

      // User errors
      case 'no-user':
        return l10n.noUserSignedIn;

      case 'user-not-found':
        return l10n.userNotFound;

      case 'user-disabled':
        return l10n.accountDisabled;

      // Email errors
      case 'email-already-in-use':
        return l10n.emailAlreadyInUse;

      case 'invalid-email':
        return l10n.invalidEmail;

      case 'invalid-email-address':
        return l10n.invalidEmailAddress;

      // Auth errors
      case 'requires-recent-login':
        return l10n.pleaseSignInAgain;

      case 'auth-failed':
        return l10n.authenticationFailed;

      case 'operation-not-allowed':
        return l10n.operationNotAllowed;

      // Network errors
      case 'network-request-failed':
        return l10n.networkError;

      case 'too-many-requests':
        return l10n.tooManyAttempts;

      case 'too-many-failed-attempts':
        return l10n.tooManyFailedAttempts;

      // Validation errors
      case 'name-too-short':
        return l10n.nameTooShort;

      // OTP/Verification errors
      case 'failed-to-resend':
        return l10n.failedToResendCode;

      case 'no-pending-verification':
        return l10n.noPendingVerification;

      case 'verification-code-not-found':
        return l10n.verificationCodeNotFound;

      case 'verification-code-already-used':
        return l10n.verificationCodeAlreadyUsed;

      case 'verification-code-expired':
        return l10n.verificationCodeExpired;

      case 'too-many-verification-attempts':
        return l10n.tooManyVerificationAttempts;
        
      case 'invalid-verification-code':
        return l10n.invalidVerificationCode;

      // Default
      case 'unknown':
      default:
        return l10n.unexpectedErrorOccurred;
    }
  }

  /// Result'tan direkt error mesajı al (kısayol method)
  ///
  /// Kullanım:
  /// ```dart
  /// final result = await FirebaseService.signIn(...);
  /// if (!result['success']) {
  ///   final message = FirebaseErrorHandler.getErrorFromResult(result, context);
  ///   showSnackBar(message);
  /// }
  /// ```
  static String getErrorFromResult(
    Map<String, dynamic> result,
    BuildContext context,
  ) {
    return getErrorMessage(result['code'], context);
  }
}
