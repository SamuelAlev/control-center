import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The four-way PR state the conversation sidebar renders, collapsed from a
/// [PullRequest].
///
/// GitHub exposes `state` (open/closed/merged) plus a separate `isDraft` flag;
/// the sidebar wants the four visual states (draft/open/closed/merged) each with
/// its own colour AND glyph — never status-by-colour-alone per DESIGN.md, so
/// every value also carries a distinct lucide icon.
enum PrSidebarStatus {
  /// Open but not yet ready for review — draft. Grey.
  draft,
  /// Open and ready for review. Green.
  open,
  /// Closed without merging. Red.
  closed,
  /// Merged. Purple.
  merged;

  /// Resolves a [PullRequest] into a sidebar status, or `null` when there is no
  /// PR to show. Precedence follows GitHub's own: merged (terminal) beats
  /// draft/closed beats plain open.
  static PrSidebarStatus? fromPullRequest(PullRequest? pr) {
    if (pr == null) {
      return null;
    }
    if (pr.isMerged) {
      return PrSidebarStatus.merged;
    }
    if (pr.isDraft) {
      return PrSidebarStatus.draft;
    }
    if (pr.isClosed) {
      return PrSidebarStatus.closed;
    }
    return PrSidebarStatus.open;
  }

  /// Distinct glyph per state — the shape differentiator that keeps this from
  /// being colour-only.
  IconData get icon => switch (this) {
    PrSidebarStatus.draft => AppIcons.gitPullRequestDraft,
    PrSidebarStatus.open => AppIcons.gitPullRequest,
    PrSidebarStatus.closed => AppIcons.gitPullRequestClosed,
    PrSidebarStatus.merged => AppIcons.gitMerge,
  };

  /// State colour, matched to the PR's identity on GitHub (draft/open/closed/
  /// merged → grey/green/red/purple).
  Color get color => switch (this) {
    PrSidebarStatus.draft => DesignSystemPalette.gray500,
    PrSidebarStatus.open => DesignSystemPalette.green600,
    PrSidebarStatus.closed => DesignSystemPalette.red600,
    PrSidebarStatus.merged => DesignSystemPalette.purple600,
  };
}

/// Renders a [PrSidebarStatus] as a coloured PR glyph sized for the
/// conversation sidebar's leading slot.
class PrStatusBadge extends StatelessWidget {
  /// Creates a [PrStatusBadge].
  const PrStatusBadge({super.key, required this.status, this.size = 18});

  /// The PR state to render.
  final PrSidebarStatus status;

  /// Glyph size in logical pixels (matches the hash icon it replaces).
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(status.icon, size: size, color: status.color);
  }
}
