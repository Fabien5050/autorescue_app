import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../services/auth_api.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/primary_button.dart';
import 'admin_login_screen.dart';
import 'admin_reset_password_screen.dart';

/// Admin-portal counterpart to [ForgotPasswordScreen] — same backend call
/// ([AuthApi.forgotPassword] is role-agnostic), just scoped so "back" and
/// "done" return into the admin flow instead of the regular one.
class AdminForgotPasswordScreen extends StatefulWidget {
  const AdminForgotPasswordScreen({super.key});

  @override
  State<AdminForgotPasswordScreen> createState() => _AdminForgotPasswordScreenState();
}

class _AdminForgotPasswordScreenState extends State<AdminForgotPasswordScreen> {
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
        MaterialPageRoute<void>(builder: (_) => const AdminLoginScreen()),
      );
    }
  }

  void _goToResetPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AdminResetPasswordScreen()),
    );
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
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
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
                        ? "If an admin account exists for that email, we've "
                              'sent a reset code to it. Enter the code on the '
                              'next screen to choose a new password.'
                        : "Enter the email on your admin account and we'll "
                              'send you a code to reset your password.',
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
                        hint: 'admin@example.com',
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
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: _goToResetPassword,
                      child: const Text(
                        'Already have a reset code?',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.blue),
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
