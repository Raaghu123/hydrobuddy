import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/hydration_provider.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HydrationProvider>();
    final data = h.last7Days();
    final entries = data.entries.toList();
    final maxY =
        (entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b))
                .toDouble() +
            250;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text('Statistics',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: AppTheme.ink)),
            const SizedBox(height: 14),
            _streakCard(h),
            const SizedBox(height: 14),
            _completionCard(context, h, entries, maxY),
            const SizedBox(height: 14),
            _achievementsGrid(h),
          ],
        ),
      ),
    );
  }

  Widget _streakCard(HydrationProvider h) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.amberBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.local_fire_department,
                color: AppTheme.amber, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${h.streakDays} day streak',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
                Text('Drink ${h.dailyGoalMl} mL daily to keep it alive',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _completionCard(BuildContext context, HydrationProvider h,
      List<MapEntry<DateTime, int>> entries, double maxY) {
    final avg = entries.isEmpty
        ? 0
        : (entries.map((e) => e.value).fold(0, (a, b) => a + b) /
                entries.length)
            .toInt();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Drink Completion',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppTheme.ink)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.tile,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('avg $avg mL',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: BarChart(
                BarChartData(
                  maxY: maxY <= 0 ? 1000 : maxY,
                  barGroups: [
                    for (var i = 0; i < entries.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: entries[i].value.toDouble(),
                            width: 22,
                            borderRadius: BorderRadius.circular(8),
                            color: entries[i].value >= h.dailyGoalMl
                                ? AppTheme.green
                                : AppTheme.primary,
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat.E().format(entries[v.toInt()].key),
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.muted),
                          ),
                        ),
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _achievementsGrid(HydrationProvider h) {
    const medals = [
      ('first_sip', 'First Sip', 'Log your first drink', '💧'),
      ('half_way', 'Halfway Hero', 'Reach 50% of goal', '🌊'),
      ('goal_crusher', 'Goal Crusher', 'Hit 100% of goal', '🏆'),
      ('big_chug', 'Big Chug', '500 mL in one tap', '🐳'),
      ('streak_3', '3-Day Splash', '3 day streak', '🔥'),
      ('streak_7', 'Legend', '7 day streak', '👑'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Achievements',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppTheme.ink)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: medals.length,
          itemBuilder: (context, i) {
            final unlocked = h.unlocked.contains(medals[i].$1);
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: unlocked
                    ? Border.all(color: AppTheme.primary, width: 1.5)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(medals[i].$4,
                      style: TextStyle(
                          fontSize: 28,
                          color: unlocked
                              ? null
                              : Colors.grey.withValues(alpha: 0.4))),
                  const SizedBox(height: 6),
                  Text(medals[i].$2,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppTheme.ink)),
                  Text(
                      unlocked ? medals[i].$3 : 'Locked — keep sipping!',
                      style: const TextStyle(
                          color: AppTheme.muted, fontSize: 11)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
