import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kaapav_app/config/theme.dart';

class VoiceRecorder extends StatefulWidget {
  final Function(String path, Duration duration) onCompleted;
  final VoidCallback onCancel;

  const VoiceRecorder({super.key, required this.onCompleted, required this.onCancel});

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _duration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      widget.onCancel();
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: path,
    );

    setState(() => _isRecording = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _duration += const Duration(seconds: 1));
    });
  }

  Future<void> _stopAndSend() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    if (path != null && await File(path).exists()) {
      HapticFeedback.lightImpact();
      widget.onCompleted(path, _duration);
    } else {
      widget.onCancel();
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    if (path != null) {
      try { await File(path).delete(); } catch (_) {}
    }
    widget.onCancel();
  }

  String _formatDuration(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KaapavTheme.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel
            IconButton(
              icon: const Icon(Icons.delete_outline, color: KaapavTheme.error),
              onPressed: _cancelRecording,
            ),
            // Recording indicator
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: _isRecording ? KaapavTheme.error : KaapavTheme.gray,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            // Duration
            Text(_formatDuration(_duration),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: KaapavTheme.dark)),
            const Spacer(),
            // Waveform placeholder
            ...List.generate(15, (i) {
              final h = 8.0 + ((_duration.inSeconds + i) % 5) * 4.0;
              return Container(
                width: 3, height: h,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(color: KaapavTheme.gold.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(2)),
              );
            }),
            const Spacer(),
            // Send
            GestureDetector(
              onTap: _stopAndSend,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(gradient: KaapavTheme.goldGradient, shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}