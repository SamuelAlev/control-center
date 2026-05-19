import 'dart:async';

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_infra/src/speech/voice_model_manager.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:cc_server_core/src/models/managed_model_control.dart';
import 'package:dio/dio.dart';

/// A server-side [SelectableModelControl] for the ASR / voice model: a thin
/// client can list the installable models (`models.voiceCatalog`), switch the
/// active one (`models.selectVoice`), and install/remove it
/// (`models.installVoice` / …) — the SERVER owns the on-disk models.
///
/// This is the headless `cc_server` counterpart to lib's selectable
/// `DesktopVoiceModelControl` (which drives the in-process Riverpod registry).
/// Embedding & diarization stay plain [ManagedModelControl]s — each is a single
/// fixed asset with nothing to select.
///
/// Internally it COMPOSES a [ManagedModelControl] bound to the currently-
/// selected model and rebuilds it on [select]. The lifecycle stream survives a
/// switch: [watch] forwards a long-lived broadcast (`_out`) that re-pipes from
/// each inner control, so a subscriber's `models.watchVoice` subscription keeps
/// animating progress and snaps to the new model's status the instant the user
/// picks a different one.
class SelectableVoiceModelControl implements SelectableModelControl {
  /// Creates a control rooted at [paths].
  ///
  /// [initialId] is the persisted selection to restore on boot (defaults to the
  /// recommended model when null/unknown). [persistSelection] is invoked with
  /// the new id on every [select] so the choice survives a restart (and the
  /// meeting-recording stack can resolve the selected model first). [onLog]
  /// receives install-failure diagnostics.
  SelectableVoiceModelControl({
    required CcPaths paths,
    Dio? dio,
    String? initialId,
    void Function(String modelId)? persistSelection,
    void Function(String message)? onLog,
  })  : _paths = paths,
        _dio = dio,
        _persist = persistSelection,
        _onLog = onLog,
        _selected = VoiceModelInfo.byId(initialId) {
    _inner = _buildInner();
    _subscribe();
  }

  final CcPaths _paths;
  final Dio? _dio;
  final void Function(String modelId)? _persist;
  final void Function(String message)? _onLog;

  VoiceModelInfo _selected;
  late ManagedModelControl _inner;
  StreamSubscription<ModelStatusSnapshot>? _innerSub;
  bool _disposed = false;

  /// Long-lived broadcast that survives model switches, so existing
  /// `models.watchVoice` subscribers keep their stream across a [select].
  final StreamController<ModelStatusSnapshot> _out =
      StreamController<ModelStatusSnapshot>.broadcast();

  ModelStatusSnapshot _last =
      const ModelStatusSnapshot(status: ModelLifecycleStatus.unknown);

  /// The id of the currently-active model.
  String get selectedId => _selected.id;

  ManagedModelControl _buildInner() {
    final manager =
        VoiceModelManager(model: _selected, paths: _paths, dio: _dio);
    return ManagedModelControl(
      probeInstalled: () async => (await manager.resolve()) != null,
      runInstall: manager.install,
      runUninstall: manager.uninstall,
      onLog: _onLog,
    );
  }

  /// Pipe the active inner control's lifecycle onto the long-lived [_out].
  void _subscribe() {
    _innerSub = _inner.watch().listen((snapshot) {
      _last = snapshot;
      if (!_out.isClosed) {
        _out.add(snapshot);
      }
    });
  }

  @override
  Future<ModelStatusSnapshot> status() => _inner.status();

  @override
  Stream<ModelStatusSnapshot> watch() async* {
    // Replay the latest snapshot so a fresh subscriber renders immediately,
    // then forward every subsequent transition (including across a [select]).
    yield _last;
    yield* _out.stream;
  }

  @override
  Future<void> install() => _inner.install();

  @override
  Future<void> cancel() => _inner.cancel();

  @override
  Future<void> uninstall() => _inner.uninstall();

  @override
  Future<ModelCatalog> catalog() async => ModelCatalog(
        selectedId: _selected.id,
        models: [
          for (final m in VoiceModelInfo.all)
            ModelChoice(id: m.id, displayName: m.displayName),
        ],
      );

  @override
  Future<ModelStatusSnapshot> select(String modelId) async {
    final next = VoiceModelInfo.byId(modelId);
    if (next.id == _selected.id) {
      return _inner.status();
    }
    // Tear down the current model's control (cancelling any in-flight download)
    // and stand up a fresh one for the newly-selected model. Subscribers keep
    // their `watch()` stream (the broadcast `_out` survives); the new inner
    // replays its probed snapshot, so the client's status row updates to the
    // new model's install state.
    await _inner.cancel();
    await _innerSub?.cancel();
    await _inner.dispose();
    _selected = next;
    _persist?.call(_selected.id);
    _inner = _buildInner();
    _subscribe();
    return _inner.status();
  }

  /// Cancels any in-flight download and closes the lifecycle stream. Call on
  /// server shutdown.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _innerSub?.cancel();
    await _inner.dispose();
    await _out.close();
  }
}
