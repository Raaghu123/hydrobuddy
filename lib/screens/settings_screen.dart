import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/voice_profile.dart';
import '../providers/hydration_provider.dart';
import '../services/voice_reminder_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_voice_card.dart';
import '../widgets/quiet_hours_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HydrationProvider>();
    final nextAt = h.nextReminderAt;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text('Settings',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: AppTheme.ink)),
            const SizedBox(height: 14),
            _permissionGate(context, h),
            const SizedBox(height: 16),
            _sectionTitle('Daily Goal'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Target intake',
                            style:
                                TextStyle(color: AppTheme.muted)),
                        Text('${h.dailyGoalMl} mL',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                                fontSize: 16)),
                      ],
                    ),
                    Slider(
                      min: 1000,
                      max: 5000,
                      divisions: 16,
                      value: h.dailyGoalMl.toDouble().clamp(1000, 5000),
                      onChanged: (v) => context
                          .read<HydrationProvider>()
                          .setGoal(v.toInt()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _sectionTitle('Reminders'),
            _locked(
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Interval',
                            style:
                                TextStyle(color: AppTheme.muted)),
                        Text(
                            h.reminderIntervalMin == 60
                                ? 'Every hour'
                                : 'Every ${h.reminderIntervalMin} min',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                                fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: HydrationProvider.intervalPresets
                          .map((m) => ChoiceChip(
                                label: Text(m == 60 ? '1h' : '${m}m'),
                                selected: h.reminderIntervalMin == m,
                                selectedColor: AppTheme.primary,
                                backgroundColor: AppTheme.tile,
                                labelStyle: TextStyle(
                                    color: h.reminderIntervalMin == m
                                        ? Colors.white
                                        : AppTheme.primary,
                                    fontWeight: FontWeight.w700),
                                onSelected: (_) => context
                                    .read<HydrationProvider>()
                                    .setInterval(m),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Custom  ',
                            style:
                                TextStyle(color: AppTheme.muted)),
                        Expanded(
                          child: Slider(
                            min: 15,
                            max: 240,
                            divisions: 45,
                            value: h.reminderIntervalMin
                                .toDouble()
                                .clamp(15, 240),
                            onChanged: (v) => context
                                .read<HydrationProvider>()
                                .setInterval(v.toInt()),
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text('${h.reminderIntervalMin}m',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Next: “${h.nextCupPhrase}”',
                      style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.muted),
                    ),
                    if (nextAt != null)
                      Text(
                        'Buzzes at ${DateFormat.jm().format(nextAt)}${h.isQuietNow ? ' (paused — quiet hours 😴)' : ''}',
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                  ],
                ),
              ),
            ),
            !h.remindersAvailable,
            ),
            const SizedBox(height: 16),
            _sectionTitle('Voice & Sound'),
            _locked(
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Original TTS styles — not real celebrity clones (those need licensing).',
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                    for (final v in VoiceProfile.all)
                      RadioListTile<String>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: v.id,
                        groupValue: h.voiceProfileId,
                        activeColor: AppTheme.primary,
                        title: Text('${v.emoji} ${v.label}'),
                        subtitle: Text(v.description,
                            style: const TextStyle(fontSize: 12)),
                        onChanged: (id) => context
                            .read<HydrationProvider>()
                            .setVoice(id ?? 'hero'),
                      ),
                    const Divider(),
                    Wrap(
                      spacing: 8,
                      children: AlertSound.values
                          .map((s) => ChoiceChip(
                                label: Text(s.label,
                                    style: const TextStyle(fontSize: 12)),
                                selected: h.alertSound == s,
                                selectedColor: AppTheme.primary,
                                backgroundColor: AppTheme.tile,
                                labelStyle: TextStyle(
                                    color: h.alertSound == s
                                        ? Colors.white
                                        : AppTheme.primary,
                                    fontWeight: FontWeight.w700),
                                onSelected: (_) => context
                                    .read<HydrationProvider>()
                                    .setSound(s),
                              ))
                          .toList(),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vibration'),
                      value: h.vibrationEnabled,
                      activeColor: AppTheme.primary,
                      onChanged: (v) => context
                          .read<HydrationProvider>()
                          .setVibration(v),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Preview'),
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
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16)),
                            ),
                            onPressed: () async {
                              final ok = await context
                                  .read<HydrationProvider>()
                                  .requestReminderPermissions();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                        content: Text(ok
                                            ? 'Reminders armed — watch for the next buzz'
                                            : 'Permission needed — reminders stay locked')));
                              }
                            },
                            child: const Text('Enable alerts'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            !h.remindersAvailable,
            ),
            const SizedBox(height: 16),
            _locked(
              const CustomVoiceCard(),
              !h.remindersAvailable,
            ),
            const SizedBox(height: 16),
            const QuietHoursCard(),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.watch, color: AppTheme.primary),
                title: Text('Wear OS + Widget',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                    'Wear tile speaks the same cup line. Home widget shows % + next cup.'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionGate(BuildContext context, HydrationProvider h) {
    if (h.remindersAvailable && h.exactTiming) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F9EE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle,
                color: AppTheme.green, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('All reminder permissions granted',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                      fontSize: 13)),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF6B6B), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock,
                  color: Color(0xFFFF6B6B), size: 20),
              const SizedBox(width: 8),
              Text(
                  h.remindersAvailable
                      ? 'Exact timing off'
                      : 'Reminder features locked',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            h.remindersAvailable
                ? 'Allow exact alarms so buzzes land on the minute — otherwise they may arrive late.'
                : 'Notification access is required. Intervals, voices, sounds and buzzes stay disabled until you grant it.',
            style:
                const TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => context
                      .read<HydrationProvider>()
                      .requestReminderPermissions(),
                  child: const Text('Grant access',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => context
                      .read<HydrationProvider>()
                      .openSystemSettings(),
                  child: const Text('Open settings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _locked(Widget child, bool locked) {
    if (!locked) return child;
    return Opacity(
      opacity: 0.45,
      child: IgnorePointer(ignoring: true, child: child),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.ink)),
      );
}
