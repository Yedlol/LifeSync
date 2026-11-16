import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

const _dur = Duration(milliseconds: 220);

extension FadeSlideIn on Widget {
  /// Subtle fade + 6% slide-up on first build; later items start a little
  /// later (capped so long lists don't lag). Don't use on draggable cards.
  Widget fadeSlideIn({int index = 0}) =>
      animate(delay: Duration(milliseconds: 30 * index.clamp(0, 5)))
          .fadeIn(duration: _dur, curve: Curves.easeOut)
          .slideY(begin: 0.06, end: 0, duration: _dur, curve: Curves.easeOut);
}

/// Progress bar that animates to its value (and grows in on first show).
class AnimatedBar extends StatelessWidget {
  const AnimatedBar({
    super.key,
    required this.value,
    required this.color,
    required this.backgroundColor,
    this.minHeight = 8,
  });
  final double value;
  final Color color;
  final Color backgroundColor;
  final double minHeight;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => LinearProgressIndicator(
        value: v,
        minHeight: minHeight,
        backgroundColor: backgroundColor,
        color: color,
      ),
    ),
  );
}
