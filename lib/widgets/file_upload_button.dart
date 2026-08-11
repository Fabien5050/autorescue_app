import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Dashed-style upload row. Toggles a local "attached" state on tap —
/// wire [onTap] to a real file picker to replace the stub behaviour.
class FileUploadButton extends StatelessWidget {
  const FileUploadButton({
    super.key,
    required this.title,
    required this.helperText,
    required this.attached,
    required this.onTap,
    this.fileName,
  });

  final String title;
  final String helperText;
  final bool attached;
  final VoidCallback onTap;
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final Color accent = attached ? const Color(0xFF16A34A) : AppColors.burntOrange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: attached ? const Color(0xFFF0FDF4) : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: attached ? const Color(0xFF86EFAC) : AppColors.border,
              width: 1.2,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                attached ? Icons.check_circle : Icons.upload_file_outlined,
                size: 20,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      attached ? '$title — attached' : title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: attached ? const Color(0xFF15803D) : AppColors.burntOrange,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      attached && fileName != null ? fileName! : helperText,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.slate),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
