import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insidex_app/core/routes/app_routes.dart';

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
      final code = _gen();

      await _firestore.collection('otp_verifications').doc(widget.email).set({
        'email': widget.email,
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 10))),
        'attempts': 0,
      }, SetOptions(merge: true));

      await _firestore.collection('mail_queue').add({
        'to': widget.email,
        'subject': 'Your INSIDEX password',
        'text': 'Your password: $code',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _toast('Code sent to ${widget.email}');
      _countdown();
    } catch (e) {
      _toast('Failed to send code. $e', bg: Colors.red);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    final input = _codeCtrl.text.trim();
    if (input.length < 4) {
      _toast('Please enter the code.');
      return;
    }
    setState(() => _busy = true);

    try {
      // 1) OTP kaydını al
      final doc = await _firestore
          .collection('otp_verifications')
          .doc(widget.email)
          .get();
      if (!doc.exists) {
        _toast('No code found. Please request a new one.', bg: Colors.red);
        return;
      }
      final data = doc.data()!;
      final server =
          (data['code'] ?? data['otp'] ?? data['passcode'])?.toString();
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        _toast('Code expired. Request a new one.', bg: Colors.red);
        return;
      }
      if (server == null || input != server) {
        try {
          await doc.reference.update({'attempts': FieldValue.increment(1)});
        } catch (_) {}
        _toast('Incorrect code. Try again.', bg: Colors.red);
        return;
      }

      // HESABI O ANDA OLUŞTUR
      UserCredential cred;
      try {
        cred = await _auth.createUserWithEmailAndPassword(
          email: widget.email,
          password: input, // mailde gelen 6 haneli kod
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          _toast('Account already exists. Please log in.');
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.welcome, (_) => false);
          return;
        } else {
          _toast('Verification failed. ${e.message ?? e.code}', bg: Colors.red);
          return;
        }
      }

      // 4) adı pending dokümandan çek (varsa)
      final name = (data['name'] ?? '') as String;

      // 5) kullanıcı profili
      await cred.user?.updateDisplayName(name);

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': widget.email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'isPremium': false,
        'favoriteSessionIds': [],
        'completedSessionIds': [],
        'totalListeningMinutes': 0,
        'emailVerified': true,
        'emailVerifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 6) OTP dokümanını temizle
      try {
        await doc.reference.delete();
      } catch (_) {}

      _toast('Account created and verified!');

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
