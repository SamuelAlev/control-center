import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_checkout_service.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Hand-rolled test doubles.
// ---------------------------------------------------------------------------

/// A fake [TicketRepository] that stores tickets in a map and captures
/// the last-updated ticket so tests can inspect state after service calls.
class _FakeTicketRepository implements TicketRepository {
  final Map<String, Ticket> _store = {};

  /// The ticket most recently passed to [update].
  Ticket? lastUpdated;

  void add(Ticket ticket) {
    _store[ticket.id] = ticket;
  }

  @override
  Future<Ticket?> getById(String id) async => _store[id];

  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async {
    _store[ticket.id] = ticket;
    lastUpdated = ticket;
  }

  @override
  Future<void> insert(Ticket ticket) async {
    _store[ticket.id] = ticket;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Helpers.
// ---------------------------------------------------------------------------

const _ws = 'ws-1';
const _agentId = 'agent-42';
const _runId = 'run-42';
const _otherRunId = 'run-99';
const _otherAgentId = 'agent-99';

final _now = DateTime.now();

/// Creates a baseline open ticket.
Ticket _ticket({
  String id = 'ticket-1',
  TicketStatus status = TicketStatus.open,
  int version = 5,
  String? checkoutRunId,
  DateTime? executionLockedAt,
  String? checkoutAgentId,
}) {
  return Ticket(
    id: id,
    workspaceId: _ws,
    title: 'Test ticket',
    status: status,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: _now,
    version: version,
    checkoutRunId: checkoutRunId,
    executionLockedAt: executionLockedAt,
    checkoutAgentId: checkoutAgentId,
  );
}

// ---------------------------------------------------------------------------
// Tests.
// ---------------------------------------------------------------------------

void main() {
  late _FakeTicketRepository repo;
  late TicketCheckoutService service;

  setUp(() {
    repo = _FakeTicketRepository();
    service = TicketCheckoutService(ticketRepository: repo);
  });

  // =========================================================================
  // checkout()
  // =========================================================================

  group('checkout', () {
    test('returns notFound when ticket does not exist', () async {
      final result = await service.checkout(
        ticketId: 'nonexistent',
        agentId: _agentId,
        runId: _runId,
      );

      expect(result, CheckoutResult.notFound);
    }, timeout: const Timeout.factor(2));

    for (final terminal in [TicketStatus.done, TicketStatus.failed, TicketStatus.cancelled]) {
      test('returns conflict when ticket is terminal ($terminal)', () async {
        repo.add(_ticket(status: terminal));

        final result = await service.checkout(
          ticketId: 'ticket-1',
          agentId: _agentId,
          runId: _runId,
        );

        expect(result, CheckoutResult.conflict);
      }, timeout: const Timeout.factor(2));
    }

    test('returns conflict when expectedStatuses constrain and ticket '
        'status not in set', () async {
      repo.add(_ticket(status: TicketStatus.open));

      final result = await service.checkout(
        ticketId: 'ticket-1',
        agentId: _agentId,
        runId: _runId,
        expectedStatuses: {TicketStatus.inProgress},
      );

      expect(result, CheckoutResult.conflict);
    }, timeout: const Timeout.factor(2));

    test('returns success when expectedStatuses includes ticket status',
        () async {
      repo.add(_ticket(status: TicketStatus.inProgress));

      final result = await service.checkout(
        ticketId: 'ticket-1',
        agentId: _agentId,
        runId: _runId,
        expectedStatuses: {TicketStatus.inProgress, TicketStatus.blocked},
      );

      expect(result, CheckoutResult.success);
    }, timeout: const Timeout.factor(2));

    test('returns alreadyOwned when checkoutRunId matches runId', () async {
      repo.add(_ticket(
        checkoutRunId: _runId,
        executionLockedAt: _now,
        checkoutAgentId: _agentId,
      ));

      final result = await service.checkout(
        ticketId: 'ticket-1',
        agentId: _agentId,
        runId: _runId,
      );

      expect(result, CheckoutResult.alreadyOwned);
      // Must not have called update.
      expect(repo.lastUpdated, isNull);
    }, timeout: const Timeout.factor(2));

    test('returns conflict when locked by another run and lock is fresh',
        () async {
      final freshLock = DateTime.now().subtract(const Duration(minutes: 30));
      repo.add(_ticket(
        checkoutRunId: _otherRunId,
        executionLockedAt: freshLock,
        checkoutAgentId: _otherAgentId,
      ));

      final result = await service.checkout(
        ticketId: 'ticket-1',
        agentId: _agentId,
        runId: _runId,
      );

      expect(result, CheckoutResult.conflict);
      // Must not have updated.
      expect(repo.lastUpdated, isNull);
    }, timeout: const Timeout.factor(2));

    test('returns success when ticket is free (no lock)', () async {
      repo.add(_ticket());

      final result = await service.checkout(
        ticketId: 'ticket-1',
        agentId: _agentId,
        runId: _runId,
      );

      expect(result, CheckoutResult.success);
    }, timeout: const Timeout.factor(2));

    test('updates ticket with checkout fields on success', () async {
      repo.add(_ticket());

      await service.checkout(
        ticketId: 'ticket-1',
        agentId: _agentId,
        runId: _runId,
      );

      final updated = repo.lastUpdated;
      expect(updated, isNotNull);
      expect(updated!.checkoutRunId, _runId);
      expect(updated.checkoutAgentId, _agentId);
      expect(updated.executionLockedAt, isNotNull);
      // executionLockedAt should be roughly now.
      final diff = DateTime.now().difference(updated.executionLockedAt!);
      expect(diff.inSeconds.abs(), lessThan(5));
    }, timeout: const Timeout.factor(2));

    test('increments version on checkout', () async {
      repo.add(_ticket(version: 5));

      await service.checkout(
        ticketId: 'ticket-1',
        agentId: _agentId,
        runId: _runId,
      );

      expect(repo.lastUpdated!.version, 6);
    }, timeout: const Timeout.factor(2));

    test('returns success and takes over when stale lock (>= 4 hours old)',
        () async {
      final staleLock = DateTime.now().subtract(const Duration(hours: 5));
      repo.add(_ticket(
        checkoutRunId: _otherRunId,
        executionLockedAt: staleLock,
        checkoutAgentId: _otherAgentId,
      ));

      final result = await service.checkout(
        ticketId: 'ticket-1',
        agentId: _agentId,
        runId: _runId,
      );

      expect(result, CheckoutResult.success);
      final updated = repo.lastUpdated!;
      expect(updated.checkoutRunId, _runId);
      expect(updated.checkoutAgentId, _agentId);
    }, timeout: const Timeout.factor(2));

    test('returns success when stale lock is exactly at threshold '
        '(>= 4 hours)', () async {
      // Locked exactly 4 hours ago → stale.
      final exactlyStale = DateTime.now().subtract(const Duration(hours: 4));
      repo.add(_ticket(
        checkoutRunId: _otherRunId,
        executionLockedAt: exactlyStale,
        checkoutAgentId: _otherAgentId,
      ));

      final result = await service.checkout(
        ticketId: 'ticket-1',
        agentId: _agentId,
        runId: _runId,
      );

      expect(result, CheckoutResult.success);
    }, timeout: const Timeout.factor(2));
  });

  // =========================================================================
  // release()
  // =========================================================================

  group('release', () {
    test('no-op when ticket not found', () async {
      await service.release('nonexistent', _runId);

      expect(repo.lastUpdated, isNull);
    }, timeout: const Timeout.factor(2));

    test('no-op when checkoutRunId != runId', () async {
      repo.add(_ticket(
        checkoutRunId: _otherRunId,
        executionLockedAt: _now,
        checkoutAgentId: _otherAgentId,
      ));

      await service.release('ticket-1', _runId);

      // Should not have called update.
      expect(repo.lastUpdated, isNull);
    }, timeout: const Timeout.factor(2));

    test('clears checkout fields when lock holder releases', () async {
      repo.add(_ticket(
        checkoutRunId: _runId,
        executionLockedAt: _now,
        checkoutAgentId: _agentId,
      ));

      await service.release('ticket-1', _runId);

      final updated = repo.lastUpdated!;
      expect(updated.checkoutRunId, isNull);
      expect(updated.executionLockedAt, isNull);
      expect(updated.checkoutAgentId, isNull);
    }, timeout: const Timeout.factor(2));

    test('increments version on release', () async {
      repo.add(_ticket(
        version: 7,
        checkoutRunId: _runId,
        executionLockedAt: _now,
        checkoutAgentId: _agentId,
      ));

      await service.release('ticket-1', _runId);

      expect(repo.lastUpdated!.version, 8);
    }, timeout: const Timeout.factor(2));

    test('does not touch ticket fields beyond checkout + version + '
        'updatedAt', () async {
      final original = _ticket(
        id: 'ticket-1',
        status: TicketStatus.inProgress,
        version: 3,
        checkoutRunId: _runId,
        executionLockedAt: _now,
        checkoutAgentId: _agentId,
      );
      repo.add(original);

      await service.release('ticket-1', _runId);

      final updated = repo.lastUpdated!;
      // Checkout fields cleared.
      expect(updated.checkoutRunId, isNull);
      expect(updated.executionLockedAt, isNull);
      expect(updated.checkoutAgentId, isNull);
      // Version bumped.
      expect(updated.version, 4);
      // updatedAt refreshed.
      expect(updated.updatedAt.isAfter(original.updatedAt), isTrue);
      // Other fields untouched.
      expect(updated.id, original.id);
      expect(updated.workspaceId, original.workspaceId);
      expect(updated.title, original.title);
      expect(updated.status, original.status);
    }, timeout: const Timeout.factor(2));
  });

  // =========================================================================
  // adoptStaleLock()
  // =========================================================================

  group('adoptStaleLock', () {
    test('returns false when ticket not found', () async {
      final result = await service.adoptStaleLock(
        ticketId: 'nonexistent',
        agentId: _agentId,
        runId: _runId,
      );

      expect(result, false);
      expect(repo.lastUpdated, isNull);
    }, timeout: const Timeout.factor(2));

    test('returns false when no lock exists (executionLockedAt null)',
        () async {
      repo.add(_ticket());

      final result = await service.adoptStaleLock(
        ticketId: 'ticket-1',
        agentId: _agentId,
        runId: _runId,
      );

      expect(result, false);
      // No checkout fields to update — should not call update.
      expect(repo.lastUpdated, isNull);
    }, timeout: const Timeout.factor(2));

    test('returns false when lock is fresh', () async {
      final freshLock = _now.subtract(const Duration(minutes: 10));
      repo.add(_ticket(
        checkoutRunId: _otherRunId,
        executionLockedAt: freshLock,
        checkoutAgentId: _otherAgentId,
      ));

      final result = await service.adoptStaleLock(
        ticketId: 'ticket-1',
        agentId: _agentId,
        runId: _runId,
      );

      expect(result, false);
      // Should not have updated.
      expect(repo.lastUpdated, isNull);
    }, timeout: const Timeout.factor(2));

    test('returns true and takes over stale lock', () async {
      final staleLock = _now.subtract(const Duration(hours: 6));
      repo.add(_ticket(
        checkoutRunId: _otherRunId,
        executionLockedAt: staleLock,
        checkoutAgentId: _otherAgentId,
      ));

      final result = await service.adoptStaleLock(
        ticketId: 'ticket-1',
        agentId: _agentId,
        runId: _runId,
      );

      expect(result, true);
    }, timeout: const Timeout.factor(2));

    test('releases old lock then checks out for new run', () async {
      final staleLock = _now.subtract(const Duration(hours: 7));
      repo.add(_ticket(
        version: 10,
        checkoutRunId: _otherRunId,
        executionLockedAt: staleLock,
        checkoutAgentId: _otherAgentId,
      ));

      await service.adoptStaleLock(
        ticketId: 'ticket-1',
        agentId: _agentId,
        runId: _runId,
      );

      // The last update should be the checkout (second call to update).
      // release happens first, then checkout.
      final updated = repo.lastUpdated!;
      expect(updated.checkoutRunId, _runId);
      expect(updated.checkoutAgentId, _agentId);
      expect(updated.executionLockedAt, isNotNull);
      // Version should be incremented twice: once by release, once by checkout.
      expect(updated.version, 12);
    }, timeout: const Timeout.factor(2));

    test('returns true when lock is exactly at threshold (>= 4 hours)',
        () async {
      final exactlyStale = _now.subtract(const Duration(hours: 4));
      repo.add(_ticket(
        checkoutRunId: _otherRunId,
        executionLockedAt: exactlyStale,
        checkoutAgentId: _otherAgentId,
      ));

      final result = await service.adoptStaleLock(
        ticketId: 'ticket-1',
        agentId: _agentId,
        runId: _runId,
      );

      expect(result, true);
    }, timeout: const Timeout.factor(2));
  });
}
