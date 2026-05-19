import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/repo_changes_provider.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
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
/// Re-opening a review tab for the same `(channelId, repoId)` refocuses it (the
/// controller dedupes), and the new anchor becomes the scrolled-to file.
class ReviewCodePane extends ConsumerStatefulWidget {
  /// Creates a [ReviewCodePane].
  const ReviewCodePane({
    super.key,
    required this.workspaceId,
    required this.repoId,
    required this.anchorPath,
    this.channelId,
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
  final String? channelId;

  @override
  ConsumerState<ReviewCodePane> createState() => _ReviewCodePaneState();
}

class _ReviewCodePaneState extends ConsumerState<ReviewCodePane> {
  /// Drives `jumpToFile(index)` on the hosted [PrDiffView] so the tab opens
  /// scrolled to the widget's `anchorPath`. Mirrors the PR details screen's pattern.
  final GlobalKey<PrDiffViewState> _diffKey = GlobalKey<PrDiffViewState>();

  /// Whether the initial anchor-scroll has fired, so it happens only once per
  /// changeset load (not on every rebuild / ref-watch).
  bool _anchored = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final args = (
      workspaceId: widget.workspaceId,
      repoId: widget.repoId,
      channelId: widget.channelId,
    );
    final async = ref.watch(repoChangesProvider(args));

    return async.when(
      loading: () => const Center(child: CcSpinner(size: 18, strokeWidth: 2)),
      error: (_, _) => _empty(t),
      data: (files) {
        if (files.isEmpty) {
          return _empty(t);
        }
        // Reset the anchor latch when the changeset identity changes (a refresh)
        // so the anchor re-applies to the new file list.
        if (!_anchored) {
          _scheduleAnchorScroll(files);
        }
        // The full branch diff: every changed file in one virtualized view,
        // exactly as the PR details page renders it. PrDiffView is a sliver, so
        // it must live inside a viewport — a bare CustomScrollView registers as
        // the primary scroller, which jumpToFile relies on.
        return CustomScrollView(
          slivers: [
            PrDiffView(key: _diffKey, files: files, comments: const []),
          ],
        );
      },
    );
  }

  /// Scrolls the diff to the widget's `anchorPath` once the sliver has mounted. The
  /// virtualized diff computes per-file offsets from measured heights, so the
  /// jump must run after the frame that builds the sliver. Guarded against a
  /// missing anchor (→ no-op) and an out-of-range index.
  void _scheduleAnchorScroll(List<PrFile> files) {
    final anchorIndex = files.indexWhere(
      (f) => f.filename == widget.anchorPath,
    );
    if (anchorIndex < 0) {
      // Anchor no longer in the changeset (reverted/renamed) — nothing to do;
      // the diff opens at the top.
      _anchored = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _diffKey.currentState?.jumpToFile(anchorIndex);
      if (mounted) {
        setState(() => _anchored = true);
      }
    });
  }

  Widget _empty(DesignSystemTokens t) {
    return ColoredBox(
      color: t.bgPrimary,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.gitCompareArrows, size: 16),
              SizedBox(width: 8),
              Text('No changes to review'),
            ],
          ),
        ),
      ),
    );
  }
}
