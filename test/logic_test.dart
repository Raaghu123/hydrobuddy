import 'package:flutter_test/flutter_test.dart';
import 'package:hydration_reminder/models/hydration_log.dart';
import 'package:hydration_reminder/models/voice_profile.dart';

void main() {
  test('HydrationLog json round-trip', () {
    final log =
        HydrationLog(timestamp: DateTime(2026, 1, 1, 12), milliliters: 250);
    final decoded =
        HydrationLog.decodeList(HydrationLog.encodeList([log]));
    expect(decoded.single.milliliters, 250);
  });

  test('cup phrases count up', () {
    expect(cupReminderPhrase(1), "It's time for your first cup of water");
    expect(cupReminderPhrase(2), "It's time for your second cup of water");
    expect(cupReminderPhrase(3), "It's time for your third cup of water");
    expect(ordinalWord(11), '11th');
    expect(ordinalWord(21), '21st');
  });

  test('voice profiles exist', () {
    expect(VoiceProfile.all.length, 5);
    expect(VoiceProfile.byId('hero').label.contains('Hero'), true);
    expect(VoiceProfile.byId('custom').id, 'custom');
    expect(AlertSound.values.contains(AlertSound.customFile), true);
  });
}
