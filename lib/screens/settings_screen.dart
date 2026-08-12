import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../services/user_api.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_button.dart';

const String _notificationsPrefKey = 'autorescue.notificationsEnabled';

/// Account settings shared by both driver and workshop-owner roles: a
/// notification preference (local only — this app has no push-notification
/// backend, so this controls in-app behavior, not real push delivery), an
/// in-app password change, and app info.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _loadingPrefs = true;

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
    _loadPrefs();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsPrefKey) ?? true;
      _loadingPrefs = false;
    });
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    setState(() => _notificationsEnabled = value);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsPrefKey, value);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.heading,
        title: const Text('Settings', style: TextStyle(color: AppColors.heading, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: _loadingPrefs
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: <Widget>[
                  _SectionLabel('Preferences'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Notifications',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.heading),
                      ),
                      subtitle: const Text(
                        'Alerts for request updates while using the app',
                        style: TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                      ),
                      value: _notificationsEnabled,
                      activeTrackColor: AppColors.accentGreen,
                      onChanged: _setNotificationsEnabled,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('Security'),
                  if (!_showPasswordForm)
                    _SettingsRow(
                      icon: Icons.lock_outline,
                      label: 'Change Password',
                      onTap: () => setState(() => _showPasswordForm = true),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Form(
                        key: _passwordFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            LabeledTextField(
                              label: 'Current Password',
                              hint: '••••••••',
                              controller: _currentPasswordController,
                              obscureText: _obscureCurrent,
                              validator: (String? v) =>
                                  (v ?? '').isEmpty ? 'Please enter your current password' : null,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 19,
                                  color: AppColors.slateLight,
                                ),
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
                                icon: Icon(
                                  _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 19,
                                  color: AppColors.slateLight,
                                ),
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
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 19,
                                  color: AppColors.slateLight,
                                ),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isChangingPassword
                                        ? null
                                        : () => setState(() {
                                            _showPasswordForm = false;
                                            _currentPasswordController.clear();
                                            _newPasswordController.clear();
                                            _confirmPasswordController.clear();
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
                    ),
                  const SizedBox(height: 20),
                  _SectionLabel('About'),
                  const _SettingsRow(icon: Icons.info_outline, label: 'App Version', trailing: 'v1.0.0'),
                ],
              ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.secondaryText),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.label, this.onTap, this.trailing});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 19, color: AppColors.slate),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.heading),
                ),
                const Spacer(),
                if (trailing != null)
                  Text(trailing!, style: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText))
                else
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.slateLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
