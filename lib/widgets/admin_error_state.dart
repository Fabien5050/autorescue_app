import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';

/// Human-readable text for whatever a failed admin request threw.
///
/// [ApiException] already carries the backend's message (or a
/// connectivity hint for transport failures); anything else is a bug or an
/// unexpected type, so fall back to a generic line rather than leaking
/// `Instance of 'Foo'` into the UI.
String adminErrorMessage(Object? error) {
  if (error is ApiException) return error.displayMessage;
  return 'Something went wrong loading this data.';
}

/// Shared failure panel for the admin tabs: the message plus a retry
/// affordance. Every admin tab fetches its own data, and a failed [Future]
/// stays failed until it's replaced — so without an explicit retry the admin
/// is stuck on a dead tab with no way back except a full page reload.
class AdminErrorState extends StatelessWidget {
  const AdminErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.cloud_off_rounded,
              size: compact ? 28 : 40,
              color: AppColors.slateLight,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.slate,
                fontSize: compact ? 13 : 14,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
