import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_change_type.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_status_normalizer.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_adapter.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_delta.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_link.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_repositories.dart';

/// In-memory [TicketRepository] for sync tests.
///
/// Every workspace-scoped read filters on the ticket's own `workspaceId`, so a
/// ticket id belonging to another workspace is simply not found — the same
/// isolation the per-workspace database file enforces in production.
class FakeTicketRepository implements TicketRepository {
  final Map<String, Ticket> store = {};

  /// Collaborators keyed by ticket id. The ticket's own row supplies the
  /// workspace, so a collaborator read for the wrong workspace resolves empty.
  final Map<String, List<TicketCollaborator>> collaborators = {};

  @override
  Future<void> insert(Ticket ticket) async => store[ticket.id] = ticket;
  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async =>
      store[ticket.id] = ticket;
  @override
  Future<void> upsertMirror(Ticket ticket) async => store[ticket.id] = ticket;
  @override
  Future<void> delete(String ticketId, {required String workspaceId}) async =>
      store.remove(ticketId);
  @override
  Future<Ticket?> getById(String w, String id) async {
    final ticket = store[id];
    return ticket != null && ticket.workspaceId == w ? ticket : null;
  }

  @override
  Future<Ticket?> getByExternal(TicketProvider p, String key) async => store
      .values
      .where((t) => t.provider == p && t.externalKey == key)
      .firstOrNull;
  @override
  Future<List<Ticket>> forAgent(String w, String agentId) async => store.values
      .where((t) => t.workspaceId == w && t.assignedAgentId == agentId)
      .toList();
  @override
  Future<List<Ticket>> childrenOf(String w, String parentId) async => store
      .values
      .where((t) => t.workspaceId == w && t.parentTicketId == parentId)
      .toList();
  @override
  Stream<List<Ticket>> watchForWorkspace(String w) =>
      Stream.value(store.values.where((t) => t.workspaceId == w).toList());
  @override
  Stream<List<Ticket>> watchByStatus(String w, TicketStatus s) => Stream.value(
    store.values.where((t) => t.workspaceId == w && t.status == s).toList(),
  );
  @override
  Stream<List<Ticket>> watchByAssignee(String w, String a) => Stream.value(
    store.values
        .where((t) => t.workspaceId == w && t.assignedAgentId == a)
        .toList(),
  );
  @override
  Future<void> addCollaborator(String w, TicketCollaborator c) async {
    if (store[c.ticketId]?.workspaceId != w) {
      return;
    }
    final list = collaborators.putIfAbsent(c.ticketId, () => []);
    list
      ..removeWhere((e) => e.principalId == c.principalId)
      ..add(c);
  }

  @override
  Future<void> removeCollaborator(String w, String t, String a) async {
    if (store[t]?.workspaceId != w) {
      return;
    }
    collaborators[t]?.removeWhere((e) => e.principalId == a);
  }

  @override
  Stream<List<TicketCollaborator>> watchCollaborators(String w, String t) =>
      Stream.value(_collaboratorsIn(w, t));

  @override
  Future<List<TicketCollaborator>> getCollaborators(String w, String t) async =>
      _collaboratorsIn(w, t);

  List<TicketCollaborator> _collaboratorsIn(String w, String t) =>
      store[t]?.workspaceId == w
      ? List.unmodifiable(collaborators[t] ?? const [])
      : const [];
}

/// In-memory [TicketSyncConfigRepository].
class FakeSyncConfigRepository implements TicketSyncConfigRepository {
  final Map<String, TicketSyncConfig> store = {};

  String _key(String w, String v) => '$w|$v';

  @override
  Future<void> upsert(TicketSyncConfig config) async =>
      store[_key(config.workspaceId, config.vendor)] = config;
  @override
  Future<List<TicketSyncConfig>> enabledForWorkspace(String w) async =>
      store.values.where((c) => c.workspaceId == w && c.enabled).toList();
  @override
  Future<TicketSyncConfig?> forVendor(String w, String v) async =>
      store[_key(w, v)];
  @override
  Future<List<TicketSyncConfig>> forWorkspace(String w) async =>
      store.values.where((c) => c.workspaceId == w).toList();
  @override
  Stream<List<TicketSyncConfig>> watchForWorkspace(String w) =>
      Stream.value(store.values.where((c) => c.workspaceId == w).toList());
  @override
  Future<int> delete(String id, {required String workspaceId}) async {
    final before = store.length;
    store.removeWhere((_, c) => c.id == id && c.workspaceId == workspaceId);
    return before - store.length;
  }
}

