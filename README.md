# 💧 HydroBuddy — Hydration Reminder (Flutter, Play-ready)

Playful gamified hydration app: smart reminders, intake tracking, stats/history, achievements, Wear OS + widget hooks.

## Run (needs Flutter SDK)
```bash
cd hydration_reminder
flutter pub get
flutter run
```

Flutter isn't installed on this machine (`flutter --version` → not found, no Java), so code is scaffolded complete but not compiled here. Install Flutter 3.22+ + Android Studio to build.

## Structure
- `lib/main.dart` — tabs + init notifications
- `lib/providers/hydration_provider.dart` — goal, logs, streak, achievements (SharedPreferences)
- `lib/services/notification_service.dart` — channel + quick actions (Log 250ml / Snooze)
- `lib/screens/` — Home (ring + quick-add + confetti), Stats (fl_chart 7-day + streak), Settings (goal slider, interval chips)
- `lib/theme/` — playful Material3 theme
- `android/app/src/main/AndroidManifest.xml` — POST_NOTIFICATIONS, exact alarms, boot

## Play Store publish
1. `flutter build appbundle --release` (package `com.hydrobuddy.app`)
2. Play Console → New app → upload `.aab`, fill Data Safety (on-device only, no collection), health disclosure, privacy policy URL
3. Graphics: icon 512, feature 1024x500, screenshots phone + 7" tablet
4. Internal test track → promote to Production

## Wear OS + Widget
- **Wear OS:** add `wear/` module (Tiles API), read progress via Wear Data Layer from phone's SharedPreferences snapshot. MVP tile shows `%` + "+250" button.
- **Home widget:** use `home_widget` package + `GlanceAppWidget` native XML showing ring %. Button broadcasts `DRANK_250` intent (already in manifest).
- Both reuse `todayMl / dailyGoalMl` — no server needed.

## Next upgrades
- WorkManager for exact 60/90/120m intervals (Doze-safe)
- Health Connect sync
- Custom cup sizes, bedtime pause
