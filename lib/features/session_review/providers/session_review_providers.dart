import 'package:cc_domain/core/domain/ports/session_diff_port.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/session_review/data/session_diff_binding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies a session changeset to compute: the files changed in
/// [worktreePath] between [baseRef] and the working tree (or [headRef]).
class SessionDiffRequest {
  /// Creates a [SessionDiffRequest].
  const SessionDiffRequest({
    required this.worktreePath,
    required this.baseRef,
    this.headRef,
  });

  /// Absolute path to the git worktree.
  final String worktreePath;

  /// The session-start snapshot ref to diff from.
  final String baseRef;

  /// Optional end ref; null diffs against the live working tree.
  final String? headRef;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionDiffRequest &&
          worktreePath == other.worktreePath &&
          baseRef == other.baseRef &&
          headRef == other.headRef;

  @override
  int get hashCode => Object.hash(worktreePath, baseRef, headRef);
}

/// The platform-resolved [SessionDiffPort]: a local-git adapter on desktop,
/// null on web (where the worktree is remote and the diff is not yet exposed
/// over RPC).
final sessionDiffPortProvider = Provider<SessionDiffPort?>(
  (ref) => createSessionDiffPort(),
);

/// Computes the changed files for a [SessionDiffRequest]. Returns an empty list
/// when session review is unavailable (e.g. on web).
final sessionChangeSetProvider =
    FutureProvider.family<List<PrFile>, SessionDiffRequest>((
      ref,
      request,
    ) async {
      final port = ref.watch(sessionDiffPortProvider);
      if (port == null) {
        return const [];
      }
      return port.changedFiles(
        request.worktreePath,
        request.baseRef,
        headRef: request.headRef,
      );
    });

/// Whether session review (local-git diffing) is available on this platform.
final sessionReviewAvailableProvider = Provider<bool>(
  (ref) => ref.watch(sessionDiffPortProvider) != null,
);
