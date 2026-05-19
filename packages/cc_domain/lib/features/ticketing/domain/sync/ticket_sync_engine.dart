import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/sync/sync_direction.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_change_type.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_conflict_resolver.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_adapter.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_delta.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_link.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_repositories.dart';
import 'package:uuid/uuid.dart';

/// Tally of a push fan-out across a workspace's vendors.
class PushSummary {
  /// Creates a [PushSummary].
  const PushSummary({this.pushed = 0, this.skipped = 0, this.failed = 0});

  /// Vendors the change was pushed to.
  final int pushed;

  /// Vendors that skipped (direction disallows push, or adapter absent).
  final int skipped;

  /// Vendors whose push failed.
  final int failed;
}

/// Tally of applying a batch of pulled deltas.
class PullSummary {
  /// Creates a [PullSummary].
  const PullSummary({
    this.created = 0,
    this.updated = 0,
    this.skipped = 0,
    this.deduplicated = 0,
    this.failed = 0,
  });

  /// New Control Center tickets created from vendor-created tickets.
  final int created;

  /// Existing tickets whose mirror changed.
  final int updated;

  /// Deltas that applied nothing (no change, or CC-owned fields only).
  final int skipped;

  /// Deltas dropped as already-processed (dedupe).
  final int deduplicated;

  /// Deltas that errored.
  final int failed;
}

/// Orchestrates bidirectional sync between Control Center's (primary) tickets
/// and any number of external vendors.
///
/// Control Center is the source of truth for agent work: a local change is
/// pushed out to every enabled vendor; a vendor change is mirrored back in
/// without ever re-emitting a domain event (so it cannot loop back into a push).
/// Conflicts are resolved per-field from each vendor's [TicketSyncConfig].
class TicketSyncEngine {
  /// Creates a [TicketSyncEngine] over the given adapters (keyed by vendor id)
  /// and persistence ports. [now]/[newId] are injectable for deterministic
  /// tests.
  TicketSyncEngine({
    required List<TicketSyncAdapter> adapters,
    required this.repository,
    required this.configRepository,
    required this.linkRepository,
    required this.logRepository,
    this.resolver = const TicketConflictResolver(),
    DateTime Function()? now,
    String Function()? newId,
  }) : _adapters = {for (final a in adapters) a.vendorId: a},
       _now = now ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  /// Registered adapters by vendor id.
  final Map<String, TicketSyncAdapter> _adapters;

  /// Local ticket store (primary).
  final TicketRepository repository;

  /// Per-vendor sync configs.
  final TicketSyncConfigRepository configRepository;

  /// Ticket↔vendor links.
  final TicketSyncLinkRepository linkRepository;

  /// Append-only sync audit log + dedupe source.
  final TicketSyncLogRepository logRepository;

  /// Field-level conflict resolution.
  final TicketConflictResolver resolver;

  final DateTime Function() _now;
  final String Function() _newId;

  /// The adapter registered for [vendor], or null.
  TicketSyncAdapter? adapterFor(String vendor) => _adapters[vendor];

  /// Pushes a local ticket change out to every enabled vendor configured for
  /// the workspace whose direction allows pushing.
  Future<PushSummary> pushTicket({
    required String workspaceId,
    required Ticket ticket,
    required TicketChangeType changeType,
  }) async {
    final configs = await configRepository.enabledForWorkspace(workspaceId);
    var pushed = 0;
    var skipped = 0;
    var failed = 0;

    for (final config in configs) {
      if (!config.direction.allowsPush) {
        skipped++;
        continue;
      }
      final adapter = _adapters[config.vendor];
      if (adapter == null) {
        skipped++;
        await _log(
          workspaceId,
          ticketId: ticket.id,
          vendor: config.vendor,
          direction: SyncDirection.push,
          outcome: SyncOutcome.skipped,
          message: 'no adapter registered for ${config.vendor}',
        );
        continue;
      }
      try {
        final link = await linkRepository.forTicketVendor(
          workspaceId,
          ticket.id,
          config.vendor,
        );
        final outcome = await adapter.pushChange(
          workspaceId: workspaceId,
          ticket: ticket,
          changeType: changeType,
          externalId: link?.externalId,
          vendorProjectId: config.vendorProjectId,
        );
        if (outcome != null) {
          await linkRepository.upsert(
            (link ??
                    TicketSyncLink(
                      id: _newId(),
                      workspaceId: workspaceId,
                      ticketId: ticket.id,
                      vendor: config.vendor,
                      externalId: outcome.externalId,
                    ))
                .copyWith(
                  externalId: outcome.externalId,
                  externalKey: outcome.externalKey,
                  externalUrl: outcome.url,
                  lastSyncedAt: _now(),
                  lastDirection: SyncDirection.push,
                ),
          );
        }
        pushed++;
        await _log(
          workspaceId,
          ticketId: ticket.id,
          vendor: config.vendor,
          direction: SyncDirection.push,
          outcome: SyncOutcome.ok,
          message: changeType.toStorageString(),
        );
      } on Object catch (e, st) {
        failed++;
        CcDomainLog.error(
          'TicketSyncEngine: push to ${config.vendor} failed',
          e,
          st,
        );
        await _log(
          workspaceId,
          ticketId: ticket.id,
          vendor: config.vendor,
          direction: SyncDirection.push,
          outcome: SyncOutcome.failed,
          message: '$e',
        );
      }
    }
    return PushSummary(pushed: pushed, skipped: skipped, failed: failed);
  }

