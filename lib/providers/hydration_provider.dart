import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hydration_log.dart';
import '../models/voice_profile.dart';
import '../services/notification_service.dart';

class HydrationProvider extends ChangeNotifier {
  static const _kLogs = 'hydration_logs';
  static const _kGoal = 'daily_goal_ml';
  static const _kInterval = 'reminder_interval_min';
  static const _kAchievements = 'unlocked_achievements';
  static const _kStreak = 'streak_days';
  static const _kLastGoalDate = 'last_goal_date';
  static const _kVoice = 'voice_profile_id';
  static const _kSound = 'alert_sound';
  static const _kVibrate = 'vibration_enabled';
  static const _kQuietOn = 'quiet_enabled';
  static const _kQuietStart = 'quiet_start_min'; // minutes since midnight
  static const _kQuietEnd = 'quiet_end_min';
  static const _kCustomPath = 'custom_voice_path';
  static const _kCustomSound = 'custom_sound_path';
  static const _kNextAt = 'next_reminder_at';

  static const List<int> intervalPresets = [30, 45, 60, 90, 120];

  List<HydrationLog> _logs = [];
  int dailyGoalMl = 2500;
  int reminderIntervalMin = 60;
  String voiceProfileId = 'hero';
  AlertSound alertSound = AlertSound.voiceAndBeep;
  bool vibrationEnabled = true;
  bool quietEnabled = true;
  int quietStartMin = 22 * 60; // 22:00 default
  int quietEndMin = 7 * 60; // 07:00 default
  String? customVoicePath;
  String? customSoundPath;
  DateTime? nextReminderAt;
  Set<String> unlocked = {};
  int streakDays = 0;
  String? lastCelebratedAchievement;

  List<HydrationLog> get logs => List.unmodifiable(_logs);

  int get todayMl {
    final now = DateTime.now();
    return _logs
        .where((l) =>
            l.timestamp.year == now.year &&
            l.timestamp.month == now.month &&
            l.timestamp.day == now.day)
        .fold(0, (sum, l) => sum + l.milliliters);
  }

  double get progress =>
      dailyGoalMl == 0 ? 0 : (todayMl / dailyGoalMl).clamp(0.0, 1.0);

  int get logsToday {
    final now = DateTime.now();
    return _logs
        .where((l) =>
            l.timestamp.year == now.year &&
            l.timestamp.month == now.month &&
            l.timestamp.day == now.day)
        .length;
  }

  /// Next cup number = drinks logged today + 1 (drives the voice line).
  int get nextCupNumber => logsToday + 1;
  String get nextCupPhrase => cupReminderPhrase(nextCupNumber);
  VoiceProfile get voiceProfile => VoiceProfile.byId(voiceProfileId);

