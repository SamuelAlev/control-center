import 'dart:async';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/messaging/domain/ports/messaging_port.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';

/// Keeps a ticket's discussion channel membership in sync as collaborators are
/// added. Channel *creation* and the assignee's dispatch are owned by the
/// `TicketDispatcher` (the single dispatch path); this service only widens
/// participation when extra collaborators join an already-open ticket channel.
///
/// Event-driven (mirrors the CEO-seed and task-resume listeners) so
/// `TicketWorkflowService` stays pure-domain.
class TicketChannelService {
  /// Creates a [TicketChannelService].
  TicketChannelService({
    required this.eventBus,
    required this.ticketRepository,
    required this.messagingPort,
  });

  /// Event bus we subscribe to.
  final DomainEventBus eventBus;

  /// Read access to tickets (to resolve the linked channel).
  final TicketRepository ticketRepository;

  /// Messaging operations.
  final MessagingPort messagingPort;

  StreamSubscription<TicketCollaboratorAdded>? _sub;

  /// Start listening.
  void start() {
    _sub = eventBus.on<TicketCollaboratorAdded>().listen(_onCollaboratorAdded);
  }

  /// Stop listening.
  void dispose() {
    _sub?.cancel();
  }

  Future<void> _onCollaboratorAdded(TicketCollaboratorAdded event) async {
    try {
      if (event.agentId == TicketCollaborator.userSentinel) {
        return;
      }
      final ticket = await ticketRepository.getById(event.ticketId);
      final channelId = ticket?.channelId;
      if (channelId == null) {
        return;
      }
      await messagingPort.addAgentToChannel(channelId, event.agentId);
    } on Object catch (e, st) {
      AppLog.e('TicketChannelService', 'collaborator hook failed', e, st);
    }
  }
}
