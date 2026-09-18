import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hydration_provider.dart';
import '../widgets/progress_ring.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
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
          SnackBar(content: Text('🎉 Achievement unlocked: $id!')),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('💧 HydroBuddy'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text('🔥 ${h.streakDays}'),
              backgroundColor: const Color(0xFFFFC42E),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: ProgressRing(
                  progress: h.progress,
                  todayMl: h.todayMl,
                  goalMl: h.dailyGoalMl,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _quickAdd(context, h, 150, '🥤'),
                  _quickAdd(context, h, 250, '💧'),
                  _quickAdd(context, h, 350, '🥛'),
                  _quickAdd(context, h, 500, '🐳'),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF1B2CC1),
                child: ListTile(
                  leading: Text(h.voiceProfile.emoji,
                      style: const TextStyle(fontSize: 28)),
                  title: Text('“${h.nextCupPhrase}”',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800)),
                  subtitle: Text(
                      '${h.voiceProfile.label} • every ${h.reminderIntervalMin} min • ${h.alertSound.label}${h.vibrationEnabled ? ' + vibrate' : ''}${h.quietEnabled ? ' • 🌙 ${HydrationProvider.fmtMin(h.quietStartMin)}-${HydrationProvider.fmtMin(h.quietEndMin)}' : ''}',
                      style: const TextStyle(color: Colors.white70)),
                ),
              ),
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Text('🏅', style: TextStyle(fontSize: 28)),
                  title: Text(
                      '${h.unlocked.length} / 6 achievements unlocked'),
                  subtitle: Text(h.unlocked.isEmpty
                      ? 'Log a drink to earn your first badge!'
                      : h.unlocked.join(' • ')),
                  trailing: IconButton(
                    icon: const Icon(Icons.undo),
                    tooltip: 'Undo last log',
                    onPressed: () => context.read<HydrationProvider>().undoLast(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Today: ${h.logsToday} drinks',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.blueGrey)),
            ],
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

  Widget _quickAdd(
      BuildContext context, HydrationProvider h, int ml, String emoji) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1B2CC1),
        foregroundColor: Colors.white,
      ),
      onPressed: () => context.read<HydrationProvider>().addWater(ml),
      child: Text('$emoji +$ml ml',
          style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
