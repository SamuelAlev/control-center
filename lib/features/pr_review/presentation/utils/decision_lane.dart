import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The decision lane a pull request falls into — the primary organizing axis of
/// the redesigned PR list. Unlike GitHub's open/closed state, lanes answer
/// "what, if anything, does this need from me right now?".
///
/// Membership is derived from signals we genuinely have on [PullRequest]
/// (draft, requested reviewers, the rolled-up checks status, diff size and
/// staleness) — never from agent telemetry we don't read per-PR. Each PR maps
/// to exactly one lane via [classifyDecisionLanes].
enum DecisionLane {
  /// Open, not draft, checks green, no pending requested reviewers, and not
  /// waiting on the operator — the closest honest signal to "ready to merge".
  ready,

  /// Open, not draft, and the operator is a requested reviewer.
  review,

  /// Open, not draft, checks pending or absent — still being worked.
  inProgress,

  /// Open, not draft, checks failing or the branch has gone stale.
  attention,

  /// A draft PR, not yet opened for review.
  draft,
}

/// How long a PR may sit untouched before it lands in [DecisionLane.attention].
const Duration kPrStaleThreshold = Duration(days: 14);

/// Classifies [pr] into one or more [DecisionLane]s.
///
/// A PR can belong to multiple lanes simultaneously (e.g. a PR with failing
/// checks that also requests the operator's review is both
/// [DecisionLane.attention] and [DecisionLane.review]).
///
/// [awaitingMe] is whether the current operator is among the PR's requested
/// reviewers. Draft PRs are always exclusive (only [DecisionLane.draft]).
Set<DecisionLane> classifyDecisionLanes(
  PullRequest pr, {
  required bool awaitingMe,
  Duration staleThreshold = kPrStaleThreshold,
}) {
  final lanes = <DecisionLane>{};

  if (pr.isDraft) {
    lanes.add(DecisionLane.draft);
    return lanes;
  }

  final isFailing = pr.checksStatus == PrChecksStatus.failing;
  final isStale = pr.isStale(staleThreshold);

  if (isFailing || isStale) {
    lanes.add(DecisionLane.attention);
  }

  if (awaitingMe) {
    lanes.add(DecisionLane.review);
  }

  final isReady =
      pr.mergeableState == PrMergeableState.clean ||
      ((pr.mergeableState == PrMergeableState.unknown ||
              pr.mergeableState == PrMergeableState.unrecognized) &&
          pr.requestedReviewers.isEmpty &&
          (pr.checksStatus == PrChecksStatus.passing ||
              pr.checksStatus == PrChecksStatus.none));
  if (isReady && !awaitingMe && pr.requestedReviewers.isEmpty) {
    lanes.add(DecisionLane.ready);
  }

  if (lanes.isEmpty) {
    lanes.add(DecisionLane.inProgress);
  }

  return lanes;
}

/// The single most urgent lane from a set of lanes, for display purposes
/// (row badge, primary action button).
///
/// Priority: attention > review > ready > inProgress > draft.
DecisionLane primaryLaneOf(Set<DecisionLane> lanes) {
  if (lanes.contains(DecisionLane.attention)) {
    return DecisionLane.attention;
  }
  if (lanes.contains(DecisionLane.review)) {
    return DecisionLane.review;
  }
  if (lanes.contains(DecisionLane.ready)) {
    return DecisionLane.ready;
  }
  if (lanes.contains(DecisionLane.inProgress)) {
    return DecisionLane.inProgress;
  }
  return DecisionLane.draft;
}

/// Resolved presentation for a [DecisionLane]: the accent [color] that tags the
/// lane everywhere (dot, row action), the soft [softColor] wash that fills the
/// card when the lane is the active filter, its sentence-case [label], and a
/// short [hint] describing the state. Colour is always paired with the label so
/// the lane survives grayscale and colour-blindness.
/// Resolved presentation for a [DecisionLane].
class DecisionLaneStyle {
  /// Creates a [DecisionLaneStyle].
  const DecisionLaneStyle({
    required this.color,
    required this.softColor,
    required this.label,
    required this.hint,
    required this.ringOnly,
  });

  /// The lane's accent colour (a status token, or [DesignSystemTokens.idle]).
  final Color color;

  /// A soft, low-opacity wash of [color] used to tint the card background when
  /// the lane is the active filter (replaces the former coloured left edge).
  final Color softColor;

  /// The lane's sentence-case label.
  final String label;

  /// A short description of what the lane means.
  final String hint;

  /// Whether the lane's dot renders as a hollow ring (used for the attention
  /// lane) to distinguish it from solid-dot lanes without relying on colour.
  final bool ringOnly;
}

/// Resolves the [DecisionLaneStyle] for [lane] from design tokens + l10n.
DecisionLaneStyle decisionLaneStyle(
  DecisionLane lane,
  DesignSystemTokens tokens,
  AppLocalizations l10n,
) {
  return switch (lane) {
    DecisionLane.ready => DecisionLaneStyle(
      color: tokens.success,
      softColor: tokens.successSoft,
      label: l10n.readyToMerge,
      hint: l10n.laneReadyHint,
      ringOnly: false,
    ),
    DecisionLane.review => DecisionLaneStyle(
      color: tokens.accent,
      softColor: tokens.accentSoft,
      label: l10n.needsYourReview,
      hint: l10n.laneReviewHint,
      ringOnly: false,
    ),
    DecisionLane.inProgress => DecisionLaneStyle(
      color: tokens.success,
      softColor: tokens.successSoft,
      label: l10n.inProgress,
      hint: l10n.laneInProgressHint,
      ringOnly: false,
    ),
    DecisionLane.attention => DecisionLaneStyle(
      color: tokens.danger,
      softColor: tokens.dangerSoft,
      label: l10n.needsAttention,
      hint: l10n.laneAttentionHint,
      ringOnly: true,
    ),
    DecisionLane.draft => DecisionLaneStyle(
      color: tokens.idle,
      // No dedicated "idle soft" token; derive a neutral ink/near-white wash
      // at the same visual weight as the colour washes above.
      softColor: tokens.idle.withValues(alpha: 0.12),
      label: l10n.drafts,
      hint: l10n.laneDraftsHint,
      ringOnly: false,
    ),
  };
}

/// The lanes in display order, left to right.
const List<DecisionLane> kDecisionLanesInOrder = [
  DecisionLane.ready,
  DecisionLane.review,
  DecisionLane.inProgress,
  DecisionLane.attention,
  DecisionLane.draft,
];
