import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Flag emoji for the dialing codes offered across the app's phone fields.
/// Cameroon is the app's home market, so +237 is always listed first by
/// callers; this map just supplies the matching flag for display.
const Map<String, String> _countryFlags = <String, String>{
  '+237': '🇨🇲',
  '+1': '🇺🇸',
  '+44': '🇬🇧',
  '+33': '🇫🇷',
  '+234': '🇳🇬',
};

/// Country-code dropdown fused with the phone number input, both inside a
/// single bordered box.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.countryCodes,
    required this.onCountryCodeChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String countryCode;
  final List<String> countryCodes;
  final ValueChanged<String?> onCountryCodeChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator,
      builder: (FormFieldState<String> field) {
        final bool hasError = field.hasError;
        final Color borderColor = hasError
            ? const Color(0xFFDC2626)
            : AppColors.border;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 12),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: countryCode,
                      onChanged: onCountryCodeChanged,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.slate,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.navy,
                      ),
                      selectedItemBuilder: (BuildContext context) => <Widget>[
                        for (final String code in countryCodes)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('${_countryFlags[code] ?? ''} $code'.trim()),
                          ),
                      ],
                      items: <DropdownMenuItem<String>>[
                        for (final String code in countryCodes)
                          DropdownMenuItem<String>(
                            value: code,
                            child: Text('${_countryFlags[code] ?? ''} $code'.trim()),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: AppColors.border,
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      onChanged: (String value) => field.didChange(value),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.navy,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Phone Number',
                        hintStyle: TextStyle(
                          color: AppColors.slateLight,
                          fontSize: 14.5,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
