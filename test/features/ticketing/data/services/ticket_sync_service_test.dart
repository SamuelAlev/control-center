import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/ports/remote_ticket.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_provider_capabilities.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_provider_port.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_query.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_infra/src/tickets/ticket_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [TicketProviderPort] for testing sync.
class _FakeTicketProviderPort implements TicketProviderPort {

  _FakeTicketProviderPort({
    this.tickets = const [],
    this.supportsSync = true,
  });
  final List<RemoteTicket> tickets;
  final bool supportsSync;

  int listCallCount = 0;

  @override
  TicketProvider get provider => TicketProvider.linear;

  @override
  TicketProviderCapabilities get capabilities => TicketProviderCapabilities(
        provider: TicketProvider.linear,
        supportsCreate: true,
        supportsRemoteSync: supportsSync,
        supportsAssignee: true,
        supportsStatusUpdate: true,
        supportsList: true,
      );

  @override
  List<String> get allowedDomains => const ['api.linear.app'];

  @override
  Future<RemoteTicket> create(RemoteTicketDraft draft) async =>
      throw UnimplementedError();

  @override
  Future<RemoteTicket?> getByExternalId(String externalId) async => null;

  @override
  Future<List<RemoteTicket>> list({TicketQuery query = const TicketQuery()}) async {
    listCallCount++;
    return tickets;
  }

  @override
  Future<RemoteTicket> update(String externalId, RemoteTicketPatch patch) async =>
      throw UnimplementedError();

  @override
  Future<RemoteTicket> transitionStatus(String externalId, TicketStatus target) async =>
      throw UnimplementedError();

  @override
  Future<RemoteTicket> assign(String externalId, String? assigneeExternalId) async =>
      throw UnimplementedError();

  @override
  Stream<RemoteTicket> watchAssigned() => const Stream.empty();
}

/// Fake [TicketRepository] for testing sync.
class _FakeTicketRepository implements TicketRepository {
  final List<Ticket> upserted = [];

  @override
  Future<void> insert(Ticket ticket) async => throw UnimplementedError();

  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async =>
      throw UnimplementedError();

  @override
  Future<void> upsertMirror(Ticket ticket) async {
    upserted.add(ticket);
  }

  @override
  Future<void> delete(String ticketId, {required String workspaceId}) async =>
      throw UnimplementedError();

  @override
  Future<Ticket?> getById(String id) async => null;

  @override
  Future<Ticket?> getByExternal(TicketProvider provider, String externalKey) async =>
      null;

  @override
  @override
  @override
  Future<List<Ticket>> forAgent(String workspaceId, String agentId) async => [];

  @override
  Future<List<Ticket>> childrenOf(String workspaceId, String parentTicketId) async =>
      [];

  @override
  Stream<List<Ticket>> watchForWorkspace(String workspaceId) =>
      const Stream.empty();

  @override
  Stream<List<Ticket>> watchByStatus(String workspaceId, TicketStatus status) =>
      const Stream.empty();

  @override
  Stream<List<Ticket>> watchByAssignee(String workspaceId, String agentId) =>
      const Stream.empty();

  @override
  @override
  Future<void> addCollaborator(TicketCollaborator collaborator) async {}

  @override
  Future<void> removeCollaborator(String ticketId, String agentId) async {}

  @override
  Stream<List<TicketCollaborator>> watchCollaborators(String ticketId) =>
      const Stream.empty();

  @override
  Future<List<TicketCollaborator>> getCollaborators(String ticketId) async => [];
}

RemoteTicket _remote({
  required String externalId,
  String? externalKey,
  String title = 'Test ticket',
  String? description,
  DateTime? createdAt,
  DateTime? updatedAt,
}) =>
    RemoteTicket(
      externalId: externalId,
      externalKey: externalKey,
      url: 'https://linear.app/issue/$externalId',
      title: title,
      description: description,
      priority: TicketPriority.medium,
      labels: const ['bug'],
      status: TicketStatus.open,
      rawStatus: 'In Progress',
      createdAt: createdAt ?? DateTime(2025, 1, 1),
      updatedAt: updatedAt ?? DateTime(2025, 1, 1),
    );

