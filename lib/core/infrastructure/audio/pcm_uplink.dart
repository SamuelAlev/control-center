import 'dart:async';
import 'dart:typed_data';

/// Sends one coalesced PCM batch to the host. [seq] counts batches, from 0; a
/// retried batch is resent with the same [seq], which the host uses to drop a
/// copy it already appended.
typedef PcmBatchSender = Future<void> Function(int seq, Uint8List pcm);

/// Coalesces captured 16 kHz mono PCM16 chunks into a few RPC calls a second,
/// sent one at a time in capture order, and never gives up on captured audio
/// while the recording is live.
///
/// Native capture delivers audio in tiny chunks: the macOS system-audio tap
/// fires about every 10 ms, the `record` mic stream every ~21 ms. One RPC per
/// chunk is well over 100 `repo/call`s a second for a two-channel meeting,
/// which the host's per-session request budget refuses. Batching to
/// [minBatchBytes] (~250 ms) keeps a two-channel recording near 8 calls a
/// second.
///
/// Delivery:
///
/// * A send that fails with a retryable error (`isRetryable`: a dropped
///   connection, a timeout, a rate-limit refusal) is retried with backoff,
///   the same bytes under the same `seq`, until it lands. Audio captured
///   meanwhile accumulates, nothing is discarded, and once the host answers
///   again the backlog drains in batches of up to [maxBatchBytes], so it
///   catches up quickly.
/// * A send that fails with any other error (the host has no such session any
///   more, or refused the arguments) is reported through `onError` and that
///   batch is dropped: resending it can never succeed.
/// * [flush] at stop waits for everything to land. Given a timeout, it gives up
///   after it, reports what was still unsent through `onDrop`, and stops
///   retrying, so a stop with the host unreachable cannot hang forever.
///
/// The backlog is held in memory: 32 KB a second per channel, so even ten
/// minutes behind is under 20 MB. `onBacklog` reports it once per
/// [backlogReportBytes] so a stalled host is visible in the log.
class PcmUplink {
  /// Creates a [PcmUplink] that hands batches to `send`.
  PcmUplink({
    required this._send,
    this._isRetryable = _neverRetry,
    this.minBatchBytes = defaultMinBatchBytes,
    this.maxBatchBytes = defaultMaxBatchBytes,
    this.backlogReportBytes = defaultBacklogReportBytes,
    this.initialRetryDelay = const Duration(milliseconds: 250),
    this.maxRetryDelay = const Duration(seconds: 5),
    this._onError,
    this._onBacklog,
    this._onDrop,
  }) : assert(minBatchBytes > 0 && minBatchBytes.isEven),
       assert(maxBatchBytes >= minBatchBytes && maxBatchBytes.isEven),
       assert(backlogReportBytes > 0);

  /// 250 ms of 16 kHz mono PCM16.
  static const int defaultMinBatchBytes = 16000 * 2 ~/ 4;

  /// 2 s of 16 kHz mono PCM16: the most one call carries.
  static const int defaultMaxBatchBytes = 16000 * 2 * 2;

  /// 10 s of 16 kHz mono PCM16: the backlog step reported through `onBacklog`.
  static const int defaultBacklogReportBytes = 16000 * 2 * 10;

  /// Pending bytes at which a batch is sent.
  final int minBatchBytes;

  /// Largest batch one call carries.
  final int maxBatchBytes;

  /// Backlog growth between two `onBacklog` reports.
  final int backlogReportBytes;

  /// Wait before the first retry of a failed batch; doubles per attempt.
  final Duration initialRetryDelay;

  /// Longest wait between two retries of one batch.
  final Duration maxRetryDelay;

  final PcmBatchSender _send;
  final bool Function(Object error) _isRetryable;
  final void Function(Object error, {required bool willRetry})? _onError;
  final void Function(int pendingBytes)? _onBacklog;
  final void Function(int lostBytes)? _onDrop;

  final BytesBuilder _pending = BytesBuilder();
  int _seq = 0;
  bool _sending = false;
  int _flushers = 0;
  bool _abandoned = false;
  int _reportedBacklogSteps = 0;
  Uint8List? _inFlight;
  Completer<void>? _idle;
  Completer<void>? _retryWake;

