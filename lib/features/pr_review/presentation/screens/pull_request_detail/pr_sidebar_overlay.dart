import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_worktree_search_panel.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which surface the PR diff sidebar shows.
enum PrDiffSidebarMode {
  /// The changed-file directory tree (the default).
  tree,

  /// "Search in files" — a content search across the PR-head worktree.
  search,
}

/// The PR diff sidebar host: renders either the changed-file [PrDiffFileTree]
/// or the [PrWorktreeSearchPanel] "search in files" surface, switched by
/// [mode]. The host (`PrDiffTab`) owns the mode + focus token so ⌘F can reveal
/// and focus search from anywhere in the diff.
class TreeOverlay extends ConsumerWidget {
  /// Creates a [TreeOverlay].
  const TreeOverlay({
    super.key,
    required this.pr,
    required this.prRef,
    required this.diffKey,
    required this.mode,
    required this.searchFocusToken,
    required this.onOpenSearch,
    required this.onShowFileTree,
    required this.onOpenFileInEditor,
  });

  /// PullRequest.
  final PullRequest pr;

  /// The PR\'s identity key (repo coords + number).
  final PrRef prRef;

  /// The diff view state key.
  final GlobalKey<PrDiffViewState> diffKey;

  /// Which surface to show.
  final PrDiffSidebarMode mode;

  /// Bumped by the host to (re)focus the search field on reveal.
  final int searchFocusToken;

  /// Switches to search mode (the tree's search button).
  final VoidCallback onOpenSearch;

  /// Switches back to the tree (search panel's toggle + Esc/`t`).
  final VoidCallback onShowFileTree;

  /// Opens a file at an optional 1-based line in an editable tab.
  final void Function(String path, {int? line}) onOpenFileInEditor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mode == PrDiffSidebarMode.search) {
      return _SearchHost(
        pr: pr,
        prRef: prRef,
        focusToken: searchFocusToken,
        onShowFileTree: onShowFileTree,
        onOpenResult: onOpenFileInEditor,
      );
    }

    final rawFiles = ref.watch(prFilesProvider(prRef)).value ?? const [];
    if (rawFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    final files = sortFilesByTreeOrder(rawFiles);
    final tree = buildDiffFileTree(files);
    return PrDiffFileTree(
      roots: tree,
      onSelectFile: (i) => diffKey.currentState?.jumpToFile(i),
      onOpenSearch: onOpenSearch,
      onOpenFileInEditor: onOpenFileInEditor,
    );
  }
}

/// Resolves the PR space/worktree ids (which provisions the PR-head worktree
/// on first open — acceptable here since the user explicitly opened search) and
/// hosts the [PrWorktreeSearchPanel]. A missing workspace/repo/space shows a
/// spinner rather than an error, mirroring the terminal/code-server tabs.
class _SearchHost extends ConsumerWidget {
  const _SearchHost({
    required this.pr,
    required this.prRef,
    required this.focusToken,
    required this.onShowFileTree,
    required this.onOpenResult,
  });

  final PullRequest pr;

  /// The PR\'s identity key (repo coords + number).
  final PrRef prRef;
  final int focusToken;
  final VoidCallback onShowFileTree;
  final void Function(String path, {int? line}) onOpenResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final repoId = prRepoIdFor(ref, pr);
    if (workspaceId == null || repoId == null) {
      return ColoredBox(
        color: tokens.bgPrimary,
        child: Center(
          child: Text(
            AppLocalizations.of(context).preparingWorkspace,
            style: TextStyle(fontSize: 12, color: tokens.textTertiary),
          ),
        ),
      );
    }
    // Files the PR touches — used to surface the diff's own files first in the
    // content-search results (a stable partition inside the panel).
    final prFiles = ref.watch(prFilesProvider(prRef)).value;
    final prTouchedPaths = <String>{
      if (prFiles != null)
        for (final f in prFiles) f.filename,
    };
    final spaceAsync = ref.watch(prSpaceProvider(pr));
    return spaceAsync.when(
      loading: () => ColoredBox(
        color: tokens.bgPrimary,
        child: const Center(child: CcSpinner()),
      ),
      error: (e, _) => ColoredBox(
        color: tokens.bgPrimary,
        child: Center(
          child: Text(
            '$e',
            style: TextStyle(fontSize: 12, color: tokens.textTertiary),
          ),
        ),
      ),
      data: (spaceId) => PrWorktreeSearchPanel(
        workspaceId: workspaceId,
        spaceId: spaceId,
        repoId: repoId,
        focusToken: focusToken,
        onShowFileTree: onShowFileTree,
        onOpenResult: onOpenResult,
        prTouchedPaths: prTouchedPaths,
      ),
    );
  }
}