void main() {
  group('TicketSyncService', () {
    test('syncs multiple remote tickets to repository', () async {
      final port = _FakeTicketProviderPort(
        tickets: [
          _remote(externalId: 'ext-1', externalKey: 'LIN-1'),
          _remote(externalId: 'ext-2', externalKey: 'LIN-2'),
          _remote(externalId: 'ext-3', externalKey: 'LIN-3'),
        ],
      );
      final repo = _FakeTicketRepository();
      final service = TicketSyncService(port: port, repository: repo);

      await service.sync('ws1');

      expect(port.listCallCount, 1);
      expect(repo.upserted.length, 3);
      expect(repo.upserted[0].externalKey, 'LIN-1');
      expect(repo.upserted[1].externalKey, 'LIN-2');
      expect(repo.upserted[2].externalKey, 'LIN-3');
    });

    test('sync maps remote fields to ticket mirror', () async {
      final port = _FakeTicketProviderPort(
        tickets: [
          _remote(
            externalId: 'ext-1',
            externalKey: 'LIN-42',
            title: 'Fix login bug',
            description: 'The login page crashes on Safari.',
          ),
        ],
      );
      final repo = _FakeTicketRepository();
      final service = TicketSyncService(port: port, repository: repo);

      await service.sync('ws1');

      final ticket = repo.upserted.single;
      expect(ticket.workspaceId, 'ws1');
      expect(ticket.provider, TicketProvider.linear);
      expect(ticket.externalKey, 'LIN-42');
      expect(ticket.title, 'Fix login bug');
      expect(ticket.description, 'The login page crashes on Safari.');
      expect(ticket.url, contains('ext-1'));
      expect(ticket.priority, TicketPriority.medium);
      expect(ticket.labels, ['bug']);
      expect(ticket.status, TicketStatus.open);
      expect(ticket.rawStatus, 'In Progress');
    });

    test('sync uses externalKey as externalKey when available', () async {
      final port = _FakeTicketProviderPort(
        tickets: [_remote(externalId: 'x', externalKey: 'KEY-99')],
      );
      final repo = _FakeTicketRepository();
      final service = TicketSyncService(port: port, repository: repo);

      await service.sync('ws1');

      expect(repo.upserted.single.externalKey, 'KEY-99');
    });

    test('sync falls back to externalId when externalKey is null', () async {
      final port = _FakeTicketProviderPort(
        tickets: [_remote(externalId: 'ext-5', externalKey: null)],
      );
      final repo = _FakeTicketRepository();
      final service = TicketSyncService(port: port, repository: repo);

      await service.sync('ws1');

      expect(repo.upserted.single.externalKey, 'ext-5');
    });

    test('sync assigns unique UUID id per ticket', () async {
      final port = _FakeTicketProviderPort(
        tickets: [
          _remote(externalId: 'e1'),
          _remote(externalId: 'e2'),
        ],
      );
      final repo = _FakeTicketRepository();
      final service = TicketSyncService(port: port, repository: repo);

      await service.sync('ws1');

      expect(repo.upserted[0].id, isNotEmpty);
      expect(repo.upserted[1].id, isNotEmpty);
      expect(repo.upserted[0].id, isNot(repo.upserted[1].id));
    });

    test('sync sets createdAt and updatedAt from remote when present', () async {
      final created = DateTime(2024, 6, 15);
      final updated = DateTime(2025, 1, 10);
      final port = _FakeTicketProviderPort(
        tickets: [_remote(externalId: 'e1', createdAt: created, updatedAt: updated)],
      );
      final repo = _FakeTicketRepository();
      final service = TicketSyncService(port: port, repository: repo);

      await service.sync('ws1');

      expect(repo.upserted.single.createdAt, created);
      expect(repo.upserted.single.updatedAt, updated);
    });

    test('sync falls back to DateTime.now for missing createdAt/updatedAt', () async {
      final before = DateTime.now();
      final port = _FakeTicketProviderPort(
        tickets: [
          const RemoteTicket(
            externalId: 'e1',
            title: 'Test',
            status: TicketStatus.open,
          ),
        ],
      );
      final repo = _FakeTicketRepository();
      final service = TicketSyncService(port: port, repository: repo);

      await service.sync('ws1');

      final after = DateTime.now();
      expect(repo.upserted.single.createdAt, isNotNull);
      expect(
        repo.upserted.single.createdAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch - 1000),
      );
      expect(
        repo.upserted.single.createdAt.millisecondsSinceEpoch,
        lessThanOrEqualTo(after.millisecondsSinceEpoch + 1000),
      );
    });

    test('sync with empty remote list is safe', () async {
      final port = _FakeTicketProviderPort(tickets: []);
      final repo = _FakeTicketRepository();
      final service = TicketSyncService(port: port, repository: repo);

      await service.sync('ws1');

      expect(repo.upserted, isEmpty);
    });

    test('sync is no-op when supportsRemoteSync is false', () async {
      final port = _FakeTicketProviderPort(
        tickets: [_remote(externalId: 'e1')],
        supportsSync: false,
      );
      final repo = _FakeTicketRepository();
      final service = TicketSyncService(port: port, repository: repo);

      await service.sync('ws1');

      expect(port.listCallCount, 0);
      expect(repo.upserted, isEmpty);
    });

    test('sync does not throw when port.list fails', () async {
      final port = _ThrowingTicketProviderPort();
      final repo = _FakeTicketRepository();
      final service = TicketSyncService(port: port, repository: repo);

      await service.sync('ws1');
      expect(repo.upserted, isEmpty);
    });

    test('sync does not throw when upsertMirror fails', () async {
      final port = _FakeTicketProviderPort(
        tickets: [_remote(externalId: 'e1')],
      );
      final repo = _ThrowingTicketRepository();
      final service = TicketSyncService(port: port, repository: repo);

      await service.sync('ws1');
    });
  });
}

class _ThrowingTicketProviderPort extends _FakeTicketProviderPort {
  @override
  Future<List<RemoteTicket>> list({TicketQuery query = const TicketQuery()}) async =>
      throw Exception('Network error');
}

class _ThrowingTicketRepository extends _FakeTicketRepository {
  @override
  Future<void> upsertMirror(Ticket ticket) async =>
      throw Exception('DB error');
}
