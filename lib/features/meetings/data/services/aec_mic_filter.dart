import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:cc_natives/cc_natives.dart';
import 'package:control_center/features/meetings/data/services/aec_delay_estimator.dart';
import 'package:control_center/features/meetings/domain/services/mic_echo_canceller.dart';

/// Wires the meeting recorder's two capture streams through signal-level
/// acoustic echo cancellation: the system loopback ("them") is fed to the AEC
/// far-end reference, and the microphone ("me") is cleaned of the remote's
/// speaker bleed before it reaches transcription. This kills the duplicate "me"
/// windows at the audio level — independent of how Whisper transcribes the
/// bleed, which is where the text-based `MeetingEchoFilter` could not help.
///
/// **Per-session auto-calibration.** The mic and the loopback are two
/// independent OS captures with different, drifting clocks and an unknown
/// delivery offset that depends entirely on the user's audio devices — so AEC3
/// alone can't lock onto the echo. [AecDelayEstimator] measures the real offset
/// live by cross-correlating the two energy envelopes on the shared clock, then
/// this filter (a) buffers the mic so the loopback reference reliably *leads*
/// the capture and (b) feeds AEC3 a real `set_stream_delay_ms`, refined as the
/// clocks drift. Nothing is hardcoded to one machine: it measures, per session,
/// on whatever hardware is present. (Active only when a `clockNow` is supplied.)
///
/// **Decoupled / eager.** Both raw streams are consumed eagerly (their
/// subscriptions are never paused) so AEC3 always sees both channels in real
/// time — even while a downstream transcribe pauses to decode a window. The
/// cleaned mic and the "them" passthrough are re-emitted through controllers, so
/// transcribe's backpressure only buffers those controllers, not the capture.
///
/// **Graceful passthrough.** When the `processor` is `null` (native AEC library
/// absent, or in-person mode with no loopback), [cleanMic] / [referenceTap]
/// return their inputs unchanged and the text `MeetingEchoFilter` remains the
/// echo defense — zero behavior change. The filter also **fails safe**: until
/// the delay is measured with confidence, the mic is passed straight through
/// AEC3 with no buffering, never worse than the no-AEC baseline.
class AecMicFilter implements MicEchoCanceller {
  /// Creates a filter. A `null` [processor] makes every method an identity
  /// passthrough (no AEC). [clockNow] (shared-clock elapsed ms, the same one
  /// both capture listeners stamp against) enables delay auto-calibration; when
  /// omitted, AEC runs with a zero stream delay and no buffering. [log] receives
  /// human-readable calibration / metrics lines for the recorder's diagnostics.
  AecMicFilter({
    AecEngine? processor,
    int Function()? clockNow,
    void Function(String message)? log,
  })  : _processor = processor,
        _clockNow = clockNow,
        _log = log,
        _estimator = (processor != null && clockNow != null)
            ? AecDelayEstimator()
            : null;

  // Desired far-end lead, in ms, after mic buffering — a comfortable positive
  // delay well inside AEC3's render-buffer range.
  static const int _targetLeadMs = 80;
  // Minimum cross-correlation confidence before we trust a measurement enough
  // to lock the mic buffer.
  static const double _minLockConfidence = 0.55;
  // Clamp for the value handed to set_stream_delay_ms (AEC3's usable range).
  static const int _maxStreamDelayMs = 500;
  static const int _calibrateIntervalMs = 500;
  static const int _logIntervalMs = 2000;

  final AecEngine? _processor;
  final int Function()? _clockNow;
  final void Function(String message)? _log;
  final AecDelayEstimator? _estimator;

  final _BlockAccumulator _near = _BlockAccumulator(AecProcessor.blockBytes);
  final _BlockAccumulator _far = _BlockAccumulator(AecProcessor.blockBytes);

  /// Mic blocks awaiting processing, held back by [_nearBufferBlocks] so the
  /// far-end reference (fed immediately on arrival) leads the capture.
  final Queue<Uint8List> _nearQueue = Queue<Uint8List>();
  int _nearBufferBlocks = 0;
  int _streamDelayMs = 0;
  bool _locked = false;

  int _lastCalibrateMs = -1 << 30;
  int _lastLogMs = -1 << 30;

  final List<StreamSubscription<Uint8List>> _subs = [];
  bool _disposed = false;

  /// Whether AEC is actually running (a native processor is present).
  bool get isActive => _processor != null;

  /// Wraps the raw mic stream, returning a stream of echo-cleaned mic PCM. The
  /// far-end must be supplied concurrently via [referenceTap]. Identity when no
  /// processor.
  @override
  Stream<Uint8List> cleanMic(Stream<Uint8List> micRaw) {
    final proc = _processor;
    if (proc == null) {
      return micRaw;
    }
    return _wrap(micRaw, (chunk, emit) {
      final out = BytesBuilder(copy: false);
      _near.add(chunk, (block) {
        _noteNear(block);
        // Copy: the accumulator's block view is reused on the next add, but a
        // buffered block may not be processed until later chunks arrive.
        _nearQueue.add(Uint8List.fromList(block));
        _maybeCalibrate();
        while (_nearQueue.length > _nearBufferBlocks) {
          out.add(proc.processCapture(_nearQueue.removeFirst(), _streamDelayMs));
        }
      });
      if (out.length > 0) {
        emit(out.takeBytes());
      }
    });
  }

  /// Taps the raw loopback stream into the AEC far-end reference and re-emits it
  /// UNCHANGED for the "them" transcription path. Identity when no processor.
  @override
  Stream<Uint8List> referenceTap(Stream<Uint8List> loopbackRaw) {
    final proc = _processor;
    if (proc == null) {
      return loopbackRaw;
    }
    return _wrap(loopbackRaw, (chunk, emit) {
      _far.add(chunk, (block) {
        _noteFar(block);
        proc.processReverse(block);
      });
      emit(chunk);
    });
  }

