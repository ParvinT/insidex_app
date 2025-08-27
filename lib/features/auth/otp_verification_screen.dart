// lib/features/auth/otp_verification_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/user_provider.dart';
import '../../services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/analytics_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  const OTPVerificationScreen({super.key, required this.email});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _codeCtrl = TextEditingController();
  bool _busy = false;
  bool _resending = false;
  Timer? _t;
  int _left = 0;

  @override
  void initState() {
    super.initState();
    _countdown(); // Start countdown on init
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _t?.cancel();
    super.dispose();
  }

  void _toast(String m, {Color bg = Colors.black}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), backgroundColor: bg));
  }

  String _gen() => List.generate(6, (_) => Random.secure().nextInt(10)).join();

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
        _toast('New code sent to ${widget.email}');
        _countdown();
      } else {
        _toast(result['error'] ?? 'Failed to send code', bg: Colors.red);
      }
    } catch (e) {
      _toast('Failed to send code. $e', bg: Colors.red);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    final input = _codeCtrl.text.trim();
    if (input.length != 6) {
      _toast('Please enter the 6-digit code.');
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
        _toast(result['error'] ?? 'Verification failed', bg: Colors.red);
        setState(() => _busy = false);
        return;
      }

      // Success! Load user data
      final user = result['user'] as User;
      if (mounted) {
        await context.read<UserProvider>().loadUserData(user.uid);
      }

      _toast('Account created successfully!');

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
      _toast('Verification failed. $e', bg: Colors.red);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label =
        GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6E6E6E));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('We sent a password to:', style: label),
            const SizedBox(height: 4),
            Text(widget.email,
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text('Enter the 6-digit password:',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
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
                    : const Text('Verify'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                    _left > 0 ? 'You can resend in $_left s' : "Didn't get it?",
                    style: label),
                const Spacer(),
                TextButton(
                  onPressed: (_left > 0 || _resending) ? null : _resend,
                  child: _resending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Resend'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
