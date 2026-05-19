import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Resolves the workspace id a ticket belongs to (for events that don't carry
/// one, e.g. [TicketReassigned]). Returning null skips the event.
typedef TicketWorkspaceResolver = Future<String?> Function(String ticketId);

/// Pushes live workspace-scoped updates to one connected device as JSON-RPC
/// notifications (id-less frames), mirroring the desktop notification mapper but
/// for the remote channel instead of OS notifications.
///
/// The server is stateless — there is no per-session workspace binding — so
/// every event the device is entitled to is forwarded, each carrying its own
/// `workspace_id` in the payload; the client filters to its active workspace.
/// Agent messages are forwarded only (user messages carry no workspace and
/// never raise a desktop notification either).
class RemoteEventForwarder {
  /// Creates a [RemoteEventForwarder].
  RemoteEventForwarder({
    required DomainEventBus eventBus,
    required RemoteRpcChannelPort channel,
    required this.deviceId,
    this.resolveTicketWorkspace,
  }) : _eventBus = eventBus,
       _channel = channel;

  final DomainEventBus _eventBus;
  final RemoteRpcChannelPort _channel;

  /// The paired-device id this forwarder serves (for logging).
  final String deviceId;

  /// Optional resolver for events without a workspace id ([TicketReassigned]).
  final TicketWorkspaceResolver? resolveTicketWorkspace;

  final List<StreamSubscription> _subs = [];

  /// Begins forwarding events. Idempotent.
  void start() {
    _subs.add(_eventBus.on<MessageReceived>().listen(_onMessageReceived));
    _subs.add(_eventBus.on<TicketAssigned>().listen(_onTicketAssigned));
    _subs.add(
      _eventBus.on<TicketStatusChanged>().listen(_onTicketStatusChanged),
    );
    _subs.add(_eventBus.on<TicketReassigned>().listen(_onTicketReassigned));
  }

  void _onMessageReceived(MessageReceived event) {
    // User messages carry no workspace and never raise a desktop notification;
    // mirror that policy on the remote channel.
    if (!event.isAgentMessage) {
      return;
    }
    _notify('notifications/message_received', {
      'channel_id': event.channelId,
      'message_id': event.messageId,
      'sender_name': event.senderName,
      'content_preview': event.contentPreview,
      'workspace_id': event.workspaceId,
    });
  }

  void _onTicketAssigned(TicketAssigned event) {
    _notify('notifications/ticket_assigned', {
      'ticket_id': event.ticketId,
      'ticket_title': event.ticketTitle,
      if (event.assignedAgentId != null)
        'assigned_agent_id': event.assignedAgentId,
      if (event.ticketUrl != null) 'ticket_url': event.ticketUrl,
      'workspace_id': event.workspaceId,
    });
  }

  void _onTicketStatusChanged(TicketStatusChanged event) {
    _notify('notifications/ticket_status_changed', {
      'ticket_id': event.ticketId,
      'from': event.from,
      'to': event.to,
      'workspace_id': event.workspaceId,
    });
  }

  Future<void> _onTicketReassigned(TicketReassigned event) async {
    // TicketReassigned carries no workspace id; resolve it (when a resolver is
    // wired) only to populate the payload's workspace_id so the client can
    // filter — forwarding is unconditional (the server is stateless).
    final resolver = resolveTicketWorkspace;
    final workspaceId = resolver == null ? null : await resolver(event.ticketId);
    _notify('notifications/ticket_reassigned', {
      'ticket_id': event.ticketId,
      if (event.fromAgentId != null) 'from_agent_id': event.fromAgentId,
      if (event.toAgentId != null) 'to_agent_id': event.toAgentId,
      'workspace_id': ?workspaceId,
    });
  }

  void _notify(String method, Map<String, dynamic> params) {
    if (!_channel.isOpen) {
      return;
    }
    final frame = JsonRpcNotification(method: method, params: params).toJson();
    // Fire-and-forget: a transient send failure just drops one notification;
    // the phone resyncs its lists on reconnect.
    _channel.send(frame).catchError((Object e) {
      CcHostLog.warning('RemoteControl: Forwarder($deviceId) send failed: $e');
    });
  }

  /// Stops forwarding and cancels all subscriptions.
  Future<void> dispose() async {
    await Future.wait(_subs.map((s) => s.cancel()));
    _subs.clear();
  }
}
