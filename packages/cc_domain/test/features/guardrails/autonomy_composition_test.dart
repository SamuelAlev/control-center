import 'package:cc_domain/features/guardrails/domain/services/autonomy_composition.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:test/test.dart';

/// The action policy's deny and ask-first decisions remain authoritative
/// regardless of the space's autonomy setting.
void main() {
  const composition = AutonomyComposition();

  group('THE SAFETY FLOOR: a hard deny survives every autonomy level', () {
    test('deny is refused at every level, including actFreely', () {
      for (final level in [null, ...AutonomyLevel.values]) {
        expect(
          composition.compose(decision: ActionDecision.deny, autonomy: level),
          AutonomyOutcome.deny,
          reason:
              'a deny rule must survive autonomy '
              '${level?.wire ?? "(unset)"} — if this ever fails, the '
              'product no longer has a safety floor to describe',
        );
      }
    });

    test('deny survives even an action the dial would not otherwise gate', () {
      expect(
        composition.compose(
          decision: ActionDecision.deny,
          autonomy: AutonomyLevel.actFreely,
          isGated: false,
        ),
        AutonomyOutcome.deny,
      );
    });
  });

  group('actFreely', () {
    test('cannot pre-approve an action-policy prompt', () {
      expect(
        composition.compose(
          decision: ActionDecision.prompt,
          autonomy: AutonomyLevel.actFreely,
        ),
        AutonomyOutcome.prompt,
      );
    });

    test('allows an allow', () {
      expect(
        composition.compose(
          decision: ActionDecision.allow,
          autonomy: AutonomyLevel.actFreely,
        ),
        AutonomyOutcome.allow,
      );
    });
  });

  group('proposeOnly', () {
    test('refuses every gated action, whatever policy said', () {
      for (final decision in ActionDecision.values) {
        expect(
          composition.compose(
            decision: decision,
            autonomy: AutonomyLevel.proposeOnly,
          ),
          AutonomyOutcome.deny,
        );
      }
    });

    test('does not block an ungated action (a mode\'s own output verb)', () {
      expect(
        composition.compose(
          decision: ActionDecision.allow,
          autonomy: AutonomyLevel.proposeOnly,
          isGated: false,
        ),
        AutonomyOutcome.allow,
      );
    });
  });

  group('actWithApproval is the default', () {
    test('unset behaves exactly as actWithApproval', () {
      for (final decision in ActionDecision.values) {
        expect(
          composition.compose(decision: decision),
          composition.compose(
            decision: decision,
            autonomy: AutonomyLevel.actWithApproval,
          ),
        );
      }
    });

    test('a prompt asks; an allow proceeds', () {
      expect(
        composition.compose(
          decision: ActionDecision.prompt,
          autonomy: AutonomyLevel.actWithApproval,
        ),
        AutonomyOutcome.prompt,
      );
      expect(
        composition.compose(
          decision: ActionDecision.allow,
          autonomy: AutonomyLevel.actWithApproval,
        ),
        AutonomyOutcome.allow,
      );
    });
  });
}
