import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class CustomVoiceService {  static final AudioRecorder _recorder = AudioRecorder();

  static Future<String> _dir() async {
    final d = await getApplicationDocumentsDirectory();
    final dir = Directory('${d.path}/custom_voice');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<bool> ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Mic state without prompting (for locked/denied UX).
  static Future<MicStatus> micStatus() async {
    final s = await Permission.microphone.status;
    if (s.isGranted || s.isLimited) return MicStatus.granted;
    if (s.isPermanentlyDenied) return MicStatus.permanentlyDenied;
    return MicStatus.denied;
  }

  static Future<String?> startRecording() async {
    if (!await ensureMicPermission()) return null;
    try {
      if (await _recorder.hasPermission()) {
        final dir = await _dir();
        final path =
            '$dir/reminder_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
          path: path,
        );
        return path;
      }
    } catch (e) {
      debugPrint('record start failed: $e');
    }
    return null;
  }

  static Future<String?> stopRecording() async {
    try {
      return await _recorder.stop();
    } catch (e) {
      debugPrint('record stop failed: $e');
      return null;
    }
  }

  static Future<bool> isRecording() => _recorder.isRecording();

  static Future<List<String>> listRecordings() async {
    try {
      final dir = await _dir();
      return Directory(dir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.m4a'))
          .map((f) => f.path)
          .toList()
        ..sort((a, b) => b.compareTo(a));
    } catch (_) {
      return [];
    }
  }

  static Future<void> deleteRecording(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('delete failed: $e');
    }
  }

  // ---- Uploaded sound files (mp3/wav/m4a/ogg) ----
  static const _allowedExts = ['mp3', 'wav', 'm4a', 'aac', 'ogg'];

  static Future<String> _soundDir() async {
    final d = await getApplicationDocumentsDirectory();
    final dir = Directory('${d.path}/custom_sounds');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  /// Let user pick an audio file, copy into app storage, return new path.
  static Future<String?> pickAndSaveSound() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: false,
      );
      if (res == null || res.files.isEmpty) return null;
      final src = res.files.single.path;
      if (src == null) return null;
      final dir = await _soundDir();
      final ext = src.split('.').last.toLowerCase();
      final safeExt = _allowedExts.contains(ext) ? ext : 'm4a';
      final dest =
          '$dir/upload_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      await File(src).copy(dest);
      return dest;
    } catch (e) {
      debugPrint('pick sound failed: $e');
      return null;
    }
  }

  static Future<List<String>> listSounds() async {
    try {
      final dir = await _soundDir();
      return Directory(dir)
          .listSync()
          .whereType<File>()
          .where((f) => _allowedExts
              .any((e) => f.path.toLowerCase().endsWith('.$e')))
          .map((f) => f.path)
          .toList()
        ..sort((a, b) => b.compareTo(a));
    } catch (_) {
      return [];
    }
  }

  static Future<void> deleteSound(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('delete sound failed: $e');
    }
  }
}

enum MicStatus { granted, denied, permanentlyDenied }
