import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_model_control.dart';
import 'package:control_center/core/infrastructure/speech/diarization_model_control.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_control.dart';
import 'package:control_center/core/providers/server_connection_status_provider.dart';
import 'package:control_center/core/server/server_startup_status.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/popup_route_tracker.dart';
import 'package:control_center/shared/widgets/server_activity_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model lanes with existing server-owned lifecycle subscriptions.
enum ServerActivityModel {
  /// The selected speech model, including Parakeet.
  voice,

  /// Semantic search embeddings.
  embedding,

  /// Meeting speaker identification.
  diarization,
}

/// Pre-authentication activity without mounting an authenticated provider scope.
class ServerStartupIndicator extends StatelessWidget {
  /// Wraps boot/setup while leaving the rest of the viewport interactive.
  const ServerStartupIndicator({
    super.key,
    required this.child,
    this.showFailures = true,
  });

  /// Existing boot or setup content.
  final Widget child;

  /// Whether this surface owns failures instead of a dedicated error callout.
  final bool showFailures;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      Positioned.fill(
        child: ValueListenableBuilder<ServerStartupStatus?>(
          valueListenable: serverStartupStatus,
          builder: (context, status, _) => ServerActivityPanel(
            entries: [
              ?_startupEntry(context, status, showFailures: showFailures),
            ],
          ),
        ),
      ),
    ],
  );
}

/// Live background model activity, shared by onboarding and all app routes.
class ServerActivityOverlay extends ConsumerWidget {
  /// Creates the activity layer. Inline progress owns any [hiddenModels] lanes.
  const ServerActivityOverlay({
    super.key,
    this.hiddenModels = const {},
    this.canManageModels = false,
    this.docked = false,
  });

  /// Suppresses only models whose progress is already visible in the current UI.
  final Set<ServerActivityModel> hiddenModels;

  /// Server-owner capability, supplied by the authenticated composition.
  final bool canManageModels;

  /// Shrink-wraps a bounded activity area on compact onboarding layouts.
  final bool docked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final connection = ref.watch(serverConnectionStatusProvider).value;
    final connected =
        connection == null ||
        connection.phase == ServerConnectionPhase.connected;
    final voice = ref.watch(voiceModelStatusSnapshotProvider);
    final embedding = ref.watch(embeddingModelStatusSnapshotProvider);
    final diarization = ref.watch(diarizationModelStatusSnapshotProvider);
    final catalog = ref.watch(voiceModelCatalogProvider).value;
    final selected = catalog?.models
        .where((model) => model.id == catalog.selectedId)
        .firstOrNull;
    final entries = <ServerActivityEntry>[];

    void addModel(
      ServerActivityModel model,
      String title,
      AsyncValue<ModelStatusSnapshot?> state,
      Future<void> Function() retryStatus,
      ModelControl control,
    ) {
      if (!connected || hiddenModels.contains(model)) {
        return;
      }
      if (state.hasError) {
        entries.add(
          ServerActivityEntry(
            id: model.name,
            title: title,
            message: l10n.serverActivityStatusUnavailable,
            error: state.error.toString(),
            onRetry: retryStatus,
          ),
        );
        return;
      }
      final snapshot = state.value;
      if (snapshot == null) {
        return;
      }
      if (snapshot.downloading) {
        final progress = snapshot.progress.isFinite
            ? snapshot.progress.clamp(0.0, 1.0)
            : 0.0;
        entries.add(
          ServerActivityEntry(
            id: model.name,
            title: title,
            message: snapshot.phase == 'extracting' || snapshot.phase == 'ready'
                ? l10n.serverActivityPreparingModel
                : l10n.downloadingLabel,
            busy: true,
            progress: progress > 0 ? progress : null,
          ),
        );
      } else if (snapshot.status == ModelLifecycleStatus.error) {
        entries.add(
          ServerActivityEntry(
            id: model.name,
            title: title,
            message: l10n.serverActivityDownloadFailed,
            error: snapshot.error ?? l10n.serverActivityDownloadFailed,
            onRetry: canManageModels ? control.install : null,
          ),
        );
      }
    }

    addModel(
      ServerActivityModel.voice,
      selected?.displayName ?? l10n.speechModel,
      voice,
      () async {
        ref.invalidate(voiceModelStatusSnapshotProvider);
        await ref.read(voiceModelStatusSnapshotProvider.future);
      },
      ref.watch(voiceModelControlProvider),
    );
    addModel(
      ServerActivityModel.embedding,
      l10n.embeddingModel,
      embedding,
      () async {
        ref.invalidate(embeddingModelStatusSnapshotProvider);
        await ref.read(embeddingModelStatusSnapshotProvider.future);
      },
      ref.watch(embeddingModelControlProvider),
    );
    addModel(
      ServerActivityModel.diarization,
      l10n.diarizationModel,
      diarization,
      () async {
        ref.invalidate(diarizationModelStatusSnapshotProvider);
        await ref.read(diarizationModelStatusSnapshotProvider.future);
      },
      ref.watch(diarizationModelControlProvider),
    );
    return ValueListenableBuilder<int>(
      valueListenable: ref.watch(rootPopupRoutesProvider).open,
      builder: (context, open, _) => open > 0
          ? const SizedBox.shrink()
          : ValueListenableBuilder<ServerStartupStatus?>(
              valueListenable: serverStartupStatus,
              builder: (context, status, _) => ServerActivityPanel(
                docked: docked,
                entries: [
                  ?_startupEntry(context, status, showFailures: false),
                  ...entries,
                ],
              ),
            ),
    );
  }
}

ServerActivityEntry? _startupEntry(
  BuildContext context,
  ServerStartupStatus? status, {
  bool showFailures = true,
}) {
  if (status == null ||
      status.phase == ServerStartupPhase.ready ||
      (!showFailures && status.phase == ServerStartupPhase.failed)) {
    return null;
  }
  final l10n = AppLocalizations.of(context);
  final failed = status.phase == ServerStartupPhase.failed;
  final diagnostic = status.error?.toString();
  final portInUse =
      diagnostic != null &&
      (diagnostic.toLowerCase().contains('address already in use') ||
          diagnostic.contains('EADDRINUSE'));
  return ServerActivityEntry(
    id: 'startup',
    title: failed
        ? l10n.serverActivityStartFailed
        : status.phase == ServerStartupPhase.starting
        ? l10n.serverActivityStarting
        : l10n.serverActivityConnecting,
    message: failed
        ? portInUse
              ? l10n.serverActivityPortInUse
              : l10n.serverActivityStartFailedHint
        : l10n.loadingEllipsis,
    busy: !failed,
    error: failed ? diagnostic ?? l10n.serverActivityStartFailed : null,
  );
}
