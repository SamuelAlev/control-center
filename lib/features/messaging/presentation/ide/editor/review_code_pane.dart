import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/providers/repo_changes_provider.dart';
import 'package:control_center/features/messaging/providers/repo_file_content_provider.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A multi-file branch review surface: the repo's ENTIRE working-tree diff
/// (every changed file in one scrollable view, the same [PrDiffView] the PR
/// details page renders). The tab is ANCHORED to one file ([anchorPath]) — the
/// file the user clicked in the Source Control panel — and scrolls to it on
/// open, but all the other changed files remain visible above/below it (the
/// user is free to browse the whole branch diff).
///
/// Re-opening a review tab for the same `(spaceId, repoId)` refocuses it (the
/// controller dedupes) and the new anchor becomes the scrolled-to file.
class ReviewCodePane extends ConsumerStatefulWidget {
  /// Creates a [ReviewCodePane].
  const ReviewCodePane({
    super.key,
    required this.workspaceId,
    required this.repoId,
    required this.anchorPath,
    this.spaceId,
  });

  /// The workspace owning the repo (workspace-scoped read).
  final String workspaceId;

  /// The repo whose working-tree changes are reviewed.
  final String repoId;

  /// The file path scrolled to on open (the clicked file). May be absent from
  /// the changeset (e.g. it was reverted since the tab opened) → falls back to
  /// the first file.
  final String anchorPath;

  /// The conversation whose isolated CoW worktree the diff reflects. Null →
  /// the original linked-repo checkout.
  final String? spaceId;

  @override
  ConsumerState<ReviewCodePane> createState() => _ReviewCodePaneState();
}

class _ReviewCodePaneState extends ConsumerState<ReviewCodePane> {
  /// Drives `jumpToFile(index)` on the hosted [PrDiffView] so the tab opens
  /// scrolled to the widget's `anchorPath`. Mirrors the PR details screen's pattern.
  final GlobalKey<PrDiffViewState> _diffKey = GlobalKey<PrDiffViewState>();

  /// The diff's own scroller. [jumpToFile] reads it through
  /// [PrimaryScrollController]; a bare [CustomScrollView] does not register
  /// as that controller on desktop (only mobile inherits the route's).
  final ScrollController _scroll = ScrollController();

  /// Whether the current [ReviewCodePane.anchorPath] has already been asked
  /// to scroll. Reset when the anchor changes so a later click in Source
  /// Control moves the same diff.
  bool _anchored = false;

  /// Bumps on each anchor request so a superseded jump does not land later.
  int _anchorGeneration = 0;

  RepoChangesArgs get _args => (
    workspaceId: widget.workspaceId,
    repoId: widget.repoId,
    spaceId: widget.spaceId,
  );

  @override
  void didUpdateWidget(covariant ReviewCodePane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anchorPath != widget.anchorPath) {
      _anchored = false;
    }
  }

  @override
  void dispose() {
    _anchorGeneration++;
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final async = ref.watch(repoChangesProvider(_args));
    // Keep the previous diff on screen while a poll is in flight. Swapping in
    // a spinner unmounts the sliver and throws away the scroll position, and
    // a reload that dropped `value` would paint the tab empty until it landed.
    final files = async.value;
    if (files == null) {
      if (async.hasError) {
        return _empty(t);
      }
      return const Center(child: CcSpinner(size: 18, strokeWidth: 2));
    }
    if (files.isEmpty) {
      return _empty(t);
    }
    if (!_anchored) {
      _scheduleAnchorScroll(files);
    }
    // The full branch diff: every changed file in one virtualized view,
    // exactly as the PR details page renders it. PrDiffView is a sliver, so
    // it lives in this viewport. The controller is also the primary one:
    // jumpToFile resolves its target through PrimaryScrollController, and on
    // desktop a scroll view does not attach to the route's controller.
    return PrimaryScrollController(
      controller: _scroll,
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          PrDiffView(
            key: _diffKey,
            files: files,
            comments: const [],
            // Gap rows ("show N lines") fetch the worktree file. Without this
            // the row is disabled and the tap does nothing.
            fetchFileContent: (path) => fetchRepoFileContent(
              ref.read(rpcClientProvider),
              workspaceId: widget.workspaceId,
              repoId: widget.repoId,
              path: path,
              spaceId: widget.spaceId,
            ),
          ),
        ],
      ),
    );
  }

  /// Scrolls the diff to the widget's `anchorPath` once the sliver has mounted.
  /// The virtualized diff computes per-file offsets from measured heights, so
  /// the jump must run after the frame that builds the sliver, and again if
  /// that frame had no scroll position yet. A missing anchor leaves the diff
  /// at the top.
  void _scheduleAnchorScroll(List<PrFile> files) {
    final anchorIndex = files.indexWhere(
      (f) => f.filename == widget.anchorPath,
    );
    if (anchorIndex < 0) {
      _anchored = true;
      return;
    }
    _anchored = true;
    final generation = ++_anchorGeneration;
    _jumpWhenReady(anchorIndex, generation, attempts: 8);
  }

  void _jumpWhenReady(int index, int generation, {required int attempts}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || generation != _anchorGeneration) {
        return;
      }
      final jumped = await _diffKey.currentState?.jumpToFile(index) ?? false;
      if (!mounted || generation != _anchorGeneration || jumped) {
        return;
      }
      if (attempts > 0) {
        _jumpWhenReady(index, generation, attempts: attempts - 1);
      }
    });
  }

  Widget _empty(DesignSystemTokens t) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: t.bgPrimary,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.gitCompareArrows, size: 16),
              const SizedBox(width: 8),
              Text(l10n.noChangesToReview),
            ],
          ),
        ),
      ),
    );
  }
}
