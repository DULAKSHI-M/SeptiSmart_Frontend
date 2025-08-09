import 'package:flutter/material.dart';
import '../db_service.dart';
import '../widgets/tank_gauge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DBService.instance;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList.list(
                children: [
                  const SizedBox(height: 8),

                  
                  // Tank 1
                  StreamBuilder<double>(
                    stream: db.tankPercent('Tank1'),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final value = (snap.data ?? 0.0).toDouble();
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
                  const SizedBox(height: 26),

                  // Tank 2
                 StreamBuilder<double>(
                  stream: db.tankPercent('Tank2'),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    final value = (snap.data ?? 0.0).toDouble();
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
      bottomNavigationBar: _BottomNav(),
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
            Text('SEPTI\nSMART',
                textAlign: TextAlign.right,
                style: theme.textTheme.titleLarge?.copyWith(
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                )),
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
          Icon(Icons.home_filled, color: cs.primary),
          Icon(Icons.wb_sunny_outlined, color: cs.outline),
          Icon(Icons.settings_outlined, color: cs.outline),
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
        Text(label,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            )),
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
