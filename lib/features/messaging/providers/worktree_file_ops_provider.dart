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
/// unavailable / the space owns no worktree for the repo.
Future<WorktreeReadResult?> readWorktreeFile(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String spaceId,
  required String repoId,
  required String path,
}) async {
  try {
    final data = await rpcClient.call('worktree.readFile', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
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
  required String spaceId,
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
      'space_id': spaceId,
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
/// or the space owns no worktree for the repo.
Future<WorktreePublishResult?> publishWorktreeBranch(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String spaceId,
  required String repoId,
  String? branch,
}) async {
  try {
    final data = await rpcClient.call('worktree.publishBranch', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
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

/// Result of syncing a conversation worktree with its remote branch.
///
/// Named for the branch sync rather than "worktree sync" in general:
/// `cc_infra` has an unrelated rig type of that name, and a client typedef
/// with the same identifier trips the ratchet that keeps rig infrastructure
/// out of `lib/`.
typedef WorktreeBranchSyncResult = ({
  bool pulled,
  bool pushed,
  bool dirty,
  bool conflict,
  bool pushRefused,
  String? error,
});

/// Fetches the conversation branch, rebases when the remote moved, and pushes
/// when this side is ahead or the branch has never been published. Never
/// commits. A rejected push sets `pushRefused` and carries the hook or remote's
/// text in `error`. Returns null when the op is unavailable.
Future<WorktreeBranchSyncResult?> syncWorktreeBranch(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String spaceId,
  required String repoId,
}) async {
  try {
    final data = await rpcClient.call('worktree.syncBranch', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'repo_id': repoId,
    });
    if (data['ok'] != true) {
      return null;
    }
    return (
      pulled: data['pulled'] as bool? ?? false,
      pushed: data['pushed'] as bool? ?? false,
      dirty: data['dirty'] as bool? ?? false,
      conflict: data['conflict'] as bool? ?? false,
      // Absent on a server that predates push-refusal reporting.
      pushRefused: data['pushRefused'] == true,
      error: data['error'] as String?,
    );
  } on Exception {
    return null;
  }
}

/// One ref the branch picker can check out.
typedef WorktreeRefEntry = ({
  String name,
  String kind,
  String sha,
  DateTime? committedAt,
  String subject,
  bool current,
  String localName,
});

/// The refs in a conversation worktree.
typedef WorktreeBranchList = ({
  String current,
  bool detached,
  List<WorktreeRefEntry> refs,
});

/// What the branch picker asks the server to check out.
typedef WorktreeCheckoutRequest = ({
  String? branch,
  String? startPoint,
  bool create,
  bool detach,
});

/// Result of [checkoutWorktreeBranch].
typedef WorktreeCheckoutResult = ({
  bool ok,
  String branch,
  bool detached,
  bool dirty,
  String? error,
});

/// Lists branches, remote-tracking refs and tags in the conversation worktree.
/// Returns null when the op is unavailable or the space owns no worktree.
Future<WorktreeBranchList?> listWorktreeBranches(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String spaceId,
  required String repoId,
}) async {
  try {
    final data = await rpcClient.call('worktree.listBranches', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'repo_id': repoId,
    });
    if (data['ok'] != true) {
      return null;
    }
    final raw = data['refs'];
    final refs = <WorktreeRefEntry>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) {
          continue;
        }
        final name = item['name'];
        final kind = item['kind'];
        if (name is! String || name.isEmpty || kind is! String) {
          continue;
        }
        final seconds = (item['committedAt'] as num?)?.toInt() ?? 0;
        refs.add((
          name: name,
          kind: kind,
          sha: item['sha'] as String? ?? '',
          committedAt: seconds <= 0
              ? null
              : DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
          subject: item['subject'] as String? ?? '',
          current: item['current'] == true,
          localName: item['localName'] as String? ?? name,
        ));
      }
    }
    return (
      current: data['current'] as String? ?? '',
      detached: data['detached'] == true,
      refs: refs,
    );
  } on Exception {
    return null;
  }
}

/// Checks a branch out in the conversation worktree, or creates one.
/// Returns null when the op is unavailable.
Future<WorktreeCheckoutResult?> checkoutWorktreeBranch(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String spaceId,
  required String repoId,
  required WorktreeCheckoutRequest request,
}) async {
  try {
    final data = await rpcClient.call('worktree.checkout', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'repo_id': repoId,
      'branch': ?request.branch,
      'start_point': ?request.startPoint,
      'create': request.create,
      'detach': request.detach,
    });
    return (
      ok: data['ok'] == true,
      branch: data['branch'] as String? ?? '',
      detached: data['detached'] == true,
      dirty: data['dirty'] == true,
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

/// Re-syncs the PR space worktree to the latest PR head via the SERVER-side
/// `worktree.syncToPrHead` op. Returns `synced` when the tree advanced,
/// `dirty` when it was skipped because of uncommitted edits, or null when the
/// op is unavailable / the space owns no worktree.
Future<PrWorktreeSyncOutcome?> syncWorktreeToPrHead(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String spaceId,
  required String repoId,
}) async {
  try {
    final data = await rpcClient.call('worktree.syncToPrHead', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
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

/// Stages every working-tree change when the git index is empty, so the
/// commit that follows includes them.
///
/// This is VS Code's `git.enableSmartCommit`: an empty index commits the
/// whole working tree (tracked and untracked, `git add -A`), and a non-empty
/// index is left alone so a partial stage still commits only what was staged.
/// Returns false when that stage was required and the op failed; returns true
/// when there was nothing to stage or the index already held changes.
Future<bool> stageAllWhenIndexEmpty(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String spaceId,
  required String repoId,
  required int stagedCount,
  required int unstagedCount,
}) async {
  if (stagedCount > 0 || unstagedCount == 0) {
    return true;
  }
  return stageWorktreeFiles(
    rpcClient,
    workspaceId: workspaceId,
    spaceId: spaceId,
    repoId: repoId,
  );
}

/// Stages [paths] (empty ⇒ all) into the conversation worktree's git index via
/// the SERVER-side `repos.stage` op (`git add`). Returns false when the op is
/// unavailable or the space owns no worktree for the repo.
Future<bool> stageWorktreeFiles(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String spaceId,
  required String repoId,
  List<String> paths = const [],
}) async {
  try {
    final data = await rpcClient.call('repos.stage', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
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
  required String spaceId,
  required String repoId,
  List<String> paths = const [],
}) async {
  try {
    final data = await rpcClient.call('repos.unstage', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
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
/// was rejected (no worktree for the space, path escape, payload too big) or
/// when the op is unavailable on the host.
Future<WorktreeWriteResult?> writeWorktreeFile(
  RemoteRpcClient rpcClient, {
  required String workspaceId,
  required String spaceId,
  required String repoId,
  required String path,
  required String content,
}) async {
  try {
    final data = await rpcClient.call('worktree.writeFile', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
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
  required String spaceId,
  required String repoId,
  required List<String> paths,
}) async {
  if (paths.isEmpty) {
    return (repoId: repoId, reverted: 0, skipped: const <String>[]);
  }
  try {
    final data = await rpcClient.call('worktree.revertFiles', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
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
