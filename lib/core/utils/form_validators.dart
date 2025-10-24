import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class FormValidators {
  // Prevent instantiation
  FormValidators._();

  // Email validator
  static String? validateEmail(String? value, [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      return context != null
          ? AppLocalizations.of(context).pleaseEnterEmail
          : 'Please enter your email';
    }

    // Basic email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return context != null
          ? AppLocalizations.of(context).pleaseEnterValidEmail
          : 'Please enter a valid email';
    }

    return null;
  }

  // Password validator
  static String? validatePassword(String? value, [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      return context != null
          ? AppLocalizations.of(context).pleaseEnterPassword
          : 'Please enter your password';
    }

    if (value.length < 6) {
      return context != null
          ? AppLocalizations.of(context).passwordMustBeAtLeast6Characters
          : 'Password must be at least 6 characters';
    }

    return null;
  }

  // Strong password validator (for registration)
  static String? validateStrongPassword(String? value,
      [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      return context != null
          ? AppLocalizations.of(context).pleaseEnterPassword
          : 'Please enter your password';
    }

    if (value.length < 8) {
      return context != null
          ? AppLocalizations.of(context).passwordMustBeAtLeast8Characters
          : 'Password must be at least 8 characters';
    }

    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return context != null
          ? AppLocalizations.of(context).passwordMustContainUppercase
          : 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return context != null
          ? AppLocalizations.of(context).passwordMustContainLowercase
          : 'Password must contain at least one lowercase letter';
    }

    // Check for at least one number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return context != null
          ? AppLocalizations.of(context).passwordMustContainNumber
          : 'Password must contain at least one number';
    }

    return null;
  }

  // Confirm password validator
  static String? validateConfirmPassword(String? value, String password,
      [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      return context != null
          ? AppLocalizations.of(context).pleaseConfirmPassword
          : 'Please confirm your password';
    }

    if (value != password) {
      return context != null
          ? AppLocalizations.of(context).passwordsDoNotMatch
          : 'Passwords do not match';
    }

    return null;
  }

  // Name validator
  static String? validateName(String? value, [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      return context != null
          ? AppLocalizations.of(context).pleaseEnterName
          : 'Please enter your name';
    }

    if (value.length < 2) {
      return context != null
          ? AppLocalizations.of(context).nameMustBeAtLeast2Characters
          : 'Name must be at least 2 characters';
    }

    if (!RegExp(
            '^[\\u0020-\\u007E\\u00C0-\\u024F\\u0400-\\u04FF\\s\\-\'\\.]+\$')
        .hasMatch(value)) {
      return context != null
          ? AppLocalizations.of(context).nameCanOnlyContainLetters
          : 'Name can only contain letters and spaces';
    }

    // Prevent names that are only whitespace
    if (value.trim().isEmpty) {
      return context != null
          ? AppLocalizations.of(context).pleaseEnterName
          : 'Please enter your name';
    }

    return null;
  }

  // Phone validator
  static String? validatePhone(String? value, [BuildContext? context]) {
    if (value == null || value.isEmpty) {
      return context != null
          ? AppLocalizations.of(context).pleaseEnterPhone
          : 'Please enter your phone number';
    }

    // Remove all non-digit characters for validation
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 10) {
      return context != null
          ? AppLocalizations.of(context).pleaseEnterValidPhone
          : 'Please enter a valid phone number';
    }

    return null;
  }

  // Generic required field validator
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter your $fieldName';
    }
    return null;
  }
}
