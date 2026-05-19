import 'package:cc_domain/core/domain/entities/repo_script_run.dart';
import 'package:cc_domain/core/domain/value_objects/repo_scripts.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The scripts configured for one repo, fetched when the scripts dialog opens
/// (they ride their own admin-gated op — see `RpcRepoScriptRepository`).
///
/// A record family key keeps workspace + repo explicit: repo ids resolve only
/// inside their workspace, so a bare repo id must never pick the database.
typedef _ScriptsKey = ({String workspaceId, String repoId});

/// The scripts configured for one repo, fetched when the scripts dialog opens.
final repoScriptsProvider = FutureProvider.autoDispose
    .family<RepoScripts, _ScriptsKey>((ref, key) {
      return ref
          .watch(repoScriptRepositoryProvider)
          .getScripts(key.workspaceId, key.repoId);
    });

/// Recorded lifecycle script runs for one repo, newest first — the scripts
/// dialog's history section (status, duration, bounded output tail).
final repoScriptRunsProvider = StreamProvider.autoDispose
    .family<List<RepoScriptRun>, _ScriptsKey>((ref, key) {
      return ref
          .watch(repoScriptRepositoryProvider)
          .watchRuns(key.workspaceId, repoId: key.repoId);
    });
