import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Visual decoration for a review finding (icon, accent color, label).
class ReviewItemDecor {
  /// Creates a [ReviewItemDecor] with required icon, accent color and label.
  const ReviewItemDecor({
    required this.icon,
    required this.accent,
    required this.label,
  });

  /// The icon representing the review item kind.
  final IconData icon;

  /// The accent color derived from kind and priority.
  final Color accent;

  /// The human-readable label for the review item kind.
  final String label;
}

/// A review finding extracted from a space message.
typedef ReviewFinding = ({Message message, ReviewNodePayload payload});

/// Parses review findings from space messages and sorts by priority, status and creation time.
List<ReviewFinding> parseAndSortFindings(List<Message> messages) {
  final findings = <ReviewFinding>[];
  for (final msg in messages) {
    if (msg.messageType != MessageType.reviewNode) {
      continue;
    }
    final payload = ReviewNodePayload.fromMetadata(msg.metadata);
    if (payload == null) {
      continue;
    }
    findings.add((message: msg, payload: payload));
  }
  findings.sort((a, b) {
    final pv = _priorityOrder(
      b.payload.priority,
    ).compareTo(_priorityOrder(a.payload.priority));
    if (pv != 0) {
      return pv;
    }
    final stv = _statusOrder(
      a.payload.status,
    ).compareTo(_statusOrder(b.payload.status));
    if (stv != 0) {
      return stv;
    }
    return a.message.createdAt.compareTo(b.message.createdAt);
  });
  return findings;
}

int _priorityOrder(ReviewNodePriority p) => switch (p) {
  ReviewNodePriority.p0 => 4,
  ReviewNodePriority.p1 => 3,
  ReviewNodePriority.p2 => 2,
  ReviewNodePriority.p3 => 1,
};

int _statusOrder(ReviewNodeStatus s) => switch (s) {
  ReviewNodeStatus.open => 4,
  ReviewNodeStatus.consensusReady => 3,
  ReviewNodeStatus.resolved => 2,
  ReviewNodeStatus.dismissed => 1,
};

/// Builds the visual decoration (icon, accent color, short label) for a
/// review finding, derived from its [kind] and [priority].
ReviewItemDecor reviewItemDecor(
  BuildContext context,
  ReviewNodeKind kind,
  ReviewNodePriority priority,
) {
  final tokens = context.designSystem!;
  final accent = _kindAccent(tokens, kind, priority);
  return switch (kind) {
    ReviewNodeKind.bug => ReviewItemDecor(
      icon: AppIcons.bug,
      accent: accent,
      label: AppLocalizations.of(context).bugLabel,
    ),
    ReviewNodeKind.suggestion => ReviewItemDecor(
      icon: AppIcons.lightbulb,
      accent: accent,
      label: AppLocalizations.of(context).suggestLabel,
    ),
    ReviewNodeKind.recommendation => ReviewItemDecor(
      icon: AppIcons.star,
      accent: accent,
      label: AppLocalizations.of(context).recommendLabel,
    ),
    ReviewNodeKind.question => ReviewItemDecor(
      icon: AppIcons.circleHelp,
      accent: accent,
      label: AppLocalizations.of(context).questionLabel,
    ),
    ReviewNodeKind.ticket => ReviewItemDecor(
      icon: AppIcons.ticket,
      accent: tokens.fgBrandPrimary,
      label: AppLocalizations.of(context).ticketLabel,
    ),
  };
}

/// Icon glyph that visually represents a [ReviewNodePriority].
IconData reviewPriorityIcon(ReviewNodePriority p) => switch (p) {
  ReviewNodePriority.p0 => AppIcons.octagonAlert,
  ReviewNodePriority.p1 => AppIcons.triangleAlert,
  ReviewNodePriority.p2 => AppIcons.info,
  ReviewNodePriority.p3 => AppIcons.sparkles,
};

