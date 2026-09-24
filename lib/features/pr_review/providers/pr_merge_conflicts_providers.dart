import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The files a pull request conflicts on against its base branch.
@immutable
class PrMergeConflictList {
  /// Creates a [PrMergeConflictList].
  const PrMergeConflictList({required this.files, required this.baseRef});

  /// The conflicting paths, in git's order.
  final List<String> files;

  /// The branch the pull request merges into.
  final String baseRef;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrMergeConflictList &&
          baseRef == other.baseRef &&
          listEquals(files, other.files);

  @override
  int get hashCode => Object.hash(baseRef, Object.hashAll(files));
}

/// The files [PrRef]'s pull request conflicts on.
///
/// GitHub says only THAT a branch conflicts, so the server computes the list
/// (a `git merge-tree` on its PR clone). Auto-disposed: it is read while the
/// conflicts flyout is open, and reopening it after a push asks again rather
/// than showing the files the push just resolved.
final prMergeConflictsProvider = FutureProvider.autoDispose
    .family<PrMergeConflictList, PrRef>((ref, pr) async {
      final slash = pr.repoFullName.indexOf('/');
      final data = await ref
          .watch(reviewStudioRepositoryProvider)
          .mergeConflicts(
            workspaceId: pr.workspaceId,
            owner: pr.repoFullName.substring(0, slash),
            repo: pr.repoFullName.substring(slash + 1),
            prNumber: pr.number,
          );
      return PrMergeConflictList(
        files: [
          for (final f in data['files'] as List? ?? const [])
            if (f is String) f,
        ],
        baseRef: data['base_ref'] as String? ?? '',
      );
    });
