import 'package:flutter/material.dart';
import '../db_service.dart';
import '../widgets/tank_gauge.dart';
import 'emergency_services_screen.dart';
import 'screens/monthly_report_screen.dart';

/// Simple alert record to show in the notifications sheet
class TankAlert {
  final String tank;
  final int level; // 80, 90, 100
  final DateTime time;
  final double value;

  TankAlert({
    required this.tank,
    required this.level,
    required this.time,
    required this.value,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = DBService.instance;

  // Track the last seen value to detect threshold crossings (rising-edge only)
  double? _lastTank1;
  double? _lastTank2;

  // Prevent spamming while value stays above the threshold
  final Set<int> _ackTank1 = {};
  final Set<int> _ackTank2 = {};

  // Active alerts to show in the bottom sheet + badge count
  final List<TankAlert> _alerts = [];

  // Common thresholds
  static const List<int> _thresholds = [80, 90, 100];

  // ---- Notification helpers ----

  void _maybeTriggerAlerts({
    required String tankName,
    required double current,
    required double? last,
    required Set<int> ackSet,
  }) {
    for (final t in _thresholds) {
      final crossedUp = (last == null || last < t) && current >= t;
      if (crossedUp && !ackSet.contains(t)) {
        ackSet.add(t);
        _pushAlert(tankName, t, current);
      }

      // Reset ack after falling below (hysteresis = 3%)
      if (current < (t - 3)) {
        ackSet.remove(t);
      }
    }
  }

  void _pushAlert(String tank, int level, double value) {
    final alert = TankAlert(
      tank: tank,
      level: level,
      time: DateTime.now(),
      value: value,
    );

    // Defer mutations to AFTER the current frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _alerts.insert(0, alert);
      });

      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.primary,
          content: Text(
            '$tank reached $level% (now: ${value.toStringAsFixed(1)}%).',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: _openAlertsSheet,
          ),
        ),
      );
    });
  }

  void _openAlertsSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined),
                    const SizedBox(width: 8),
                    Text(
                      'Tank Alerts',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    if (_alerts.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _alerts.clear());
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear all'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_alerts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'No alerts right now.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Theme.of(context).hintColor),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _alerts.length,
                      separatorBuilder: (_, __) => const Divider(height: 8),
                      itemBuilder: (_, i) {
                        final a = _alerts[i];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            a.level >= 100
                                ? Icons.warning_amber_rounded
                                : a.level >= 90
                                    ? Icons.priority_high_rounded
                                    : Icons.notifications_none,
                            color: a.level >= 100
                                ? Colors.red
                                : a.level >= 90
                                    ? Colors.orange
                                    : const Color(0xFF0B5D33),
                          ),
                          title: Text('${a.tank} reached ${a.level}%'),
                          subtitle: Text(
                            'Current: ${a.value.toStringAsFixed(1)}% • ${_formatTime(a.time)}',
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList.list(
                children: [
                  const SizedBox(height: 8),

                  // ---- Tank 1 ----
                  StreamBuilder<double>(
                    stream: db.tankPercent('Tank1'),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const _GaugeSkeleton(label: 'Tank 1 summary');
                      }
                      final value = (snap.data ?? 0.0).toDouble();

                      _maybeTriggerAlerts(
                        tankName: 'Tank 1',
                        current: value,
                        last: _lastTank1,
                        ackSet: _ackTank1,
                      );
                      _lastTank1 = value;

                      return TankGauge(
                        title: 'Tank 1 summary',
                        percent: value,
                        onTap: () {
                          // TODO: navigate to tank 1 details
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 26),
                  Center(
                    child: Text(
                      'Click icon to see more…',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: Theme.of(context).hintColor),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // NEW: Tap here button -> Monthly Report chart
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B5D33), // dark green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const MonthlyReportScreen()),
                        );
                      },
                      child: const Text('Tap here'),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ---- Tank 2 ----
                  StreamBuilder<double>(
                    stream: db.tankPercent('Tank2'),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const _GaugeSkeleton(label: 'Tank 2 summary');
                      }
                      final value = (snap.data ?? 0.0).toDouble();

                      _maybeTriggerAlerts(
                        tankName: 'Tank 2',
                        current: value,
                        last: _lastTank2,
                        ackSet: _ackTank2,
                      );
                      _lastTank2 = value;

                      return TankGauge(
                        title: 'Tank 2 summary',
                        percent: value,
                        onTap: () {
                          // TODO: navigate to tank 2 details
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),

      // Tiny bell button with a badge. Only visible when we have alerts.
      floatingActionButton: Visibility(
        visible: _alerts.isNotEmpty,
        child: FloatingActionButton.small(
          onPressed: _openAlertsSheet,
          backgroundColor: Colors.white,
          elevation: 4,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_active_outlined, color: cs.primary),
              Positioned(
                top: -4,
                right: -4,
                child: _Badge(count: _alerts.length),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              spreadRadius: -6,
              offset: const Offset(0, 10),
              color: Colors.black.withOpacity(.08),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.water_drop_outlined,
                size: 34, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello! User', style: theme.textTheme.titleMedium),
                  Text('WELCOME TO', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            Text(
              'SEPTI\nSMART',
              textAlign: TextAlign.right,
              style: theme.textTheme.titleLarge?.copyWith(
                height: 1.0,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BottomAppBar(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Home (current page → no-op)
          IconButton(
            tooltip: 'Home',
            icon: Icon(Icons.home_filled, color: cs.primary),
            onPressed: () {
              // Already on Home. Keep as no-op.
            },
          ),

          // Middle: Emergency Services (navigate)
          IconButton(
            tooltip: 'Emergency Services',
            icon: Icon(Icons.wb_sunny_outlined, color: cs.outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EmergencyServicesScreen(),
                ),
              );
            },
          ),

          // Right: Settings (placeholder)
          IconButton(
            tooltip: 'Settings',
            icon: Icon(Icons.settings_outlined, color: cs.outline),
            onPressed: () {
              // TODO: hook up your settings screen later
            },
          ),
        ],
      ),
    );
  }
}

/// Simple placeholder while first data frame arrives
class _GaugeSkeleton extends StatelessWidget {
  final String label;
  const _GaugeSkeleton({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          width: 220,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(.3),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      ],
    );
  }
}
