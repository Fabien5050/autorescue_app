import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_colors.dart';
import '../widgets/file_upload_button.dart';
import '../widgets/floating_label_field.dart';
import '../widgets/map_location_preview.dart';
import '../widgets/notice_box.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_card.dart';
import '../widgets/service_chip_group.dart';
import '../widgets/verification_timeline.dart';
import 'login_screen.dart';
import 'pending_verification_screen.dart';

const List<String> _offeredServices = <String>[
  'Towing',
  'Engine Repair',
  'Battery Jumpstart',
  'Tire Vulcanizing',
  'Fuel Delivery',
];

const List<VerificationStep> _verificationSteps = <VerificationStep>[
  VerificationStep(
    title: 'Submit Application',
    description: 'Credentials & map location uploaded.',
  ),
  VerificationStep(
    title: 'Admin Review',
    description:
        'Our admin team will review your business documents within 24 hours.',
  ),
  VerificationStep(
    title: 'Approval & Platform Fee Payment',
    description:
        'Once approved, you will receive an email notification and a '
        'payment link to pay your platform fee and activate your account.',
  ),
];

/// Workshop / mechanic sign-up: owner identity, business credentials, and
/// service location. Payment is intentionally not collected here — it's
/// requested only after an admin approves the application.
class WorkshopRegistrationScreen extends StatefulWidget {
  const WorkshopRegistrationScreen({super.key});

  @override
  State<WorkshopRegistrationScreen> createState() =>
      _WorkshopRegistrationScreenState();
}

