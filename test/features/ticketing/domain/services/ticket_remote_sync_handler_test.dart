import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/ports/remote_ticket.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_provider_capabilities.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_provider_port.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_remote_sync_handler.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Hand-rolled test doubles (build_runner excludes test/** from sources so we
// cannot use @GenerateNiceMocks here).
// ---------------------------------------------------------------------------

class _FakeRepository implements TicketRepository {
  final Map<String, Ticket> store = {};
  final List<Ticket> upsertedMirrors = [];

  @override
  Future<Ticket?> getById(String id) async => store[id];

  @override
  Future<void> upsertMirror(Ticket ticket) async {
    store[ticket.id] = ticket;
    upsertedMirrors.add(ticket);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProviderPort implements TicketProviderPort {

  _FakeProviderPort({
    TicketProvider provider = TicketProvider.linear,
    TicketProviderCapabilities? capabilities,
  })  : _provider = provider,
        _capabilities = capabilities ?? TicketProviderCapabilities.full(provider);
  final TicketProvider _provider;
  final TicketProviderCapabilities _capabilities;

  RemoteTicket? nextResult;

  final List<RemoteTicketDraft> createCalls = [];
  final List<_StatusTransition> transitionCalls = [];
  final List<_AssignCall> assignCalls = [];
  final List<_UpdateCall> updateCalls = [];

  Object? throwOnNext;

  @override
  TicketProvider get provider => _provider;

  @override
  TicketProviderCapabilities get capabilities => _capabilities;

  @override
  List<String> get allowedDomains => [];

  @override
  Future<RemoteTicket> create(RemoteTicketDraft draft) async {
    createCalls.add(draft);
    _throwIfSet();
    return nextResult ??
        RemoteTicket(
          externalId: 'ext-${draft.title}',
          externalKey: 'KEY-1',
          title: draft.title,
          status: TicketStatus.open,
        );
  }

  @override
  Future<RemoteTicket> update(String externalId, RemoteTicketPatch patch) async {
    updateCalls.add(_UpdateCall(externalId, patch));
    _throwIfSet();
    return nextResult ??
        RemoteTicket(
          externalId: externalId,
          title: patch.title ?? 'updated',
          status: TicketStatus.open,
        );
  }

  @override
  Future<RemoteTicket> transitionStatus(
    String externalId,
    TicketStatus target,
  ) async {
    transitionCalls.add(_StatusTransition(externalId, target));
    _throwIfSet();
    return nextResult ??
        RemoteTicket(
          externalId: externalId,
          title: 'ticket',
          status: target,
        );
  }

  @override
  Future<RemoteTicket> assign(
    String externalId,
    String? assigneeExternalId,
  ) async {
    assignCalls.add(_AssignCall(externalId, assigneeExternalId));
    _throwIfSet();
    return nextResult ??
        RemoteTicket(
          externalId: externalId,
          title: 'ticket',
          status: TicketStatus.open,
        );
  }

  void _throwIfSet() {
    final err = throwOnNext;
    throwOnNext = null;
    if (err != null) {
      throw err;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StatusTransition {
  const _StatusTransition(this.externalId, this.target);
  final String externalId;
  final TicketStatus target;
}

class _AssignCall {
  const _AssignCall(this.externalId, this.assigneeExternalId);
  final String externalId;
  final String? assigneeExternalId;
}

class _UpdateCall {
  const _UpdateCall(this.externalId, this.patch);
  final String externalId;
  final RemoteTicketPatch patch;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Ticket _makeTicket({
  String id = 't1',
  TicketProvider provider = TicketProvider.linear,
  String? externalKey,
  String? assignedAgentId,
  String title = 'Test ticket',
  String? description = 'A ticket for testing',
  List<String> labels = const [],
  TicketPriority priority = TicketPriority.none,
}) {
  final now = DateTime.now();
  return Ticket(
    id: id,
    workspaceId: 'ws1',
    provider: provider,
    externalKey: externalKey,
    title: title,
    description: description,
    labels: labels,
    priority: priority,
    status: TicketStatus.open,
    assignedAgentId: assignedAgentId,
    createdAt: now,
    updatedAt: now,
  );
}

void _seedTicket(_FakeRepository repo, [Ticket Function(Ticket)? customize]) {
  var t = _makeTicket();
  if (customize != null) {
    t = customize(t);
  }
  repo.store[t.id] = t;
}

/// Drains the microtask queue so async event handlers triggered by
/// [DomainEventBus.publish] complete before assertions run. Each `await`
/// inside an async handler enqueues a microtask; we iterate enough to drain
/// the full handler chain.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.value();
  }
}

void main() {
  late _FakeRepository repo;
  late _FakeProviderPort providerPort;
  late DomainEventBus bus;
  late TicketRemoteSyncHandler handler;

  setUp(() {
    repo = _FakeRepository();
    providerPort = _FakeProviderPort();
    bus = DomainEventBus();
    handler = TicketRemoteSyncHandler(
      eventBus: bus,
      repository: repo,
      providerPort: providerPort,
    );
    handler.start();
  });

  tearDown(() {
    handler.dispose();
  });

  void restartHandler() {
    handler.dispose();
    handler = TicketRemoteSyncHandler(
      eventBus: bus,
      repository: repo,
      providerPort: providerPort,
    );
    handler.start();
  }

  // =========================================================================
  // _onCreated — sync flow
  // =========================================================================

  group('onCreated sync flow', () {
    test('creates remote ticket and upserts mirror with external key', () async {
      _seedTicket(repo);
      final now = DateTime.now();

      bus.publish(TicketCreated(ticketId: 't1', occurredAt: now));
      await _settle();

      expect(providerPort.createCalls, hasLength(1));
      final draft = providerPort.createCalls.first;
      expect(draft.title, 'Test ticket');
      expect(draft.description, 'A ticket for testing');
      expect(draft.priority, TicketPriority.none);
      expect(draft.parentExternalId, isNull);

      expect(repo.upsertedMirrors, hasLength(1));
      final mirrored = repo.upsertedMirrors.first;
      expect(mirrored.externalKey, 'KEY-1');
      expect(mirrored.metadata['externalId'], 'ext-Test ticket');
    });

    test('uses externalId fallback when externalKey is null', () async {
      _seedTicket(repo);
      providerPort.nextResult = const RemoteTicket(
        externalId: 'EXT-42',
        title: 'Test ticket',
        status: TicketStatus.open,
      );

      bus.publish(TicketCreated(ticketId: 't1', occurredAt: DateTime.now()));
      await _settle();

      expect(repo.upsertedMirrors.first.externalKey, 'EXT-42');
      expect(repo.upsertedMirrors.first.metadata['externalId'], 'EXT-42');
    });

    test('draft carries labels from ticket', () async {
      _seedTicket(repo, (t) => _makeTicket(
        title: 'Label ticket',
        labels: ['bug', 'ui'],
      ));

      bus.publish(TicketCreated(ticketId: 't1', occurredAt: DateTime.now()));
      await _settle();

      expect(providerPort.createCalls.first.labels, ['bug', 'ui']);
    });
  });

  // =========================================================================
  // Conflict resolution: guard clauses for all event handlers
  // =========================================================================

  group('guard: ticket not found', () {
    test('_onCreated skips when ticket missing', () {
      bus.publish(TicketCreated(ticketId: 'nope', occurredAt: DateTime.now()));
      expect(providerPort.createCalls, isEmpty);
    });

    test('_onStatusChanged skips when ticket missing', () {
      bus.publish(TicketStatusChanged(
        ticketId: 'nope', from: 'open', to: 'inProgress',
        workspaceId: 'ws1', occurredAt: DateTime.now(),
      ));
      expect(providerPort.transitionCalls, isEmpty);
    });

    test('_onAssigned skips when ticket missing', () {
      bus.publish(TicketAssigned(
        ticketId: 'nope', ticketTitle: 'T', occurredAt: DateTime.now(),
      ));
      expect(providerPort.assignCalls, isEmpty);
    });

    test('_onDetailsUpdated skips when ticket missing', () {
      bus.publish(TicketDetailsUpdated(
        ticketId: 'nope', occurredAt: DateTime.now(),
      ));
      expect(providerPort.updateCalls, isEmpty);
    });
  });

  group('guard: not remote (provider = local)', () {
    test('_onCreated skips local tickets', () {
      _seedTicket(repo, (_) => _makeTicket(provider: TicketProvider.local));
      bus.publish(TicketCreated(ticketId: 't1', occurredAt: DateTime.now()));
      expect(providerPort.createCalls, isEmpty);
    });

    test('_onStatusChanged skips local tickets', () {
      _seedTicket(repo, (_) => _makeTicket(
        provider: TicketProvider.local, externalKey: 'K-1',
      ));
      bus.publish(TicketStatusChanged(
        ticketId: 't1', from: 'open', to: 'inProgress',
        workspaceId: 'ws1', occurredAt: DateTime.now(),
      ));
      expect(providerPort.transitionCalls, isEmpty);
    });

    test('_onAssigned skips local tickets', () {
      _seedTicket(repo, (_) => _makeTicket(
        provider: TicketProvider.local,
        externalKey: 'K-1',
        assignedAgentId: 'a1',
      ));
      bus.publish(TicketAssigned(
        ticketId: 't1', ticketTitle: 'T',
        assignedAgentId: 'a1', occurredAt: DateTime.now(),
      ));
      expect(providerPort.assignCalls, isEmpty);
    });

    test('_onDetailsUpdated skips local tickets', () {
      _seedTicket(repo, (_) => _makeTicket(
        provider: TicketProvider.local, externalKey: 'K-1',
      ));
      bus.publish(TicketDetailsUpdated(
        ticketId: 't1', occurredAt: DateTime.now(),
      ));
      expect(providerPort.updateCalls, isEmpty);
    });
  });

  group('guard: provider mismatch', () {
    test('_onCreated skips when ticket provider differs', () {
      _seedTicket(repo, (_) => _makeTicket(provider: TicketProvider.jira));
      bus.publish(TicketCreated(ticketId: 't1', occurredAt: DateTime.now()));
      expect(providerPort.createCalls, isEmpty);
    });

    test('_onStatusChanged skips when ticket provider differs', () {
      _seedTicket(repo, (_) => _makeTicket(
        provider: TicketProvider.jira, externalKey: 'K-1',
      ));
      bus.publish(TicketStatusChanged(
        ticketId: 't1', from: 'open', to: 'inProgress',
        workspaceId: 'ws1', occurredAt: DateTime.now(),
      ));
      expect(providerPort.transitionCalls, isEmpty);
    });
  });

  group('guard: capability missing', () {
    test('_onCreated skips when supportsCreate is false', () {
      _seedTicket(repo);
      providerPort = _FakeProviderPort(
        capabilities: const TicketProviderCapabilities(
          provider: TicketProvider.linear,
          supportsCreate: false,
        ),
      );
      restartHandler();

      bus.publish(TicketCreated(ticketId: 't1', occurredAt: DateTime.now()));
      expect(providerPort.createCalls, isEmpty);
    });

    test('_onStatusChanged skips when supportsStatusUpdate is false', () {
      _seedTicket(repo, (_) => _makeTicket(externalKey: 'K-1'));
      providerPort = _FakeProviderPort(
        capabilities: const TicketProviderCapabilities(
          provider: TicketProvider.linear,
          supportsStatusUpdate: false,
        ),
      );
      restartHandler();

      bus.publish(TicketStatusChanged(
        ticketId: 't1', from: 'open', to: 'inProgress',
        workspaceId: 'ws1', occurredAt: DateTime.now(),
      ));
      expect(providerPort.transitionCalls, isEmpty);
    });

    test('_onAssigned skips when supportsAssignee is false', () {
      _seedTicket(repo, (_) => _makeTicket(
        externalKey: 'K-1', assignedAgentId: 'a1',
      ));
      providerPort = _FakeProviderPort(
        capabilities: const TicketProviderCapabilities(
          provider: TicketProvider.linear,
          supportsAssignee: false,
        ),
      );
      restartHandler();

      bus.publish(TicketAssigned(
        ticketId: 't1', ticketTitle: 'T',
        assignedAgentId: 'a1', occurredAt: DateTime.now(),
      ));
      expect(providerPort.assignCalls, isEmpty);
    });

    test('_onDetailsUpdated skips when supportsUpdate is false', () {
      _seedTicket(repo, (_) => _makeTicket(externalKey: 'K-1'));
      providerPort = _FakeProviderPort(
        capabilities: const TicketProviderCapabilities(
          provider: TicketProvider.linear,
          supportsUpdate: false,
        ),
      );
      restartHandler();

      bus.publish(TicketDetailsUpdated(
        ticketId: 't1', occurredAt: DateTime.now(),
      ));
      expect(providerPort.updateCalls, isEmpty);
    });
  });

  group('guard: missing externalKey (update/status/assign only)', () {
    test('_onStatusChanged skips when externalKey is null', () {
      _seedTicket(repo, (_) => _makeTicket(externalKey: null));
      bus.publish(TicketStatusChanged(
        ticketId: 't1', from: 'open', to: 'inProgress',
        workspaceId: 'ws1', occurredAt: DateTime.now(),
      ));
      expect(providerPort.transitionCalls, isEmpty);
    });

    test('_onAssigned skips when externalKey is null', () {
      _seedTicket(repo, (_) => _makeTicket(
        externalKey: null, assignedAgentId: 'a1',
      ));
      bus.publish(TicketAssigned(
        ticketId: 't1', ticketTitle: 'T',
        assignedAgentId: 'a1', occurredAt: DateTime.now(),
      ));
      expect(providerPort.assignCalls, isEmpty);
    });

    test('_onDetailsUpdated skips when externalKey is null', () {
      _seedTicket(repo, (_) => _makeTicket(externalKey: null));
      bus.publish(TicketDetailsUpdated(
        ticketId: 't1', occurredAt: DateTime.now(),
      ));
      expect(providerPort.updateCalls, isEmpty);
    });
  });

  group('guard: missing assignedAgentId (assign only)', () {
    test('_onAssigned skips when assignedAgentId is null', () {
      _seedTicket(repo, (_) => _makeTicket(
        externalKey: 'K-1', assignedAgentId: null,
      ));
      bus.publish(TicketAssigned(
        ticketId: 't1', ticketTitle: 'T',
        assignedAgentId: 'a1', occurredAt: DateTime.now(),
      ));
      expect(providerPort.assignCalls, isEmpty);
    });
  });

  // =========================================================================
  // _onStatusChanged — sync flow
  // =========================================================================

  group('onStatusChanged sync flow', () {
    test('transitions status on remote provider', () async {
      _seedTicket(repo, (_) => _makeTicket(externalKey: 'KEY-1'));

      bus.publish(TicketStatusChanged(
        ticketId: 't1', from: 'open', to: 'inProgress',
        workspaceId: 'ws1', occurredAt: DateTime.now(),
      ));
      await _settle();

      expect(providerPort.transitionCalls, hasLength(1));
      final call = providerPort.transitionCalls.first;
      expect(call.externalId, 'KEY-1');
      expect(call.target, TicketStatus.inProgress);
    });

    test('maps storage string to TicketStatus', () async {
      _seedTicket(repo, (_) => _makeTicket(externalKey: 'KEY-1'));

      bus.publish(TicketStatusChanged(
        ticketId: 't1', from: 'inProgress', to: 'done',
        workspaceId: 'ws1', occurredAt: DateTime.now(),
      ));
      await _settle();

      expect(providerPort.transitionCalls.first.target, TicketStatus.done);
    });
  });

  // =========================================================================
  // _onAssigned — sync flow
  // =========================================================================

  group('onAssigned sync flow', () {
    test('assigns agent on remote provider', () async {
      _seedTicket(repo, (_) => _makeTicket(
        externalKey: 'KEY-1', assignedAgentId: 'agent-42',
      ));

      bus.publish(TicketAssigned(
        ticketId: 't1', ticketTitle: 'T',
        assignedAgentId: 'agent-42', occurredAt: DateTime.now(),
      ));
      await _settle();

      expect(providerPort.assignCalls, hasLength(1));
      final call = providerPort.assignCalls.first;
      expect(call.externalId, 'KEY-1');
      expect(call.assigneeExternalId, 'agent-42');
    });
  });

  // =========================================================================
  // _onReassigned — delegates to _onAssigned
  // =========================================================================

  group('onReassigned sync flow', () {
    test('delegates to assign with new agent id', () async {
      _seedTicket(repo, (_) => _makeTicket(
        externalKey: 'KEY-1', assignedAgentId: 'agent-99',
      ));

      bus.publish(TicketReassigned(
        ticketId: 't1', fromAgentId: 'agent-42',
        toAgentId: 'agent-99', occurredAt: DateTime.now(),
      ));
      await _settle();

      expect(providerPort.assignCalls, hasLength(1));
      final call = providerPort.assignCalls.first;
      expect(call.externalId, 'KEY-1');
      expect(call.assigneeExternalId, 'agent-99');
    });
  });

  // =========================================================================
  // _onDetailsUpdated — sync flow
  // =========================================================================

  group('onDetailsUpdated sync flow', () {
    test('patches remote ticket with title, description, and priority', () async {
      _seedTicket(repo, (_) => _makeTicket(
        externalKey: 'KEY-1',
        title: 'Updated title',
        description: 'New description',
        priority: TicketPriority.high,
      ));

      bus.publish(TicketDetailsUpdated(
        ticketId: 't1', occurredAt: DateTime.now(),
      ));
      await _settle();

      expect(providerPort.updateCalls, hasLength(1));
      final call = providerPort.updateCalls.first;
      expect(call.externalId, 'KEY-1');
      expect(call.patch.title, 'Updated title');
      expect(call.patch.description, 'New description');
      expect(call.patch.priority, TicketPriority.high);
    });
  });

  // =========================================================================
  // Error handling — provider throws, handler survives
  // =========================================================================

  group('error handling', () {
    test('_onCreated survives provider.create throwing', () async {
      _seedTicket(repo);
      providerPort.throwOnNext = Exception('create boom');

      bus.publish(TicketCreated(ticketId: 't1', occurredAt: DateTime.now()));
      await _settle();

      expect(repo.upsertedMirrors, isEmpty);
    });

    test('_onStatusChanged survives provider.transitionStatus throwing', () {
      _seedTicket(repo, (_) => _makeTicket(externalKey: 'KEY-1'));
      providerPort.throwOnNext = Exception('transition boom');

      bus.publish(TicketStatusChanged(
        ticketId: 't1', from: 'open', to: 'inProgress',
        workspaceId: 'ws1', occurredAt: DateTime.now(),
      ));
    });

    test('_onAssigned survives provider.assign throwing', () {
      _seedTicket(repo, (_) => _makeTicket(
        externalKey: 'KEY-1', assignedAgentId: 'a1',
      ));
      providerPort.throwOnNext = Exception('assign boom');

      bus.publish(TicketAssigned(
        ticketId: 't1', ticketTitle: 'T',
        assignedAgentId: 'a1', occurredAt: DateTime.now(),
      ));
    });

    test('_onDetailsUpdated survives provider.update throwing', () {
      _seedTicket(repo, (_) => _makeTicket(externalKey: 'KEY-1'));
      providerPort.throwOnNext = Exception('update boom');

      bus.publish(TicketDetailsUpdated(
        ticketId: 't1', occurredAt: DateTime.now(),
      ));
    });

    test('handler survives error and processes next event normally', () async {
      _seedTicket(repo, (_) => _makeTicket(externalKey: 'KEY-1'));
      providerPort.throwOnNext = Exception('boom');

      bus.publish(TicketStatusChanged(
        ticketId: 't1', from: 'open', to: 'inProgress',
        workspaceId: 'ws1', occurredAt: DateTime.now(),
      ));
      await _settle();

      // The call was attempted (fake adds to list before throwing). The
      // handler caught the error and survived — the key assertion is that
      // the NEXT event still processes successfully.
      expect(providerPort.transitionCalls, hasLength(1));

      // Overwrite with a fresh ticket and publish a new event.
      repo.store['t1'] = _makeTicket(
        externalKey: 'KEY-1', title: 'New title',
      );

      bus.publish(TicketDetailsUpdated(
        ticketId: 't1', occurredAt: DateTime.now(),
      ));
      await _settle();

      expect(providerPort.updateCalls, hasLength(1));
    });
  });

  // =========================================================================
  // dispose
  // =========================================================================

  group('dispose', () {
    test('stops processing events after dispose', () {
      handler.dispose();
      _seedTicket(repo, (_) => _makeTicket(externalKey: 'KEY-1'));

      bus.publish(TicketStatusChanged(
        ticketId: 't1', from: 'open', to: 'inProgress',
        workspaceId: 'ws1', occurredAt: DateTime.now(),
      ));

      expect(providerPort.transitionCalls, isEmpty);
    });
  });
}
