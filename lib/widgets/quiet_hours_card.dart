import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hydration_provider.dart';

class QuietHoursCard extends StatelessWidget {
  const QuietHoursCard({super.key});

  Future<void> _pick(
      BuildContext context, bool isStart, int currentMin) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: currentMin ~/ 60, minute: currentMin % 60),
    );
    if (picked == null || !context.mounted) return;
    final h = context.read<HydrationProvider>();
    final newMin = picked.hour * 60 + picked.minute;
    if (isStart) {
      await h.setQuiet(true, newMin, h.quietEndMin);
    } else {
      await h.setQuiet(true, h.quietStartMin, newMin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HydrationProvider>();
    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🌙 Quiet hours',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                Switch(
                  value: h.quietEnabled,
                  onChanged: (v) => context
                      .read<HydrationProvider>()
                      .setQuiet(v, h.quietStartMin, h.quietEndMin),
                ),
              ],
            ),
            Text(
              h.quietEnabled
                  ? 'Paused ${HydrationProvider.fmtMin(h.quietStartMin)} → ${HydrationProvider.fmtMin(h.quietEndMin)}${h.isQuietNow ? ' • sleeping now 😴' : ''}'
                  : 'Off — reminders anytime',
              style: const TextStyle(color: Colors.white70),
            ),
            if (h.quietEnabled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white),
                      onPressed: () => _pick(
                          context, true, h.quietStartMin),
                      child: Text(
                          'Bedtime ${HydrationProvider.fmtMin(h.quietStartMin)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white),
                      onPressed: () =>
                          _pick(context, false, h.quietEndMin),
                      child: Text(
                          'Wake ${HydrationProvider.fmtMin(h.quietEndMin)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Next reminder: ${h.nextReminderAfter(DateTime.now()).hour.toString().padLeft(2, '0')}:${h.nextReminderAfter(DateTime.now()).minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    color: Color(0xFFFFC42E), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
