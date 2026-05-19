import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_conflict_resolver.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_field_conflict_policy.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_delta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = TicketConflictResolver();
  final now = DateTime.utc(2026);

  Ticket local() => Ticket(
    id: 't1',
    workspaceId: 'ws',
    title: 'Local title',
    description: 'local desc',
    status: TicketStatus.open,
    priority: TicketPriority.medium,
    labels: const ['a'],
    createdAt: now,
    updatedAt: now,
  );

  test('cc-wins policy leaves every field untouched', () {
    final result = resolver.merge(
      local: local(),
      incoming: const TicketSyncDelta(
        externalId: 'x',
        title: 'Vendor title',
        status: TicketStatus.done,
        priority: TicketPriority.urgent,
      ),
      policy: TicketFieldConflictPolicy.ccOwned,
    );
    expect(result.changed, isFalse);
    expect(result.merged.title, 'Local title');
    expect(result.merged.status, TicketStatus.open);
  });

  test('vendor-wins policy applies changed fields only', () {
    final result = resolver.merge(
      local: local(),
      incoming: const TicketSyncDelta(
        externalId: 'x',
        title: 'Vendor title',
        status: TicketStatus.done,
        rawStatus: 'Done',
      ),
      policy: TicketFieldConflictPolicy.vendorOwned,
    );
    expect(result.changed, isTrue);
    expect(result.merged.title, 'Vendor title');
    expect(result.merged.status, TicketStatus.done);
    expect(result.merged.rawStatus, 'Done');
    expect(result.appliedFromVendor, contains(TicketSyncField.title));
    expect(result.appliedFromVendor, contains(TicketSyncField.status));
    // description was not in the delta → unchanged.
    expect(result.merged.description, 'local desc');
  });

  test('per-field override: vendor owns status, cc owns title', () {
    const policy = TicketFieldConflictPolicy(
      perField: {TicketSyncField.status: ConflictWinner.vendor},
    );
    final result = resolver.merge(
      local: local(),
      incoming: const TicketSyncDelta(
        externalId: 'x',
        title: 'Vendor title',
        status: TicketStatus.inReview,
      ),
      policy: policy,
    );
    expect(result.merged.title, 'Local title', reason: 'cc owns title');
    expect(
      result.merged.status,
      TicketStatus.inReview,
      reason: 'vendor owns status',
    );
    expect(result.appliedFromVendor, {TicketSyncField.status});
  });

  test('a vendor-won field equal to local is not counted as a change', () {
    final result = resolver.merge(
      local: local(),
      incoming: const TicketSyncDelta(externalId: 'x', title: 'Local title'),
      policy: TicketFieldConflictPolicy.vendorOwned,
    );
    expect(result.changed, isFalse);
  });

  test('policy round-trips through JSON', () {
    const policy = TicketFieldConflictPolicy(
      defaultWinner: ConflictWinner.vendor,
      perField: {
        TicketSyncField.title: ConflictWinner.cc,
        TicketSyncField.status: ConflictWinner.vendor,
      },
    );
    final restored = TicketFieldConflictPolicy.fromJson(policy.toJson());
    expect(restored.defaultWinner, ConflictWinner.vendor);
    expect(restored.winnerFor(TicketSyncField.title), ConflictWinner.cc);
    expect(restored.winnerFor(TicketSyncField.status), ConflictWinner.vendor);
    expect(restored.winnerFor(TicketSyncField.labels), ConflictWinner.vendor);
  });

  test('malformed JSON degrades to safe cc-wins default', () {
    final p = TicketFieldConflictPolicy.fromJson('{not json');
    expect(p.defaultWinner, ConflictWinner.cc);
  });
}
