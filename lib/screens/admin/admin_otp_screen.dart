import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../services/admin_auth_api.dart';
import '../../widgets/otp_code_field.dart';
import '../../widgets/primary_button.dart';
import 'admin_shell.dart';

const int _codeLength = 6;
const int _resendCooldownSeconds = 30;

/// Step 2 of admin sign-in — the 6-digit code emailed after a successful
/// password check. Verifying issues the real session token, so this is the
/// only screen in the admin flow that leads into [AdminShell].
class AdminOtpScreen extends StatefulWidget {
  const AdminOtpScreen({super.key, required this.email});

  final String email;

  @override
  State<AdminOtpScreen> createState() => _AdminOtpScreenState();
}

class _AdminOtpScreenState extends State<AdminOtpScreen> {
  final GlobalKey<OtpCodeFieldState> _codeFieldKey = GlobalKey<OtpCodeFieldState>();

  String _code = '';
  String? _codeError;
  bool _isSubmitting = false;
  bool _isResending = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = _resendCooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown -= 1);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _codeError = _code.length == _codeLength ? null : 'Enter the full $_codeLength-digit code';
    });
    if (_codeError != null) return;

    setState(() => _isSubmitting = true);
    try {
      await AdminAuthApi.verifyOtp(email: widget.email, code: _code);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AdminShell()),
        (Route<dynamic> route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _codeFieldKey.currentState?.clear();
      setState(() => _code = '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          content: Text(error.message),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      final String message = await AdminAuthApi.resendOtp(widget.email);
      if (!mounted) return;
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          content: Text(error.message),
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.navy, size: 22),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Verify Your Identity',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We've sent a 6-digit code to ${widget.email}. Enter it "
                    'below to finish signing in.',
                    style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.slate),
                  ),
                  const SizedBox(height: 24),
                  OtpCodeField(
                    key: _codeFieldKey,
                    length: _codeLength,
                    errorText: _codeError,
                    onChanged: (String value) => setState(() {
                      _code = value;
                      if (_codeError != null) _codeError = null;
                    }),
                    onCompleted: (_) => _submit(),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: _isSubmitting ? 'Verifying…' : 'Verify & Sign In',
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: (_isResending || _cooldown > 0) ? null : _resend,
                      child: Text(
                        _cooldown > 0
                            ? 'Resend code in ${_cooldown}s'
                            : (_isResending ? 'Sending…' : "Didn't get a code? Resend"),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
