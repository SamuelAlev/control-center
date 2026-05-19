import 'package:control_center/features/pr_review/presentation/utils/diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/pr_review/providers/compose_pr_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The compose-screen counterpart to the PR detail page's `TreeOverlay`: the
/// sticky changed-files tree shown beside the `base...head` diff. Watches the
/// same [branchComparisonProvider] the diff renders from, so the tree and the
/// diff always agree on file order, and jumps the diff to a file on tap via the
/// shared [PrDiffViewState] key.
class ComposeFileTreeOverlay extends ConsumerWidget {
  /// Creates a [ComposeFileTreeOverlay] for the `base...head` comparison.
  const ComposeFileTreeOverlay({
    super.key,
    required this.base,
    required this.head,
    required this.diffKey,
  });

  /// Base branch of the comparison.
  final String base;

  /// Head (compare) branch of the comparison.
  final String head;

  /// The diff view's state key — used to scroll the diff to a tapped file.
  final GlobalKey<PrDiffViewState> diffKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diff = ref
        .watch(branchComparisonProvider((base: base, head: head)))
        .value;
    final rawFiles = diff?.files ?? const [];
    if (rawFiles.isEmpty) {
      return const SizedBox.shrink();
    }
    final files = sortFilesByTreeOrder(rawFiles);
    final tree = buildDiffFileTree(files);
    return PrDiffFileTree(
      roots: tree,
      onSelectFile: (i) => diffKey.currentState?.jumpToFile(i),
    );
  }
}
