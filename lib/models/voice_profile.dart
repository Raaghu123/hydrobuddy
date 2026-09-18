class VoiceProfile {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final double pitch;
  final double rate;
  final bool preferMale;

  const VoiceProfile({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.pitch,
    required this.rate,
    required this.preferMale,
  });

  // NOTE: These are original TTS styles inspired by archetypes — NOT actual
  // celebrity voice clones. Shipping "Chris Hemsworth's real voice" would
  // need his + studio licensing. These give the same feel legally.
  static const List<VoiceProfile> all = [
    VoiceProfile(
      id: 'hero',
      label: 'Hero (deep, Aussie-style)',
      emoji: '⚡',
      description: 'Hemsworth-style motivational coach. Deep + upbeat.',
      pitch: 0.85,
      rate: 0.48,
      preferMale: true,
    ),
    VoiceProfile(
      id: 'coach',
      label: 'Coach (energetic female)',
      emoji: '📣',
      description: 'Bright, high-energy trainer vibe.',
      pitch: 1.15,
      rate: 0.52,
      preferMale: false,
    ),
    VoiceProfile(
      id: 'calm',
      label: 'Calm (soft mindful)',
      emoji: '🧘',
      description: 'Gentle mindfulness reminder.',
      pitch: 1.0,
      rate: 0.42,
      preferMale: false,
    ),
    VoiceProfile(
      id: 'robot',
      label: 'Robot (fun)',
      emoji: '🤖',
      description: 'Playful low-pitch bot.',
      pitch: 0.6,
      rate: 0.5,
      preferMale: true,
    ),
    VoiceProfile(
      id: 'custom',
      label: 'My Voice (my recording)',
      emoji: '🎤',
      description: 'Play your own recorded reminder instead of TTS.',
      pitch: 1.0,
      rate: 0.5,
      preferMale: true,
    ),
  ];

  static VoiceProfile byId(String id) =>
      all.firstWhere((v) => v.id == id, orElse: () => all.first);
}

enum AlertSound { voiceOnly, beep, chime, voiceAndBeep, customFile }

extension AlertSoundX on AlertSound {
  String get label {
    switch (this) {
      case AlertSound.voiceOnly:
        return 'Voice only';
      case AlertSound.beep:
        return 'Beep';
      case AlertSound.chime:
        return 'Chime';
      case AlertSound.voiceAndBeep:
        return 'Voice + sound';
      case AlertSound.customFile:
        return 'My uploaded sound';
    }
  }
}

String ordinalWord(int n) {
  const words = {
    1: 'first',
    2: 'second',
    3: 'third',
    4: 'fourth',
    5: 'fifth',
    6: 'sixth',
    7: 'seventh',
    8: 'eighth',
    9: 'ninth',
    10: 'tenth',
  };
  if (words.containsKey(n)) return words[n]!;
  final suffix = (n % 10 == 1 && n % 100 != 11)
      ? 'st'
      : (n % 10 == 2 && n % 100 != 12)
          ? 'nd'
          : (n % 10 == 3 && n % 100 != 13)
              ? 'rd'
              : 'th';
  return '$n$suffix';
}

String cupReminderPhrase(int nextCupNumber) {
  final ord = ordinalWord(nextCupNumber);
  return "It's time for your $ord cup of water";
}