  void _noteNear(Uint8List block) {
    final clock = _clockNow;
    if (clock != null) {
      _estimator?.addNear(clock(), AecDelayEstimator.rms(block));
    }
  }

  void _noteFar(Uint8List block) {
    final clock = _clockNow;
    if (clock != null) {
      _estimator?.addFar(clock(), AecDelayEstimator.rms(block));
    }
  }

  /// Periodically re-measures the far→near offset and (once) locks the mic
  /// buffer, then keeps the fed stream delay tracking clock drift. Throttled by
  /// the shared clock. Driven from the mic path (the cancellation timeline).
  void _maybeCalibrate() {
    final estimator = _estimator;
    final clock = _clockNow;
    if (estimator == null || clock == null) {
      return;
    }
    final now = clock();
    if (now - _lastCalibrateMs < _calibrateIntervalMs) {
      return;
    }
    _lastCalibrateMs = now;

    final est = estimator.estimate();
    if (est != null) {
      if (!_locked && est.confidence >= _minLockConfidence) {
        // Buffer the mic enough that the far end leads by the target margin.
        final deficitMs = _targetLeadMs - est.lagMs;
        _nearBufferBlocks =
            deficitMs <= 0 ? 0 : (deficitMs / _blockMs).round();
        _locked = true;
        _streamDelayMs = _clampDelay(est.lagMs + _nearBufferBlocks * _blockMs);
        _log?.call(
          'AEC delay locked: far-lead ${est.lagMs}ms '
          '(conf ${est.confidence.toStringAsFixed(2)}) → '
          'mic buffer ${_nearBufferBlocks * _blockMs}ms, '
          'stream-delay ${_streamDelayMs}ms',
        );
      } else {
        // Keep AEC3's external delay hint tracking the live measurement, so it
        // follows clock drift even after the mic buffer is locked.
        _streamDelayMs = _clampDelay(est.lagMs + _nearBufferBlocks * _blockMs);
      }
    }

    if (now - _lastLogMs >= _logIntervalMs) {
      _lastLogMs = now;
      _logStatus(est);
    }
  }

  int _clampDelay(int ms) =>
      ms < 0 ? 0 : (ms > _maxStreamDelayMs ? _maxStreamDelayMs : ms);

  void _logStatus(AecDelayEstimate? est) {
    final m = _processor?.metrics() ?? AecMetrics.empty;
    final raw = est == null
        ? 'far-lead n/a (warming up)'
        : 'far-lead ${est.lagMs}ms (conf ${est.confidence.toStringAsFixed(2)})';
    String dec(double? v) => v == null ? 'n/a' : v.toStringAsFixed(1);
    _log?.call(
      'AEC cal: $raw | ${_locked ? 'LOCKED' : 'unlocked'} '
      'buffer ${_nearBufferBlocks * _blockMs}ms stream-delay ${_streamDelayMs}ms '
      '| ERLE ${dec(m.erle)}dB delay ${m.delayMs ?? 'n/a'}ms '
      'residual ${dec(m.residual)}',
    );
  }

  /// Disposes the AEC: cancels the eager source subscriptions, then frees the
  /// native processor. Idempotent. Callers MUST stop feeding (cancel the
  /// downstream transcribe subscriptions) before this so no block is in flight.
  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _nearQueue.clear();
    _processor?.dispose();
  }

  static const int _blockMs = 10; // 160 samples @ 16 kHz

  /// Eagerly subscribes to [source] (never paused) and re-emits through a
  /// controller; [onChunk] processes each input chunk and emits zero or more
  /// output chunks via the supplied callback.
  Stream<Uint8List> _wrap(
    Stream<Uint8List> source,
    void Function(Uint8List chunk, void Function(Uint8List) emit) onChunk,
  ) {
    final controller = StreamController<Uint8List>();
    StreamSubscription<Uint8List>? sub;
    controller.onListen = () {
      sub = source.listen(
        (chunk) {
          if (!controller.isClosed) {
            onChunk(chunk, controller.add);
          }
        },
        onError: controller.addError,
        onDone: controller.close,
        cancelOnError: false,
      );
      _subs.add(sub!);
    };
    controller.onCancel = () async {
      await sub?.cancel();
    };
    return controller.stream;
  }
}

/// Accumulates a byte stream into fixed-size blocks, invoking a callback for
/// each complete block and carrying the remainder to the next [add].
class _BlockAccumulator {
  _BlockAccumulator(this._blockBytes);

  final int _blockBytes;
  Uint8List _carry = Uint8List(0);

  /// Appends [chunk] and invokes [onBlock] for each complete [_blockBytes]-byte
  /// block. Blocks are views over a backing buffer and must be consumed
  /// synchronously within [onBlock] (the AEC processor copies them out).
  void add(Uint8List chunk, void Function(Uint8List block) onBlock) {
    final Uint8List data;
    if (_carry.isEmpty) {
      data = chunk;
    } else {
      data = Uint8List(_carry.length + chunk.length)
        ..setRange(0, _carry.length, _carry)
        ..setRange(_carry.length, _carry.length + chunk.length, chunk);
    }
    var off = 0;
    while (data.length - off >= _blockBytes) {
      onBlock(Uint8List.sublistView(data, off, off + _blockBytes));
      off += _blockBytes;
    }
    _carry =
        off == data.length ? Uint8List(0) : Uint8List.sublistView(data, off);
  }
}