  // ---- Quiet hours ----
  static String fmtMin(int m) {
    final h = m ~/ 60, mm = m % 60;
    return '${h.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  }

  bool isQuietAt(DateTime t) {
    if (!quietEnabled) return false;
    final nowMin = t.hour * 60 + t.minute;
    if (quietStartMin == quietEndMin) return false;
    if (quietStartMin < quietEndMin) {
      return nowMin >= quietStartMin && nowMin < quietEndMin;
    }
    // overnight span e.g. 22:00 -> 07:00
    return nowMin >= quietStartMin || nowMin < quietEndMin;
  }

  bool get isQuietNow => isQuietAt(DateTime.now());

  /// Next fire time after [from], skipping quiet hours.
  DateTime nextReminderAfter(DateTime from) {
    var next = from.add(Duration(minutes: reminderIntervalMin));
    // push forward out of quiet window (cap 24h loop)
    for (var i = 0; i < 48; i++) {
      if (!isQuietAt(next)) break;
      next = next.add(const Duration(minutes: 5));
    }
    return next;
  }

  Map<DateTime, int> last7Days() {
    final map = <DateTime, int>{};
    final now = DateTime.now();
    for (var i = 6; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final total = _logs
          .where((l) =>
              l.timestamp.year == d.year &&
              l.timestamp.month == d.month &&
              l.timestamp.day == d.day)
          .fold(0, (s, l) => s + l.milliliters);
      map[d] = total;
    }
    return map;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    dailyGoalMl = prefs.getInt(_kGoal) ?? 2500;
    reminderIntervalMin = prefs.getInt(_kInterval) ?? 60;
    voiceProfileId = prefs.getString(_kVoice) ?? 'hero';
    final soundIdx = prefs.getInt(_kSound) ?? AlertSound.voiceAndBeep.index;
    alertSound = AlertSound.values[soundIdx.clamp(0, AlertSound.values.length - 1)];
    vibrationEnabled = prefs.getBool(_kVibrate) ?? true;
    quietEnabled = prefs.getBool(_kQuietOn) ?? true;
    quietStartMin = prefs.getInt(_kQuietStart) ?? 22 * 60;
    quietEndMin = prefs.getInt(_kQuietEnd) ?? 7 * 60;
    customVoicePath = prefs.getString(_kCustomPath);
    customSoundPath = prefs.getString(_kCustomSound);
    final nextMs = prefs.getInt(_kNextAt);
    nextReminderAt =
        nextMs == null ? null : DateTime.fromMillisecondsSinceEpoch(nextMs);
    streakDays = prefs.getInt(_kStreak) ?? 0;
    unlocked = (prefs.getStringList(_kAchievements) ?? []).toSet();
    final raw = prefs.getString(_kLogs);
    if (raw != null && raw.isNotEmpty) {
      try {
        _logs = HydrationLog.decodeList(raw);
      } catch (_) {
        _logs = [];
      }
    }
    _updateStreak();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLogs, HydrationLog.encodeList(_logs));
    await prefs.setInt(_kGoal, dailyGoalMl);
    await prefs.setInt(_kInterval, reminderIntervalMin);
    await prefs.setString(_kVoice, voiceProfileId);
    await prefs.setInt(_kSound, alertSound.index);
    await prefs.setBool(_kVibrate, vibrationEnabled);
    await prefs.setBool(_kQuietOn, quietEnabled);
    await prefs.setInt(_kQuietStart, quietStartMin);
    await prefs.setInt(_kQuietEnd, quietEndMin);
    if (customVoicePath == null) {
      await prefs.remove(_kCustomPath);
    } else {
      await prefs.setString(_kCustomPath, customVoicePath!);
    }
    if (customSoundPath == null) {
      await prefs.remove(_kCustomSound);
    } else {
      await prefs.setString(_kCustomSound, customSoundPath!);
    }
    if (nextReminderAt == null) {
      await prefs.remove(_kNextAt);
    } else {
      await prefs.setInt(_kNextAt, nextReminderAt!.millisecondsSinceEpoch);
    }
    await prefs.setInt(_kStreak, streakDays);
    await prefs.setStringList(_kAchievements, unlocked.toList());
  }

  Future<void> addWater(int ml) async {
    _logs.add(HydrationLog(timestamp: DateTime.now(), milliliters: ml));
    _checkAchievements(ml);
    _updateStreak();
    await _save();
    notifyListeners();
    // Refresh the scheduled notification so its text names the NEW next cup.
    await refreshSchedule();
  }

  Future<void> undoLast() async {
    if (_logs.isEmpty) return;
    _logs.removeLast();
    await _save();
    notifyListeners();
    await refreshSchedule();
  }

  Future<void> setGoal(int ml) async {
    dailyGoalMl = ml.clamp(500, 6000);
    await _save();
    notifyListeners();
  }

  Future<void> setInterval(int minutes) async {
    // Exact user value (15–240 min) — presets and custom slider both land here.
    reminderIntervalMin = minutes.clamp(15, 240);
    nextReminderAt = nextReminderAfter(DateTime.now());
    await NotificationService.scheduleNext(
        fireAt: nextReminderAt!, phrase: nextCupPhrase);
    await _save();
    notifyListeners();
  }

  /// Schedule (or re-schedule) the next reminder. Call on app start,
  /// after logging water, after tapping a notification, after snooze.
  Future<void> ensureScheduled() async {
    final now = DateTime.now();
    if (nextReminderAt == null || nextReminderAt!.isBefore(now)) {
      nextReminderAt = nextReminderAfter(now);
    }
    await NotificationService.scheduleNext(
        fireAt: nextReminderAt!, phrase: nextCupPhrase);
    await _save();
    notifyListeners();
  }

