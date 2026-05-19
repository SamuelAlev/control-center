import 'package:cc_rpc/cc_rpc.dart';

/// Result of writing a draft into a conversation's worktree.
typedef WorktreeWriteResult = ({String repoId, String path});

/// Result of reverting working-tree files in a conversation's worktree.
typedef WorktreeRevertResult = ({
  String repoId,
  int reverted,
  List<String> skipped,
});

/// Contents of a file read from a conversation's worktree.
typedef WorktreeReadResult = ({String content, bool binary});

/// Result of committing (and optionally pushing) worktree changes.
typedef WorktreeCommitResult = ({
  bool committed,
  bool pushed,
  String? headSha,
  String? error,
});

/// Reads a file from the conversation's isolated worktree (the PR-head tree)
/// via the SERVER-side `worktree.readFile` op. Returns null when the op is
/// unavailable / the channel owns no worktree for the repo.
Future<WorktreeReadResult?> readWorktreeFile(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String channelId,
  required String repoId,
  required String path,
}) async {
  try {
    final data = await rpcClient.call('worktree.readFile', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'repo_id': repoId,
      'path': path,
    });
    if (data['ok'] != true) {
      return null;
    }
    return (
      content: data['content'] as String? ?? '',
      binary: data['binary'] as bool? ?? false,
    );
  } on Exception {
    return null;
  }
}

/// Commits (and optionally pushes) changes in the conversation's isolated
/// worktree via `worktree.commitAndPush`. [pushBranch] is the remote branch to
/// push to (the PR head branch). [amend] rewrites the previous commit instead
/// of adding a new one; [sync] integrates the remote branch (fetch + rebase)
/// before pushing. Returns null when the op is unavailable.
Future<WorktreeCommitResult?> commitAndPushWorktree(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String channelId,
  required String repoId,
  required String message,
  List<String> paths = const [],
  bool push = true,
  bool amend = false,
  bool sync = false,
  String? pushBranch,
  String? authorName,
  String? authorEmail,
}) async {
  try {
    final data = await rpcClient.call('worktree.commitAndPush', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'repo_id': repoId,
      'message': message,
      'paths': paths,
      'push': push,
      'amend': amend,
      'sync': sync,
      'push_branch': ?pushBranch,
      if (authorName != null && authorName.trim().isNotEmpty)
        'author_name': authorName.trim(),
      if (authorEmail != null && authorEmail.trim().isNotEmpty)
        'author_email': authorEmail.trim(),
    });
    if (data['ok'] != true) {
      return null;
    }
    return (
      committed: data['committed'] as bool? ?? false,
      pushed: data['pushed'] as bool? ?? false,
      headSha: data['headSha'] as String?,
      error: data['error'] as String?,
    );
  } on Exception {
    return null;
  }
}

/// Result of publishing a conversation worktree's branch to `origin`.
typedef WorktreePublishResult = ({
  String branch,
  bool pushed,
  int uncommitted,
  String? error,
});

/// Publishes the conversation worktree's branch to `origin` via the SERVER-side
/// `worktree.publishBranch` op — a push, never a commit.
///
/// A conversation worktree's branch is created locally and never pushed, so it
/// does not exist on GitHub and cannot be a pull-request head until this runs.
/// Uncommitted changes are NOT included (the count comes back in `uncommitted`
/// so the caller can say so). Returns null when the op is unavailable on the host
/// or the channel owns no worktree for the repo.
Future<WorktreePublishResult?> publishWorktreeBranch(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String channelId,
  required String repoId,
  String? branch,
}) async {
  try {
    final data = await rpcClient.call('worktree.publishBranch', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'repo_id': repoId,
      'branch': ?branch,
    });
    if (data['ok'] != true) {
      return null;
    }
    return (
      branch: data['branch'] as String? ?? branch ?? '',
      pushed: data['pushed'] as bool? ?? false,
      uncommitted: (data['uncommitted'] as num?)?.toInt() ?? 0,
      error: data['error'] as String?,
    );
  } on Exception {
    return null;
  }
}

