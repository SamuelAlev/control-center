import 'dart:async';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_host/cc_host.dart';
import 'package:test/test.dart';

ConfirmationRequest _req({String conversationId = 'c1'}) => ConfirmationRequest(
      conversationId: conversationId,
      title: 'Push to main',
      detail: 'force-push',
      severity: ConfirmationSeverity.destructive,
      command: 'git push --force',
    );

void main() {
  group('PendingConfirmationRegistry', () {
    test('register publishes a pending entry and resolves on approve', () async {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);

      final reg = registry.register(_req());
      expect(registry.snapshot, hasLength(1));
      expect(registry.snapshot.single.id, reg.id);

      final done = reg.approved;
      expect(registry.respond(reg.id, true), isTrue);
      expect(await done, isTrue);
      expect(registry.snapshot, isEmpty);
    });

    test('respond deny resolves false', () async {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      final reg = registry.register(_req());
      registry.respond(reg.id, false);
      expect(await reg.approved, isFalse);
    });

    test('respond for an unknown/already-resolved id is a no-op false', () async {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      expect(registry.respond('bogus', true), isFalse);
      final reg = registry.register(_req());
      expect(registry.respond(reg.id, true), isTrue);
      expect(registry.respond(reg.id, true), isFalse); // already resolved
    });

    test('timeout auto-denies an unresolved request', () async {
      final registry =
          PendingConfirmationRegistry(timeout: const Duration(milliseconds: 20));
      addTearDown(registry.dispose);
      final reg = registry.register(_req());
      expect(await reg.approved, isFalse);
      expect(registry.snapshot, isEmpty);
    });

    test('cancel resolves the entry with the given value', () async {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      final reg = registry.register(_req());
      registry.cancel(reg.id, true);
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
      registry.respond(reg.id, true);
      // Allow broadcast stream delivery.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      final lengths = snapshots.map((s) => s.length).toList();
      expect(lengths, containsAll([1, 0]));
    });
  });

  group('RemoteConfirmationPort', () {
    test('routes requestApproval through the registry', () async {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      final port = RemoteConfirmationPort(registry);
      final future = port.requestApproval(_req());
      expect(registry.snapshot, hasLength(1));
      registry.respond(registry.snapshot.single.id, true);
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
      local.resolve(true);
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
      registry.respond(registry.snapshot.single.id, true);
      expect(await future, isTrue);
      // The still-open local decision is orphaned but resolves harmlessly.
      local.resolve(false);
    });
  });
}

/// A [ConfirmationPort] whose decision is driven by an external completer so
/// tests can control when the "local dialog" resolves.
class _ControllablePort implements ConfirmationPort {
  final List<Completer<bool>> _pending = [];

  void resolve(bool approved) {
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
