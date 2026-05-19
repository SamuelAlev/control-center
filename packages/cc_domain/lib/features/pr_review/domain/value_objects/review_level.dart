// How deep an AI review goes, and how much of what it finds is reported
// front-and-centre.
//
// The level is a workspace policy with a per-run override. It moves two dials
// at once — which reviewers fan out (enforced by the pipeline template's
// `runWhen` gates, not by prompt wording) and where sub-threshold findings are
// rendered (enforced by the finalizer). Neither dial ever deletes a finding:
// a level that reports less files exactly as much and groups the remainder.

import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';

/// The `workspace_settings` key holding a workspace's default [ReviewLevel].
///
/// Defined once, here, because the server resolves it and the client writes
/// it — a second copy of the literal is how the two ends silently stop
/// agreeing about which row they are reading.
const String kReviewLevelSettingKey = 'review_level';

/// The state key the pipeline carries its resolved level under.
const String kReviewLevelStateKey = 'review_level';

/// The state key holding the level's reporting guidance for reviewer prompts.
const String kReviewLevelBriefStateKey = 'review_level_reporting_brief';

/// How thorough an AI review should be.
enum ReviewLevel {
  /// One reviewer, and only what materially matters.
  light,

  /// The standing three-reviewer pass. The default, and what every review ran
  /// as before levels existed.
  balanced,

  /// Every reviewer including the security and performance specialists, and
  /// nothing demoted.
  thorough;

  /// The stable wire/storage name.
  String get wireName => name;

  /// Parses a wire name (case-insensitive), or null when unrecognized.
  ///
  /// Null rather than a default so a caller validating client input can reject
  /// a bad value loudly; callers resolving stored state use
  /// `fromWire(x) ?? defaultLevel`.
  static ReviewLevel? fromWire(String? name) {
    if (name == null) {
      return null;
    }
    final lower = name.trim().toLowerCase();
    for (final l in ReviewLevel.values) {
      if (l.wireName == lower) {
        return l;
      }
    }
    return null;
  }

  /// The level a review runs at when nothing says otherwise.
  ///
  /// Load-bearing: every path that cannot name a level — a run started before
  /// levels shipped, a manual run off the pipeline canvas, an event trigger, a
  /// workspace that never opened settings — resolves here, and resolving to
  /// [balanced] is what makes those paths behave exactly as they did.
  static const ReviewLevel defaultLevel = ReviewLevel.balanced;

  /// This level's behavioural profile.
  ReviewLevelProfile get profile => ReviewLevelProfile.of(this);
}

/// What a [ReviewLevel] actually does.
///
/// Split out of the enum for the same reason `Mode` keeps its policy in
/// `ModeCapabilityProfile`: the enum is the key a workspace stores, and the
/// behaviour behind it should be editable without migrating stored values.
class ReviewLevelProfile {
  /// Creates a [ReviewLevelProfile].
  const ReviewLevelProfile({
    required this.level,
    required this.nitpickFloor,
    required this.confidenceFloor,
    required this.reportingBrief,
  });

  /// The level this profile describes.
  final ReviewLevel level;

  /// The least severe finding this level still reports up front. Anything
  /// below it is demoted into the collapsed nitpick group — still filed, still
  /// stored, still counted, just not in the reader's way. Null demotes nothing.
  ///
  /// Never applies to [ReviewFindingSeverity.critical] or
  /// [ReviewFindingSeverity.major]: the verdict is computed from those, so a
  /// reporting dial that could hide them would be a reporting dial that
  /// changes whether a PR ships.
  final ReviewFindingSeverity? nitpickFloor;

  /// The reviewer's self-assessed confidence a finding must reach to be
  /// reported up front. Below it the finding is demoted, never dropped.
  ///
  /// A confidence field that nothing reads is a field the reviewer learns to
  /// fill in carelessly. Gating on it is what makes it mean something — and a
  /// low-confidence finding is the single most expensive kind, because one
  /// wrong call teaches the reader to skim the next ten.
  ///
  /// Exempt for the same reason as [nitpickFloor]: a critical or major finding
  /// is reported whatever the reviewer thought of its odds. "I am only 40% sure
  /// this leaks credentials" is still worth a human's minute.
  final double confidenceFloor;

  /// Guidance appended to every reviewer prompt at this level. Shapes what the
  /// reviewer bothers to write up; it is not the enforcement — [nitpickFloor]
  /// and [confidenceFloor] are, and they run server-side after the fact.
  final String reportingBrief;

  /// Whether a finding of [severity] held with [confidence] should be demoted
  /// at this level.
  ///
  /// [confidence] defaults to 1.0 so a caller asking purely about severity
  /// gets the severity answer.
  bool demotes(ReviewFindingSeverity severity, {double confidence = 1.0}) {
    // Critical and major are never demoted at any level, on either axis — see
    // [nitpickFloor] and [confidenceFloor].
    if (severity == ReviewFindingSeverity.critical ||
        severity == ReviewFindingSeverity.major) {
      return false;
    }
    if (confidence < confidenceFloor) {
      return true;
    }
    final floor = nitpickFloor;
    if (floor == null) {
      return false;
    }
    return !severity.atLeast(floor);
  }

  /// The profile for [level].
  static ReviewLevelProfile of(ReviewLevel level) => switch (level) {
    ReviewLevel.light => const ReviewLevelProfile(
      level: ReviewLevel.light,
      nitpickFloor: ReviewFindingSeverity.major,
      confidenceFloor: 0.8,
      reportingBrief:
          '\n\nReporting level: LIGHT. Report only what materially matters — '
          'correctness, security, data loss and reliability. Prefer no finding '
          'to a weak one. Minor and cosmetic observations are still worth '
          'filing when you are confident, but they will be grouped away from '
          'the main report, so do not spend the review on them.',
    ),
    ReviewLevel.balanced => const ReviewLevelProfile(
      level: ReviewLevel.balanced,
      nitpickFloor: ReviewFindingSeverity.minor,
      confidenceFloor: 0.7,
      reportingBrief:
          '\n\nReporting level: BALANCED. Report the issues that a careful '
          'reviewer would raise: bugs, risks and design problems, plus minor '
          'issues worth fixing. Skip pure style preferences the repo does not '
          'enforce.',
    ),
    ReviewLevel.thorough => const ReviewLevelProfile(
      level: ReviewLevel.thorough,
      nitpickFloor: null,
      confidenceFloor: 0.5,
      reportingBrief:
          '\n\nReporting level: THOROUGH. Report everything you find, down to '
          'polish, naming and consistency with surrounding code. Nothing is '
          'grouped away at this level, so keep each finding short and make the '
          'severity honest — an inflated severity is worse than a low one.',
    ),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewLevelProfile &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          nitpickFloor == other.nitpickFloor &&
          confidenceFloor == other.confidenceFloor &&
          reportingBrief == other.reportingBrief;

  @override
  int get hashCode =>
      Object.hash(level, nitpickFloor, confidenceFloor, reportingBrief);
}
