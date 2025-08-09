import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class TankGauge extends StatelessWidget {
  final String title;
  final double percent; // 0..100
  final VoidCallback? onTap;

  const TankGauge({
    super.key,
    required this.title,
    required this.percent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = percent.clamp(0, 100);
    final p = clamped / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onTap,
          child: CircularPercentIndicator(
            radius: 110,
            lineWidth: 16,
            percent: p.isNaN ? 0 : p,
            animation: true,
            animateFromLastPercent: true,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor:
                theme.colorScheme.surfaceVariant.withOpacity(.5),
            progressColor: theme.colorScheme.primary,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${clamped.toStringAsFixed(clamped % 1 == 0 ? 0 : 1)}%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap here',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
