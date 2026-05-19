/// Platform-neutral control surface for an on-device ML model's lifecycle
/// (embedding / diarization / voice), read by the settings sections.
///
/// On the desktop these are backed by the in-process model controllers
/// (cc_natives FFI download/probe/install); on the web/thin client they are
/// backed by the `models.*` RPC ops, which drive the model the SERVER hosts.
/// The section watches [status] and calls the mutators, so a SINGLE section
/// widget renders identically on both platforms.
///
/// On-device ML models physically cannot run in a browser, so a web client
/// reports the SERVER's model status and offers install/uninstall only when the
/// connected server hosts these ops. When the server does not (a headless host
/// that hosts no models), the status provider degrades to `null` and the
/// section renders an honest "managed on the server host" placeholder.
library;

/// Lifecycle status of an on-device model, shared by the three model sections.
///
/// A platform-neutral superset of the per-model status enums
/// (`EmbeddingModelStatus`, `DiarizationModelStatus`, `VoiceModelStatus`): the
/// section maps it back to the same labels each model used before unification.
enum ModelLifecycleStatus {
  /// The model state has not been probed yet.
  unknown,

  /// The model is not present and no download is in flight.
  notInstalled,

  /// The model is downloading / extracting (see [ModelStatusSnapshot.progress]).
  downloading,

  /// The model is installed and ready for use.
  installed,

  /// The last install attempt failed; see [ModelStatusSnapshot.error].
  error;

  /// Parses a wire string (the enum `.name`) back to a status, defaulting to
  /// [unknown] for an unrecognized value.
  static ModelLifecycleStatus fromName(String? name) =>
      ModelLifecycleStatus.values.asNameMap()[name] ??
      ModelLifecycleStatus.unknown;
}

/// An immutable snapshot of an on-device model's lifecycle.
///
/// HOST-GLOBAL (not workspace-scoped): a model is a single device-local asset,
/// so this carries no `workspaceId`. The thin client receives it over the
/// `models.*Status` RPC op; the desktop builds it straight from the in-process
/// controller's state. The wire shape is the snake_case JSON in
/// [toJson]/[fromJson].
class ModelStatusSnapshot {
  /// Creates a [ModelStatusSnapshot].
  const ModelStatusSnapshot({
    required this.status,
    this.progress = 0,
    this.phase,
    this.error,
  });

  /// Reconstructs the snapshot from a `models.*Status` wire map.
  factory ModelStatusSnapshot.fromJson(Map<String, dynamic> json) =>
      ModelStatusSnapshot(
        status: ModelLifecycleStatus.fromName(json['status'] as String?),
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        phase: json['phase'] as String?,
        error: json['error'] as String?,
      );

  /// Current lifecycle status.
  final ModelLifecycleStatus status;

  /// Download / extraction progress in `[0, 1]`.
  final double progress;

  /// Sub-phase, e.g. `downloading`, `extracting`, `ready`.
  final String? phase;

  /// Last error message when [status] is [ModelLifecycleStatus.error].
  final String? error;

  /// True when the model is installed.
  bool get installed => status == ModelLifecycleStatus.installed;

  /// True when the model is currently downloading / extracting.
  bool get downloading => status == ModelLifecycleStatus.downloading;

  /// The wire map (snake_case) the `models.*Status` op returns.
  Map<String, dynamic> toJson() => {
    'status': status.name,
    'progress': progress,
    'phase': ?phase,
    'error': ?error,
  };

  @override
  bool operator ==(Object other) =>
      other is ModelStatusSnapshot &&
      other.status == status &&
      other.progress == progress &&
      other.phase == phase &&
      other.error == error;

  @override
  int get hashCode => Object.hash(status, progress, phase, error);

  @override
  String toString() =>
      'ModelStatusSnapshot(status: $status, progress: $progress, '
      'phase: $phase, error: $error)';
}

/// A platform-neutral control surface for one on-device model's lifecycle,
/// read by the settings sections.
///
/// On the desktop it adapts the in-process model controller; on the web/thin
/// client it is backed by the `models.*` RPC ops. The section watches [status]
/// and calls [install]/[cancel]/[uninstall], so it is identical on both.
abstract interface class ModelControl {
  /// The current lifecycle snapshot (status / progress / phase / error).
  Future<ModelStatusSnapshot> status();