  /// User-triggered "sync now": pulls the latest vendor changes for every
  /// enabled, pull-capable config in [workspaceId] (optionally narrowed to a
  /// single [vendor]) and applies them via [applyPull]. Routine sync is
  /// event-/webhook-driven; this is the manual refresh path behind the sync
  /// health card's button. Per-vendor failures are logged and rolled into the
  /// returned summary rather than aborting the whole run.
  Future<PullSummary> pullNow({
    required String workspaceId,
    String? vendor,
  }) async {
    final configs = await configRepository.enabledForWorkspace(workspaceId);
    var created = 0;
    var updated = 0;
    var skipped = 0;
    var deduplicated = 0;
    var failed = 0;
    for (final config in configs) {
      if (vendor != null && config.vendor != vendor) {
        continue;
      }
      if (!config.direction.allowsPull) {
        skipped++;
        continue;
      }
      final adapter = _adapters[config.vendor];
      if (adapter == null) {
        skipped++;
        await _log(
          workspaceId,
          vendor: config.vendor,
          direction: SyncDirection.pull,
          outcome: SyncOutcome.skipped,
          message: 'no adapter registered for ${config.vendor}',
        );
        continue;
      }
      try {
        final deltas = await adapter.pullChanges(
          workspaceId: workspaceId,
          vendorProjectId: config.vendorProjectId,
        );
        final summary = await applyPull(
          workspaceId: workspaceId,
          vendor: config.vendor,
          deltas: deltas,
        );
        created += summary.created;
        updated += summary.updated;
        skipped += summary.skipped;
        deduplicated += summary.deduplicated;
        failed += summary.failed;
      } on Object catch (e, st) {
        failed++;
        CcDomainLog.error(
          'TicketSyncEngine: manual pull from ${config.vendor} failed',
          e,
          st,
        );
        await _log(
          workspaceId,
          vendor: config.vendor,
          direction: SyncDirection.pull,
          outcome: SyncOutcome.failed,
          message: '$e',
        );
      }
    }
    return PullSummary(
      created: created,
      updated: updated,
      skipped: skipped,
      deduplicated: deduplicated,
      failed: failed,
    );
  }

  /// Applies a batch of vendor deltas into Control Center. A delta with no
  /// existing link creates a new CC ticket (the primary copy of a vendor-created
  /// ticket); a delta with a link mirror-updates the existing ticket under the
  /// vendor's conflict policy. Re-delivered deltas (matching [batchDedupeKey] or
  /// a per-delta dedupe key) are dropped.
  Future<PullSummary> applyPull({
    required String workspaceId,
    required String vendor,
    required List<TicketSyncDelta> deltas,
    String? batchDedupeKey,
  }) async {
    final config = await configRepository.forVendor(workspaceId, vendor);
    if (config == null || !config.enabled || !config.direction.allowsPull) {
      await _log(
        workspaceId,
        vendor: vendor,
        direction: SyncDirection.pull,
        outcome: SyncOutcome.skipped,
        message: config == null
            ? 'no sync config'
            : (!config.enabled ? 'disabled' : 'direction disallows pull'),
      );
      return const PullSummary(skipped: 1);
    }

    var created = 0;
    var updated = 0;
    var skipped = 0;
    var deduplicated = 0;
    var failed = 0;

    for (final delta in deltas) {
      final dedupeKey = delta.dedupeKey ?? batchDedupeKey;
      try {
        if (dedupeKey != null &&
            await logRepository.hasProcessed(workspaceId, vendor, dedupeKey)) {
          deduplicated++;
          await _log(
            workspaceId,
            vendor: vendor,
            direction: SyncDirection.pull,
            outcome: SyncOutcome.deduplicated,
            dedupeKey: dedupeKey,
            message: 'already processed',
          );
          continue;
        }

        final outcome = await _applyOneDelta(
          workspaceId,
          vendor,
          config,
          delta,
        );
        switch (outcome) {
          case _PullOutcome.created:
            created++;
          case _PullOutcome.updated:
            updated++;
          case _PullOutcome.skipped:
            skipped++;
        }
        await _log(
          workspaceId,
          ticketId: (await linkRepository.byExternalId(
            workspaceId,
            vendor,
            delta.externalId,
          ))?.ticketId,
          vendor: vendor,
          direction: SyncDirection.pull,
          outcome: outcome == _PullOutcome.skipped
              ? SyncOutcome.skipped
              : SyncOutcome.ok,
          dedupeKey: dedupeKey,
          message: outcome.name,
        );
      } on Object catch (e, st) {
        failed++;
        CcDomainLog.error('TicketSyncEngine: pull $vendor delta failed', e, st);
        await _log(
          workspaceId,
          vendor: vendor,
          direction: SyncDirection.pull,
          outcome: SyncOutcome.failed,
          dedupeKey: dedupeKey,
          message: '$e',
        );
      }
    }
    return PullSummary(
      created: created,
      updated: updated,
      skipped: skipped,
      deduplicated: deduplicated,
      failed: failed,
    );
  }

