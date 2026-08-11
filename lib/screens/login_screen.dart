import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/user_role.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/role_card.dart';
import 'driver_registration_screen.dart';
import 'location_permission_screen.dart';
import 'workshop_registration_screen.dart';

/// Role selection + credentials entry.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.driver;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectRole(UserRole role) => setState(() => _selectedRole = role);

  String? _validateEmail(String? value) {
    final String email = (value ?? '').trim();
    if (email.isEmpty) return 'Please enter your email address';
    final RegExp pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) return 'Please enter your password';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    // TODO: re-enable `_formKey.currentState?.validate()` gating once the
    // real auth backend exists — skipped for now so every screen stays
    // reachable while there's nothing to submit to.

    if (_selectedRole == UserRole.driver) {
      // "Get Started" here represents an existing driver signing in, so it
      // skips registration/payment and heads straight into onboarding.
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const LocationPermissionScreen(),
        ),
      );
      return;
    }

    _goToRegistration();
  }

  void _goToRegistration() {
    if (_selectedRole == UserRole.driver) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const DriverRegistrationScreen(),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const WorkshopRegistrationScreen(),
        ),
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
                const _Header(),
                const SizedBox(height: 26),
                const Text(
                  'Welcome to AutoRescue',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select your role to get started with our '
                  'emergency assistance network.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: 20),
                RoleCard(
                  icon: Icons.directions_car_filled_outlined,
                  title: UserRole.driver.title,
                  subtitle: UserRole.driver.subtitle,
                  selected: _selectedRole == UserRole.driver,
                  onTap: () => _selectRole(UserRole.driver),
                ),
                const SizedBox(height: 12),
                RoleCard(
                  icon: Icons.build_outlined,
                  title: UserRole.mechanic.title,
                  subtitle: UserRole.mechanic.subtitle,
                  selected: _selectedRole == UserRole.mechanic,
                  onTap: () => _selectRole(UserRole.mechanic),
                ),
                const SizedBox(height: 22),
                LabeledTextField(
                  label: 'Email Address',
                  hint: 'name@example.com',
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.email],
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  validator: _validatePassword,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.password],
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 19,
                      color: AppColors.slateLight,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 6),
                _OptionsRow(
                  rememberMe: _rememberMe,
                  onRememberChanged: (bool value) =>
                      setState(() => _rememberMe = value),
                  onForgotPassword: () {},
                ),
                const SizedBox(height: 14),
                PrimaryButton(label: 'Get Started', onPressed: _submit),
                const SizedBox(height: 18),
                Center(child: _SignUpPrompt(onTap: _goToRegistration)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Orange SOS badge next to the wordmark.
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
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'AutoRescue',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _OptionsRow extends StatelessWidget {
  const _OptionsRow({
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onForgotPassword,
  });

  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        InkWell(
          onTap: () => onRememberChanged(!rememberMe),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: (bool? value) =>
                        onRememberChanged(value ?? false),
                    activeColor: AppColors.orange,
                    side: const BorderSide(
                      color: AppColors.slateLight,
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Remember me',
                  style: TextStyle(fontSize: 13, color: AppColors.slate),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: onForgotPassword,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Forgot password?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.blue,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignUpPrompt extends StatelessWidget {
  const _SignUpPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          "Don't have an account? ",
          style: TextStyle(fontSize: 13, color: AppColors.slate),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'Sign up',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.blue,
            ),
          ),
        ),
      ],
    );
  }
}
