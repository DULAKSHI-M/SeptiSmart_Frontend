import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/monthly_report.dart';
import '../service/monthly_report_service.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  late Future<List<MonthlyReport>> _future;

  // Brand palette
  static const Color kDarkGreen = Color(0xFF0B5D33);
  static const Color kGreen = Color(0xFF2E7D32);
  static const Color kMint = Color(0xFF66BB6A);
  static const Color kBg = Color(0xFFF6F8F7);

  // Alert line
  static const double kThreshold = 80;

  // Month order (full year)
  static const List<String> kMonths = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];

  @override
  void initState() {
    super.initState();
    _future = MonthlyReportService().fetchMonthlyReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kDarkGreen,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: const [
            SizedBox(width: 12),
            Icon(Icons.stacked_bar_chart_rounded),
            SizedBox(width: 8),
            Text('Monthly Tank Report'),
          ],
        ),
      ),
      body: FutureBuilder<List<MonthlyReport>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _LoadingView();
          }
          if (snap.hasError) {
            return _ErrorView(message: snap.error.toString(), onRetry: _reload);
          }

          final raw = snap.data ?? [];

          // Full-year series (Jan..Dec); fill missing with 0.0
          final byMonth = {for (final m in raw) m.month.trim(): m.filledPercentage};
          final series = kMonths
              .map((m) => MonthlyReport(
                    month: m,
                    filledPercentage: ((byMonth[m] ?? 0).clamp(0, 100)).toDouble(),
                  ))
              .toList();

          final values = series.map((e) => e.filledPercentage).toList();
          final double avg   = values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
          final double minVal = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
          final double maxVal = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                _SummaryRow(avg: avg, minVal: minVal, maxVal: maxVal),
                const SizedBox(height: 14),
                _ChartCard(series: series),
                const SizedBox(height: 10),
                const Text(
                  'Tap a bar to see the exact percentage for that month.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _reload() {
    setState(() {
      _future = MonthlyReportService().fetchMonthlyReports();
    });
  }
}

class _ChartCard extends StatefulWidget {
  const _ChartCard({required this.series});
  final List<MonthlyReport> series;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  static const Color kDarkGreen = _MonthlyReportScreenState.kDarkGreen;
  static const double kThreshold = _MonthlyReportScreenState.kThreshold;

  // Track which group (month) is currently touched; -1 means none
  int _touchedGroupIndex = -1;

  LinearGradient _barGradient(double v) {
    // Green for normal, amber->red for high (>= threshold)
    if (v >= kThreshold) {
      return const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFFFFA000), Color(0xFFE53935)], // amber -> red
      );
    }
    return const LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)], // greens
    );
  }

  @override
  Widget build(BuildContext context) {
    const maxY = 100.0;
    final months = _MonthlyReportScreenState.kMonths;
    final series = widget.series;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 14),
            color: Colors.black.withOpacity(.08),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: const [
              Icon(Icons.calendar_month_rounded, color: kDarkGreen),
              SizedBox(width: 8),
              Text(
                'Month-wise Filled Percentage',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 330,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                groupsSpace: 12,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  drawHorizontalLine: true,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                    dashArray: const [6, 6],
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),

                // Touch + tooltip: only show when a bar is tapped
                barTouchData: BarTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.spot == null) {
                      setState(() => _touchedGroupIndex = -1);
                      return;
                    }
                    setState(() => _touchedGroupIndex =
                        response.spot!.touchedBarGroupIndex);
                  },
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 10,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final month = months[group.x.toInt()];
                      final val = rod.toY;
                      return BarTooltipItem(
                        '$month\n',
                        const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: '${val.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: kThreshold,
                    color: Colors.red.shade400,
                    strokeWidth: 1.4,
                    dashArray: const [8, 6],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 6, bottom: 2),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
                      labelResolver: (_) => 'Alert ${kThreshold.toInt()}%',
                    ),
                  ),
                ]),

                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: 20,
                      getTitlesWidget: (v, meta) => Text(
                        '${v.toInt()}%',
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= months.length) return const SizedBox.shrink();
                        final m = months[i].substring(0, 3); // Jan, Feb, ...
                        final isTouched = i == _touchedGroupIndex;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // When touched, show the exact value above label
                              if (isTouched)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '${series[i].filledPercentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: kDarkGreen,
                                    ),
                                  ),
                                ),
                              Text(
                                m,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isTouched ? kDarkGreen : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // IMPORTANT: show tooltip indicator ONLY for touched bar
                barGroups: List.generate(months.length, (i) {
                  final v = series[i].filledPercentage.clamp(0, 100).toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: v,
                        width: 18,
                        gradient: _barGradient(v),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        rodStackItems: [
                          BarChartRodStackItem(0, v * 0.10, Colors.black.withOpacity(.04)),
                          BarChartRodStackItem(v * 0.10, v, Colors.transparent),
                        ],
                      ),
                    ],
                    showingTooltipIndicators:
                        _touchedGroupIndex == i ? const [0] : const [],
                  );
                }),
              ),
              swapAnimationDuration: const Duration(milliseconds: 250),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.avg, required this.minVal, required this.maxVal});

  final double avg;
  final double minVal;
  final double maxVal;

  static const Color kDarkGreen = _MonthlyReportScreenState.kDarkGreen;

  Widget _chip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: -8,
            offset: const Offset(0, 12),
            color: Colors.black.withOpacity(.06),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: kDarkGreen, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        _chip(Icons.trending_down_rounded, 'Min', '${minVal.toStringAsFixed(1)}%'),
        _chip(Icons.show_chart_rounded, 'Avg', '${avg.toStringAsFixed(1)}%'),
        _chip(Icons.trending_up_rounded, 'Max', '${maxVal.toStringAsFixed(1)}%'),
      ],
    );
  }
}

/// ---------- States (loading / error) ----------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 44,
        height: 44,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.error_outline_rounded,
      title: 'Failed to load report',
      subtitle: message,
      actionLabel: 'Retry',
      onAction: onRetry,
      color: Colors.red.shade400,
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              spreadRadius: -8,
              offset: const Offset(0, 14),
              color: Colors.black.withOpacity(.08),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
