import 'dart:async';

import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_host/cc_host.dart';
import 'package:test/test.dart';

RunCredentialBlockRequest _request({
  RunCredentialLane lane = RunCredentialLane.harness,
  RunCredentialReason reason = RunCredentialReason.noCredential,
  String? workspaceId = 'ws-1',
  String detail = '[harness] No credential for provider "anthropic".',
}) => RunCredentialBlockRequest(
  lane: lane,
  reason: reason,
  detail: detail,
  runLogId: 'run-1',
  providerId: 'anthropic',
  workspaceId: workspaceId,
  spaceId: 'space-1',
  agentName: 'Ada',
);

void main() {
  group('PendingCredentialBlockRegistry', () {
    test('resolves the run when the credential starts working', () async {
      var usable = false;
      final registry = PendingCredentialBlockRegistry(
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(registry.dispose);

      final parked = registry.register(_request(), recheck: () async => usable);
      expect(registry.snapshot, hasLength(1));

      usable = true;
      expect(await parked.outcome, RunCredentialOutcome.resolved);
      expect(
        registry.snapshot,
        isEmpty,
        reason: 'a resolved block leaves the pending list',
      );
    });

    test('nudge resolves without waiting for the next poll', () async {
      var usable = false;
      // An interval far longer than the test: only the nudge can finish this.
      final registry = PendingCredentialBlockRegistry(
        pollInterval: const Duration(minutes: 5),
      );
      addTearDown(registry.dispose);

      final parked = registry.register(_request(), recheck: () async => usable);
      usable = true;
      await registry.nudge();

      expect(await parked.outcome, RunCredentialOutcome.resolved);
    });

    test('cancel ends the run; retry only re-probes', () async {
      final registry = PendingCredentialBlockRegistry(
        pollInterval: const Duration(minutes: 5),
      );
      addTearDown(registry.dispose);

      // Nothing ever fixes it: the only ways out are the two answers.
      final parked = registry.register(_request(), recheck: () async => false);

      // A retry that finds nothing fixed is not a wrong answer — the run stays
      // parked and the operator can try again.
      expect(await registry.respond(parked.id, cancel: false), isTrue);
      expect(registry.snapshot, hasLength(1));

      expect(await registry.respond(parked.id, cancel: true), isTrue);
      expect(await parked.outcome, RunCredentialOutcome.cancelled);
      expect(registry.snapshot, isEmpty);
      expect(
        await registry.respond(parked.id, cancel: true),
        isFalse,
        reason: 'an already-resolved block is unknown',
      );
    });

    test('times out into the caller\'s own failure', () async {
      final registry = PendingCredentialBlockRegistry(
        deadline: const Duration(milliseconds: 20),
        pollInterval: const Duration(minutes: 5),
      );
      addTearDown(registry.dispose);

      final parked = registry.register(_request(), recheck: () async => false);
      expect(await parked.outcome, RunCredentialOutcome.timedOut);
      expect(registry.snapshot, isEmpty);
    });

    test('a throwing probe leaves the run parked, neither verdict', () async {
      var throwing = true;
      final registry = PendingCredentialBlockRegistry(
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(registry.dispose);

      final parked = registry.register(
        _request(),
        recheck: () async {
          if (throwing) {
            throw StateError('keychain locked');
          }
          return true;
        },
      );

      await registry.nudge();
      expect(
        registry.snapshot,
        hasLength(1),
        reason: 'a transient probe failure is not "still broken forever"',
      );

      throwing = false;
      expect(await parked.outcome, RunCredentialOutcome.resolved);
    });

    test(
      'the watch stream seeds a late subscriber with what is already parked',
      () async {
        final registry = PendingCredentialBlockRegistry(
          pollInterval: const Duration(minutes: 5),
        );
        addTearDown(registry.dispose);

        registry.register(_request(), recheck: () async => false);

        // Subscribing AFTER the block was raised — a desktop that reconnected
        // mid-wait. The plain `blocked` stream would sit silent until the next
        // change, which may be the deadline.
        final seeded = await registry.blockedWithSnapshot.first;
        expect(seeded, hasLength(1));
        expect(seeded.first.request.agentName, 'Ada');
      },
    );

    test('the wire shape carries what the dialog branches on', () {
      final registry = PendingCredentialBlockRegistry(
        deadline: const Duration(minutes: 15),
        pollInterval: const Duration(minutes: 5),
      );
      addTearDown(registry.dispose);

      registry.register(
        _request(
          lane: RunCredentialLane.claudeCode,
          reason: RunCredentialReason.planSpent,
        ),
        recheck: () async => false,
      );
      final wire = pendingCredentialBlockToWire(registry.snapshot.single);

      expect(wire['lane'], 'claude_code');
      expect(wire['reason'], 'plan_spent');
      expect(wire['workspace_id'], 'ws-1');
      expect(wire['expires_at'], isA<String>());
      // Round-trips through the DTO the client actually parses.
      final dto = RunCredentialBlockDto.fromJson(wire);
      expect(dto.lane, RunCredentialLane.claudeCode);
      expect(dto.reason, RunCredentialReason.planSpent);
      expect(dto.agentName, 'Ada');
      expect(dto.expiresAt, isNotNull);
    });

    test(
      'dispose fails every parked run open rather than hanging it',
      () async {
        final registry = PendingCredentialBlockRegistry(
          pollInterval: const Duration(minutes: 5),
        );
        final parked = registry.register(
          _request(),
          recheck: () async => false,
        );
        registry.dispose();
        expect(await parked.outcome, RunCredentialOutcome.timedOut);
      },
    );

    test('the gate port is the registry, with no timeout of its own', () async {
      var usable = false;
      final registry = PendingCredentialBlockRegistry(
        pollInterval: const Duration(milliseconds: 10),
      );
      addTearDown(registry.dispose);
      final gate = RemoteRunCredentialGate(registry);

      final outcome = gate.awaitCredentials(
        _request(),
        recheck: () async => usable,
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(registry.snapshot, hasLength(1));
      usable = true;
      expect(await outcome, RunCredentialOutcome.resolved);
    });
  });
}
