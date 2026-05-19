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

/// Composes the resolved policy decision with the space's autonomy dial.
///
/// Extracted as a pure rule because the most important property of this
/// product's safety story is a single line of it — **a hard `deny` survives
/// every autonomy level, including `actFreely`** — and a property that
/// matters that much should be a named, tested function rather than a
/// branch inside a 3,000-line dispatch session.
///
/// The three levels, stated plainly:
///
/// * `proposeOnly` — every gated action is refused. The agent may reason and
///   reply; it may not act.
/// * `actWithApproval` (and unset) — the fail-closed approval gate: `prompt`
///   asks a human, and with nobody to ask it denies.
/// * `actFreely` — pre-approves anything that did not resolve to `deny`. A
///   `prompt` is **not** escalated: it is allowed and no one is asked. That
///   is a deliberate grant of autonomy rather than a convenience setting,
///   which is exactly why the deny floor beneath it has to be absolute.
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