  /// A live stream of lifecycle snapshots. The first emission is the current
  /// snapshot (so a subscriber renders immediately), followed by one emission
  /// per download/extract progress tick and on every status transition.
  ///
  /// This is what makes a server-handled download legible to a thin client:
  /// [install] returns as soon as the download has STARTED (it does not block
  /// for the whole transfer), and the client watches this stream to animate
  /// progress. Over RPC it is exposed as the `models.watch*` subscription; the
  /// desktop projects its in-process controller's state changes onto it.
  Stream<ModelStatusSnapshot> watch();

  /// Begins downloading + installing the model, returning as soon as the
  /// download has STARTED (it does NOT block for the whole transfer — watch
  /// [watch] for progress). A no-op if already installed or downloading.
  Future<void> install();

  /// Cancels an in-flight download.
  Future<void> cancel();

  /// Removes the installed model.
  Future<void> uninstall();
}

/// One installable model in a [ModelCatalog].
///
/// Voice/ASR only — the embedding & diarization models are each a single fixed
/// asset, so only the voice control exposes a catalog. The wire shape is the
/// snake_case JSON in [toJson]/[fromJson]; the picker renders [displayName] and
/// switches the active model by [id] via [SelectableModelControl.select].
class ModelChoice {
  /// Creates a [ModelChoice].
  const ModelChoice({required this.id, required this.displayName});

  /// Reconstructs a choice from a `models.voiceCatalog` entry.
  factory ModelChoice.fromJson(Map<String, dynamic> json) => ModelChoice(
    id: json['id'] as String,
    displayName: (json['display_name'] as String?) ?? json['id'] as String,
  );

  /// Stable model id (matches `VoiceModelInfo.id`).
  final String id;

  /// Human-readable name shown in the picker (e.g. "Parakeet TDT 0.6B v3").
  final String displayName;

  /// The wire map (snake_case).
  Map<String, dynamic> toJson() => {'id': id, 'display_name': displayName};

  @override
  bool operator ==(Object other) =>
      other is ModelChoice && other.id == id && other.displayName == displayName;

  @override
  int get hashCode => Object.hash(id, displayName);
}

/// The catalog of installable models for a [SelectableModelControl]: every
/// choice plus which one is currently active ([selectedId]).
///
/// HOST-GLOBAL (not workspace-scoped) — a model is a single device-local asset.
/// The thin client receives it over `models.voiceCatalog` to populate the ASR
/// model picker; the desktop builds it straight from the in-process registry.
class ModelCatalog {
  /// Creates a [ModelCatalog].
  const ModelCatalog({required this.selectedId, required this.models});

  /// Reconstructs the catalog from a `models.voiceCatalog` wire map.
  factory ModelCatalog.fromJson(Map<String, dynamic> json) => ModelCatalog(
    selectedId: (json['selected_id'] as String?) ?? '',
    models: [
      for (final m in (json['models'] as List? ?? const []))
        ModelChoice.fromJson((m as Map).cast<String, dynamic>()),
    ],
  );

  /// The id of the currently-active model.
  final String selectedId;

  /// Every installable model, in picker order.
  final List<ModelChoice> models;

  /// The wire map (snake_case) `models.voiceCatalog` returns.
  Map<String, dynamic> toJson() => {
    'selected_id': selectedId,
    'models': [for (final m in models) m.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is ModelCatalog &&
      other.selectedId == selectedId &&
      _listEquals(other.models, models);

  @override
  int get hashCode => Object.hash(selectedId, Object.hashAll(models));

  static bool _listEquals(List<ModelChoice> a, List<ModelChoice> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// A [ModelControl] whose backing model can be SWITCHED among a [catalog] of
/// choices, then installed/removed like any other model.
///
/// Voice/ASR only: the user picks the active speech-to-text model in Settings.
/// On the desktop the catalog/selection is the in-process registry; on the
/// web/thin client it is driven over the `models.voiceCatalog` /
/// `models.selectVoice` RPC ops (the SERVER owns the on-disk models). The
/// embedding & diarization controls are plain [ModelControl]s — each is a single
/// fixed asset with nothing to select.
abstract interface class SelectableModelControl implements ModelControl {
  /// The catalog of installable models + which one is currently active.
  Future<ModelCatalog> catalog();

  /// Switches the active model to [modelId] and returns the fresh status
  /// snapshot for the newly-selected model. Re-probes install state, so a
  /// subscriber to [watch] sees the new model's status (each model installs
  /// independently). A no-op (returns the current snapshot) if already selected.
  Future<ModelStatusSnapshot> select(String modelId);
}