  Future<_PullOutcome> _applyOneDelta(
    String workspaceId,
    String vendor,
    TicketSyncConfig config,
    TicketSyncDelta delta,
  ) async {
    final link = await linkRepository.byExternalId(
      workspaceId,
      vendor,
      delta.externalId,
    );

    if (link == null) {
      // Vendor-created ticket with no CC counterpart yet → create the primary
      // CC ticket and link it. A deletion delta for an unknown ticket is a
      // no-op.
      if (delta.deleted) {
        return _PullOutcome.skipped;
      }
      final ticket = Ticket(
        id: _newId(),
        workspaceId: workspaceId,
        title: delta.title ?? delta.externalKey ?? delta.externalId,
        description: delta.description,
        priority: delta.priority ?? TicketPriority.none,
        labels: delta.labels ?? const [],
        status: delta.status ?? TicketStatus.open,
        rawStatus: delta.rawStatus,
        url: delta.url,
        originKind: TicketOriginKind.externalSync,
        createdAt: _now(),
        updatedAt: _now(),
      );
      await repository.insert(ticket);
      await linkRepository.upsert(
        TicketSyncLink(
          id: _newId(),
          workspaceId: workspaceId,
          ticketId: ticket.id,
          vendor: vendor,
          externalId: delta.externalId,
          externalKey: delta.externalKey,
          externalUrl: delta.url,
          lastSyncedAt: _now(),
          lastDirection: SyncDirection.pull,
        ),
      );
      return _PullOutcome.created;
    }

    final local = await repository.getById(workspaceId, link.ticketId);
    if (local == null) {
      // The CC ticket was deleted; drop the stale link rather than resurrect it.
      await linkRepository.delete(link.id, workspaceId: workspaceId);
      return _PullOutcome.skipped;
    }

    final result = resolver.merge(
      local: local,
      incoming: delta,
      policy: config.fieldPolicy,
    );
    if (!result.changed) {
      // Still refresh the link's last-synced bookkeeping even on a no-op.
      await linkRepository.upsert(
        link.copyWith(
          externalKey: delta.externalKey ?? link.externalKey,
          externalUrl: delta.url ?? link.externalUrl,
          lastSyncedAt: _now(),
          lastDirection: SyncDirection.pull,
        ),
      );
      return _PullOutcome.skipped;
    }

    // Update the existing primary ticket by id (not upsertMirror, which keys on
    // externalKey and would insert a duplicate for a CC-primary ticket). The
    // merged ticket carries the freshly-loaded overlay, so only the vendor-won
    // mirror fields change. No domain event is emitted, so the push coordinator
    // never sees this and the change cannot loop back to the vendor.
    await repository.update(
      result.merged.copyWith(updatedAt: _now(), version: local.version + 1),
      expectedVersion: local.version,
    );
    await linkRepository.upsert(
      link.copyWith(
        externalKey: delta.externalKey ?? link.externalKey,
        externalUrl: delta.url ?? link.externalUrl,
        lastSyncedAt: _now(),
        lastDirection: SyncDirection.pull,
      ),
    );
    return _PullOutcome.updated;
  }

  Future<void> _log(
    String workspaceId, {
    String? ticketId,
    required String vendor,
    required SyncDirection direction,
    required SyncOutcome outcome,
    String? message,
    String? dedupeKey,
  }) {
    return logRepository.append(
      TicketSyncLogEntry(
        id: _newId(),
        workspaceId: workspaceId,
        ticketId: ticketId,
        vendor: vendor,
        direction: direction,
        outcome: outcome,
        message: message,
        dedupeKey: dedupeKey,
        createdAt: _now(),
      ),
    );
  }
}

enum _PullOutcome { created, updated, skipped }
