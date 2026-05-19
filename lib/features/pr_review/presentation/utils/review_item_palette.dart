import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';

/// Visual decoration for a review finding (icon, accent color, label).
class ReviewItemDecor {
  /// Creates a [ReviewItemDecor] with required icon, accent color, and label.
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

/// A review finding extracted from a channel message.
typedef ReviewFinding = ({ChannelMessage message, ReviewNodePayload payload});

/// Parses review findings from channel messages and sorts by priority, status, and creation time.
List<ReviewFinding> parseAndSortFindings(List<ChannelMessage> messages) {
  final findings = <ReviewFinding>[];
  for (final msg in messages) {
    if (msg.messageType != ChannelMessageType.reviewNode) {
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

/// Color of the small status indicator ring drawn next to a finding's label.
Color reviewStatusRingColor(ReviewNodeStatus? status, BuildContext context) {
  final tokens = context.designSystem!;
  return switch (status) {
    ReviewNodeStatus.consensusReady => tokens.fgBrandPrimary,
    ReviewNodeStatus.dismissed => tokens.textTertiary,
    ReviewNodeStatus.resolved => tokens.textTertiary.withValues(alpha: 0.5),
    _ => tokens.borderSecondary,
  };
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