  Future<void> refreshSchedule() => ensureScheduled();

  Future<void> snooze(Duration by) async {
    nextReminderAt = DateTime.now().add(by);
    await NotificationService.scheduleNext(
        fireAt: nextReminderAt!, phrase: nextCupPhrase);
    await _save();
    notifyListeners();
  }

  /// Called by a lightweight timer while the app is open.
  /// Returns the phrase to speak when a reminder falls due, else null.
  Future<String?> tick() async {
    final now = DateTime.now();
    if (nextReminderAt == null || nextReminderAt!.isAfter(now)) return null;
    if (isQuietNow) {
      nextReminderAt = nextReminderAfter(now);
      await NotificationService.scheduleNext(
          fireAt: nextReminderAt!, phrase: nextCupPhrase);
      await _save();
      notifyListeners();
      return null;
    }
    final phrase = nextCupPhrase;
    nextReminderAt = nextReminderAfter(now);
    await NotificationService.scheduleNext(
        fireAt: nextReminderAt!, phrase: nextCupPhrase);
    await _save();
    notifyListeners();
    return phrase;
  }

  Future<void> setVoice(String id) async {
    voiceProfileId = id;
    await _save();
    notifyListeners();
  }

  Future<void> setSound(AlertSound s) async {
    alertSound = s;
    await _save();
    notifyListeners();
  }

  Future<void> setVibration(bool v) async {
    vibrationEnabled = v;
    await _save();
    notifyListeners();
  }

  Future<void> setQuiet(bool enabled, int startMin, int endMin) async {
    quietEnabled = enabled;
    quietStartMin = startMin.clamp(0, 1439);
    quietEndMin = endMin.clamp(0, 1439);
    nextReminderAt = nextReminderAfter(DateTime.now());
    await NotificationService.scheduleNext(
        fireAt: nextReminderAt!, phrase: nextCupPhrase);
    await _save();
    notifyListeners();
  }

  Future<void> setCustomVoicePath(String? path) async {
    customVoicePath = path;
    if (path != null) voiceProfileId = 'custom';
    await _save();
    notifyListeners();
  }

  Future<void> setCustomSoundPath(String? path) async {
    customSoundPath = path;
    if (path != null) alertSound = AlertSound.customFile;
    await _save();
    notifyListeners();
  }

  int _dayTotal(DateTime day) {
    return _logs
        .where((l) =>
            l.timestamp.year == day.year &&
            l.timestamp.month == day.month &&
            l.timestamp.day == day.day)
        .fold(0, (s, l) => s + l.milliliters);
  }

  void _updateStreak() {
    // Count consecutive goal-met days ending today (or yesterday if today incomplete).
    final today = DateTime.now();
    final todayMidnight =
        DateTime(today.year, today.month, today.day);
    int streak = 0;
    // If today is already complete, it counts; otherwise start from yesterday.
    int startOffset = _dayTotal(todayMidnight) >= dailyGoalMl ? 0 : 1;
    for (var offset = startOffset; offset < 365; offset++) {
      final d = todayMidnight.subtract(Duration(days: offset));
      if (_dayTotal(d) >= dailyGoalMl) {
        streak++;
      } else {
        break;
      }
    }
    streakDays = streak;
  }

  void _checkAchievements(int lastAddedMl) {
    void unlock(String id) {
      if (!unlocked.contains(id)) {
        unlocked.add(id);
        lastCelebratedAchievement = id;
      }
    }

    if (todayMl > 0) unlock('first_sip');
    if (progress >= 0.5) unlock('half_way');
    if (progress >= 1.0) unlock('goal_crusher');
    if (lastAddedMl >= 500) unlock('big_chug');
    if (streakDays >= 3) unlock('streak_3');
    if (streakDays >= 7) unlock('streak_7');
  }

  void clearCelebration() {
    lastCelebratedAchievement = null;
    notifyListeners();
  }
}
