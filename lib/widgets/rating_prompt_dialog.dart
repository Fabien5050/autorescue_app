import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../services/review_api.dart';

/// Star-rating popup shown to a driver right after their assistance request
/// wraps up, so feedback is captured while the job is still fresh instead of
/// depending on the driver to go find a "rate this workshop" screen later.
class RatingPromptDialog extends StatefulWidget {
  const RatingPromptDialog({super.key, required this.workshopId, required this.workshopName});

  final int workshopId;
  final String workshopName;

  /// Shows the dialog if (and only if) the driver hasn't already rated this
  /// workshop for this job — a stray double-trigger just silently no-ops
  /// against the backend's one-review-per-workshop constraint.
  static Future<void> show(
    BuildContext context, {
    required int workshopId,
    required String workshopName,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext _) => RatingPromptDialog(workshopId: workshopId, workshopName: workshopName),
    );
  }

  @override
  State<RatingPromptDialog> createState() => _RatingPromptDialogState();
}

class _RatingPromptDialogState extends State<RatingPromptDialog> {
  final TextEditingController _commentController = TextEditingController();
  int _stars = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0 || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ReviewApi.create(
        workshopId: widget.workshopId,
        rating: _stars,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      // 409 = already reviewed this workshop — nothing more to do here.
      if (e.statusCode == 409) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn\'t submit your rating. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How was your experience?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            widget.workshopName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.slate),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 1; i <= 5; i++)
                IconButton(
                  onPressed: _submitting ? null : () => setState(() => _stars = i),
                  icon: Icon(
                    i <= _stars ? Icons.star : Icons.star_border,
                    color: AppColors.warningOrange,
                    size: 32,
                  ),
                  splashRadius: 24,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            enabled: !_submitting,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(
              hintText: 'Add a comment (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.dangerRed, fontSize: 12.5)),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: _stars == 0 || _submitting ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
          child: _submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
