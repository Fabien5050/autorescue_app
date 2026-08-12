import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';

/// A row of single-digit boxes for entering a numeric code (e.g. a
/// password-reset code). Auto-advances focus as digits are typed, moves
/// back on backspace from an empty box, and — since there's no way to
/// auto-detect a code emailed to the user the way SMS OTPs can be
/// auto-read — supports pasting the whole code into any box to fill the
/// rest at once.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.onCompleted,
    this.errorText,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final String? errorText;

  @override
  State<OtpCodeField> createState() => OtpCodeFieldState();
}

class OtpCodeFieldState extends State<OtpCodeField> {
  late final List<TextEditingController> _controllers =
      List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _focusNodes = List.generate(widget.length, (_) => FocusNode());

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    for (final FocusNode node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get code => _controllers.map((TextEditingController c) => c.text).join();

  /// Clears every box — used after a failed attempt so the user isn't
  /// stuck editing a code that's already been rejected.
  void clear() {
    for (final TextEditingController controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }

  void _emit() {
    widget.onChanged(code);
    if (code.length == widget.length) widget.onCompleted?.call(code);
  }

  void _onChanged(int index, String value) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      _emit();
      return;
    }

    if (digits.length == 1) {
      _controllers[index].value = TextEditingValue(
        text: digits,
        selection: const TextSelection.collapsed(offset: 1),
      );
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
      _emit();
      return;
    }

    // More than one digit landed here — a paste. Spread it across this box
    // and the ones after it.
    int cursor = index;
    for (final String digit in digits.split('')) {
      if (cursor >= widget.length) break;
      _controllers[cursor].value = TextEditingValue(
        text: digit,
        selection: const TextSelection.collapsed(offset: 1),
      );
      cursor++;
    }
    final int lastFilled = (cursor - 1).clamp(0, widget.length - 1);
    if (lastFilled == widget.length - 1) {
      _focusNodes[lastFilled].unfocus();
    } else {
      _focusNodes[lastFilled + 1].requestFocus();
    }
    _emit();
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isNotEmpty || index == 0) return;
    _focusNodes[index - 1].requestFocus();
    _controllers[index - 1].clear();
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (int i = 0; i < widget.length; i++)
              SizedBox(
                width: 44,
                height: 52,
                child: Focus(
                  onKeyEvent: (FocusNode node, KeyEvent event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                      _onBackspace(i);
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    autofillHints: const <String>[AutofillHints.oneTimeCode],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: hasError ? const Color(0xFFDC2626) : AppColors.border,
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: hasError ? const Color(0xFFDC2626) : AppColors.border,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.orange, width: 1.6),
                      ),
                    ),
                    onChanged: (String value) => _onChanged(i, value),
                  ),
                ),
              ),
          ],
        ),
        if (hasError) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
          ),
        ],
      ],
    );
  }
}
