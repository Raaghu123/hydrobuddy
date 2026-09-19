import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Hydrify-style progress ring: blue track, water drop + intake in the middle.
class ProgressRing extends StatelessWidget {
  final double progress;
  final int todayMl;
  final int goalMl;
  const ProgressRing(
      {super.key,
      required this.progress,
      required this.todayMl,
      required this.goalMl});

  @override
  Widget build(BuildContext context) {
    final pct = (progress.clamp(0.0, 1.0) * 100).toInt();
    return SizedBox(
      height: 220,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 220,
            width: 220,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 20,
              strokeCap: StrokeCap.round,
              backgroundColor: AppTheme.tile,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppTheme.tile,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop,
                    color: AppTheme.primary, size: 30),
              ),
              const SizedBox(height: 6),
              Text('$todayMl',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                      color: AppTheme.ink,
                      letterSpacing: -0.5)),
              Text('/$goalMl mL',
                  style:
                      const TextStyle(color: AppTheme.muted, fontSize: 13)),
              const SizedBox(height: 2),
              Text('$pct%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
