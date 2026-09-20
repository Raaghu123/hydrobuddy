import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/hydration_provider.dart';
import '../services/voice_reminder_service.dart';
import '../theme/app_theme.dart';
import '../widgets/progress_ring.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onViewAllHistory;
  final VoidCallback? onEnableReminders;
  const HomeScreen(
      {super.key, this.onViewAllHistory, this.onEnableReminders});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController _confetti;
  Timer? _timer;
  int _cup = 250;
  static const _cups = [100, 150, 250, 350, 500];

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    // In-app voice engine: while the app is open, speak each due reminder.
    // (Background/alarm reminders arrive as notifications — see
    // NotificationService.scheduleNext — so the phone reminds you too.)
    _timer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (!mounted) return;
      final h = context.read<HydrationProvider>();
      final phrase = await h.tick();
      if (phrase != null && mounted) {
        await VoiceReminderService.playReminder(
          nextCupNumber: h.nextCupNumber,
          profile: h.voiceProfile,
          sound: h.alertSound,
          vibrationEnabled: h.vibrationEnabled,
          customVoicePath: h.customVoicePath,
          customSoundPath: h.customSoundPath,
          isQuietNow: false,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🔔 $phrase')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  String _greeting() {
    final hr = DateTime.now().hour;
    if (hr < 12) return 'Good morning,';
    if (hr < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HydrationProvider>();

    if (h.lastCelebratedAchievement != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confetti.play();
        final id = h.lastCelebratedAchievement!;
        h.clearCelebration();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Achievement unlocked: $id')),
        );
      });
    }

    final todayLogs = h.logs
        .where((l) {
          final now = DateTime.now();
          return l.timestamp.year == now.year &&
              l.timestamp.month == now.month &&
              l.timestamp.day == now.day;
        })
        .toList()
        .reversed
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _header(h),
                const SizedBox(height: 16),
                _heroCard(context, h),
                const SizedBox(height: 16),
                h.remindersAvailable
                    ? _voiceCard(context, h)
                    : _permissionCta(context, h),
                const SizedBox(height: 16),
                _historyCard(context, h, todayLogs),
                const SizedBox(height: 16),
                _achievementsStrip(h),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(HydrationProvider h) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppTheme.tile,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: AppTheme.primary, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(),
                  style:
                      const TextStyle(color: AppTheme.muted, fontSize: 13)),
              const Text('Stay Hydrated',
                  style: TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.amberBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: AppTheme.amber, size: 18),
              const SizedBox(width: 4),
              Text('${h.streakDays}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppTheme.ink)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroCard(BuildContext context, HydrationProvider h) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily Goal',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.muted,
                        fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.tile,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${(h.progress * 100).toInt()}%',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ProgressRing(
                progress: h.progress,
                todayMl: h.todayMl,
                goalMl: h.dailyGoalMl),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    onPressed: () =>
                        context.read<HydrationProvider>().addWater(_cup),
                    child: Text('Drink $_cup mL',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.tile,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.local_drink,
                        color: AppTheme.primary),
                    tooltip: 'Undo last log',
                    onPressed: () =>
                        context.read<HydrationProvider>().undoLast(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: _cups
                  .map((c) => ChoiceChip(
                        label: Text('$c'),
                        selected: _cup == c,
                        selectedColor: AppTheme.primary,
                        backgroundColor: AppTheme.tile,
                        labelStyle: TextStyle(
                            color: _cup == c
                                ? Colors.white
                                : AppTheme.primary,
                            fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        onSelected: (_) => setState(() => _cup = c),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionCta(BuildContext context, HydrationProvider h) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF9F68)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_off,
              color: Colors.white, size: 24),
        ),
        title: const Text('Reminders are off',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        subtitle: const Text(
            'Grant notification access to unlock voice reminders, sounds and buzzes.',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFFF6B6B),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: () async {
            final ok = await context
                .read<HydrationProvider>()
                .requestReminderPermissions();
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Permission denied — reminders stay locked.')),
              );
            }
            widget.onEnableReminders?.call();
          },
          child: const Text('Enable',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _voiceCard(BuildContext context, HydrationProvider h) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.record_voice_over,
              color: Colors.white, size: 24),
        ),
        title: Text('“${h.nextCupPhrase}”',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        subtitle: Text(
            '${h.voiceProfile.label} • every ${h.reminderIntervalMin} min${h.vibrationEnabled ? ' • vibrate' : ''}',
            style:
                const TextStyle(color: Colors.white70, fontSize: 12)),
        trailing: Container(
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.play_arrow, color: AppTheme.primary),
            tooltip: 'Preview reminder',
            onPressed: () => VoiceReminderService.playReminder(
              nextCupNumber: h.nextCupNumber,
              profile: h.voiceProfile,
              sound: h.alertSound,
              vibrationEnabled: h.vibrationEnabled,
              customVoicePath: h.customVoicePath,
              customSoundPath: h.customSoundPath,
              isQuietNow: false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _historyCard(
      BuildContext context, HydrationProvider h, List<dynamic> todayLogs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('History',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppTheme.ink)),
                TextButton(
                  onPressed: widget.onViewAllHistory,
                  child: const Text('View All',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            if (todayLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No drinks yet today — tap Drink to start!',
                    style: TextStyle(color: AppTheme.muted)),
              )
            else
              for (final log in todayLogs.take(4))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.tile,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.water_drop,
                            color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Water',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.ink)),
                            Text(
                                DateFormat.jm().format(
                                    (log as dynamic).timestamp as DateTime),
                                style: const TextStyle(
                                    color: AppTheme.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('+${(log as dynamic).milliliters as int} mL',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.ink)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _achievementsStrip(HydrationProvider h) {
    const medals = [
      ('first_sip', 'First Sip', '💧'),
      ('half_way', 'Halfway', '🌊'),
      ('goal_crusher', 'Crusher', '🏆'),
      ('big_chug', 'Big Chug', '🐳'),
      ('streak_3', '3-Day', '🔥'),
      ('streak_7', 'Legend', '👑'),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: medals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final unlocked = h.unlocked.contains(medals[i].$1);
          return Container(
            width: 92,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: unlocked
                  ? Border.all(color: AppTheme.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(medals[i].$3,
                    style: TextStyle(
                        fontSize: 26,
                        color: unlocked ? null : Colors.grey.withValues(alpha: 0.5))),
                const SizedBox(height: 4),
                Text(medals[i].$2,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: unlocked
                            ? AppTheme.ink
                            : AppTheme.muted)),
              ],
            ),
          );
        },
      ),
    );
  }
}
