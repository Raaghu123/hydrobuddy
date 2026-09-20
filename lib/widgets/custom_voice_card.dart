import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hydration_provider.dart';
import '../services/custom_voice_service.dart';
import '../services/voice_reminder_service.dart';

class CustomVoiceCard extends StatefulWidget {
  const CustomVoiceCard({super.key});
  @override
  State<CustomVoiceCard> createState() => _CustomVoiceCardState();
}

class _CustomVoiceCardState extends State<CustomVoiceCard> {
  bool _recording = false;
  String? _activePath;
  List<String> _files = [];
  List<String> _sounds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final files = await CustomVoiceService.listRecordings();
    final sounds = await CustomVoiceService.listSounds();
    if (mounted) {
      setState(() {
        _files = files;
        _sounds = sounds;
        _loading = false;
      });
    }
  }

  String _label(String path) {
    final name = path.split('/').last;
    return name
        .replaceAll('.m4a', '')
        .replaceAll('.mp3', '')
        .replaceAll('.wav', '')
        .replaceAll('reminder_', 'Take ')
        .replaceAll('upload_', '')
        .replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HydrationProvider>();
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🎤 My voice',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                if (h.voiceProfileId == 'custom')
                  const Chip(
                      label: Text('selected'),
                      backgroundColor: Color(0xFF4ADE80)),
              ],
            ),
            const Text(
              'Record yourself saying “it’s time for your first cup…” — played instead of TTS when “My Voice” is selected.',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _recording ? Colors.red : const Color(0xFF1B2CC1),
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(_recording ? Icons.stop : Icons.mic),
                  label: Text(_recording ? 'Stop' : 'Record'),
                  onPressed: () async {
                    if (_recording) {
                      final p =
                          await CustomVoiceService.stopRecording();
                      setState(() {_recording = false; _activePath = p;});
                      await _refresh();
                      if (p != null && context.mounted) {
                        await context
                            .read<HydrationProvider>()
                            .setCustomVoicePath(p);
                      }
                    } else {
                      final status =
                          await CustomVoiceService.micStatus();
                      if (status == MicStatus.granted) {
                        final p =
                            await CustomVoiceService.startRecording();
                        if (p == null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Could not start recording — try again')));
                          return;
                        }
                        setState(() {_recording = true; _activePath = p;});
                      } else if (status == MicStatus.permanentlyDenied) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Mic blocked — enable it in system settings to record')),
                          );
                          await context
                              .read<HydrationProvider>()
                              .openSystemSettings();
                          await context
                              .read<HydrationProvider>()
                              .refreshPermissions();
                        }
                      } else {
                        final p =
                            await CustomVoiceService.startRecording();
                        if (p == null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Mic permission needed to record')));
                          await context
                              .read<HydrationProvider>()
                              .refreshPermissions();
                          return;
                        }
                        setState(() {_recording = true; _activePath = p;});
                        await context
                            .read<HydrationProvider>()
                            .refreshPermissions();
                      }
                    }
                  },
                ),
                const SizedBox(width: 8),
                if (_activePath != null && !_recording)
                  OutlinedButton(
                    onPressed: () => VoiceReminderService.playReminder(
                      nextCupNumber: h.nextCupNumber,
                      profile: h.voiceProfile,
                      sound: h.alertSound,
                      vibrationEnabled: false,
                      customVoicePath: _activePath,
                    ),
                    child: const Text('Play last'),
                  ),
              ],
            ),
            if (_recording)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('🔴 Recording… speak now!',
                    style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 8),
            if (_loading)
              const LinearProgressIndicator()
            else ...[
              if (_files.isEmpty)
                const Text('No recordings yet.',
                    style: TextStyle(color: Colors.blueGrey))
              else
                for (final f in _files.take(5))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      h.customVoicePath == f
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: const Color(0xFF1B2CC1),
                    ),
                    title: Text(_label(f),
                        style: const TextStyle(fontSize: 13)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () =>
                              VoiceReminderService.playFile(f),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await CustomVoiceService.deleteRecording(f);
                            await _refresh();
                          },
                        ),
                      ],
                    ),
                    onTap: () => context
                        .read<HydrationProvider>()
                        .setCustomVoicePath(f),
                  ),
              const Divider(),
              Row(
                children: [
                  const Text('📁 Uploaded sounds',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (h.customSoundPath != null)
                    const Chip(
                        label: Text('1 selected', style: TextStyle(fontSize: 11)),
                        backgroundColor: Color(0xFFFFC42E)),
                ],
              ),
              const Text(
                'Upload MP3/WAV/M4a beeps, songs or voice lines. Pick “My uploaded sound” under Sound to use it.',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload audio'),
                    onPressed: () async {
                      final p =
                          await CustomVoiceService.pickAndSaveSound();
                      if (p != null && context.mounted) {
                        await context
                            .read<HydrationProvider>()
                            .setCustomSoundPath(p);
                        await _refresh();
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('No file picked')));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (_sounds.isEmpty)
                const Text('No uploads yet.',
                    style: TextStyle(color: Colors.blueGrey))
              else
                for (final s in _sounds.take(5))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      h.customSoundPath == s
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: const Color(0xFFFF6B6B),
                    ),
                    title: Text(_label(s),
                        style: const TextStyle(fontSize: 13)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () =>
                              VoiceReminderService.playFile(s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await CustomVoiceService.deleteSound(s);
                            await _refresh();
                          },
                        ),
                      ],
                    ),
                    onTap: () => context
                        .read<HydrationProvider>()
                        .setCustomSoundPath(s),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
