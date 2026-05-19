import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/ports/remote_ticket.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_provider_capabilities.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_provider_port.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_query.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_infra/src/tickets/ticket_sync_service.dart';
import 'package:test/test.dart';

class _FakePort implements TicketProviderPort {
  _FakePort({
    this.remoteSync = true,
    List<RemoteTicket>? listResult,
    Object? listError,
  }) : provider = TicketProvider.linear,
       _listResult = listResult,
       _listError = listError;

  @override
  final TicketProvider provider;

  @override
  TicketProviderCapabilities get capabilities => TicketProviderCapabilities(
    provider: provider,
    supportsRemoteSync: remoteSync,
  );

  final bool remoteSync;
  final List<RemoteTicket>? _listResult;
  final Object? _listError;

  final List<RemoteTicketDraft> created = [];
  final List<String> fetched = [];

  @override
  Future<List<RemoteTicket>> list({
    TicketQuery query = const TicketQuery(),
  }) async {
    if (_listError != null) {
      throw _listError;
    }
    return _listResult ?? const [];
  }

  @override
  Future<RemoteTicket> create(RemoteTicketDraft draft) async {
    created.add(draft);
    return RemoteTicket(
      externalId: 'new-id',
      title: draft.title,
      status: TicketStatus.backlog,
    );
  }

  @override
  Future<RemoteTicket?> getByExternalId(String externalId) async {
    fetched.add(externalId);
    return null;
  }

  @override
  Future<RemoteTicket> update(
    String externalId,
    RemoteTicketPatch patch,
  ) async {
    throw UnimplementedError('unused');
  }

  @override
  Future<RemoteTicket> transitionStatus(
    String externalId,
    TicketStatus target,
  ) async => throw UnimplementedError('unused');

  @override
  Future<RemoteTicket> assign(
    String externalId,
    String? assigneeExternalId,
  ) async => throw UnimplementedError('unused');

  @override
  Stream<RemoteTicket> watchAssigned() => const Stream<RemoteTicket>.empty();

  @override
  List<String> get allowedDomains => const ['linear.app'];
}

class _RecordingRepo implements TicketRepository {
  final List<Ticket> mirrored = [];

  @override
  Future<void> upsertMirror(Ticket ticket) async => mirrored.add(ticket);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TicketSyncService', () {
    test('no-op when provider does not support remote sync', () async {
      final repo = _RecordingRepo();
      final port = _FakePort(remoteSync: false);
      final svc = TicketSyncService(port: port, repository: repo);
      await svc.sync('ws');
      expect(repo.mirrored, isEmpty);
    });

    test('mirrors every remote ticket into the local store', () async {
      final repo = _RecordingRepo();
      final port = _FakePort(
        remoteSync: true,
        listResult: [
          const RemoteTicket(
            externalId: 'a',
            externalKey: 'LIN-1',
            title: 'First',
            status: TicketStatus.inProgress,
            rawStatus: 'In Progress',
          ),
          const RemoteTicket(
            externalId: 'b',
            title: 'Second',
            status: TicketStatus.backlog,
          ),
        ],
      );
      final svc = TicketSyncService(port: port, repository: repo);
      await svc.sync('ws');

      expect(repo.mirrored, hasLength(2));
      final first = repo.mirrored[0];
      expect(first.workspaceId, 'ws');
      expect(first.provider, TicketProvider.linear);
      expect(first.externalKey, 'LIN-1');
      expect(first.title, 'First');
      expect(first.status, TicketStatus.inProgress);
      expect(first.rawStatus, 'In Progress');
      // externalKey is preferred over externalId when present.
      expect(repo.mirrored[1].externalKey, 'b');
    });

    test('list failure is swallowed (logged, not rethrown)', () async {
      final repo = _RecordingRepo();
      final port = _FakePort(
        remoteSync: true,
        listError: StateError('network down'),
      );
      final svc = TicketSyncService(port: port, repository: repo);
      // No throw.
      await svc.sync('ws');
      expect(repo.mirrored, isEmpty);
    });

    test('empty remote list mirrors nothing', () async {
      final repo = _RecordingRepo();
      final port = _FakePort(remoteSync: true, listResult: const []);
      final svc = TicketSyncService(port: port, repository: repo);
      await svc.sync('ws');
      expect(repo.mirrored, isEmpty);
    });
  });
}