/// Outcome of a [syncWorktreeToPrHead] call.
///
/// Named for the PR flow rather than "worktree sync" in general: `cc_infra`
/// has its own, unrelated `WorktreeSyncResult` (a rig's tar-in / bundle-out),
/// and two records with one name across a repo is a trap for whoever greps
/// next — as well as a false positive for the ratchet that keeps rig
/// infrastructure out of the client.
typedef PrWorktreeSyncOutcome = ({bool synced, bool dirty, String? error});

/// Re-syncs the PR channel worktree to the latest PR head via the SERVER-side
/// `worktree.syncToPrHead` op. Returns `synced` when the tree advanced,
/// `dirty` when it was skipped because of uncommitted edits, or null when the
/// op is unavailable / the channel owns no worktree.
Future<PrWorktreeSyncOutcome?> syncWorktreeToPrHead(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String channelId,
  required String repoId,
}) async {
  try {
    final data = await rpcClient.call('worktree.syncToPrHead', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'repo_id': repoId,
    });
    if (data['ok'] != true) {
      return (synced: false, dirty: false, error: data['error'] as String?);
    }
    return (
      synced: data['synced'] == true,
      dirty: data['dirty'] == true,
      error: null,
    );
  } on Exception {
    return null;
  }
}

/// Stages [paths] (empty ⇒ all) into the conversation worktree's git index via
/// the SERVER-side `repos.stage` op (`git add`). Returns false when the op is
/// unavailable or the channel owns no worktree for the repo.
Future<bool> stageWorktreeFiles(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String channelId,
  required String repoId,
  List<String> paths = const [],
}) async {
  try {
    final data = await rpcClient.call('repos.stage', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'repo_id': repoId,
      'paths': paths,
    });
    return data['ok'] == true;
  } on Exception {
    return false;
  }
}

/// Unstages [paths] (empty ⇒ all) from the conversation worktree's git index via
/// the SERVER-side `repos.unstage` op (`git reset HEAD`). The working-tree
/// content is untouched. Returns false when unavailable.
Future<bool> unstageWorktreeFiles(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String channelId,
  required String repoId,
  List<String> paths = const [],
}) async {
  try {
    final data = await rpcClient.call('repos.unstage', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'repo_id': repoId,
      'paths': paths,
    });
    return data['ok'] == true;
  } on Exception {
    return false;
  }
}

/// Writes a draft file into the conversation's isolated worktree via the
/// SERVER-side `worktree.writeFile` op (which confines the path to the worktree
/// root and caps the payload). Returns null when the server reports the write
/// was rejected (no worktree for the channel, path escape, payload too big) or
/// when the op is unavailable on the host.
Future<WorktreeWriteResult?> writeWorktreeFile(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String channelId,
  required String repoId,
  required String path,
  required String content,
}) async {
  try {
    final data = await rpcClient.call('worktree.writeFile', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'repo_id': repoId,
      'path': path,
      'content': content,
    });
    if (data['ok'] != true) {
      return null;
    }
    return (
      repoId: data['repoId'] as String? ?? repoId,
      path: data['path'] as String? ?? path,
    );
  } on Exception {
    // The op is absent on hosts that own no worktrees, or the call failed —
    // surface as "not saved" rather than throwing to the caller.
    return null;
  }
}

/// Reverts working-tree files in the conversation's worktree to HEAD via the
/// SERVER-side `worktree.revertFiles` op. Tracked files are restored; untracked
/// files come back in `skipped`. Returns null when the op is unavailable.
Future<WorktreeRevertResult?> revertWorktreeFiles(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String channelId,
  required String repoId,
  required List<String> paths,
}) async {
  if (paths.isEmpty) {
    return (repoId: repoId, reverted: 0, skipped: const <String>[]);
  }
  try {
    final data = await rpcClient.call('worktree.revertFiles', {
      'workspace_id': workspaceId,
      'channel_id': channelId,
      'repo_id': repoId,
      'paths': paths,
    });
    if (data['ok'] != true) {
      return null;
    }
    final skipped =
        (data['skipped'] as List?)?.whereType<String>().toList(
          growable: false,
        ) ??
        const <String>[];
    return (
      repoId: data['repoId'] as String? ?? repoId,
      reverted: (data['reverted'] as num?)?.toInt() ?? 0,
      skipped: skipped,
    );
  } on Exception {
    return null;
  }
}