class _WorkshopRegistrationScreenState
    extends State<WorkshopRegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _workshopNameController =
      TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();

  final TextEditingController _addressController = TextEditingController();

  bool _obscurePassword = true;
  String? _businessCertFileName;
  String? _ownerIdFrontFileName;
  String? _ownerIdBackFileName;
  String? _facePhotoFileName;
  bool _isSubmitting = false;

  final ImagePicker _imagePicker = ImagePicker();

  // Buea, South-West Region — placeholder until a real map picker is wired.
  final double _latitude = 4.1550;
  final double _longitude = 9.2415;

  final Set<String> _selectedServices = <String>{};
  String? _servicesError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _workshopNameController.dispose();
    _nationalIdController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
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

  void _toggleService(String service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
      if (_selectedServices.isNotEmpty) _servicesError = null;
    });
  }

  Future<void> _pickDocument({required bool isBusinessCert}) async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty || !mounted) return;

    setState(() {
      if (isBusinessCert) {
        _businessCertFileName = result.files.single.name;
      } else {
        _ownerIdFrontFileName = result.files.single.name;
      }
    });
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primaryBlue),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryBlue),
              title: const Text('Choose from Device'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickIdentityPhoto(void Function(String fileName) onPicked) async {
    final ImageSource? source = await _chooseImageSource();
    if (source == null || !mounted) return;

    final XFile? photo = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (photo == null || !mounted) return;

    setState(() => onPicked(photo.name));
  }

  void _setPhysicalLocation() {
    // Stub: a real implementation would open a map picker and write back
    // the chosen lat/lng. No mapping package is wired into this project yet.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
        content: Text('Map picker not wired up yet — using default location.'),
      ),
    );
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    // TODO: re-enable the `_formKey.currentState?.validate()` /
    // `_selectedServices` gating once the real registration backend exists
    // — skipped for now so every screen stays reachable while there's
    // nothing to submit to.

    setState(() => _isSubmitting = true);

    // TODO: POST /api/workshops/register with the collected payload
    // (owner identity, credentials, documents, location, services).
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const PendingVerificationScreen()),
    );
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
                  onPressed: _goBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.navy, size: 22),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Register Workshop',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Submit your garage credentials and location for verification.',
                  style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.slate),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  icon: Icons.person_outline,
                  title: 'Account Owner',
                  children: <Widget>[
                    FloatingLabelField(
                      label: 'Full Name',
                      hint: 'Full Name',
                      controller: _fullNameController,
                      validator: (String? v) => _required(v, 'Please enter your full name'),
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.name],
                    ),
                    FloatingLabelField(
                      label: 'Email Address',
                      hint: 'john@example.com',
                      controller: _emailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.email],
                    ),
                    FloatingLabelField(
                      label: 'Operational Phone',
                      hint: '+237 XXX XXX XXX',
                      controller: _phoneController,
                      validator: (String? v) =>
                          _required(v, 'Please enter your operational phone'),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    FloatingLabelField(
                      label: 'Password',
                      controller: _passwordController,
                      validator: _validatePassword,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[AutofillHints.newPassword],
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
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  icon: Icons.verified_outlined,
                  title: 'Credentials',
                  children: <Widget>[
                    FloatingLabelField(
                      label: 'Workshop Name',
                      hint: 'Buea Auto Care Garage',
                      controller: _workshopNameController,
                      validator: (String? v) =>
                          _required(v, 'Please enter your workshop name'),
                      textInputAction: TextInputAction.next,
                    ),
                    FloatingLabelField(
                      label: 'National ID Number',
                      hint: '123456789',
                      controller: _nationalIdController,
                      validator: (String? v) =>
                          _required(v, 'Please enter your national ID number'),
                      textInputAction: TextInputAction.next,
                    ),
                    FloatingLabelField(
                      label: 'Tax ID Number',
                      hint: 'M012345678901Y',
                      controller: _taxIdController,
                      validator: (String? v) =>
                          _required(v, 'Please enter your tax ID number'),
                      textInputAction: TextInputAction.done,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 2, bottom: 2),
                      child: Text(
                        'Document Uploads',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.burntOrange,
                        ),
                      ),
                    ),
                    FileUploadButton(
                      title: 'Upload Business Registration Certificate',
                      helperText: 'PDF, JPG or PNG (Max 5MB)',
                      attached: _businessCertFileName != null,
                      fileName: _businessCertFileName,
                      onTap: () => _pickDocument(isBusinessCert: true),
                    ),
                    FileUploadButton(
                      title: 'Owner National ID — Front',
                      helperText: 'Take a photo or upload from device',
                      attached: _ownerIdFrontFileName != null,
                      fileName: _ownerIdFrontFileName,
                      onTap: () => _pickIdentityPhoto(
                        (String fileName) => _ownerIdFrontFileName = fileName,
                      ),
                    ),
                    FileUploadButton(
                      title: 'Owner National ID — Back',
                      helperText: 'Take a photo or upload from device',
                      attached: _ownerIdBackFileName != null,
                      fileName: _ownerIdBackFileName,
                      onTap: () => _pickIdentityPhoto(
                        (String fileName) => _ownerIdBackFileName = fileName,
                      ),
                    ),
                    FileUploadButton(
                      title: 'Face Photo (Selfie)',
                      helperText: 'Clear photo of your face, for identity matching',
                      attached: _facePhotoFileName != null,
                      fileName: _facePhotoFileName,
                      onTap: () => _pickIdentityPhoto(
                        (String fileName) => _facePhotoFileName = fileName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  icon: Icons.place_outlined,
                  title: 'Location & Services',
                  children: <Widget>[
                    MapLocationPreview(
                      latitude: _latitude,
                      longitude: _longitude,
                      onSetLocation: _setPhysicalLocation,
                    ),
                    FloatingLabelField(
                      label: 'Physical Address',
                      hint: 'Commercial Avenue, opposite Total filling station',
                      controller: _addressController,
                      validator: (String? v) =>
                          _required(v, 'Please enter your physical address'),
                      textInputAction: TextInputAction.next,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Offered Services',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.burntOrange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ServiceChipGroup(
                          options: _offeredServices,
                          selected: _selectedServices,
                          onChanged: _toggleService,
                        ),
                        if (_servicesError != null) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            _servicesError!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  icon: Icons.verified_user_outlined,
                  title: 'Verification & Next Steps',
                  iconColor: AppColors.indigo,
                  children: const <Widget>[
                    VerificationTimeline(steps: _verificationSteps),
                  ],
                ),
                const SizedBox(height: 20),
                const NoticeBox(
                  text: 'Your profile will remain in "Pending Verification" '
                      'status until approved by an administrator.',
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: _isSubmitting
                      ? 'Submitting…'
                      : 'Submit Credentials for Review',
                  color: AppColors.safetyOrange,
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
