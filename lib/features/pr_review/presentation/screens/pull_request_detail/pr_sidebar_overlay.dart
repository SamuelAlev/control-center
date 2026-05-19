import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sidebar overlay.
class SidebarOverlay extends ConsumerWidget {
  /// SidebarOverlay({super.key,.
  const SidebarOverlay({super.key, required this.pr, required this.prNumber});

  /// PullRequest.
  final PullRequest pr;

  /// Pull request number for data lookups.
  final int prNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checks =
        ref.watch(prCheckRunsProvider(prNumber)).value ?? <CheckRun>[];
    final currentLogin = ref.watch(currentUserLoginProvider);
    final isAuthor =
        currentLogin.isNotEmpty &&
        pr.author?.login.toLowerCase() == currentLogin;
    final parts = pr.repoFullName.split('/');
    final owner = parts.isNotEmpty ? parts[0] : '';
    final repoName = parts.length > 1 ? parts[1] : '';
    final hasWriteAccess =
        ref
            .watch(repoPermissionProvider((owner: owner, repo: repoName)))
            .whenOrNull(data: (perm) => perm == 'admin' || perm == 'write') ??
        false;
    return PrSidebar(
      pr: pr,
      checks: checks,
      canEdit: isAuthor || hasWriteAccess,
    );
  }
}

/// Tree overlay.
class TreeOverlay extends ConsumerStatefulWidget {
  /// TreeOverlay({super.key,.
  const TreeOverlay({super.key, required this.pr, required this.diffKey});

  /// PullRequest.
  final PullRequest pr;

  /// The diff view state key.
  final GlobalKey<PrDiffViewState> diffKey;
  @override
  ConsumerState<TreeOverlay> createState() => _TreeOverlayState();
}

class _TreeOverlayState extends ConsumerState<TreeOverlay> {
  @override
  Widget build(BuildContext context) {
    final rawFiles =
        ref.watch(prFilesProvider(widget.pr.number)).value ?? const [];
    if (rawFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    final files = sortFilesByTreeOrder(rawFiles);
    final tree = buildDiffFileTree(files);
    return PrDiffFileTree(
      roots: tree,
      onSelectFile: (i) => widget.diffKey.currentState?.jumpToFile(i),
    );
  }
}
