import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../services/auth_api.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/otp_code_field.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';

const int _codeLength = 6;

/// Second half of the forgot-password flow — the user enters the 6-digit
/// code they were emailed (or pastes it, filling every box at once) and
/// picks a new password.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<OtpCodeFieldState> _codeFieldKey = GlobalKey<OtpCodeFieldState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _code = '';
  String? _codeError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) return 'Please enter a new password';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Please confirm your new password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _codeError = _code.length == _codeLength ? null : 'Enter the full $_codeLength-digit code';
    });
    final bool formValid = _formKey.currentState?.validate() ?? false;
    if (_codeError != null || !formValid) return;

    setState(() => _isSubmitting = true);
    try {
      await AuthApi.resetPassword(
        token: _code,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          content: Text('Password reset — sign in with your new password.'),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
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

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Form(
            key: _formKey,
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
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the reset code from your email along with your new '
                  'password.',
                  style: TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.slate),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Reset Code',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
                const SizedBox(height: 7),
                OtpCodeField(
                  key: _codeFieldKey,
                  length: _codeLength,
                  errorText: _codeError,
                  onChanged: (String value) => setState(() {
                    _code = value;
                    if (_codeError != null) _codeError = null;
                  }),
                  onCompleted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'New Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  validator: _validatePassword,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 19,
                      color: AppColors.slateLight,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'Confirm New Password',
                  hint: '••••••••',
                  controller: _confirmPasswordController,
                  validator: _validateConfirmPassword,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 19,
                      color: AppColors.slateLight,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _isSubmitting ? 'Resetting…' : 'Reset Password',
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