/// In-memory [TicketSyncLinkRepository].
class FakeSyncLinkRepository implements TicketSyncLinkRepository {
  final List<TicketSyncLink> store = [];

  @override
  Future<void> upsert(TicketSyncLink link) async {
    store.removeWhere(
      (l) =>
          l.workspaceId == link.workspaceId &&
          l.ticketId == link.ticketId &&
          l.vendor == link.vendor,
    );
    store.add(link);
  }

  @override
  Future<TicketSyncLink?> forTicketVendor(String w, String t, String v) async =>
      store
          .where((l) => l.workspaceId == w && l.ticketId == t && l.vendor == v)
          .firstOrNull;

  @override
  Future<TicketSyncLink?> byExternalId(String w, String v, String ext) async =>
      store
          .where(
            (l) => l.workspaceId == w && l.vendor == v && l.externalId == ext,
          )
          .firstOrNull;

  @override
  Future<List<TicketSyncLink>> forTicket(String w, String t) async =>
      store.where((l) => l.workspaceId == w && l.ticketId == t).toList();

  @override
  Future<int> delete(String id, {required String workspaceId}) async {
    final before = store.length;
    store.removeWhere((l) => l.id == id && l.workspaceId == workspaceId);
    return before - store.length;
  }
}

/// In-memory [TicketSyncLogRepository].
class FakeSyncLogRepository implements TicketSyncLogRepository {
  final List<TicketSyncLogEntry> entries = [];

  @override
  Future<void> append(TicketSyncLogEntry entry) async => entries.add(entry);

  @override
  Future<bool> hasProcessed(String w, String v, String dedupeKey) async =>
      entries.any(
        (e) =>
            e.workspaceId == w &&
            e.vendor == v &&
            e.dedupeKey == dedupeKey &&
            (e.outcome == SyncOutcome.ok ||
                e.outcome == SyncOutcome.deduplicated),
      );

  @override
  Future<List<TicketSyncLogEntry>> recentForWorkspace(
    String w, {
    int limit = 100,
  }) async => entries.where((e) => e.workspaceId == w).toList();

  @override
  Stream<List<TicketSyncLogEntry>> watchForWorkspace(
    String w, {
    int limit = 100,
  }) => Stream.value(entries.where((e) => e.workspaceId == w).toList());
}

/// A scriptable [TicketSyncAdapter] that records pushes and replays canned
/// pull deltas.
class FakeSyncAdapter implements TicketSyncAdapter {
  FakeSyncAdapter(
    this.vendorId, {
    this.pulls = const [],
    this.failOnPush = false,
  });

  @override
  final String vendorId;

  /// Deltas returned by [pullChanges].
  List<TicketSyncDelta> pulls;

  /// When true, [pushChange] throws.
  bool failOnPush;

  final List<({Ticket ticket, TicketChangeType change})> pushes = [];
  int _seq = 0;

  @override
  List<String> get allowedDomains => const [];

  @override
  Future<List<TicketSyncDelta>> pullChanges({
    required String workspaceId,
    required String vendorProjectId,
    DateTime? since,
  }) async => pulls;

  @override
  Future<TicketPushOutcome?> pushChange({
    required String workspaceId,
    required Ticket ticket,
    required TicketChangeType changeType,
    String? externalId,
    String vendorProjectId = '',
  }) async {
    if (failOnPush) {
      throw StateError('push failed');
    }
    pushes.add((ticket: ticket, change: changeType));
    final id = externalId ?? 'ext-${++_seq}';
    return TicketPushOutcome(
      externalId: id,
      externalKey: '$vendorId-$id',
      url: 'https://$vendorId.example/$id',
    );
  }

  @override
  Future<String?> resolveVendorUrl(String url) async =>
      url.contains(vendorId) ? url.split('/').last : null;

  @override
  TicketStatus mapVendorStatus(String vendorStatus) =>
      normalizeVendorStatus(vendorStatus);

  @override
  String mapCcStatus(TicketStatus ccStatus) => ccStatus.name;
}
