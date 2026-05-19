import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/features/dictation/domain/dictation_control_port.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/infrastructure/audio/audio_input_settings.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

/// The lifecycle phase of a composer dictation session (PRD 25 §2).
enum DictationPhase {
  /// No session — the mic is idle.
  idle,

  /// A session is live: the mic streams to the host and windows arrive back.
  listening,

  /// The last start attempt failed (see [DictationState.errorKind]).
  error,
}

/// Why a dictation session could not start — surfaced by the UI, which owns the
/// `BuildContext` needed to localize it (the controller has none).
enum DictationErrorKind {
  /// No failure.
  none,

  /// The microphone permission was denied.
  micDenied,

  /// The host could not open the session (e.g. no ASR model installed, or no
  /// active workspace to bind it to).
  startFailed,
}

/// Immutable state of the composer dictation session.
///
/// [transcript] is the running text assembled from the host's finalized windows
/// (each window appended, space-separated) — the SAME accumulated string the
/// composer applies to its pending span on every update.
class DictationState {
  /// Creates a [DictationState].
  const DictationState({
    this.phase = DictationPhase.idle,
    this.transcript = '',
    this.errorKind = DictationErrorKind.none,
  });

  /// The idle state (no session).
  static const DictationState idle = DictationState();

  /// The current lifecycle phase.
  final DictationPhase phase;

  /// The accumulated finalized transcript so far.
  final String transcript;

  /// Why the session failed, when [phase] is [DictationPhase.error].
  final DictationErrorKind errorKind;

  /// Whether a session is live.
  bool get isListening => phase == DictationPhase.listening;

  /// Whether the last start attempt errored.
  bool get hasError => phase == DictationPhase.error;

  /// Returns a copy with the given fields replaced.
  DictationState copyWith({
    DictationPhase? phase,
    String? transcript,
    DictationErrorKind? errorKind,
  }) => DictationState(
    phase: phase ?? this.phase,
    transcript: transcript ?? this.transcript,
    errorKind: errorKind ?? this.errorKind,
  );

  @override
  bool operator ==(Object other) =>
      other is DictationState &&
      other.phase == phase &&
      other.transcript == transcript &&
      other.errorKind == errorKind;

  @override
  int get hashCode => Object.hash(phase, transcript, errorKind);
}

