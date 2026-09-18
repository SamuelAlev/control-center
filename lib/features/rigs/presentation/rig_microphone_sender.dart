// Streams the selected microphone into a microphone-capable rig.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:control_center/core/infrastructure/audio/audio_input_settings.dart';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

/// Captures PCM16 from the selected app microphone and POSTs bounded chunks to
/// the rig input lane. Mounting owns the session; unmounting closes it.
class RigMicrophoneSender extends StatefulWidget {
  /// Creates a microphone sender for [url].
  const RigMicrophoneSender({
    super.key,
    required this.url,
    required this.endUrl,
    required this.inputDeviceId,
    required this.onStopped,
  });

  /// Signed URL for microphone chunks.
  final String url;

  /// Signed URL carrying `end=1` for deterministic guest cleanup.
  final String endUrl;

  /// Per-tab input device id, or null for the system default.
  final String? inputDeviceId;

  /// Called when permission, capture, or transport fails.
  final VoidCallback onStopped;
  @override
  State<RigMicrophoneSender> createState() => _RigMicrophoneSenderState();
}

class _RigMicrophoneSenderState extends State<RigMicrophoneSender> {
  static int _sessionSequence = 0;
  static const _config = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
    autoGain: true,
    echoCancel: true,
    noiseSuppress: true,
  );

  final http.Client _client = http.Client();
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _subscription;
  Uint8List? _next;
  Future<void>? _pump;
  bool _closing = false;
  late final String _sessionId =
      '${DateTime.now().microsecondsSinceEpoch}-${_sessionSequence++}';

  String _sessionUrl(String base, {bool start = false}) {
    final uri = Uri.parse(base);
    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            'session': _sessionId,
            if (start) 'start': '1',
          },
        )
        .toString();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    final recorder = AudioRecorder();
    _recorder = recorder;
    try {
      if (!await recorder.hasPermission()) {
        await _fail();
        return;
      }
      final config = await withSelectedInputDevice(
        recorder,
        widget.inputDeviceId,
        _config,
      );
      final started = await _client
          .post(
            Uri.parse(_sessionUrl(widget.url, start: true)),
            headers: const {'Content-Type': 'application/octet-stream'},
            body: Uint8List(0),
          )
          .timeout(const Duration(seconds: 5));
      if (started.statusCode != 204) {
        await _fail();
        return;
      }
      if (_closing) {
        return;
      }
      final stream = await recorder.startStream(config);
      if (_closing) {
        await recorder.stop();
        return;
      }
      _subscription = stream.listen(
        _enqueue,
        onError: (Object _, StackTrace _) => unawaited(_fail()),
        onDone: () {
          if (!_closing) {
            unawaited(_fail());
          }
        },
      );
    } on Object {
      await _fail();
    }
  }

  /// Keeps at most one unsent chunk. When the local HTTP hop stalls, old audio
  /// is dropped instead of growing latency and memory without bound.
  void _enqueue(Uint8List pcm) {
    if (_closing || pcm.isEmpty) {
      return;
    }
    if (_pump != null) {
      _next = pcm;
      return;
    }
    _pump = _sendLoop(pcm);
  }

  Future<void> _sendLoop(Uint8List first) async {
    var current = first;
    try {
      while (!_closing) {
        final response = await _client
            .post(
              Uri.parse(_sessionUrl(widget.url)),
              headers: const {'Content-Type': 'application/octet-stream'},
              body: current,
            )
            .timeout(const Duration(seconds: 5));
        if (response.statusCode != 204) {
          await _fail();
          return;
        }
        final next = _next;
        _next = null;
        if (next == null) {
          return;
        }
        current = next;
      }
    } on Object {
      await _fail();
    } finally {
      _pump = null;
      final next = _next;
      _next = null;
      if (!_closing && next != null) {
        _pump = _sendLoop(next);
      }
    }
  }

  Future<void> _fail() async {
    if (_closing) {
      return;
    }
    await _close(notify: true);
  }

  Future<void> _close({required bool notify}) async {
    if (_closing) {
      return;
    }
    _closing = true;
    _next = null;
    await _subscription?.cancel();
    _subscription = null;
    final recorder = _recorder;
    _recorder = null;
    try {
      await recorder?.stop();
    } on Object {
      // The recorder may already have ended after a device disconnect.
    }
    await recorder?.dispose();
    try {
      await _client
          .post(
            Uri.parse(_sessionUrl(widget.endUrl)),
            headers: const {'Content-Type': 'application/octet-stream'},
            body: Uint8List(0),
          )
          .timeout(const Duration(seconds: 2));
    } on Object {
      // Best effort. The guest watchdog also closes an orphaned input lane.
    }
    _client.close();
    if (notify && mounted) {
      widget.onStopped();
    }
  }

  @override
  void dispose() {
    unawaited(_close(notify: false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
