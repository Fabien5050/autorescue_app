import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Three blue dots pulsing in sequence while the splash waits.
class LoadingDots extends StatefulWidget {
  const LoadingDots({
    super.key,
    this.count = 3,
    this.color = AppColors.blue,
    this.dotSize = 7,
  });

  final int count;
  final Color color;
  final double dotSize;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(widget.count, (int i) {
            // Stagger each dot by a fraction of the loop.
            final double phase = (_controller.value - i / widget.count) % 1.0;
            final double wave = (1 - (phase * 2 - 1).abs()).clamp(0.0, 1.0);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.dotSize * 0.4),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.28 + wave * 0.72),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
