import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Circular percentage ring used on subject cards & dashboard hero.
class PercentageIndicator extends StatelessWidget {
  final double percentage;
  final double target;
  final double size;
  final Color? color;
  final double strokeWidth;

  const PercentageIndicator({
    super.key,
    required this.percentage,
    this.target = AppDefaults.targetPercentage,
    this.size = 64,
    this.color,
    this.strokeWidth = 6,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = color ??
        (percentage >= target ? AppColors.success : AppColors.warning);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: (percentage / 100).clamp(0, 1),
              strokeWidth: strokeWidth,
              backgroundColor: ringColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(ringColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.w700,
              color: ringColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slim horizontal bar variant, used in lists.
class PercentageBar extends StatelessWidget {
  final double percentage;
  final double target;
  final Color? color;

  const PercentageBar({
    super.key,
    required this.percentage,
    this.target = AppDefaults.targetPercentage,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final barColor =
        color ?? (percentage >= target ? AppColors.success : AppColors.warning);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: (percentage / 100).clamp(0, 1),
        minHeight: 8,
        backgroundColor: barColor.withValues(alpha: 0.15),
        valueColor: AlwaysStoppedAnimation(barColor),
      ),
    );
  }
}
