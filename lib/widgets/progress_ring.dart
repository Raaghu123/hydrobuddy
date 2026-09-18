import 'package:flutter/material.dart';

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
    return SizedBox(
      height: 230,
      width: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 230,
            width: 230,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 22,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00C2FF)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💧', style: TextStyle(fontSize: 36)),
              Text('$todayMl ml',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(color: const Color(0xFF1B2CC1))),
              Text('of $goalMl ml goal',
                  style: const TextStyle(color: Colors.blueGrey)),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: Color(0xFF00C2FF))),
            ],
          ),
        ],
      ),
    );
  }
}
