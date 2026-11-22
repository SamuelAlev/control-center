import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/features/dispatch/domain/ports/worktree_fingerprint_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_natives/cc_natives.dart' show RepoStateProbe;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// [WorktreeFingerprintPort] over the code indexer's [RepoStateProbe]: the
/// HEAD commit, `git status` with every untracked file, and a stat of every
/// dirty path, so an edit, a commit or a new file each change it.
///
/// A conversation's worktrees are its space's checkouts,
/// `<space dir>/repos/<slug>`. One checkout gives its probe digest; several
/// give a SHA-256 over their sorted `name:digest` pairs. Null when the
/// conversation is not in the workspace, has no checkout, or any checkout
/// cannot be probed (not a git work tree, too many dirty files).
final class WorktreeFingerprints implements WorktreeFingerprintPort {
  /// Creates the adapter.
  const WorktreeFingerprints({
    required this.conversations,
    required this.filesystem,
    this.probe = const RepoStateProbe(),
  });

  /// Finds the conversation's space, scoped to its workspace.
  final ConversationRepository conversations;

  /// Where the space's checkouts are.
  final WorkspaceFilesystemPort filesystem;

  /// Fingerprints one checkout.
  final RepoStateProbe probe;

  @override
  Future<String?> fingerprint({
    required String workspaceId,
    required String conversationId,
  }) async {
    try {
      final conversation = await conversations.getById(
        workspaceId: workspaceId,
        conversationId: conversationId,
      );
      if (conversation == null) {
        return null;
      }
      final reposDir = Directory(
        p.join(
          await filesystem.spaceDir(workspaceId, conversation.spaceId),
          'repos',
        ),
      );
      if (!reposDir.existsSync()) {
        return null;
      }
      final worktrees =
          reposDir.listSync(followLinks: false).whereType<Directory>().toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      if (worktrees.isEmpty) {
        return null;
      }
      final digests = <String>[];
      for (final worktree in worktrees) {
        final state = await probe.probe(worktree.path);
        if (state == null) {
          return null;
        }
        digests.add('${p.basename(worktree.path)}:${state.digest}');
      }
      if (digests.length == 1) {
        return digests.single.substring(digests.single.indexOf(':') + 1);
      }
      return sha256.convert(utf8.encode(digests.join('\n'))).toString();
    } on Object catch (e) {
      CcInfraLog.warning('worktree fingerprint failed: $e');
      return null;
    }
  }
}
