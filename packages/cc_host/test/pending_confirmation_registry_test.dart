import 'dart:async';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_host/cc_host.dart';
import 'package:test/test.dart';

ConfirmationRequest _req({String spaceId = 'c1'}) => ConfirmationRequest(
  spaceId: spaceId,
  title: 'Push to main',
  detail: 'force-push',
  severity: ConfirmationSeverity.destructive,
  command: 'git push --force',
);

void main() {
  group('PendingConfirmationRegistry', () {
    test(
      'register publishes a pending entry and resolves on approve',
      () async {
        final registry = PendingConfirmationRegistry();
        addTearDown(registry.dispose);

        final reg = registry.register(_req());
        expect(registry.snapshot, hasLength(1));
        expect(registry.snapshot.single.id, reg.id);

        final done = reg.approved;
        expect(registry.respond(reg.id, approved: true), isTrue);
        expect(await done, isTrue);
        expect(registry.snapshot, isEmpty);
      },
    );

    test('respond deny resolves false', () async {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      final reg = registry.register(_req());
      registry.respond(reg.id, approved: false);
      expect(await reg.approved, isFalse);
    });

    test(
      'respond for an unknown/already-resolved id is a no-op false',
      () async {
        final registry = PendingConfirmationRegistry();
        addTearDown(registry.dispose);
        expect(registry.respond('bogus', approved: true), isFalse);
        final reg = registry.register(_req());
        expect(registry.respond(reg.id, approved: true), isTrue);
        expect(
          registry.respond(reg.id, approved: true),
          isFalse,
        ); // already resolved
      },
    );

    test(
      'with no timeout a request blocks until responded (never auto-denies)',
      () async {
        final registry = PendingConfirmationRegistry(); // default: no timeout
        addTearDown(registry.dispose);
        final reg = registry.register(_req());
        var resolved = false;
        unawaited(reg.approved.then((_) => resolved = true));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(resolved, isFalse, reason: 'must keep hanging with no approver');
        expect(registry.snapshot, hasLength(1));
        registry.respond(reg.id, approved: true);
        expect(await reg.approved, isTrue);
      },
    );

    test('timeout auto-denies an unresolved request', () async {
      final registry = PendingConfirmationRegistry(
        timeout: const Duration(milliseconds: 20),
      );
      addTearDown(registry.dispose);
      final reg = registry.register(_req());
      expect(await reg.approved, isFalse);
      expect(registry.snapshot, isEmpty);
    });

    test('cancel resolves the entry with the given value', () async {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      final reg = registry.register(_req());
      registry.cancel(reg.id, approved: true);
      expect(await reg.approved, isTrue);
      expect(registry.snapshot, isEmpty);
    });

    test('the pending stream emits a full snapshot on each change', () async {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      final snapshots = <List<PendingConfirmation>>[];
      final sub = registry.pending.listen(snapshots.add);
      // Skip the (possible) initial listener-broadcast; collect after register.
      final reg = registry.register(_req());
      registry.respond(reg.id, approved: true);
      // Allow broadcast stream delivery.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      final lengths = snapshots.map((s) => s.length).toList();
      expect(lengths, containsAll([1, 0]));
    });

    test('dispose denies and drops every still-pending request', () async {
      // A registry with a real timeout: two requests are registered and left
      // hanging, so dispose() must cancel their timers and resolve them false.
      final registry = PendingConfirmationRegistry(
        timeout: const Duration(minutes: 1),
      );
      final a = registry.register(_req());
      final b = registry.register(_req(spaceId: 'c2'));
      expect(registry.snapshot, hasLength(2));

      registry.dispose();
      // Both pending futures resolve to false (denied) and the registry empties.
      expect(await a.approved, isFalse);
      expect(await b.approved, isFalse);
      expect(registry.snapshot, isEmpty);
    });

    test('dispose is harmless on an already-empty registry', () {
      final registry = PendingConfirmationRegistry();
      registry.dispose();
      // Calling again must not throw.
      registry.dispose();
    });

    test('cancel on an unknown id is a silent no-op', () {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      registry.cancel('never-registered', approved: true); // no throw
      expect(registry.snapshot, isEmpty);
    });
  });

  group('pendingConfirmationToWire', () {
    test('serializes every field, including the command, as ISO-8601 UTC', () {
      final registry = PendingConfirmationRegistry(
        clock: () => DateTime.utc(2026, 7, 13, 9, 30),
      );
      addTearDown(registry.dispose);
      final reg = registry.register(_req());

      final wire = pendingConfirmationToWire(registry.snapshot.single);
      expect(wire['id'], reg.id);
      expect(wire['space_id'], 'c1');
      expect(wire['title'], 'Push to main');
      expect(wire['detail'], 'force-push');
      expect(wire['severity'], 'destructive');
      expect(wire['command'], 'git push --force');
      expect(wire['created_at'], '2026-07-13T09:30:00.000Z');
    });

    test('omits the command key when the request has none', () {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      const noCommand = ConfirmationRequest(
        spaceId: 'c1',
        title: 'Network egress',
        detail: 'allowlisted host',
        severity: ConfirmationSeverity.info,
      );
      registry.register(noCommand);
      final wire = pendingConfirmationToWire(registry.snapshot.single);
      expect(wire.containsKey('command'), isFalse);
    });
  });

  group('RemoteConfirmationPort', () {
    test('routes requestApproval through the registry', () async {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      final port = RemoteConfirmationPort(registry);
      final future = port.requestApproval(_req());
      expect(registry.snapshot, hasLength(1));
      registry.respond(registry.snapshot.single.id, approved: true);
      expect(await future, isTrue);
    });
  });

  group('RemoteAwareConfirmationPort', () {
    test('local approval wins and clears the remote pending entry', () async {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      final local = _ControllablePort();
      final port = RemoteAwareConfirmationPort(
        local: local,
        registry: registry,
      );

      final future = port.requestApproval(_req());
      expect(registry.snapshot, hasLength(1)); // published for the phone.

      // The desktop user approves locally.
      local.resolve(approved: true);
      expect(await future, isTrue);
      expect(registry.snapshot, isEmpty); // phone view cleared.
    });

    test('remote approval wins before the local dialog responds', () async {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      final local = _ControllablePort();
      final port = RemoteAwareConfirmationPort(
        local: local,
        registry: registry,
      );

      final future = port.requestApproval(_req());
      // The phone approves first.
      registry.respond(registry.snapshot.single.id, approved: true);
      expect(await future, isTrue);
      // The still-open local decision is orphaned but resolves harmlessly.
      local.resolve(approved: false);
    });
  });
}

/// A [ConfirmationPort] whose decision is driven by an external completer so
/// tests can control when the "local dialog" resolves.
class _ControllablePort implements ConfirmationPort {
  final List<Completer<bool>> _pending = [];

  void resolve({required bool approved}) {
    for (final c in _pending) {
      if (!c.isCompleted) {
        c.complete(approved);
      }
    }
    _pending.clear();
  }

  @override
  Future<bool> requestApproval(ConfirmationRequest request) {
    final c = Completer<bool>();
    _pending.add(c);
    return c.future;
  }
}
