import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:test/test.dart';

void main() {
  final epoch = DateTime.utc(2026, 8, 18, 12);

  Rig rig({
    RigStatus status = const RigReady(),
    Principal? controller,
    DateTime? lastActivityAt,
    Duration ttl = const Duration(hours: 2),
    Duration idleTimeout = const Duration(minutes: 15),
    String workspaceId = 'ws1',
  }) => Rig(
    id: 'rig1',
    workspaceId: workspaceId,
    surface: RigSurface.computer,
    backend: EnclosureBackend.qemuHvf,
    status: status,
    spec: RigSpec(
      surface: RigSurface.computer,
      ttl: ttl,
      idleTimeout: idleTimeout,
    ),
    createdBy: const AgentPrincipal('agent1'),
    agentId: 'agent1',
    controller: controller,
    createdAt: epoch,
    lastActivityAt: lastActivityAt ?? epoch,
  );

  group('workspace ownership', () {
    test('a rig cannot exist without a workspace', () {
      // Isolation is structural everywhere else in this app; a workspace-less
      // rig would have nowhere to be written and nobody allowed to watch it.
      expect(
        () => Rig(
          id: 'r',
          workspaceId: '',
          surface: RigSurface.computer,
          backend: EnclosureBackend.qemuHvf,
          status: const RigReady(),
          spec: RigSpec(surface: RigSurface.computer),
          createdBy: const AgentPrincipal('a'),
          createdAt: epoch,
          lastActivityAt: epoch,
        ),
        throwsArgumentError,
      );
    });
  });

  group('take-over', () {
    test('an uncontrolled rig lets its agent act', () {
      expect(rig().agentMayAct, isTrue);
      expect(rig().isHumanControlled, isFalse);
    });

    test('a human hold suspends the agent', () {
      final held = rig(controller: const UserPrincipal('u1'));
      expect(held.isHumanControlled, isTrue);
      expect(
        held.agentMayAct,
        isFalse,
        reason:
            'Two actors typing into one machine produces input nobody meant.',
      );
    });

    test('an agent hold does not suspend agents', () {
      // The lock exists to arbitrate between a person and an agent; an agent
      // holding it is the ordinary case, not a take-over.
      final held = rig(controller: const AgentPrincipal('agent1'));
      expect(held.isHumanControlled, isFalse);
      expect(held.agentMayAct, isTrue);
    });

    test('releasing clears the hold and its timestamp', () {
      final held = rig(controller: const UserPrincipal('u1')).copyWith(
        controlHeldSince: epoch,
      );
      final released = held.releaseControl();
      expect(released.controller, isNull);
      expect(released.controlHeldSince, isNull);
    });

    test('copyWith cannot clear a controller', () {
      // Documented asymmetry: passing null to copyWith means "unchanged", so
      // releasing has its own method rather than a null that silently no-ops.
      final held = rig(controller: const UserPrincipal('u1'));
      expect(held.copyWith().controller, isNotNull);
    });
  });

  group('lifetime', () {
    test('the hard TTL is measured from creation, not from activity', () {
      final busy = rig(
        ttl: const Duration(hours: 1),
        lastActivityAt: epoch.add(const Duration(minutes: 59)),
      );
      expect(
        busy.isExpired(epoch.add(const Duration(hours: 1, minutes: 1))),
        isTrue,
        reason:
            'A guest that could extend its own life by staying busy would not '
            'be ephemeral.',
      );
    });

    test('idle is measured from the last action', () {
      final quiet = rig(idleTimeout: const Duration(minutes: 15));
      expect(quiet.isIdle(epoch.add(const Duration(minutes: 10))), isFalse);
      expect(quiet.isIdle(epoch.add(const Duration(minutes: 20))), isTrue);
    });
  });

  group('status', () {
    test('live phases are the ones still holding a machine', () {
      expect(const RigReady().isLive, isTrue);
      expect(const RigParked().isLive, isTrue);
      expect(const RigProvisioning(step: 'x').isLive, isFalse);
      expect(const RigClosed(RigCloseReason.requested).isLive, isFalse);
      expect(const RigFailed('x').isLive, isFalse);
    });

    test('a status round-trips through storage', () {
      for (final status in <RigStatus>[
        const RigProvisioning(step: 'Creating the disk overlay'),
        const RigReady(),
        const RigParked(),
        const RigClosing(),
        const RigClosed(RigCloseReason.idleTimeout),
        const RigFailed('qemu exited immediately'),
      ]) {
        final restored = RigStatus.fromStorage(
          phase: status.phase.wire,
          detail: status.detail,
          closeReason: status.closeReason?.wire,
        );
        expect(restored, status);
      }
    });

    test('an unreadable phase reads as failed, never as running', () {
      // A row written by a newer build must still be readable enough to
      // close, and a machine whose state we cannot read is not one to report
      // as ready.
      final restored = RigStatus.fromStorage(phase: 'quantum');
      expect(restored, isA<RigFailed>());
      expect(restored.isLive, isFalse);
    });
  });

  group('spec', () {
    test('an exec rig is lean and long-lived', () {
      final spec = RigSpec.exec(conversationId: 'c1');
      expect(spec.memoryMb, lessThanOrEqualTo(512));
      expect(
        spec.idleTimeout,
        greaterThan(const Duration(minutes: 15)),
        reason:
            'A person staring at a shell is still using it while typing '
            'nothing.',
      );
    });

    test('a desktop rig gets real headroom', () {
      // 512 MB suits a shell and OOMs Chromium on the first heavy page — and
      // an OOM inside a rig reads to the agent as "the site is broken".
      expect(RigSpec(surface: RigSurface.browser).memoryMb, greaterThan(1024));
      expect(RigSpec(surface: RigSurface.computer).memoryMb, greaterThan(1024));
    });

    test('an empty egress allowlist means nothing, not everything', () {
      expect(RigSpec(surface: RigSurface.computer).egressAllowlist, isEmpty);
    });

    test('a spec round-trips through JSON', () {
      final spec = RigSpec(
        surface: RigSurface.browser,
        egressAllowlist: const ['example.com', '*.github.com'],
        memoryMb: 3072,
        cpuCount: 4,
        ttl: const Duration(hours: 3),
        conversationId: 'c1',
      );
      final restored = RigSpec.fromJson(spec.toJson());
      expect(restored.surface, spec.surface);
      expect(restored.egressAllowlist, spec.egressAllowlist);
      expect(restored.memoryMb, spec.memoryMb);
      expect(restored.cpuCount, spec.cpuCount);
      expect(restored.ttl, spec.ttl);
      expect(restored.conversationId, spec.conversationId);
    });

    test('an unknown surface is an error, not a default', () {
      // There is no sensible default for "which machine did you want".
      expect(
        () => RigSpec.fromJson({'surface': 'hologram'}),
        throwsArgumentError,
      );
    });

    test('an exec spec names the shell image explicitly', () {
      // Two images serve the `computer` surface and they are NOT
      // interchangeable: the exec one has no display server. Leaving the
      // choice to "the default for this surface" is how `computer_use` ends
      // up driving a machine with no screen.
      final exec = RigSpec.exec(conversationId: 'c1');
      expect(exec.imageId, RigSpec.execImageId);
      expect(exec.isExec, isTrue);
    });

    test('an interactive spec is not an exec spec', () {
      expect(RigSpec(surface: RigSurface.computer).isExec, isFalse);
      expect(RigSpec(surface: RigSurface.browser).isExec, isFalse);
    });

    test('isExec survives a JSON round trip', () {
      // Reuse matching reads this off a rehydrated spec, so losing it here
      // would silently let a terminal VM be handed to `computer_use`.
      final restored = RigSpec.fromJson(
        RigSpec.exec(conversationId: 'c1').toJson(),
      );
      expect(restored.isExec, isTrue);
    });

    test('an undersized guest is refused', () {
      expect(
        () => RigSpec(surface: RigSurface.computer, memoryMb: 16),
        throwsArgumentError,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Value semantics. Every one of these had a real consequence: `Rig.==`
  // compared a SUBSET of fields and the watch stream is de-duplicated with
  // `distinctUntilChanged`, so a change to any omitted field never reached a
  // viewer at all.
  // ---------------------------------------------------------------------------
  group('Rig equality', () {
    test('two identical rigs are equal', () {
      expect(rig(), rig());
      expect(rig().hashCode, rig().hashCode);
    });

    test('a workerId-only change is NOT equal', () {
      // The subset comparison dropped this one, so a rig being picked up by a
      // fleet worker was a status change no client ever saw.
      expect(rig().copyWith(workerId: 'w1'), isNot(rig()));
    });

    test('a readyAt-only change is NOT equal', () {
      expect(rig().copyWith(readyAt: epoch), isNot(rig()));
    });

    test('a closedAt-only change is NOT equal', () {
      expect(rig().copyWith(closedAt: epoch), isNot(rig()));
    });

    test('a controlHeldSince-only change is NOT equal', () {
      expect(rig().copyWith(controlHeldSince: epoch), isNot(rig()));
    });
  });

  group('Rig.copyWith clearing', () {
    test('clearWorkerId unsets a worker', () {
      final assigned = rig().copyWith(workerId: 'w1');
      expect(assigned.workerId, 'w1');
      expect(assigned.copyWith(clearWorkerId: true).workerId, isNull);
    });

    test('clearCurrentUrl unsets the browser URL', () {
      final navigated = rig().copyWith(currentUrl: 'https://example.test');
      expect(navigated.copyWith(clearCurrentUrl: true).currentUrl, isNull);
    });

    test('clearReadyAt and clearClosedAt unset their timestamps', () {
      final stamped = rig().copyWith(readyAt: epoch, closedAt: epoch);
      final cleared = stamped.copyWith(clearReadyAt: true, clearClosedAt: true);
      expect(cleared.readyAt, isNull);
      expect(cleared.closedAt, isNull);
    });

    test('a plain copyWith still carries the old value through', () {
      final assigned = rig().copyWith(workerId: 'w1');
      expect(assigned.copyWith(status: const RigClosing()).workerId, 'w1');
    });
  });

  group('RigSpec equality', () {
    test('identical specs are equal', () {
      final a = RigSpec(surface: RigSurface.browser);
      final b = RigSpec(surface: RigSurface.browser);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different egress allowlist is NOT equal', () {
      // The one field where a missed comparison is a security question.
      expect(
        RigSpec(surface: RigSurface.browser, egressAllowlist: const ['a.test']),
        isNot(
          RigSpec(
            surface: RigSurface.browser,
            egressAllowlist: const ['b.test'],
          ),
        ),
      );
    });

    test('allowlist ORDER matters', () {
      // Each entry is interpolated into a command line in order, so two orders
      // are two command lines.
      expect(
        RigSpec(
          surface: RigSurface.browser,
          egressAllowlist: const ['a.test', 'b.test'],
        ),
        isNot(
          RigSpec(
            surface: RigSurface.browser,
            egressAllowlist: const ['b.test', 'a.test'],
          ),
        ),
      );
    });

    test('a different memory envelope is NOT equal', () {
      expect(
        RigSpec(surface: RigSurface.browser, memoryMb: 1024),
        isNot(RigSpec(surface: RigSurface.browser, memoryMb: 2048)),
      );
    });
  });
}
