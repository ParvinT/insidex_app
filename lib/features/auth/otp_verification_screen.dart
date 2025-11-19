// lib/features/auth/otp_verification_screen.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/firebase_error_handler.dart';
import '../../providers/user_provider.dart';
import '../../services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/analytics_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/device_session_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  const OTPVerificationScreen({super.key, required this.email});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {

  final _codeCtrl = TextEditingController();
  final _focusNode = FocusNode(); 
  bool _busy = false;
  bool _resending = false;
  Timer? _t;
  int _left = 0;

  @override
  void initState() {
    super.initState();
    _countdown(); // Start countdown on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 300), () {
        _focusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _focusNode.dispose();
    _t?.cancel();
    super.dispose();
  }

  void _toast(String m, {Color bg = Colors.black}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), backgroundColor: bg));
  }

  void _countdown([int s = 60]) {
    _t?.cancel();
    setState(() => _left = s);
    _t = Timer.periodic(const Duration(seconds: 1), (tm) {
      if (!mounted) return;
      if (_left <= 1) {
        tm.cancel();
        setState(() => _left = 0);
      } else {
        setState(() => _left -= 1);
      }
    });
  }

  Future<void> _resend() async {
    if (_left > 0 || _resending) return;
    setState(() => _resending = true);

    try {
      final result = await FirebaseService.resendOTP(widget.email);

      if (result['success']) {
        _toast('${AppLocalizations.of(context).newCodeSentTo} ${widget.email}');
        _countdown();
      } else {
        final errorMessage = FirebaseErrorHandler.getErrorMessage(
          result['code'],
          context,
        );
        _toast(errorMessage, bg: Colors.red);
      }
    } catch (e) {
      _toast('${AppLocalizations.of(context).failedToSendCode}. $e',
          bg: Colors.red);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    final input = _codeCtrl.text.trim();
    if (input.length != 6) {
      _toast(AppLocalizations.of(context).pleaseEnterSixDigitCode);
      return;
    }
    setState(() => _busy = true);

    try {
      // Use Firebase service to verify OTP and create account
      final result = await FirebaseService.verifyOTPAndCreateAccount(
        email: widget.email,
        code: input,
      );

      if (!result['success']) {
        final errorMessage = FirebaseErrorHandler.getErrorMessage(
          result['code'],
          context,
        );
        _toast(errorMessage, bg: Colors.red);
        setState(() => _busy = false);
        return;
      }

      // Success! Load user data
      final user = result['user'] as User;
      if (mounted) {
        await context.read<UserProvider>().loadUserData(user.uid);
      }

      debugPrint('💾 Saving active device for new user...');
      await DeviceSessionService().saveActiveDevice(user.uid);
      debugPrint('✅ Active device saved for new user');

      _toast(AppLocalizations.of(context).accountCreatedSuccessfully);

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_logged_in', true);
        await prefs.setString('cached_user_id', user.uid);
        await prefs.setString('cached_user_email', user.email ?? '');
        debugPrint('✅ New user login state cached for device');
      } catch (e) {
        debugPrint('⚠️ Could not cache login state: $e');
      }

      final prefs = await SharedPreferences.getInstance();
      final goals = prefs.getStringList('goals') ?? [];
      final gender = prefs.getString('gender');
      final birthDateString = prefs.getString('birthDate');
      final userAge = prefs.getInt('userAge');

      if (user != null &&
          (goals.isNotEmpty || gender != null || birthDateString != null)) {
        try {
          // Create a map with only non-null values
          final Map<String, dynamic> userData = {
            'onboardingComplete': true,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          if (goals.isNotEmpty) userData['goals'] = goals;
          if (gender != null) userData['gender'] = gender.split('.').last;
          if (birthDateString != null) {
            userData['birthDate'] =
                Timestamp.fromDate(DateTime.parse(birthDateString));
          }
          if (userAge != null) userData['age'] = userAge;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update(userData);

          // Set analytics user properties
          await AnalyticsService.setUserProperties(
            userId: user.uid,
            goals: goals,
            gender: gender?.split('.').last,
            age: userAge,
          );

          debugPrint('Onboarding data saved to Firestore');
        } catch (e) {
          debugPrint('Error saving onboarding data: $e');
        }
      }
      // Navigate to home
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } catch (e) {
      _toast('${AppLocalizations.of(context).verificationFailed}. $e',
          bg: Colors.red);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label =
        GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6E6E6E));
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).verifyEmail),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).weSentPasswordTo, style: label),
            const SizedBox(height: 4),
            Text(widget.email,
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).enterSixDigitPassword,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _codeCtrl,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: OutlineInputBorder(),
                hintText: '••••••',
              ),
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : Text(AppLocalizations.of(context).verify),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _left > 0
                        ? '${AppLocalizations.of(context).youCanResendIn} $_left ${AppLocalizations.of(context).seconds}'
                        : AppLocalizations.of(context).didntGetIt,
                    style: label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: (_left > 0 || _resending) ? null : _resend,
                  child: _resending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(AppLocalizations.of(context).resend),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
