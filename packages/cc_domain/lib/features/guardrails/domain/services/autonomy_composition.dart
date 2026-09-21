import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';

/// What a chokepoint should DO once policy and the autonomy dial are combined.
enum AutonomyOutcome {
  /// Proceed without asking.
  allow,

  /// Ask the operator (fail-closed when nobody can be asked).
  prompt,

  /// Refuse, terminally.
  deny,
}

/// Composes the policy decision with the space autonomy dial.
///
/// Hard `deny` survives every level including `actFreely`. `proposeOnly`:
/// refuse gated actions. `actWithApproval`/unset: `prompt` asks or denies.
/// `actFreely`: allow non-deny (including `prompt`) without asking.
class AutonomyComposition {
  /// Creates an [AutonomyComposition].
  const AutonomyComposition();

  /// Combines [decision] with [autonomy] (null = the default,
  /// [AutonomyLevel.actWithApproval]).
  ///
  /// [isGated] is whether this action is subject to the dial at all — a
  /// mode's own pinned output verbs and the user-interaction tools are not.
  AutonomyOutcome compose({
    required ActionDecision decision,
    AutonomyLevel? autonomy,
    bool isGated = true,
  }) {
    // A hard deny is the floor. It is checked FIRST and returns immediately,
    // so no autonomy level — present or future — can be written in a way that
    // reaches past it.
    if (decision == ActionDecision.deny) {
      return AutonomyOutcome.deny;
    }
    if (!isGated) {
      return AutonomyOutcome.allow;
    }
    final level = autonomy ?? AutonomyLevel.actWithApproval;
    return switch (level) {
      AutonomyLevel.proposeOnly => AutonomyOutcome.deny,
      AutonomyLevel.actFreely => AutonomyOutcome.allow,
      AutonomyLevel.actWithApproval => switch (decision) {
        ActionDecision.allow => AutonomyOutcome.allow,
        ActionDecision.prompt => AutonomyOutcome.prompt,
        ActionDecision.deny => AutonomyOutcome.deny,
      },
    };
  }
}
