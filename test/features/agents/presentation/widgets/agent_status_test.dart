import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_status.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the status-dot colour contract for a run: green when it succeeded, red
/// when it failed, grey while queued, accent while running.
///
/// Asserted against the token set rather than raw hex so a palette change moves
/// both sides together, and in both brightnesses so neither theme silently loses
/// the distinction.
void main() {
  final l10n = AppLocalizationsEn();

  for (final (name, tokens) in [
    ('light', DesignSystemTokens.light()),
    ('dark', DesignSystemTokens.dark()),
  ]) {
    group('AgentStatusVisual.resolve ($name)', () {
      AgentStatusVisual resolve(AgentLiveState state) =>
          AgentStatusVisual.resolve(state, tokens, l10n);

      test('a succeeded run is green', () {
        final visual = resolve(AgentLiveState.succeeded);
        expect(visual.dotColor, tokens.fgSuccessSecondary);
        expect(visual.label, 'Succeeded');
        expect(
          visual.isLive,
          isFalse,
          reason: 'a finished run must not breathe like a live one',
        );
        expect(
          visual.icon,
          isNotNull,
          reason: 'green-vs-red cannot be colour-alone (DESIGN.md status rule)',
        );
      });

      test('a failed run is red', () {
        final visual = resolve(AgentLiveState.failed);
        expect(visual.dotColor, tokens.fgErrorSecondary);
        expect(visual.label, 'Failed');
        expect(visual.isLive, isFalse);
        expect(visual.icon, isNotNull);
      });

      test('a queued run is neutral grey and does not breathe', () {
        final visual = resolve(AgentLiveState.queued);
        expect(visual.dotColor, tokens.fgQuaternary);
        expect(visual.label, 'Queued');
        expect(
          visual.isLive,
          isFalse,
          reason: 'a breathing dot would claim work is in flight',
        );
      });

      test('a running run is the accent and breathes', () {
        final visual = resolve(AgentLiveState.running);
        expect(visual.dotColor, tokens.fgBrandPrimary);
        expect(visual.label, 'Running');
        expect(visual.isLive, isTrue);
      });

      test('succeeded is visually distinct from queued and from running', () {
        // The point of the change: a finished subagent used to share idle's grey,
        // so "done" and "nothing happening" looked identical.
        final succeeded = resolve(AgentLiveState.succeeded).dotColor;
        expect(succeeded, isNot(resolve(AgentLiveState.queued).dotColor));
        expect(succeeded, isNot(resolve(AgentLiveState.idle).dotColor));
        expect(succeeded, isNot(resolve(AgentLiveState.running).dotColor));
        expect(succeeded, isNot(resolve(AgentLiveState.failed).dotColor));
      });

      test('idle stays neutral — only a RUN turns green', () {
        // `idle` is the roster's "this agent has nothing in flight"; recolouring
        // it would turn every idle agent green.
        expect(resolve(AgentLiveState.idle).dotColor, tokens.fgQuaternary);
      });

      test('every state resolves a non-empty label', () {
        for (final state in AgentLiveState.values) {
          expect(
            resolve(state).label,
            isNotEmpty,
            reason: '$state must be nameable for screen readers',
          );
        }
      });
    });
  }
}
