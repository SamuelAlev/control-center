import 'dart:async';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
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
  test('a withdrawn request comes down as a deny', () async {
    final registry = PendingConfirmationRegistry();
    addTearDown(registry.dispose);
    final withdraw = Completer<void>();
    final reg = registry.register(
      ConfirmationRequest(
        spaceId: 'c1',
        title: 'Push to main',
        detail: 'push',
        withdrawn: withdraw.future,
      ),
    );
    expect(registry.snapshot, hasLength(1));
    withdraw.complete();
    expect(await reg.approved, isFalse);
    expect(registry.snapshot, isEmpty);
    // Answering after the withdrawal changes nothing.
    expect(registry.respond(reg.id, approved: true), isFalse);
  });

  group('only a person\'s answer is an answer', () {
    // Each way a request can end, and whether the producer heard it went
    // unanswered. A producer that stores a decision stores none for those.
    ConfirmationRequest told(
      List<String> heard,
      String name, [
      Future<void>? w,
    ]) => ConfirmationRequest(
      spaceId: 'c1',
      title: name,
      detail: name,
      withdrawn: w,
      onUnanswered: () => heard.add(name),
    );

    test('a timeout, a withdrawal, an expiry and a shutdown are unanswered; '
        'a person\'s deny and approval are not', () async {
      final heard = <String>[];
      final registry = PendingConfirmationRegistry(
        timeout: const Duration(milliseconds: 20),
      );
      final timedOut = registry.register(told(heard, 'timeout'));
      expect(await timedOut.approved, isFalse);

      final withdraw = Completer<void>();
      final withdrawn = registry.register(
        told(heard, 'withdrawn', withdraw.future),
      );
      withdraw.complete();
      expect(await withdrawn.approved, isFalse);

      final expired = registry.register(told(heard, 'expired'));
      expect(registry.expire(expired.id), isTrue);
      expect(await expired.approved, isFalse);
      expect(registry.expire(expired.id), isFalse);

      final denied = registry.register(told(heard, 'denied'));
      registry.respond(denied.id, approved: false);
      expect(await denied.approved, isFalse);
      final approved = registry.register(told(heard, 'approved'));
      registry.respond(approved.id, approved: true);
      expect(await approved.approved, isTrue);

      final atShutdown = registry.register(told(heard, 'shutdown'));
      registry.dispose();
      expect(await atShutdown.approved, isFalse);

      expect(heard, ['timeout', 'withdrawn', 'expired', 'shutdown']);
    });
  });

  test('a request the server refuses before asking shows no card, resolves '
      'false at once and is unanswered; a failing check shows the card',
      () async {
    final registry = PendingConfirmationRegistry();
    addTearDown(registry.dispose);
    final snapshots = <int>[];
    final sub = registry.pending.listen((s) => snapshots.add(s.length));
    addTearDown(sub.cancel);
    var unanswered = false;
    registry.refuseUnasked = (r) => r.runId == 'run-expired';
    final refused = registry.register(
      ConfirmationRequest(
        spaceId: 'c1',
        title: 'Deploy',
        detail: 'deploy',
        runId: 'run-expired',
        onUnanswered: () => unanswered = true,
      ),
    );
    expect(await refused.approved, isFalse);
    expect(unanswered, isTrue);
    expect(registry.snapshot, isEmpty);
    expect(registry.respond(refused.id, approved: true), isFalse);

    // Another run's request is shown.
    registry.register(
      const ConfirmationRequest(
        spaceId: 'c1',
        title: 'Deploy',
        detail: 'deploy',
        runId: 'run-other',
      ),
    );
    expect(registry.snapshot, hasLength(1));
    registry.refuseUnasked = (_) => throw StateError('broken');
    registry.register(_req());
    expect(registry.snapshot, hasLength(2));
    await Future<void>.delayed(Duration.zero);
    expect(snapshots, [0, 1, 2], reason: 'the refused one never showed');
  });

  group('a moved deadline (a run the server started)', () {
    test('outlasts the registry timeout, then denies: never approves', () async {
      final registry = PendingConfirmationRegistry(
        timeout: const Duration(milliseconds: 20),
      );
      addTearDown(registry.dispose);
      final reg = registry.register(_req());
      expect(
        registry.denyAfter(reg.id, const Duration(milliseconds: 150)),
        isTrue,
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(registry.pendingById(reg.id), isNotNull, reason: 'still waiting');
      expect(await reg.approved, isFalse);
      expect(registry.snapshot, isEmpty);
      expect(registry.denyAfter(reg.id, Duration.zero), isFalse);
    });

    test('a person who answers first still decides', () async {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      final reg = registry.register(_req());
      registry.denyAfter(reg.id, const Duration(milliseconds: 20));
      expect(registry.respond(reg.id, approved: true), isTrue);
      expect(await reg.approved, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(registry.snapshot, isEmpty);
    });

    test('a deadline already past denies at once', () async {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      final reg = registry.register(_req());
      registry.denyAfter(reg.id, const Duration(hours: -1));
      expect(await reg.approved, isFalse);
    });
  });

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

    test(
      'a late subscriber sees pending requests before live resolution',
      () async {
        final registry = PendingConfirmationRegistry();
        addTearDown(registry.dispose);
        final request = registry.register(_req());
        final first = registry.pending.take(2).toList();
        final second = registry.pending.take(2).toList();

        registry.respond(request.id, approved: true);
        for (final snapshots in [await first, await second]) {
          expect(snapshots.first.map((p) => p.id), [request.id]);
          expect(snapshots.last, isEmpty);
        }
        expect(await registry.pending.first, isEmpty);
        expect(await request.approved, isTrue);
      },
    );

    test('the pending stream emits a full snapshot on each change', () async {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      final snapshots = <List<PendingConfirmation>>[];
      final sub = registry.pending.listen(snapshots.add);
      // The initial snapshot and subsequent changes are both delivered.
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
      expect(wire.containsKey('conversation_id'), isFalse);
    });

    test('carries the conversation through to the client DTO', () {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      registry.register(
        const ConfirmationRequest(
          spaceId: 's1',
          conversationId: 'conv-1',
          title: 'Push',
          detail: '',
        ),
      );
      final wire = pendingConfirmationToWire(registry.snapshot.single);
      expect(wire['conversation_id'], 'conv-1');
      expect(ConfirmationRequestDto.fromJson(wire).conversationId, 'conv-1');
    });

    test('names the script a nested call came from, and only then', () {
      final registry = PendingConfirmationRegistry();
      addTearDown(registry.dispose);
      registry
        ..register(_req())
        ..register(
          ConfirmationRequest(
            spaceId: 's1',
            title: 'Push',
            detail: '',
            origin: ScriptCallOrigin(
              parentToolCallId: 'r',
              executionId: 'run-1/r',
            ),
          ),
        );
      final direct = pendingConfirmationToWire(registry.snapshot.first);
      final nested = pendingConfirmationToWire(registry.snapshot.last);

      expect(direct.containsKey('origin'), isFalse);
      expect(nested['origin'], {
        'parent_tool_call_id': 'r',
        'execution_id': 'run-1/r',
      });
      expect(
        ConfirmationRequestDto.fromJson(nested).origin,
        ScriptCallOrigin(parentToolCallId: 'r', executionId: 'run-1/r'),
      );
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