  static bool _neverRetry(Object _) => false;

  /// Unsent bytes currently buffered, not counting a batch in flight.
  int get pendingBytes => _pending.length;

  /// Batches handed to the sender so far (a retry does not count again).
  int get batchesSent => _seq;

  /// Queues one captured [pcm] chunk. Ignored once [flush] has given up.
  void add(Uint8List pcm) {
    if (pcm.isEmpty || _abandoned) {
      return;
    }
    _pending.add(pcm);
    final steps = _pending.length ~/ backlogReportBytes;
    if (steps > _reportedBacklogSteps) {
      _reportedBacklogSteps = steps;
      _onBacklog?.call(_pending.length);
    }
    _pump();
  }

  /// Sends everything buffered, including a final short batch, and completes
  /// with `true` once nothing is pending or in flight.
  ///
  /// With a [timeout], completes with `false` if the audio has not all landed
  /// by then: the uplink stops retrying, reports the unsent bytes through
  /// `onDrop` and accepts no more audio.
  Future<bool> flush({Duration? timeout}) async {
    _flushers++;
    try {
      _pump();
      final idle = _waitIdle();
      if (timeout == null) {
        await idle;
        return true;
      }
      return await idle
          .then((_) => true)
          .timeout(
            timeout,
            onTimeout: () {
              _abandon();
              return false;
            },
          );
    } finally {
      _flushers--;
    }
  }

  Future<void> _waitIdle() async {
    while (_sending || (_pending.isNotEmpty && !_abandoned)) {
      await (_idle ??= Completer<void>()).future;
    }
  }

  void _abandon() {
    if (_abandoned) {
      return;
    }
    _abandoned = true;
    final lost = _pending.length + (_inFlight?.length ?? 0);
    _pending.clear();
    _wakeRetry();
    if (lost > 0) {
      _onDrop?.call(lost);
    }
  }

  bool get _hasBatch =>
      !_abandoned &&
      (_pending.length >= minBatchBytes ||
          (_flushers > 0 && _pending.isNotEmpty));

  void _pump() {
    if (_sending || !_hasBatch) {
      return;
    }
    _sending = true;
    unawaited(_drain());
  }

  Future<void> _drain() async {
    try {
      while (_hasBatch) {
        final batch = _takeBatch();
        _reportedBacklogSteps = _pending.length ~/ backlogReportBytes;
        final seq = _seq++;
        _inFlight = batch;
        await _deliver(seq, batch);
        _inFlight = null;
      }
    } finally {
      _sending = false;
      final idle = _idle;
      _idle = null;
      idle?.complete();
    }
  }

  /// Sends [batch] until it lands, the error is not retryable, or the uplink
  /// is abandoned.
  Future<void> _deliver(int seq, Uint8List batch) async {
    var delay = initialRetryDelay;
    while (true) {
      try {
        await _send(seq, batch);
        return;
      } on Object catch (e) {
        final willRetry = !_abandoned && _isRetryable(e);
        _onError?.call(e, willRetry: willRetry);
        if (!willRetry) {
          return;
        }
      }
      await _sleep(delay);
      if (_abandoned) {
        return;
      }
      final doubled = delay * 2;
      delay = doubled > maxRetryDelay ? maxRetryDelay : doubled;
    }
  }

  /// Waits [delay], or less if [_abandon] wakes it.
  Future<void> _sleep(Duration delay) {
    final wake = _retryWake = Completer<void>();
    final timer = Timer(delay, _wakeRetry);
    return wake.future.whenComplete(timer.cancel);
  }

  void _wakeRetry() {
    final wake = _retryWake;
    _retryWake = null;
    if (wake != null && !wake.isCompleted) {
      wake.complete();
    }
  }

  Uint8List _takeBatch() {
    final all = _pending.takeBytes();
    if (all.length <= maxBatchBytes) {
      return all;
    }
    _pending.add(Uint8List.sublistView(all, maxBatchBytes));
    return Uint8List.sublistView(all, 0, maxBatchBytes);
  }
}
