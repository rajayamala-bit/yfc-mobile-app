import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecordService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentFilePath;
  DateTime? _startTime;

  bool get isRecording => _isRecording;

  Future<bool> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
          path: path,
        );

        _isRecording = true;
        _currentFilePath = path;
        _startTime = DateTime.now();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      final endTime = DateTime.now();

      final durationSecs = _startTime != null
          ? endTime.difference(_startTime!).inSeconds
          : 0;

      final targetPath = path ?? _currentFilePath;
      if (targetPath != null) {
        final file = File(targetPath);
        if (await file.exists() && await file.length() > 0) {
          return {
            'path': targetPath,
            'duration': durationSecs > 0 ? durationSecs : 1,
            'size': await file.length(),
          };
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> cancelRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {}
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
