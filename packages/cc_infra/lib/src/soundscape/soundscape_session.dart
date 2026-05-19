import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/soundscape/domain/synth/soundscape_composer.dart';
import 'package:cc_domain/features/soundscape/domain/value_objects/soundscape_tune.dart';
import 'package:cc_infra/src/soundscape/hls_segmenter.dart';
import 'package:cc_natives/cc_natives.dart' show Mp3Encoder;

/// One shared generative soundscape session, keyed by `(workspaceId, mood)`.
///
/// It runs a single [SoundscapeComposer] → [Mp3Encoder] render loop and fans the
/// resulting MP3 byte stream out to every attached listener (per-listener volume
/// is applied client-side, so a shared mix is correct). Weather / daypart changes
/// arrive via [updateContext] and glide in on the composer's parameter ramps —
/// the stream is never restarted. The render loop is paced to real time against
/// a [Stopwatch], keeping a small look-ahead buffer so clients never underrun,
/// and stops itself when the last listener detaches (the hub then reaps it).
class SoundscapeSession {
  /// Creates a session rendering [context] at [sampleRate] through [encoder].
  /// [onEmpty] fires when the last listener leaves so the hub can dispose it.
  SoundscapeSession({
    required this.key,
    required SoundscapeContext context,
    required this.sampleRate,
    required Mp3Encoder encoder,
    required void Function() onEmpty,
  }) : _encoder = encoder,
       _onEmpty = onEmpty,
       _composer = SoundscapeComposer(sampleRate: sampleRate, context: context),
       _block = Float32List(_blockFrames * 2),
       _pcm = Int16List(_blockFrames * 2);

  /// `'<workspaceId>|<mood>'`.
  final String key;

  /// Render sample rate in Hz.
  final int sampleRate;

  final Mp3Encoder _encoder;
  final void Function() _onEmpty;
  final SoundscapeComposer _composer;
  final HlsSegmenter _hls = HlsSegmenter();

  static const int _blockFrames = 1024;
  static const Duration _tick = Duration(milliseconds: 120);
  static const double _lookaheadSeconds = 1.5;
  static const int _maxBlocksPerPump = 400;

  final Float32List _block;
  final Int16List _pcm;
  final Set<StreamController<List<int>>> _sinks = {};

  Timer? _timer;
  final Stopwatch _clock = Stopwatch();
  int _producedFrames = 0;
  bool _disposed = false;

  /// The mood/weather/daypart the running mix is currently rendering.
  SoundscapeContext get context => _composer.context;

  /// Number of currently attached listeners.
  int get listenerCount => _sinks.length;

  /// Attaches a new listener, returning its MP3 byte stream. Cancelling the
  /// subscription (client disconnect) detaches it; when the last one leaves the
  /// render loop stops and `onEmpty` fires.
  Stream<List<int>> attach() {
    late final StreamController<List<int>> controller;
    controller = StreamController<List<int>>(
      onCancel: () {
        _sinks.remove(controller);
        if (_sinks.isEmpty) {
          _stop();
        }
      },
    );
    _sinks.add(controller);
    _ensureRunning();
    return controller.stream;
  }

  /// Glides the running mix toward [next] (no restart, no click).
  void updateContext(SoundscapeContext next) {
    if (_disposed) {
      return;
    }
    _composer.updateContext(next);
  }

  /// Glides the listener's tune-pad position into the running mix.
  void updateTune(SoundscapeTune tune) {
    if (_disposed) {
      return;
    }
    _composer.updateTune(tune);
  }

  /// The live HLS playlist for this session's current window.
  String playlist(String segmentQuery) => _hls.playlist(segmentQuery);

  /// The bytes of HLS segment [index], or null if aged out.
  List<int>? segment(int index) => _hls.segment(index);

  void _ensureRunning() {
    if (_timer != null || _disposed) {
      return;
    }
    _producedFrames = 0;
    _clock
      ..reset()
      ..start();
    _timer = Timer.periodic(_tick, (_) => _pump());
    _pump();
  }

  void _pump() {
    if (_disposed) {
      return;
    }
    final elapsedSeconds = _clock.elapsedMicroseconds / 1e6;
    final targetFrames = ((elapsedSeconds + _lookaheadSeconds) * sampleRate)
        .round();
    var guard = 0;
    while (_producedFrames < targetFrames && guard < _maxBlocksPerPump) {
      _composer.renderBlock(_block, _blockFrames);
      for (var i = 0; i < _blockFrames * 2; i++) {
        final s = _block[i];
        final clamped = s < -1.0 ? -1.0 : (s > 1.0 ? 1.0 : s);
        _pcm[i] = (clamped * 32767.0).round();
      }
      final bytes = _encoder.encode(_pcm);
      if (bytes.isNotEmpty) {
        _broadcast(bytes);
        _hls.add(bytes);
      }
      _producedFrames += _blockFrames;
      guard++;
    }
  }

  void _broadcast(Uint8List bytes) {
    for (final controller in _sinks.toList()) {
      if (!controller.isClosed) {
        try {
          controller.add(bytes);
        } catch (_) {
          // Sink errored (client gone mid-add) — its onCancel will detach it.
        }
      }
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _clock.stop();
    _onEmpty();
  }

  /// Tears the session down: stops the loop, closes any remaining sinks and
  /// releases the encoder.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _clock.stop();
    for (final controller in _sinks.toList()) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
    _sinks.clear();
    _encoder.dispose();
  }
}