/// Drives a host-run dictation session for the composer over RPC (PRD 25 §2).
///
/// The client owns NO ASR model — like the meeting recorder, it captures the
/// microphone (16 kHz mono PCM16, one channel, no system audio, no AEC) and
/// streams frames to the host through [DictationControlPort]
/// (`dictation.start` → `ingestAudio` → `stop`). The host runs the rolling
/// window transcriber and pushes each finalized window back over
/// [DictationControlPort.watchPartials]; this controller appends them into
/// [DictationState.transcript]. `package:record` streams PCM on both desktop
/// (native) and web (AudioWorklet), so a single controller serves both targets.
class DictationController extends Notifier<DictationState> {
  /// Raw mic capture: OS audio processing OFF so the host transcriber sees the
  /// true signal (matching the meeting recorder — VPIO/AGC degrade Whisper).
  static const RecordConfig _micConfig = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
    autoGain: false,
    echoCancel: false,
    noiseSuppress: false,
  );

  AudioRecorder? _mic;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<DictationPartial>? _partialsSub;

  // Serialized per-session ingest chain: each frame awaits the previous so PCM
  // reaches the host in capture order (natural backpressure, no racing calls).
  int _seq = 0;
  Future<void> _chain = Future<void>.value();

  // Captured at start so teardown/stop never touch `ref` during disposal.
  DictationControlPort? _control;
  String? _dictationId;

  /// Completes when the host's terminal partial (`isFinal`) arrives, so
  /// [stopAndDrain] can wait for the trailing window before returning.
  Completer<void>? _drained;

  @override
  DictationState build() {
    ref.onDispose(() => unawaited(_teardown()));
    return DictationState.idle;
  }

  /// Starts a session. Returns `true` when a NEW session began; `false` when
  /// one is already live or start failed (state carries the error).
  Future<bool> start() async {
    if (state.isListening) {
      return false;
    }
    // The workspace is auto-injected by the RPC transport (the composer only
    // renders inside a workspace-scoped route), so no workspace read here.
    final control = ref.read(dictationControlProvider);
    final wantedDeviceId = ref.read(audioInputDeviceProvider);
    try {
      final mic = AudioRecorder();
      if (!await mic.hasPermission()) {
        await mic.dispose();
        state = const DictationState(
          phase: DictationPhase.error,
          errorKind: DictationErrorKind.micDenied,
        );
        return false;
      }

      final id = await control.start();
      _control = control;
      _dictationId = id;
      _mic = mic;
      _seq = 0;
      _chain = Future<void>.value();
      _drained = Completer<void>();
      state = const DictationState(phase: DictationPhase.listening);

      // Watch finalized windows first, so none is missed while the mic opens.
      _partialsSub = control
          .watchPartials(id)
          .listen(
            _onPartial,
            onError: (Object e, StackTrace s) =>
                AppLog.w('Dictation', 'partials error: $e'),
            onDone: _completeDrain,
          );

      final config = await _resolveConfig(mic, wantedDeviceId);
      final stream = await mic.startStream(config);
      _micSub = stream.listen(
        (pcm) => _ingest(id, pcm),
        onError: (Object e, StackTrace s) =>
            AppLog.w('Dictation', 'mic stream error: $e'),
      );
      return true;
    } catch (e, s) {
      AppLog.e('Dictation', 'start failed: $e', e, s);
      await _teardown();
      state = const DictationState(
        phase: DictationPhase.error,
        errorKind: DictationErrorKind.startFailed,
      );
      return false;
    }
  }

  /// Stops capture, drains pending ingests, asks the host to flush its trailing
  /// window, waits (bounded) for the terminal partial, and returns the final
  /// accumulated transcript. Idempotent — safe to call with no live session.
  Future<String> stopAndDrain() async {
    final id = _dictationId;
    if (id == null) {
      final text = state.transcript;
      if (!state.isListening) {
        return text;
      }
      state = DictationState.idle;
      return text;
    }
    await _micSub?.cancel();
    _micSub = null;
    try {
      await _mic?.stop();
    } catch (e) {
      AppLog.w('Dictation', 'mic stop failed: $e');
    }
    await _mic?.dispose();
    _mic = null;
    // Let any in-flight ingests land before the host drains the transcript.
    await _chain.catchError((Object _) {});
    try {
      await _control?.stop(dictationId: id);
    } catch (e) {
      AppLog.w('Dictation', 'stop failed: $e');
    }
    final drained = _drained;
    if (drained != null && !drained.isCompleted) {
      await drained.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );
    }
    await _partialsSub?.cancel();
    _partialsSub = null;
    _dictationId = null;
    _drained = null;
    _control = null;
    final finalText = state.transcript;
    state = DictationState.idle;
    return finalText;
  }

  /// Aborts the session and discards its transcript (no submit path).
  Future<void> cancel() async {
    await _teardown();
    state = DictationState.idle;
  }

  void _onPartial(DictationPartial partial) {
    if (partial.isFinal) {
      _completeDrain();
      return;
    }
    final text = partial.text.trim();
    if (text.isEmpty || state.phase != DictationPhase.listening) {
      return;
    }
    final joined = state.transcript.isEmpty
        ? text
        : '${state.transcript} $text';
    state = state.copyWith(transcript: joined);
  }

  void _ingest(String id, Uint8List pcm) {
    final control = _control;
    if (control == null || _dictationId != id) {
      return;
    }
    final seq = _seq++;
    _chain = _chain
        .then((_) => control.ingestAudio(dictationId: id, seq: seq, pcm: pcm))
        .catchError((Object e) {
          AppLog.w('Dictation', 'ingest failed: $e');
        });
  }

  void _completeDrain() {
    final drained = _drained;
    if (drained != null && !drained.isCompleted) {
      drained.complete();
    }
  }

  /// Resolves the mic config, honouring the saved input device when still
  /// attached (falling back to the system default otherwise).
  Future<RecordConfig> _resolveConfig(
    AudioRecorder mic,
    String? wantedDeviceId,
  ) async {
    if (wantedDeviceId == null) {
      return _micConfig;
    }
    try {
      final devices = await mic.listInputDevices();
      final match = devices.firstWhere(
        (d) => d.id == wantedDeviceId,
        orElse: () => const InputDevice(id: '', label: ''),
      );
      if (match.id.isEmpty) {
        return _micConfig;
      }
      return RecordConfig(
        encoder: _micConfig.encoder,
        sampleRate: _micConfig.sampleRate,
        numChannels: _micConfig.numChannels,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
        device: match,
      );
    } catch (_) {
      return _micConfig;
    }
  }

  /// Cancels streams, releases the mic, and best-effort-stops the host session.
  /// Uses the captured [_control] (never `ref`) so it is safe during disposal.
  Future<void> _teardown() async {
    await _micSub?.cancel();
    _micSub = null;
    await _partialsSub?.cancel();
    _partialsSub = null;
    try {
      await _mic?.stop();
    } catch (e) {
      AppLog.w('Dictation', 'teardown: mic stop failed: $e');
    }
    await _mic?.dispose();
    _mic = null;
    final id = _dictationId;
    final control = _control;
    if (id != null && control != null) {
      try {
        await control.stop(dictationId: id);
      } catch (e) {
        AppLog.w('Dictation', 'teardown: stop failed: $e');
      }
    }
    _dictationId = null;
    _control = null;
    _completeDrain();
    _drained = null;
  }
}

/// Controls the composer's active dictation session. A single global session
/// (only one field can be dictated into at a time).
final dictationControllerProvider =
    NotifierProvider<DictationController, DictationState>(
      DictationController.new,
    );

/// Persisted push-to-talk mode for dictation: `true` = hold-to-talk (dictate
/// while the mic button / shortcut is held, stop on release), `false` = toggle
/// (press once to start, again to stop). Defaults to toggle — the most
/// reliable across platforms (macOS can drop a held key's key-up event).
class DictationHoldToTalkNotifier extends Notifier<bool> {
  late AppPreferences _prefs;

  @override
  bool build() {
    _prefs = ref.watch(appPreferencesProvider);
    return _prefs.getBool(dictationHoldToTalkKey) ?? false;
  }

  /// Persists whether push-to-talk holds ([hold] true) or toggles.
  Future<void> setHoldToTalk({required bool hold}) async {
    await _prefs.setBool(dictationHoldToTalkKey, value: hold);
    state = hold;
  }
}

/// Whether dictation push-to-talk is hold-to-talk (true) or toggle (false).
final dictationHoldToTalkProvider =
    NotifierProvider<DictationHoldToTalkNotifier, bool>(
      DictationHoldToTalkNotifier.new,
    );
