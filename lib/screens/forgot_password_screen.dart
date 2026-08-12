import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../services/auth_api.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

/// First half of the forgot-password flow — the user enters their email
/// and, regardless of whether an account exists for it (the backend
/// deliberately never reveals that), sees the same "check your email"
/// confirmation, from which they can move on to enter the emailed code.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final String email = (value ?? '').trim();
    if (email.isEmpty) return 'Please enter your email address';
    final RegExp pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await AuthApi.forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _emailSent = true);
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _goToResetPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ResetPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IconButton(
                onPressed: _goBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back, color: AppColors.navy, size: 22),
              ),
              const SizedBox(height: 12),
              const Text(
                'Forgot Password',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _emailSent
                    ? "If an account exists for that email, we've sent a "
                          'reset code to it. Enter the code on the next '
                          'screen to choose a new password.'
                    : "Enter the email on your account and we'll send you a "
                          'code to reset your password.',
                style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.slate),
              ),
              const SizedBox(height: 22),
              if (_emailSent) ...<Widget>[
                PrimaryButton(
                  label: 'Enter Reset Code',
                  onPressed: _goToResetPassword,
                ),
              ] else ...<Widget>[
                Form(
                  key: _formKey,
                  child: LabeledTextField(
                    label: 'Email Address',
                    hint: 'name@example.com',
                    controller: _emailController,
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.email],
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _isSubmitting ? 'Sending…' : 'Send Reset Code',
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: _goToResetPassword,
                  child: const Text(
                    'Already have a reset code?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