/// Color that visually represents a [ReviewNodePriority] using the design-system tokens.
Color reviewPriorityColor(ReviewNodePriority priority, BuildContext context) {
  final tokens = context.designSystem!;
  return switch (priority) {
    ReviewNodePriority.p0 => tokens.fgErrorPrimary,
    ReviewNodePriority.p1 => tokens.fgWarningPrimary,
    ReviewNodePriority.p2 => tokens.fgBrandPrimary,
    ReviewNodePriority.p3 => tokens.textTertiary,
  };
}

/// The design-system tint a finding's status pill carries.
///
/// `open` is deliberately NEUTRAL rather than warning-tinted: it is the state
/// every finding starts in, so tinting it would flood a fifty-row review with
/// amber and spend the accent on the default case. What was there before was
/// worse than either — the pill drew `borderSecondary` text on a 12%-alpha wash
/// of the same color, so "Open" was effectively invisible (well under the 4.5:1
/// floor) on every finding in the list.
CcBadgeVariant reviewStatusVariant(ReviewNodeStatus? status) =>
    switch (status) {
      ReviewNodeStatus.resolved => CcBadgeVariant.success,
      ReviewNodeStatus.consensusReady => CcBadgeVariant.info,
      ReviewNodeStatus.dismissed => CcBadgeVariant.neutral,
      _ => CcBadgeVariant.neutral,
    };

/// The glyph a finding's status pill carries.
///
/// Tint alone cannot separate `open` from `dismissed` — both are neutral — so
/// the shape is what tells them apart in greyscale and for a colorblind reader.
IconData reviewStatusIcon(ReviewNodeStatus? status) => switch (status) {
  ReviewNodeStatus.resolved => AppIcons.check,
  ReviewNodeStatus.consensusReady => AppIcons.checkCheck,
  ReviewNodeStatus.dismissed => AppIcons.x,
  _ => AppIcons.circleDot,
};

/// The localized name of a finding's status.
String reviewStatusLabel(BuildContext context, ReviewNodeStatus? status) {
  final l10n = AppLocalizations.of(context);
  return switch (status) {
    ReviewNodeStatus.resolved => l10n.resolved,
    ReviewNodeStatus.consensusReady => l10n.consensus,
    ReviewNodeStatus.dismissed => l10n.dismissed,
    _ => l10n.openStatus,
  };
}

/// How far a settled finding recedes.
///
/// It stays in the list — hiding it would make the counts disagree with what is
/// on screen — but it stops competing with the work that is left. Kept above
/// the old 0.4/0.65 pair, which pushed body text under the contrast floor;
/// these match the findings rail's own dimming.
double reviewSettledOpacity(ReviewNodeStatus? status) => switch (status) {
  ReviewNodeStatus.dismissed => 0.55,
  ReviewNodeStatus.resolved => 0.75,
  _ => 1,
};

/// The finding's headline: the first line of its body, stripped of the markdown
/// that would otherwise show up as literal `##` and `**` in a one-line row.
///
/// A row that carries only `BUG · P1 · 85% · path` tells a reader nothing about
/// what the finding IS, which is what turned a list of nine into nine identical
/// rows. Returns an empty string when there is no body to summarize; callers
/// fall back to the anchor.
String reviewFindingSummary(String content) {
  for (final rawLine in content.split('\n')) {
    final line = rawLine
        .replaceAll(RegExp(r'^\s*#{1,6}\s*'), '')
        .replaceAll(RegExp(r'^\s*[-*+]\s+'), '')
        .replaceAll(RegExp(r'[*_`]'), '')
        .trim();
    if (line.isNotEmpty) {
      return line;
    }
  }
  return '';
}

Color _kindAccent(
  DesignSystemTokens tokens,
  ReviewNodeKind kind,
  ReviewNodePriority priority,
) {
  return switch (priority) {
    ReviewNodePriority.p0 => tokens.fgErrorPrimary,
    ReviewNodePriority.p1 => tokens.fgWarningPrimary,
    ReviewNodePriority.p2 =>
      kind == ReviewNodeKind.bug
          ? tokens.fgErrorPrimary
          : tokens.fgBrandPrimary,
    ReviewNodePriority.p3 => tokens.textTertiary,
  };
}
