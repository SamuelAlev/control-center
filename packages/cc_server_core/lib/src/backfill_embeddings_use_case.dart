import 'dart:async';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/dao_code_graph_repository.dart';

/// Embeds the memory facts, messages and code symbols that have no vector
/// yet, in every live workspace.
///
/// All three are embedded when they are written, but only while the
/// on-device model is installed. Whatever was written without it (before the
/// first download finished, after an uninstall, or when a schema change
/// dropped the stored vectors) has no vector row: a fact or symbol is found
/// by keyword search only, and a message is never recalled into a later
/// prompt by meaning. This fills those rows once the model is there.
class BackfillEmbeddingsUseCase {
  /// Creates a [BackfillEmbeddingsUseCase].
  ///
  /// The fact and code graph repositories carry the embedding service;
  /// messages are embedded with the given embedder, the same service. With
  /// none ready nothing is embedded. The error callback hears a workspace
  /// whose backfill failed; the others still run.
  BackfillEmbeddingsUseCase({
    required this._workspaces,
    required this._facts,
    required this._messages,
    required this._codeGraph,
    this._embedder,
    this._onError,
  });

  final WorkspaceDatabaseManager _workspaces;
  final DaoMemoryFactRepository _facts;
  final DaoMessagingRepository _messages;
  final DaoCodeGraphRepository _codeGraph;
  final EmbeddingPort? _embedder;
  final void Function(String workspaceId, Object error, StackTrace stack)?
  _onError;

  Future<int>? _running;

  /// Backfills every live workspace and returns how many vectors were stored.
  ///
  /// A call while a run is in progress joins that run instead of starting a
  /// second one over the same rows.
  Future<int> execute() =>
      _running ??= _run().whenComplete(() => _running = null);

  /// Runs [execute] each time [statuses] reports the model installed, the
  /// current status included. Returns the subscription; cancelling it stops
  /// further runs.
  StreamSubscription<ModelStatusSnapshot> runWhenInstalled(
    Stream<ModelStatusSnapshot> statuses,
  ) => statuses
      .where((s) => s.status == ModelLifecycleStatus.installed)
      .listen((_) => unawaited(execute()));

  Future<int> _run() async {
    var stored = 0;
    for (final workspaceId in await _workspaces.liveWorkspaceIds()) {
      try {
        stored += await _facts.backfillEmbeddings(workspaceId);
        stored += await _codeGraph.backfillEmbeddings(workspaceId);
        // Messages last: they are the long list, and search needs the other
        // two first.
        final embedder = _embedder;
        if (embedder != null) {
          stored += await _messages.backfillEmbeddings(workspaceId, embedder);
        }
      } on Object catch (error, stack) {
        // A damaged workspace takes no writes, and its owner already has
        // the notice saying so.
        if (_workspaces.integrityFailure(workspaceId) == null) {
          _onError?.call(workspaceId, error, stack);
        }
      }
    }
    return stored;
  }
}
