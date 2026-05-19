/// Driver-free capture of system **output** audio (loopback) — the audio that
/// plays through the speakers, e.g. the other participants in a Slack Huddle,
/// Google Meet, Tuple, or Zoom call.
///
/// All platforms deliver the same wire format: **16 kHz, mono, signed 16-bit
/// little-endian PCM** frames, so the bytes can be fed straight into a 16 kHz
/// speech recognizer (Whisper) without further resampling on the Dart side.
///
/// Platform backends:
/// - **macOS 14.4+** — Core Audio process taps (native, via platform channels).
///   Prompts an *audio capture* permission (not Screen Recording) and never
///   lights the screen-recording indicator.
/// - **Windows 10 1703+** — WASAPI loopback (native, via platform channels).
///   No permission prompt.
/// - **Linux** — a PipeWire/PulseAudio monitor source, streamed in pure Dart by
///   spawning `parecord` (falling back to `pw-record`). No native code, no
///   permission prompt.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The kind of audio source exposed by [SystemAudioCapture.listSources].
enum AudioCaptureSourceKind {
  /// The full system output mixdown (everything the speakers play).
  system,

  /// A single application's audio (macOS per-process tap).
  process,

  /// A PipeWire/PulseAudio monitor of an output sink (Linux).
  monitor,

  /// Unrecognized kind reported by a newer native backend.
  unknown,
}

/// A tappable system-audio source.
@immutable
class AudioCaptureSource {
  /// Creates an [AudioCaptureSource].
  const AudioCaptureSource({
    required this.id,
    required this.name,
    required this.kind,
  });

  /// Decodes a source from the native channel map.
  factory AudioCaptureSource.fromMap(Map<dynamic, dynamic> map) {
    return AudioCaptureSource(
      id: '${map['id']}',
      name: '${map['name']}',
      kind: switch ('${map['kind']}') {
        'system' => AudioCaptureSourceKind.system,
        'process' => AudioCaptureSourceKind.process,
        'monitor' => AudioCaptureSourceKind.monitor,
        _ => AudioCaptureSourceKind.unknown,
      },
    );
  }

  /// Stable identifier passed back to [SystemAudioCapture.capture]. The
  /// sentinel `'system'` always means "the full system mixdown".
  final String id;

  /// Human-readable label (app name, endpoint name, or monitor name).
  final String name;

  /// What this source represents.
  final AudioCaptureSourceKind kind;
}

/// The output sample rate of every backend, in Hz.
const int kCaptureSampleRate = 16000;

/// Captures system output audio as 16 kHz mono PCM16.
///
/// One instance owns at most one in-flight capture. Call [capture] to start
/// (it returns the PCM frame stream) and [stop] to tear the capture down.
class SystemAudioCapture {
  /// Creates a [SystemAudioCapture].
  SystemAudioCapture();

  static const MethodChannel _method =
      MethodChannel('dev.controlcenter/system_audio_capture');
  static const EventChannel _events =
      EventChannel('dev.controlcenter/system_audio_capture/frames');

  // Linux-only state: the spawned monitor-capture process.
  Process? _linuxProcess;
  StreamController<Uint8List>? _linuxController;

  /// Whether the running OS supports driver-free capture.
  ///
  /// macOS < 14.4 returns false (the Core Audio taps API is unavailable). On
  /// Linux, support depends on a working PipeWire/PulseAudio stack and is
  /// reported optimistically (the actual failure surfaces when [capture]
  /// cannot spawn `parecord`/`pw-record`).
  Future<bool> isSupported() async {
    if (Platform.isLinux) {
      return _linuxToolExists();
    }
    if (Platform.isMacOS || Platform.isWindows) {
      final ok = await _method.invokeMethod<bool>('isSupported');
      return ok ?? false;
    }
    return false;
  }

  /// Requests the OS audio-capture permission (macOS). No-op elsewhere.
  Future<bool> requestPermission() async {
    if (Platform.isMacOS || Platform.isWindows) {
      final ok = await _method.invokeMethod<bool>('requestPermission');
      return ok ?? false;
    }
    return true;
  }

  /// Lists the sources that can be tapped.
  Future<List<AudioCaptureSource>> listSources() async {
    if (Platform.isLinux) {
      return _linuxListSources();
    }
    if (Platform.isMacOS || Platform.isWindows) {
      final raw = await _method.invokeMethod<List<dynamic>>('listSources');
      return (raw ?? const [])
          .whereType<Map<dynamic, dynamic>>()
          .map(AudioCaptureSource.fromMap)
          .toList(growable: false);
    }
    return const [];
  }

