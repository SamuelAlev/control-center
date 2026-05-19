import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';

/// Result of a ticket checkout attempt.
enum CheckoutResult {
  /// Checkout succeeded, agent now owns this ticket.
  success,
  /// This run already owns the ticket.
  alreadyOwned,
  /// Another run owns this ticket (conflict — do not retry).
  conflict,
  /// Ticket not found.
  notFound,
}

/// Atomic ticket checkout service.
///
/// Ensures only one heartbeat run owns a ticket at a time. Implements the
/// "Never retry a 409" discipline: if another run already holds the lock,
/// the caller should skip the heartbeat entirely.
class TicketCheckoutService {
  /// Creates a checkout service backed by [ticketRepository].
  TicketCheckoutService({
    required TicketRepository ticketRepository,
  }) : _ticketRepo = ticketRepository;

  final TicketRepository _ticketRepo;

  static const Duration _staleLockThreshold = Duration(hours: 4);

  /// Attempts to atomically checkout [ticketId] for [agentId] under [runId].
  ///
  /// [expectedStatuses] (optional) constrains which statuses are valid for
  /// checkout. Defaults to all non-terminal statuses.
  Future<CheckoutResult> checkout({
    required String ticketId,
    required String agentId,
    required String runId,
    Set<TicketStatus>? expectedStatuses,
  }) async {
    final ticket = await _ticketRepo.getById(ticketId);
    if (ticket == null) {
      return CheckoutResult.notFound;
    }

    if (ticket.isTerminal) {
      return CheckoutResult.conflict;
    }

    if (expectedStatuses != null && !expectedStatuses.contains(ticket.status)) {
      return CheckoutResult.conflict;
    }

    final currentRunId = ticket.checkoutRunId;
    if (currentRunId == runId) {
      return CheckoutResult.alreadyOwned;
    }

    if (currentRunId != null) {
      final lockedAt = ticket.executionLockedAt;
      if (lockedAt != null &&
          DateTime.now().difference(lockedAt) < _staleLockThreshold) {
        return CheckoutResult.conflict;
      }
    }

    final now = DateTime.now();
    await _ticketRepo.update(
      ticket.copyWith(
        checkoutRunId: runId,
        executionLockedAt: now,
        checkoutAgentId: agentId,
        version: ticket.version + 1,
        updatedAt: now,
      ),
    );

    return CheckoutResult.success;
  }

  /// Releases the execution lock held by [runId] on [ticketId].
  Future<void> release(String ticketId, String runId) async {
    final ticket = await _ticketRepo.getById(ticketId);
    if (ticket == null) {
      return;
    }
    if (ticket.checkoutRunId != runId) {
      return;
    }

    await _ticketRepo.update(
      ticket.copyWith(
        version: ticket.version + 1,
        updatedAt: DateTime.now(),
        removeCheckoutRunId: true,
        removeExecutionLockedAt: true,
        removeCheckoutAgentId: true,
      ),
    );
  }

  /// Force-adopts a stale lock for [ticketId]. Used when the current lock
  /// holder has been dead for longer than [_staleLockThreshold].
  Future<bool> adoptStaleLock({
    required String ticketId,
    required String agentId,
    required String runId,
  }) async {
    final ticket = await _ticketRepo.getById(ticketId);
    if (ticket == null) {
      return false;
    }

    final lockedAt = ticket.executionLockedAt;
    if (lockedAt == null) {
      return false;
    }
    if (DateTime.now().difference(lockedAt) < _staleLockThreshold) {
      return false;
    }

    await release(ticketId, ticket.checkoutRunId ?? '');

    final result = await checkout(
      ticketId: ticketId,
      agentId: agentId,
      runId: runId,
    );
    return result == CheckoutResult.success;
  }
}
