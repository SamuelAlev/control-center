import 'package:cc_infra/src/speech/voice_model_manager.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Voice model installation / readiness state.
enum VoiceModelStatus {
  /// Disk state has not yet been probed.
  unknown,
  /// Model files are missing.
  notInstalled,
  /// Archive is being downloaded and extracted.
  downloading,
  /// Model is present and ready to use.
  installed,
  /// Download or extraction failed.
  error,
}

@immutable
/// Voice model state.
class VoiceModelState {
  /// Creates a [VoiceModelState].
  const VoiceModelState({
    required this.status,
    this.progress = 0,
    this.phase = '',
    this.paths,
    this.error,
  });

  /// Current readiness status.
  final VoiceModelStatus status;

  /// Download / extraction progress in [0.0, 1.0].
  final double progress;

  /// Human-readable phase name ("downloading", "extracting", "ready").
  final String phase;

  /// Resolved file paths when [status] is [VoiceModelStatus.installed].
  final VoiceModelPaths? paths;

  /// Last error message when [status] is [VoiceModelStatus.error].
  final String? error;

  /// Copy with.
  VoiceModelState copyWith({
    VoiceModelStatus? status,
    double? progress,
    String? phase,
    VoiceModelPaths? paths,
    String? error,
    bool clearError = false,
  }) =>
      VoiceModelState(
        status: status ?? this.status,
        progress: progress ?? this.progress,
        phase: phase ?? this.phase,
        paths: paths ?? this.paths,
        error: clearError ? null : (error ?? this.error),
      );

  /// True when the model is installed and [paths] are resolved.
  bool get isInstalled => status == VoiceModelStatus.installed && paths != null;
}

/// Persists + exposes the user's selected ASR model id. Defaults to Parakeet
/// TDT v3 (fast, multilingual, fully portable) via [VoiceModelInfo.byId].
/// Backed by AppPreferences (non-sensitive), mirroring the theme-mode
/// provider's pattern.
class SelectedVoiceModelNotifier extends Notifier<String> {
  late AppPreferences _prefs;

  @override
  String build() {
    _prefs = ref.watch(appPreferencesProvider);
    final saved = _prefs.getString(selectedVoiceModelKey);
    return VoiceModelInfo.byId(saved).id;
  }

  /// Selects [id] (must be a `VoiceModelInfo.all` id) and persists it. Switching
  /// rebuilds [voiceModelManagerProvider] + re-probes [voiceModelStateProvider].
  void select(String id) {
    final resolved = VoiceModelInfo.byId(id).id;
    _prefs.setString(selectedVoiceModelKey, resolved);
    state = resolved;
  }
}

/// The currently selected voice model id.
final selectedVoiceModelProvider =
    NotifierProvider<SelectedVoiceModelNotifier, String>(
  SelectedVoiceModelNotifier.new,
);

/// The selected model's metadata.
final selectedVoiceModelInfoProvider = Provider<VoiceModelInfo>((ref) {
  return VoiceModelInfo.byId(ref.watch(selectedVoiceModelProvider));
});

/// Shared manager for the selected model — owns its on-disk archive +
/// extraction. Rebuilds when the selection changes so install/resolve target
/// the right model.
final voiceModelManagerProvider = Provider<VoiceModelManager>((ref) {
  final model = ref.watch(selectedVoiceModelInfoProvider);
  return VoiceModelManager(model: model, paths: appCcPaths);
});

/// Lifecycle: starts in [VoiceModelStatus.unknown], probes disk on build,
/// resolves to [VoiceModelStatus.installed] or [VoiceModelStatus.notInstalled].
/// Calling [VoiceModelStateNotifier.installIfNeeded] kicks off a download
/// and streams progress.
class VoiceModelStateNotifier extends Notifier<VoiceModelState> {
  CancelToken? _cancelToken;

  @override
  VoiceModelState build() {
    // Re-probe whenever the selected model changes so the section reflects the
    // newly-selected model's install state (each model installs independently).
    ref.watch(selectedVoiceModelProvider);
    _probe();
    return const VoiceModelState(status: VoiceModelStatus.unknown);
  }

  Future<void> _probe() async {
    final manager = ref.read(voiceModelManagerProvider);
    final paths = await manager.resolve();
    if (paths != null) {
      state = VoiceModelState(
        status: VoiceModelStatus.installed,
        progress: 1,
        paths: paths,
      );
    } else {
      state = const VoiceModelState(status: VoiceModelStatus.notInstalled);
    }
  }

  /// Install if needed.
  Future<void> installIfNeeded() async {
    if (state.status == VoiceModelStatus.installed ||
        state.status == VoiceModelStatus.downloading) {
      return;
    }
    final manager = ref.read(voiceModelManagerProvider);
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    state = const VoiceModelState(
      status: VoiceModelStatus.downloading,
      progress: 0,
      phase: 'downloading',
    );
    try {
      final paths = await manager.install(
        cancelToken: cancelToken,
        onProgress: (pct, phase) {
          state = state.copyWith(
            status: VoiceModelStatus.downloading,
            progress: pct,
            phase: phase,
          );
        },
      );
      state = VoiceModelState(
        status: VoiceModelStatus.installed,
        progress: 1,
        phase: 'ready',
        paths: paths,
      );
    } catch (e) {
      state = VoiceModelState(
        status: VoiceModelStatus.error,
        error: e.toString(),
      );
    } finally {
      _cancelToken = null;
    }
  }

  /// Cancels an in-progress download.
  void cancel() {
    _cancelToken?.cancel('user cancelled');
    _cancelToken = null;
  }

  /// Uninstall.
  Future<void> uninstall() async {
    final manager = ref.read(voiceModelManagerProvider);
    await manager.uninstall();
    state = const VoiceModelState(status: VoiceModelStatus.notInstalled);
  }
}

/// Riverpod notifier that tracks the on-disk voice model lifecycle.
final voiceModelStateProvider =
    NotifierProvider<VoiceModelStateNotifier, VoiceModelState>(
  VoiceModelStateNotifier.new,
);
