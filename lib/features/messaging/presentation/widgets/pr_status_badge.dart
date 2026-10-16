import 'dart:math' as math;

import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The four-way PR state the conversation sidebar renders, collapsed from a
/// [PullRequest].
///
/// GitHub exposes `state` (open/closed/merged) plus a separate `isDraft` flag;
/// the sidebar wants the four visual states (draft/open/closed/merged) each with
/// its own colour AND glyph — never status-by-colour-alone per DESIGN.md, so
/// every value also carries a distinct icon.
enum PrSidebarStatus {
  /// Open but not yet ready for review — draft. Grey.
  draft,

  /// Open and ready for review. Green.
  open,

  /// Closed without merging. Red.
  closed,

  /// Merged. Purple.
  merged;

  /// Resolves a PR into a sidebar status. Terminal lifecycle states take
  /// precedence over a retained draft flag.
  static PrSidebarStatus? fromPullRequest(PullRequest? pr) {
    if (pr == null) {
      return null;
    }
    if (pr.isMerged) {
      return PrSidebarStatus.merged;
    }
    if (pr.isClosed) {
      return PrSidebarStatus.closed;
    }
    if (pr.isDraft) {
      return PrSidebarStatus.draft;
    }
    return PrSidebarStatus.open;
  }

  /// Bit identifying this state in a space's distinct-status mask.
  int get mask => 1 << index;

  /// One bit per distinct PR state, independent of counts and input order.
  /// Zero means no PRs. The integer projection compares by value across refreshes.
  static int aggregate(Iterable<PullRequest> prs) {
    var mask = 0;
    for (final pr in prs) {
      mask |= fromPullRequest(pr)!.mask;
    }
    return mask;
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

  /// Localized state name for the combined tooltip and accessible label.
  String label(AppLocalizations l10n) => switch (this) {
    PrSidebarStatus.draft => l10n.draft,
    PrSidebarStatus.open => l10n.openStatus,
    PrSidebarStatus.closed => l10n.closed,
    PrSidebarStatus.merged => l10n.merged,
  };
}

/// One full glyph for a single PR state, or equal angular slices of each
/// distinct state's glyph for a mixed space. Counts never weight the slices.
class PrStatusBadge extends StatelessWidget {
  /// Creates a sidebar PR-status glyph from [PrSidebarStatus.aggregate].
  const PrStatusBadge({
    super.key,
    required this.statusMask,
    this.size = 18,
    this.selected = false,
    this.semanticLabel,
  }) : assert(statusMask > 0 && statusMask < 16);

  /// One bit per distinct [PrSidebarStatus].
  final int statusMask;

  /// Glyph size in logical pixels.
  final double size;

  /// Single glyphs invert on the selected row. Mixed glyphs retain their
  /// status colors on a neutral circular backing to preserve contrast.
  final bool selected;

  /// Replaces the state list when the caller can give a more specific label,
  /// such as a fully resolved inventory in which every PR has merged.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final states = [
      for (final state in PrSidebarStatus.values)
        if (statusMask & state.mask != 0) state,
    ];
    final l10n = AppLocalizations.of(context);
    final label =
        semanticLabel ?? states.map((state) => state.label(l10n)).join(' / ');
    final Widget glyph;
    if (states.length == 1) {
      final state = states.single;
      glyph = Icon(
        state.icon,
        size: size,
        color: selected ? tokens.accentOn : state.color,
      );
    } else {
      final sectors = SizedBox.square(
        dimension: size,
        child: CustomPaint(
          foregroundPainter: _PrStatusDividerPainter(
            count: states.length,
            color: tokens.borderPrimary,
          ),
          child: Stack(
            children: [
              for (var i = 0; i < states.length; i++)
                ClipPath(
                  clipper: _PrStatusSectorClipper(i, states.length),
                  child: Icon(
                    states[i].icon,
                    size: size,
                    color: states[i].color,
                  ),
                ),
            ],
          ),
        ),
      );
      glyph = selected
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.bgPrimary,
                shape: BoxShape.circle,
              ),
              child: sectors,
            )
          : sectors;
    }
    return CcTooltip(
      message: label,
      child: Semantics(label: label, excludeSemantics: true, child: glyph),
    );
  }
}

class _PrStatusSectorClipper extends CustomClipper<Path> {
  const _PrStatusSectorClipper(this.index, this.count);

  final int index;
  final int count;

  @override
  Path getClip(Size size) {
    // RTL carve-out: physical angles keep status sectors stable across locales.
    final center = size.center(Offset.zero);
    final sweep = 2 * math.pi / count;
    return Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        // Reach the glyph's square corners instead of cropping its strokes.
        Rect.fromCircle(center: center, radius: size.longestSide),
        -math.pi / 2 + index * sweep,
        sweep,
        false,
      )
      ..close();
  }

  @override
  bool shouldReclip(_PrStatusSectorClipper oldClipper) =>
      index != oldClipper.index || count != oldClipper.count;
}

class _PrStatusDividerPainter extends CustomPainter {
  _PrStatusDividerPainter({required this.count, required Color color})
    : _paint = Paint()
        ..color = color
        ..strokeWidth = 1;

  final int count;
  final Paint _paint;

  @override
  void paint(Canvas canvas, Size size) {
    // RTL carve-out: dividers follow the physical angles of the status sectors.
    final center = size.center(Offset.zero);
    final edge = Offset(0, -size.shortestSide / 2);
    final sweep = 2 * math.pi / count;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (var i = 0; i < count; i++) {
      canvas.drawLine(Offset.zero, edge, _paint);
      canvas.rotate(sweep);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PrStatusDividerPainter oldDelegate) =>
      count != oldDelegate.count || _paint.color != oldDelegate._paint.color;
}
