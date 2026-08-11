import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Rounded field whose label is pinned above the value, inside the border.
///
/// Pass [label] to pin it (e.g. registration forms); omit it to fall back to
/// a plain placeholder-only field (e.g. the emergency-contact card).
class FloatingLabelField extends StatelessWidget {
  const FloatingLabelField({
    super.key,
    this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffix,
    this.prefixIcon,
    this.prefixText,
    this.autofillHints,
    this.accentColor = AppColors.burntOrange,
    this.textCapitalization = TextCapitalization.none,
  });

  final String? label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final Widget? prefixIcon;
  final String? prefixText;
  final Iterable<String>? autofillHints;

  /// Drives the label color and focused-border color — defaults to the
  /// burnt-orange used by the driver/workshop registration forms.
  final Color accentColor;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border, width: 1.2),
    );

    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      style: const TextStyle(fontSize: 15, color: AppColors.navy),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: TextStyle(
          color: accentColor,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.slateLight, fontSize: 14.5),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        suffixIcon: suffix,
        prefixIcon: prefixIcon,
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
        border: base,
        enabledBorder: base,
        focusedBorder: base.copyWith(
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: base.copyWith(
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
        ),
        focusedErrorBorder: base.copyWith(
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
    );
  }
}