  /// Starts capturing [sourceId] (null/`'system'` = full system mixdown) and
  /// returns a broadcast stream of 16 kHz mono PCM16 frames.
  ///
  /// The stream closes when [stop] is called or the backend ends.
  Stream<Uint8List> capture({String? sourceId}) {
    if (Platform.isLinux) {
      return _linuxCapture(sourceId);
    }
    if (Platform.isMacOS || Platform.isWindows) {
      // Begin the native capture, then surface the EventChannel frames. The
      // start invocation is fire-and-forget here; failures arrive as an error
      // on the returned stream via the EventChannel error path.
      final controller = StreamController<Uint8List>(sync: true);
      StreamSubscription<dynamic>? sub;
      controller.onListen = () {
        _method
            .invokeMethod<void>('start', {'sourceId': sourceId})
            .catchError(controller.addError);
        sub = _events.receiveBroadcastStream().listen(
          (event) {
            if (event is Uint8List) {
              controller.add(event);
            } else if (event is List<int>) {
              controller.add(Uint8List.fromList(event));
            }
          },
          onError: controller.addError,
          onDone: controller.close,
        );
      };
      controller.onCancel = () async {
        await sub?.cancel();
        await stop();
      };
      return controller.stream;
    }
    return const Stream.empty();
  }

  /// Stops the in-flight capture and releases native/OS resources.
  Future<void> stop() async {
    if (Platform.isLinux) {
      _linuxProcess?.kill();
      _linuxProcess = null;
      await _linuxController?.close();
      _linuxController = null;
      return;
    }
    if (Platform.isMacOS || Platform.isWindows) {
      await _method.invokeMethod<void>('stop');
    }
  }

  // ── Linux backend (pure Dart) ──────────────────────────────────────────────

  static Future<bool> _linuxToolExists() async {
    for (final tool in const ['parecord', 'pw-record']) {
      try {
        final r = await Process.run('which', [tool]);
        if (r.exitCode == 0) {
          return true;
        }
      } catch (_) {
        // Ignore and try the next tool.
      }
    }
    return false;
  }

  Future<List<AudioCaptureSource>> _linuxListSources() async {
    final sources = <AudioCaptureSource>[
      const AudioCaptureSource(
        id: 'system',
        name: 'System audio',
        kind: AudioCaptureSourceKind.system,
      ),
    ];
    try {
      final r = await Process.run('pactl', ['list', 'sources', 'short']);
      if (r.exitCode == 0) {
        for (final line in (r.stdout as String).split('\n')) {
          final cols = line.split(RegExp(r'\s+'));
          if (cols.length >= 2 && cols[1].endsWith('.monitor')) {
            sources.add(
              AudioCaptureSource(
                id: cols[1],
                name: cols[1],
                kind: AudioCaptureSourceKind.monitor,
              ),
            );
          }
        }
      }
    } catch (_) {
      // pactl unavailable — only the system mixdown sentinel is offered.
    }
    return sources;
  }

  Stream<Uint8List> _linuxCapture(String? sourceId) {
    final controller = StreamController<Uint8List>();
    _linuxController = controller;
    controller.onCancel = stop;

    Future<void> spawn() async {
      // Resolve the monitor target: an explicit `.monitor` id, or the default
      // sink's monitor for the `system`/null sentinel.
      final String? target = (sourceId != null && sourceId != 'system')
          ? sourceId
          : await _defaultSinkMonitor();

      // Prefer parecord with --raw (headerless PCM to stdout); fall back to
      // pw-record. Both are asked for 16 kHz mono s16le directly.
      final attempts = <List<String>>[
        [
          'parecord',
          '--raw',
          '--rate=16000',
          '--channels=1',
          '--format=s16le',
          if (target != null) '--device=$target',
        ],
        [
          'pw-record',
          '--rate=16000',
          '--channels=1',
          '--format=s16',
          if (target != null) '--target=$target',
          '-',
        ],
      ];

      for (final cmd in attempts) {
        try {
          final proc = await Process.start(cmd.first, cmd.sublist(1));
          _linuxProcess = proc;
          proc.stdout.listen(
            (chunk) => controller.add(Uint8List.fromList(chunk)),
            onError: controller.addError,
            onDone: () {
              if (!controller.isClosed) {
                controller.close();
              }
            },
          );
          // Drain stderr so the pipe never blocks the child.
          unawaited(proc.stderr.drain<void>());
          return;
        } catch (_) {
          // Try the next tool.
        }
      }
      controller.addError(
        StateError(
          'No system-audio capture tool found (need parecord or pw-record).',
        ),
      );
      await controller.close();
    }

    controller.onListen = spawn;
    return controller.stream;
  }

  static Future<String?> _defaultSinkMonitor() async {
    try {
      final r = await Process.run('pactl', ['get-default-sink']);
      if (r.exitCode == 0) {
        final sink = (r.stdout as String).trim();
        if (sink.isNotEmpty) {
          return '$sink.monitor';
        }
      }
    } catch (_) {
      // Fall through to null (parecord/pw-record default device).
    }
    return null;
  }
}
