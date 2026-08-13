import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../core/session.dart';
import '../../core/websocket_service.dart';
import '../../models/user_profile.dart';
import '../../services/user_api.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/primary_button.dart';
import 'admin_login_screen.dart';

/// Admin's own profile: photo, name/phone, password. Reuses the same
/// `/api/users/me` endpoints [DriverProfileScreen] and [SettingsScreen] use
/// — that surface is role-agnostic on the backend, so there's nothing
/// admin-specific to wire up server-side.
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key, this.onProfileChanged});

  /// Notified whenever this screen loads or saves a fresh profile, so the
  /// sidebar (owned by [AdminShell], a sibling in its `IndexedStack`) can
  /// show the current name/photo without a separate fetch of its own.
  final ValueChanged<UserProfile>? onProfileChanged;

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late Future<UserProfile> _profileFuture;
  UserProfile? _profile;
  bool _isSavingProfile = false;
  bool _isUploadingPhoto = false;

  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _showPasswordForm = false;
  bool _isChangingPassword = false;
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _load() {
    _profileFuture = UserApi.getMe().then((UserProfile profile) {
      _profile = profile;
      _nameController.text = profile.fullName;
      _phoneController.text = profile.phoneNumber;
      widget.onProfileChanged?.call(profile);
      return profile;
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? const Color(0xFFDC2626) : AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!(_profileFormKey.currentState?.validate() ?? false)) return;
    setState(() => _isSavingProfile = true);
    try {
      final UserProfile updated = await UserApi.updateProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _profile = updated);
      widget.onProfileChanged?.call(updated);
      _showSnack('Profile updated.');
    } on ApiException catch (error) {
      if (mounted) _showSnack(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
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
      final UserProfile updated = await UserApi.uploadProfilePhoto(fileBytes: bytes, fileName: photo.name);
      if (!mounted) return;
      setState(() => _profile = updated);
      widget.onProfileChanged?.call(updated);
    } on ApiException catch (error) {
      if (mounted) _showSnack(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  String? _validateNewPassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) return 'Please enter a new password';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Please confirm your new password';
    if (value != _newPasswordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _changePassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;
    setState(() => _isChangingPassword = true);
    try {
      await UserApi.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _showPasswordForm = false);
      _showSnack('Password changed successfully.');
    } on ApiException catch (error) {
      if (mounted) _showSnack(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _logOut(BuildContext context) async {
    WebSocketService.instance.disconnect();
    await Session.instance.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AdminLoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (BuildContext context, AsyncSnapshot<UserProfile> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final String message =
                snapshot.error is ApiException ? (snapshot.error! as ApiException).message : 'Failed to load your profile.';
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 4),
                  const Text('Your admin profile and account preferences.', style: TextStyle(fontSize: 13.5, color: AppColors.slate)),
                  const SizedBox(height: 24),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Center(child: _AvatarPicker(
                          profile: _profile!,
                          isUploading: _isUploadingPhoto,
                          onTap: _isUploadingPhoto ? null : _pickProfilePhoto,
                        )),
                        const SizedBox(height: 22),
                        Form(
                          key: _profileFormKey,
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
                              const SizedBox(height: 8),
                              _ReadOnlyField(label: 'Email Address', value: _profile!.email),
                              const SizedBox(height: 18),
                              Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  width: 160,
                                  child: PrimaryButton(
                                    label: _isSavingProfile ? 'Saving…' : 'Save Changes',
                                    trailingIcon: null,
                                    onPressed: _isSavingProfile ? null : _saveProfile,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Security', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
                        const SizedBox(height: 12),
                        if (!_showPasswordForm)
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _showPasswordForm = true),
                            icon: const Icon(Icons.lock_outline, size: 17, color: AppColors.primaryBlue),
                            label: const Text('Change Password', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          )
                        else
                          Form(
                            key: _passwordFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                LabeledTextField(
                                  label: 'Current Password',
                                  hint: '••••••••',
                                  controller: _currentPasswordController,
                                  obscureText: _obscureCurrent,
                                  validator: (String? v) => (v ?? '').isEmpty ? 'Please enter your current password' : null,
                                  suffix: IconButton(
                                    icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19, color: AppColors.slateLight),
                                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                LabeledTextField(
                                  label: 'New Password',
                                  hint: '••••••••',
                                  controller: _newPasswordController,
                                  obscureText: _obscureNew,
                                  validator: _validateNewPassword,
                                  suffix: IconButton(
                                    icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19, color: AppColors.slateLight),
                                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                LabeledTextField(
                                  label: 'Confirm New Password',
                                  hint: '••••••••',
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirm,
                                  validator: _validateConfirmPassword,
                                  suffix: IconButton(
                                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19, color: AppColors.slateLight),
                                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    TextButton(
                                      onPressed: _isChangingPassword
                                          ? null
                                          : () => setState(() {
                                              _showPasswordForm = false;
                                              _currentPasswordController.clear();
                                              _newPasswordController.clear();
                                              _confirmPasswordController.clear();
                                            }),
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 160,
                                      child: PrimaryButton(
                                        label: _isChangingPassword ? 'Saving…' : 'Save',
                                        trailingIcon: null,
                                        onPressed: _isChangingPassword ? null : _changePassword,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => _logOut(context),
                    icon: const Icon(Icons.logout, size: 18, color: AppColors.dangerRed),
                    label: const Text('Log Out', style: TextStyle(color: AppColors.dangerRed, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.dangerRed),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.profile, required this.isUploading, required this.onTap});

  final UserProfile profile;
  final bool isUploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: 84,
          height: 84,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(color: AppColors.badgeSoft, shape: BoxShape.circle),
          child: isUploading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2.2))
              : profile.fullProfilePhotoUrl != null
                  ? Image.network(
                      profile.fullProfilePhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.person, color: AppColors.primaryBlue, size: 40),
                    )
                  : const Icon(Icons.person, color: AppColors.primaryBlue, size: 40),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: AppColors.primaryBlue,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.screenBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(value, style: const TextStyle(fontSize: 15, color: AppColors.slate)),
        ),
      ],
    );
  }
}
