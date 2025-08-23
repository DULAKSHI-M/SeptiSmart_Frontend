import 'dart:math' as math;
import 'package:flutter/material.dart';

class TankGauge extends StatelessWidget {
  final String title;
  /// percent should be 0..100
  final double percent;
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
    final p = percent.clamp(0, 100).toDouble();


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.water_drop_outlined,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const _LiveBadge(),
                  ],
                ),
                const SizedBox(height: 16),

                // Gauge
                LayoutBuilder(
                  builder: (context, c) {
                    final size = math.min(c.maxWidth, 260.0);
                    return Center(
                      child: _AnimatedGauge(
                        percent: p,
                        size: size,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Legend row
                _Legend(percent: p),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedGauge extends StatefulWidget {
  final double percent; // 0..100
  final double size;
  const _AnimatedGauge({required this.percent, required this.size});

  @override
  State<_AnimatedGauge> createState() => _AnimatedGaugeState();
}

class _AnimatedGaugeState extends State<_AnimatedGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.0,
      upperBound: 0.065, // subtle
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final critical = widget.percent >= 90;
    final targetColor = _colorForPercent(widget.percent, context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.percent),
      curve: Curves.easeInOutCubic,
      duration: const Duration(milliseconds: 900),
      builder: (context, value, _) {
        final sweep = (value / 100) * 2 * math.pi;
        return AnimatedScale(
          scale: critical ? 1.0 + _pulse.value : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Canvas
              CustomPaint(
                size: Size.square(widget.size),
                painter: _GaugeRingPainter(
                  sweep: sweep,
                  color: targetColor,
                  trackColor: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(.3),
                ),
              ),

              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: value),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.decelerate,
                    builder: (context, v, __) => Text(
                      '${v.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: targetColor,
                          fontWeight: FontWeight.w700,
                        ),
                    child: Text(_statusForPercent(value)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugeRingPainter extends CustomPainter {
  final double sweep; // radians
  final Color color;
  final Color trackColor;

  _GaugeRingPainter({
    required this.sweep,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.08; // responsive thickness
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide / 2) - stroke;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep,
        colors: [
          color.withOpacity(.6),
          color,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Draw track (full circle)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      trackPaint,
    );

    // Draw progress
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        progressPaint,
      );
    }

    // Soft glow for critical range
    if (sweep > 0) {
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12)
        ..color = color.withOpacity(.35);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        glow,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugeRingPainter oldDelegate) {
    return oldDelegate.sweep != sweep ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

class _Legend extends StatelessWidget {
  final double percent;
  const _Legend({required this.percent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      _LegendItem('0–20%', _colorForPercent(10, context)),
      _LegendItem('21–50%', _colorForPercent(35, context)),
      _LegendItem('51–80%', _colorForPercent(65, context)),
      _LegendItem('81–90%', _colorForPercent(85, context)),
      _LegendItem('91–100%', _colorForPercent(95, context)),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items
          .map((e) => Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: e.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(e.label, style: theme.textTheme.labelMedium),
                ],
              ))
          .toList(),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  _LegendItem(this.label, this.color);
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;
  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.35,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _blink,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('Live', style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

/// Returns a semantic label for the current level.
String _statusForPercent(double p) {
  if (p >= 90) return 'Critical';
  if (p >= 80) return 'High';
  if (p >= 50) return 'Moderate';
  if (p >= 20) return 'Normal';
  return 'Low';
}

/// Returns the color based on the level thresholds and theme.
Color _colorForPercent(double p, BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  if (p >= 90) return Colors.red.shade600;
  if (p >= 80) return Colors.orange.shade600;
  if (p >= 50) return Colors.amber.shade700;
  if (p >= 20) return Colors.lightGreen.shade600;
  return Colors.green.shade600;
}

/// A simple breathing shimmer-like placeholder without extra packages.
class GaugeSkeleton extends StatefulWidget {
  final String label;
  const GaugeSkeleton({super.key, required this.label});

  @override
  State<GaugeSkeleton> createState() => _GaugeSkeletonState();
}

class _GaugeSkeletonState extends State<GaugeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: .55,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                  const _LiveBadge(),
                ],
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _breath,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.surfaceVariant.withOpacity(.45),
                        theme.colorScheme.surfaceVariant.withOpacity(.15),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 10,
                width: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(.5),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
