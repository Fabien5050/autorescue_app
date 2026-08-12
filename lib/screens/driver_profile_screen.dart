import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../models/user_profile.dart';
import '../services/user_api.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_button.dart';

/// The driver's own account info — view mode by default, with an inline
/// edit mode for name/phone. Email is read-only (it's the login
/// identifier — changing it is a bigger feature nobody's asked for yet).
class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  late Future<UserProfile> _profileFuture;
  UserProfile? _profile;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _load() {
    _profileFuture = UserApi.getMe().then((UserProfile profile) {
      _profile = profile;
      _nameController.text = profile.fullName;
      _phoneController.text = profile.phoneNumber;
      return profile;
    });
  }

  void _showError(Object error) {
    final String message = error is ApiException ? error.message : 'Something went wrong';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final UserProfile updated = await UserApi.updateProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          content: Text('Profile updated.'),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

  Future<void> _pickProfilePhoto() async {
    final ImageSource? source = await _chooseImageSource();
    if (source == null || !mounted) return;

    final XFile? photo = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (photo == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final Uint8List bytes = await photo.readAsBytes();
      final UserProfile updated = await UserApi.uploadProfilePhoto(
        fileBytes: bytes,
        fileName: photo.name,
      );
      if (!mounted) return;
      setState(() => _profile = updated);
    } on ApiException catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.heading,
        title: const Text('My Profile', style: TextStyle(color: AppColors.heading, fontWeight: FontWeight.w800)),
        actions: <Widget>[
          if (!_isEditing && _profile != null)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text('Edit'),
            ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<UserProfile>(
          future: _profileFuture,
          builder: (BuildContext context, AsyncSnapshot<UserProfile> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final String message = snapshot.error is ApiException
                  ? (snapshot.error! as ApiException).message
                  : 'Failed to load your profile.';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slate)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: () => setState(_load), child: const Text('Retry')),
                    ],
                  ),
                ),
              );
            }

            final UserProfile profile = _profile!;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: _isEditing ? _buildEditForm() : _buildView(profile),
            );
          },
        ),
      ),
    );
  }

  Widget _buildView(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(color: AppColors.badgeSoft, shape: BoxShape.circle),
                child: _isUploadingPhoto
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2.2))
                    : profile.fullProfilePhotoUrl != null
                        ? Image.network(
                            profile.fullProfilePhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.person, color: AppColors.primaryBlue, size: 36),
                          )
                        : const Icon(Icons.person, color: AppColors.primaryBlue, size: 36),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: AppColors.primaryBlue,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isUploadingPhoto ? null : _pickProfilePhoto,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _InfoRow(label: 'Full Name', value: profile.fullName),
        _InfoRow(label: 'Email Address', value: profile.email),
        _InfoRow(label: 'Phone Number', value: profile.phoneNumber),
        _InfoRow(label: 'Account Type', value: profile.role == 'DRIVER' ? 'Driver' : profile.role),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LabeledTextField(
            label: 'Full Name',
            hint: 'Full Name',
            controller: _nameController,
            validator: (String? v) => (v ?? '').trim().isEmpty ? 'Please enter your full name' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            label: 'Phone Number',
            hint: 'Phone Number',
            controller: _phoneController,
            validator: (String? v) => (v ?? '').trim().isEmpty ? 'Please enter your phone number' : null,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => setState(() {
                          _isEditing = false;
                          _nameController.text = _profile!.fullName;
                          _phoneController.text = _profile!.phoneNumber;
                        }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: _isSaving ? 'Saving…' : 'Save',
                  trailingIcon: null,
                  onPressed: _isSaving ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.heading)),
        ],
      ),
    );
  }
}
