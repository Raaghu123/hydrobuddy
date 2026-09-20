# HydroBuddy — Project Map (agent handbook)

> Read this first before any code task. Update it when architecture changes.

## What it is
Flutter hydration reminder (Play Store, `com.hydrobuddy.app`). No backend.
State = SharedPreferences JSON. Voice = on-device TTS / recordings / uploads.

## File responsibilities
| File | Owns |
|---|---|
| `lib/main.dart` | Startup: `NotificationService.init()` → load provider → wire `onAction` taps → `ensureScheduled()` → tabs (Drink/Stats/Settings) |
| `lib/providers/hydration_provider.dart` | Single source of truth: logs, goal, `reminderIntervalMin` (exact 15–240), voice/sound/vibrate prefs, quiet hours, `nextReminderAt`, streak, achievements. Scheduling entry points: `ensureScheduled()`, `refreshSchedule()`, `snooze()`, `tick()` (in-app 20s timer). `addWater/undoLast/setQuiet/setInterval` all re-schedule |
| `lib/services/notification_service.dart` | System alarms ONLY: permission requests, `scheduleNext(fireAt, phrase)` via `zonedSchedule` + exact alarm, action buttons `drank_250` / `snooze_15`, `onAction` callback. Chain-of-one: exactly one alarm (id 1001) always pending. Times scheduled as UTC instants (one-shots need no device zone) |
| `lib/services/voice_reminder_service.dart` | Foreground sound: TTS (profile pitch/rate) OR `customVoicePath` recording OR `customSoundPath` upload (`AlertSound.customFile`), + vibration. `playReminder()` returns bool (false in quiet) |
| `lib/services/custom_voice_service.dart` | Mic recording (`record`) + file upload (`file_picker`) into app docs; list/delete |
| `lib/models/voice_profile.dart` | `VoiceProfile` presets (hero/coach/calm/robot/custom — originals, NOT celebrity clones), `AlertSound` enum, `ordinalWord()` / `cupReminderPhrase(n)` |
| `lib/models/hydration_log.dart` | Log entry + JSON list codec |
| `lib/models/achievement.dart` | 6 achievement defs |
| `lib/screens/home_screen.dart` | Hydrify home + 20s `Timer` calling `tick()` → speak + snackbar. Cup-size chips, history preview, achievements strip |
| `lib/screens/stats_screen.dart` | Streak card, 7-day `fl_chart` bars, achievements grid |
| `lib/screens/settings_screen.dart` | Goal slider, preset chips + custom 15–240 slider, voice radios, sound chips, preview/test, embeds CustomVoiceCard + QuietHoursCard |
| `lib/widgets/custom_voice_card.dart` | Record + upload UI, select/play/delete |
| `lib/widgets/quiet_hours_card.dart` | Bedtime/wake pickers, next-reminder line |
| `lib/widgets/progress_ring.dart` | Hydrify ring (drop + ml + %) |
| `lib/theme/app_theme.dart` | Hydrify palette: primary `0xFF1E9BF3`, ink `0xFF0A2540`, bg `0xFFEDF4F9`, tile `0xFFE3F1FD` |
| `patch_android.py` | CI-only: injects permissions into manifest; APPENDS desugaring blocks (Gradle merges duplicates — never regex the middle) |
| `.github/workflows/build-apk.yml` | CI: checkout → Java 17 → Flutter stable → `flutter create` (regenerates `android/`, never committed) → `patch_android.py` → `pub get` → `analyze` → `build apk --debug` → artifact `hydrobuddy-apk` |

## Reminder flow (two layers)
1. **Phone asleep/closed:** exact-alarm notification with live cup phrase + Log/Snooze buttons → tap fires `onAction` in `main.dart`.
2. **App open:** `HomeScreen` 20s timer → `tick()` → `VoiceReminderService.playReminder()` + snackbar.
3. Quiet hours suppress both and push `nextReminderAt` past wake.

## Permission wall (hard gate)
- Reminder/voice/sound features require `Permission.notification`; UI (Settings cards, Home voice banner) is disabled + CTA shown until granted. `tick()`/`ensureScheduled()` no-op scheduling while denied.
- Exact-minute timing needs `scheduleExactAlarm` (Android) — warning tile, not a block.
- Mic recording needs `Permission.microphone`; permanently-denied opens system settings.
- Provider owns `notifGranted/alarmGranted/micGranted` + `refreshPermissions()`; `_Tabs` refreshes on resume; `requestReminderPermissions()` lifts the wall and schedules.

## Gotchas (learned the hard way)
- `android/` is NEVER committed; CI regenerates via `flutter create`. Don't hand-write manifests (v1-embedding breakage).
- `flutter_local_notifications` v17 NEEDS desugaring → `patch_android.py` appends it. v16 doesn't compile on new SDK. Stay on v17+.
- `vibration` must be v3+ (v2 targets android-33 → AAR metadata failure).
- `record` must be v6+ for current Flutter stable.
- BANNED: `flutter_timezone` (breaks Gradle with JVM-target clash; UTC instants suffice).
- `periodicallyShow` can't do 30/45-min intervals — that path is dead, use `scheduleNext` chain.
- Extensions (e.g. `AlertSound.label`) need a DIRECT `voice_profile.dart` import in every file using them.
- Provider ↔ NotificationService: provider may import the service; never the reverse (main.dart wires callbacks).
- CI pins: `ubuntu-24.04`, `upload-artifact@v5`, Java 17.

## Build/test loop
- Push via GitHub Desktop → Actions → `Build APK` → green → Artifacts `hydrobuddy-apk` → `app-debug.apk`.
- No Flutter SDK on the dev machine: verify with brace-balance script + `flutter analyze` in CI.
