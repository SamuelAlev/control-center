import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:test/test.dart';

/// The predicates that decide whether an existing rig is reused.
///
/// These are one-line getters and they were both wrong in a way no
/// behavioural test noticed. Reuse keyed on `isLive` excluded `provisioning`,
/// so a model told "still starting, try again" booted another 2 GB VM on
/// every retry — a poll loop became a VM stampede that evicted its own
/// predecessors and never converged. That is why they are pinned here rather
/// than left as obvious.
void main() {
  group('holdsMachine', () {
    test('a booting rig already owns a machine', () {
      expect(
        RigPhase.provisioning.holdsMachine,
        isTrue,
        reason:
            'Reuse matches on this. If a boot does not count, every retry '
            'during the boot window starts another VM.',
      );
      expect(
        RigPhase.provisioning.isLive,
        isFalse,
        reason: 'It cannot accept actions yet — that is a separate question.',
      );
    });

    test('ready, parked and closing all hold a machine', () {
      expect(RigPhase.ready.holdsMachine, isTrue);
      expect(RigPhase.parked.holdsMachine, isTrue);
      expect(RigPhase.closing.holdsMachine, isTrue);
    });

    test('terminal phases hold nothing', () {
      expect(RigPhase.closed.holdsMachine, isFalse);
      expect(RigPhase.failed.holdsMachine, isFalse);
    });

    test('holdsMachine is strictly wider than isLive', () {
      for (final phase in RigPhase.values) {
        if (phase.isLive) {
          expect(
            phase.holdsMachine,
            isTrue,
            reason: 'A live rig must always count as holding a machine.',
          );
        }
      }
    });
  });

  group('exec vs interactive', () {
    test('an exec rig is never reused for a computer_use rig', () {
      // Both are the `computer` surface and can share a conversation, but the
      // exec image is a shell with no display server. Handing one to
      // `computer_use` gives an agent a machine it cannot see, and the
      // failure reads as a broken screenshot rather than the wrong machine.
      final exec = RigSpec.exec(conversationId: 'c1');
      final desktop = RigSpec(
        surface: RigSurface.computer,
        conversationId: 'c1',
      );
      expect(exec.surface, desktop.surface);
      expect(exec.conversationId, desktop.conversationId);
      expect(
        exec.isExec == desktop.isExec,
        isFalse,
        reason: 'This inequality is the whole thing keeping them apart.',
      );
    });
  });

  group('slots', () {
    test('the default machine and a slot are different machines', () {
      // The whole point: a person can open a second WebKit beside the first
      // to compare two things. Equal specs would be reused for one another
      // and the second tab would show the first machine.
      final primary = RigSpec(
        surface: RigSurface.browser,
        conversationId: 'c1',
      );
      final second = RigSpec(
        surface: RigSurface.browser,
        conversationId: 'c1',
        slotId: 's2',
      );
      expect(primary == second, isFalse);
      expect(primary.slotId, isNull);
      expect(second.slotId, 's2');
    });

    test('the slot survives a JSON round trip', () {
      // The spec is stored whole and rehydrated on restart; a slot lost there
      // turns every extra machine into a second claimant on the default one.
      final spec = RigSpec(
        surface: RigSurface.computer,
        conversationId: 'c1',
        slotId: 's3',
      );
      expect(RigSpec.fromJson(spec.toJson()).slotId, 's3');
    });

    test('a spec with no slot writes none', () {
      // A default machine must serialise exactly as it did before slots
      // existed, so an older reader keeps understanding it.
      final spec = RigSpec(surface: RigSurface.browser, conversationId: 'c1');
      expect(spec.toJson().containsKey('slotId'), isFalse);
      expect(RigSpec.fromJson(spec.toJson()).slotId, isNull);
    });

    test('a malformed slot is refused', () {
      expect(RigSpec.slotIdError('', RigSurface.browser), isNotNull);
      expect(RigSpec.slotIdError('a b', RigSurface.browser), isNotNull);
      expect(RigSpec.slotIdError('s' * 65, RigSurface.browser), isNotNull);
      expect(RigSpec.slotIdError('s2', RigSurface.browser), isNull);
      expect(
        () => RigSpec(surface: RigSurface.browser, slotId: '../etc'),
        throwsArgumentError,
      );
    });

    test('the mobile surface refuses a slot', () {
      // The Android emulator is the HOST's attached device: two mobile rigs
      // would drive one phone while claiming to be two machines.
      expect(RigSpec.slotIdError('s2', RigSurface.mobile), isNotNull);
      expect(RigSpec.slotIdError(null, RigSurface.mobile), isNull);
      expect(
        () => RigSpec(surface: RigSurface.mobile, slotId: 's2'),
        throwsArgumentError,
      );
    });
  });

  group('credentials', () {
    test('a rig grants nothing by default', () {
      // An enclosure does not get push rights because it exists. The broker
      // has nothing to mint under safeDefault and says so.
      final spec = RigSpec(surface: RigSurface.computer);
      expect(spec.capabilities.canPushToRepo, isFalse);
      expect(spec.capabilities.canCallGitHubApi, isFalse);
    });

    test('capabilities survive a JSON round trip', () {
      // The spec is stored whole and rehydrated before the broker is asked,
      // so losing this silently turns every in-VM `git push` into a 404.
      final spec = RigSpec.exec(
        conversationId: 'c1',
        capabilities: const AgentCapabilities(
          canPushToRepo: true,
          canCallGitHubApi: true,
        ),
        repoOwner: 'acme',
        repoName: 'widgets',
      );
      final restored = RigSpec.fromJson(spec.toJson());
      expect(restored.capabilities.canPushToRepo, isTrue);
      expect(restored.repoOwner, 'acme');
      expect(restored.repoName, 'widgets');
    });
  });
}
