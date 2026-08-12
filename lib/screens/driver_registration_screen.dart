import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../models/user_role.dart';
import '../services/auth_api.dart';
import '../widgets/floating_label_field.dart';
import '../widgets/phone_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_card.dart';
import 'login_screen.dart';
import 'payment_screen.dart';

const List<String> _vehicleCategories = <String>[
  'Sedan',
  'SUV',
  'Hatchback',
  'Pickup Truck',
  'Motorcycle',
  'Van',
];

const List<String> _countryCodes = <String>['+237', '+1', '+44', '+33', '+234'];

/// Driver sign-up form: personal identity, vehicle details, emergency contact.
class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final TextEditingController _makeModelController = TextEditingController();
  final TextEditingController _licensePlateController =
      TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  final TextEditingController _contactNameController =
      TextEditingController();
  final TextEditingController _contactPhoneController =
      TextEditingController();

  String _countryCode = _countryCodes.first;
  String _vehicleCategory = _vehicleCategories.first;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _makeModelController.dispose();
    _licensePlateController.dispose();
    _colorController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  String? _required(String? value, String message) {
    if ((value ?? '').trim().isEmpty) return message;
    return null;
  }

  String? _validateEmail(String? value) {
    final String email = (value ?? '').trim();
    if (email.isEmpty) return 'Please enter your email address';
    final RegExp pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) return 'Please enter a password';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await AuthApi.registerDriver(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: '$_countryCode${_phoneController.text.trim()}',
        password: _passwordController.text,
        vehicle: DriverVehicleInput(
          category: _vehicleCategory,
          makeModel: _makeModelController.text.trim(),
          licensePlate: _licensePlateController.text.trim(),
          color: _colorController.text.trim(),
        ),
        emergencyContact: EmergencyContactInput(
          contactName: _contactNameController.text.trim(),
          contactPhone: _contactPhoneController.text.trim(),
        ),
      );
      if (!mounted) return;

      // Drivers don't wait on admin review, so the next stop is straight to
      // activation payment.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const PaymentScreen(userRole: UserRole.driver),
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goToLogin() {
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconButton(
                  onPressed: _goToLogin,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.navy,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Driver Registration',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Set up your profile and vehicle details for instant '
                  'emergency assistance.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  icon: Icons.person_outline,
                  title: 'Personal Identity',
                  children: <Widget>[
                    FloatingLabelField(
                      label: 'Full Name',
                      hint: 'Full Name',
                      controller: _fullNameController,
                      validator: (String? v) =>
                          _required(v, 'Please enter your full name'),
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.name],
                    ),
                    FloatingLabelField(
                      label: 'Email Address',
                      hint: 'driver@example.com',
                      controller: _emailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.email],
                    ),
                    PhoneField(
                      controller: _phoneController,
                      countryCode: _countryCode,
                      countryCodes: _countryCodes,
                      onCountryCodeChanged: (String? code) => setState(
                        () => _countryCode = code ?? _countryCode,
                      ),
                      validator: (String? value) => _required(
                        _phoneController.text,
                        'Please enter your phone number',
                      ),
                    ),
                    FloatingLabelField(
                      label: 'Password',
                      controller: _passwordController,
                      validator: _validatePassword,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.newPassword],
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 19,
                          color: AppColors.slateLight,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    FloatingLabelField(
                      label: 'Confirm Password',
                      controller: _confirmPasswordController,
                      validator: _validateConfirmPassword,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      suffix: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 19,
                          color: AppColors.slateLight,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  icon: Icons.directions_car_outlined,
                  title: 'Vehicle Details',
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      initialValue: _vehicleCategory,
                      onChanged: (String? value) => setState(
                        () => _vehicleCategory = value ?? _vehicleCategory,
                      ),
                      items: <DropdownMenuItem<String>>[
                        for (final String category in _vehicleCategories)
                          DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ),
                      ],
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.navy,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.slate,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Vehicle Category',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelStyle: const TextStyle(
                          color: AppColors.burntOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.burntOrange,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    FloatingLabelField(
                      label: 'Make & Model',
                      hint: 'Toyota Corolla 2018',
                      controller: _makeModelController,
                      validator: (String? v) =>
                          _required(v, 'Please enter make & model'),
                      textInputAction: TextInputAction.next,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: FloatingLabelField(
                            label: 'License Plate',
                            hint: 'SW 123 AB',
                            controller: _licensePlateController,
                            validator: (String? v) =>
                                _required(v, 'Required'),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FloatingLabelField(
                            label: 'Color',
                            hint: 'Silver',
                            controller: _colorController,
                            validator: (String? v) =>
                                _required(v, 'Required'),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  icon: Icons.badge_outlined,
                  title: 'Emergency Contact',
                  children: <Widget>[
                    FloatingLabelField(
                      hint: 'Contact Name',
                      controller: _contactNameController,
                      validator: (String? v) =>
                          _required(v, 'Please enter a contact name'),
                      textInputAction: TextInputAction.next,
                    ),
                    FloatingLabelField(
                      hint: 'Contact Phone',
                      controller: _contactPhoneController,
                      validator: (String? v) =>
                          _required(v, 'Please enter a contact phone'),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _isSubmitting
                      ? 'Submitting…'
                      : 'Complete Driver Registration',
                  color: AppColors.burntOrange,
                  onPressed: _isSubmitting ? null : _submit,
                ),
                const SizedBox(height: 18),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(fontSize: 13, color: AppColors.slate),
                      ),
                      GestureDetector(
                        onTap: _goToLogin,
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
