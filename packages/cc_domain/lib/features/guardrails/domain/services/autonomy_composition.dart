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
/// An action-policy `deny` or `prompt` is authoritative at every autonomy
/// level: `actFreely` may only spare an independent approval when policy
/// already allows the action. `proposeOnly` refuses otherwise gated actions.
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
    // Policy is the floor: a space's autonomy cannot silently authorize an
    // action the operator configured to require confirmation.
    if (decision == ActionDecision.deny) {
      return AutonomyOutcome.deny;
    }
    if (autonomy == AutonomyLevel.proposeOnly && isGated) {
      return AutonomyOutcome.deny;
    }
    if (decision == ActionDecision.prompt) {
      return AutonomyOutcome.prompt;
    }
    return AutonomyOutcome.allow;
  }
}
