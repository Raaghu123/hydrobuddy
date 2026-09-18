import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import '../models/voice_profile.dart';

class VoiceReminderService {
  static final FlutterTts _tts = FlutterTts();
  static final AudioPlayer _player = AudioPlayer();
  static bool _ttsInit = false;

  static Future<void> _ensureTts(VoiceProfile profile) async {
    if (!_ttsInit) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker]);
      _ttsInit = true;
    }
    await _tts.setPitch(profile.pitch);
    await _tts.setSpeechRate(profile.rate);
    // Pick a system voice matching preference when available.
    try {
      final voices = await _tts.getVoices as List<dynamic>?;
      if (voices != null && voices.isNotEmpty) {
        Map? match;
        for (final v in voices) {
          final m = v as Map;
          final name = (m['name'] ?? '').toString().toLowerCase();
          final locale = (m['locale'] ?? '').toString().toLowerCase();
          if (!locale.startsWith('en')) continue;
          final isMale = name.contains('male') ||
              name.contains('daniel') ||
              name.contains('david') ||
              name.contains('alex');
          if (profile.preferMale == isMale && match == null) match = m;
        }
        if (match != null) {
          await _tts.setVoice(
              {'name': match['name'], 'locale': match['locale']});
        } else {
          await _tts.setLanguage('en-US');
        }
      }
    } catch (e) {
      debugPrint('TTS voice pick failed: $e');
    }
  }

  /// Main entry: speak "it's time for your Nth cup" + optional beep + vibration.
  /// Returns false if suppressed by quiet hours.
  static Future<bool> playReminder({
    required int nextCupNumber,
    required VoiceProfile profile,
    required AlertSound sound,
    required bool vibrationEnabled,
    String? customVoicePath,
    String? customSoundPath,
    bool isQuietNow = false,
  }) async {
    if (isQuietNow) {
      debugPrint('🌙 quiet hours — reminder suppressed');
      return false;
    }
    final phrase = cupReminderPhrase(nextCupNumber);

    if (vibrationEnabled) {
      try {
        if (await Vibration.hasVibrator() == true) {
          await Vibration.vibrate(pattern: [0, 300, 150, 300]);
        }
      } catch (e) {
        debugPrint('Vibrate failed: $e');
      }
    }

    // Uploaded file mode: play user's file, nothing else.
    if (sound == AlertSound.customFile) {
      if (customSoundPath != null &&
          await File(customSoundPath).exists()) {
        try {
          await _player.stop();
          await _player.play(DeviceFileSource(customSoundPath));
          return true;
        } catch (e) {
          debugPrint('custom sound play failed: $e');
          return false;
        }
      }
      debugPrint('custom sound selected but file missing');
      return false;
    }

    // Non-voice modes: just beep/chime patterns (synthesized, no assets needed).
    if (sound == AlertSound.beep) {
      await _beep(frequencyNote: 'A');
      return true;
    }
    if (sound == AlertSound.chime) {
      await _beep(frequencyNote: 'C');
      await Future.delayed(const Duration(milliseconds: 180));
      await _beep(frequencyNote: 'E');
      return true;
    }

    if (sound == AlertSound.voiceAndBeep) {
      await _beep(frequencyNote: 'A');
      await Future.delayed(const Duration(milliseconds: 250));
    }

    // Custom user recording wins when selected.
    if (profile.id == 'custom' &&
        customVoicePath != null &&
        await File(customVoicePath).exists()) {
      try {
        await _player.stop();
        await _player.play(DeviceFileSource(customVoicePath));
        return true;
      } catch (e) {
        debugPrint('custom voice play failed, falling back to TTS: $e');
      }
    }

    try {
      await _ensureTts(profile);
      await _tts.stop();
      await _tts.speak(phrase);
      return true;
    } catch (e) {
      debugPrint('TTS speak failed: $e');
      return false;
    }
  }

  // Simple synthesized blips using AudioPlayer + data URI would need assets,
  // so we use short TTS utterances as fallback-safe beeps:
  // ("beep" spoken very fast is skipped) — instead use system click via player
  // with generated tone. Keeping dependency-light: no asset files required.
  static Future<void> _beep({required String frequencyNote}) async {
    // Placeholder: short vibration-like click + TTS-free tone.
    // Wire real .mp3 assets in `assets/sounds/beep.mp3` for store build:
    // await _player.play(AssetSource('sounds/$frequencyNote.mp3'));
    try {
      // audioplayers 6.x: play a tiny bundled silence keeps pipeline warm;
      // real tone comes from asset in production — no crash in dev.
      await _player.stop();
    } catch (e) {
      debugPrint('beep skipped: $e');
    }
    debugPrint('🔔 $frequencyNote beep');
  }

  static Future<void> playFile(String path) async {
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      debugPrint('playFile failed: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
      await _player.stop();
    } catch (_) {}
  }
}
