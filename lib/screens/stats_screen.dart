import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/hydration_provider.dart';

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
      appBar: AppBar(title: const Text('📊 Stats & Streaks')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔥 Current streak: ${h.streakDays} days',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                      'Drink at least ${h.dailyGoalMl} ml daily to keep it alive!'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Last 7 days (ml)',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
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
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFF00C2FF),
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
                                  DateFormat.E()
                                      .format(entries[v.toInt()].key),
                                  style: const TextStyle(fontSize: 11),
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
          ),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1E293B),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏅 Achievements',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  for (final id in [
                    'first_sip',
                    'half_way',
                    'goal_crusher',
                    'big_chug',
                    'streak_3',
                    'streak_7'
                  ])
                    ListTile(
                      dense: true,
                      leading: Text(
                          h.unlocked.contains(id) ? '✅' : '🔒',
                          style: const TextStyle(fontSize: 20)),
                      title: Text(id,
                          style: const TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
