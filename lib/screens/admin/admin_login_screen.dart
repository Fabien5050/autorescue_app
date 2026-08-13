import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../core/session.dart';
import '../../services/admin_auth_api.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/primary_button.dart';
import 'admin_forgot_password_screen.dart';
import 'admin_otp_screen.dart';
import 'admin_shell.dart';

/// Entry point for the web-only admin portal. Checks for an already-signed-in
/// admin session first (e.g. a page refresh) before showing the credentials
/// form — signing in from here is only step 1 of 2; success moves on to
/// [AdminOtpScreen] rather than the portal itself.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final Future<bool> _sessionCheck = _checkExistingSession();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  Future<bool> _checkExistingSession() async {
    await Session.instance.restore();
    return Session.instance.isLoggedIn && Session.instance.role == 'ADMIN';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final String email = (value ?? '').trim();
    if (email.isEmpty) return 'Please enter your email address';
    final RegExp pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Please enter your password';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final String email = _emailController.text.trim();
    setState(() => _isSubmitting = true);
    try {
      await AdminAuthApi.login(email: email, password: _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => AdminOtpScreen(email: email)),
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AdminForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: FutureBuilder<bool>(
        future: _sessionCheck,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == true) {
            return const AdminShell();
          }
          return _LoginForm(
            formKey: _formKey,
            emailController: _emailController,
            passwordController: _passwordController,
            obscurePassword: _obscurePassword,
            isSubmitting: _isSubmitting,
            onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
            onValidateEmail: _validateEmail,
            onValidatePassword: _validatePassword,
            onSubmit: _submit,
            onForgotPassword: _goToForgotPassword,
          );
        },
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.onTogglePassword,
    required this.onValidateEmail,
    required this.onValidatePassword,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isSubmitting;
  final VoidCallback onTogglePassword;
  final String? Function(String?) onValidateEmail;
  final String? Function(String?) onValidatePassword;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Center(
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
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _Header(),
                  const SizedBox(height: 24),
                  const Text(
                    'Admin Portal',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in with your administrator credentials. '
                    "We'll email you a verification code before you're let in.",
                    style: TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.slate),
                  ),
                  const SizedBox(height: 24),
                  LabeledTextField(
                    label: 'Email Address',
                    hint: 'admin@example.com',
                    controller: emailController,
                    validator: onValidateEmail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.email],
                  ),
                  const SizedBox(height: 16),
                  LabeledTextField(
                    label: 'Password',
                    hint: '••••••••',
                    controller: passwordController,
                    validator: onValidatePassword,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.password],
                    suffix: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 19,
                        color: AppColors.slateLight,
                      ),
                      onPressed: onTogglePassword,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onForgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: isSubmitting ? 'Sending Code…' : 'Continue',
                    onPressed: isSubmitting ? null : onSubmit,
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'SOS',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'AutoRescue',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
      ],
    );
  }
}
