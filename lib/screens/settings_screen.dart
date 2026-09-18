import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voice_profile.dart';
import '../providers/hydration_provider.dart';
import '../services/notification_service.dart';
import '../services/voice_reminder_service.dart';
import '../widgets/custom_voice_card.dart';
import '../widgets/quiet_hours_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HydrationProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Settings')),
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
                  Text('Daily goal: ${h.dailyGoalMl} ml',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Slider(
                    min: 1000,
                    max: 5000,
                    divisions: 16,
                    value: h.dailyGoalMl.toDouble().clamp(1000, 5000),
                    onChanged: (v) =>
                        context.read<HydrationProvider>().setGoal(v.toInt()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⏰ Remind me every ${h.reminderIntervalMin} min',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: HydrationProvider.intervalPresets
                        .map((m) => ChoiceChip(
                              label: Text(m == 60 ? '1 hour' : '${m}m'),
                              selected: h.reminderIntervalMin == m,
                              onSelected: (_) => context
                                  .read<HydrationProvider>()
                                  .setInterval(m),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Next: “${h.nextCupPhrase}” (cup #${h.nextCupNumber})',
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎙️ Reminder voice',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(
                    'Original TTS styles — not real celebrity clones (those need licensing).',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  for (final v in VoiceProfile.all)
                    RadioListTile<String>(
                      dense: true,
                      value: v.id,
                      groupValue: h.voiceProfileId,
                      title: Text('${v.emoji} ${v.label}'),
                      subtitle: Text(v.description,
                          style: const TextStyle(fontSize: 12)),
                      onChanged: (id) => context
                          .read<HydrationProvider>()
                          .setVoice(id ?? 'hero'),
                    ),
                  const Divider(),
                  const Text('🔔 Sound',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  Wrap(
                    spacing: 8,
                    children: AlertSound.values
                        .map((s) => ChoiceChip(
                              label: Text(s.label),
                              selected: h.alertSound == s,
                              onSelected: (_) => context
                                  .read<HydrationProvider>()
                                  .setSound(s),
                            ))
                        .toList(),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('📳 Vibration'),
                    value: h.vibrationEnabled,
                    onChanged: (v) => context
                        .read<HydrationProvider>()
                        .setVibration(v),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Preview reminder'),
                        onPressed: () =>
                            VoiceReminderService.playReminder(
                          nextCupNumber: h.nextCupNumber,
                          profile: h.voiceProfile,
                          sound: h.alertSound,
                          vibrationEnabled: h.vibrationEnabled,
                          customVoicePath: h.customVoicePath,
                          customSoundPath: h.customSoundPath,
                          isQuietNow: h.isQuietNow,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () async {
                          await NotificationService.init();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        '✅ Notifications enabled!')));
                          }
                        },
                        child: const Text('Enable notifications'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const CustomVoiceCard(),
          const SizedBox(height: 12),
          const QuietHoursCard(),
          const SizedBox(height: 12),
          const Card(
            color: Colors.white,
            child: ListTile(
              leading: Text('⌚', style: TextStyle(fontSize: 24)),
              title: Text('Wear OS + Widget'),
              subtitle: Text(
                  'Wear tile speaks the same “Nth cup” line via TTS. Home widget shows % + next cup.'),
            ),
          ),
        ],
      ),
    );
  }
}
