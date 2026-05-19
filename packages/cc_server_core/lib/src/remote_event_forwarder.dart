import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/calendar_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/events/task_lifecycle_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/notification_wire.dart';

/// Resolves the workspace id a ticket belongs to (for events that don't carry
/// one, e.g. [TicketReassigned]). Returning null skips the event.
typedef TicketWorkspaceResolver = Future<String?> Function(String ticketId);

/// Pushes live workspace-scoped updates to every connected client as JSON-RPC
/// notifications (id-less frames) — the single source the client-side
/// `RpcNotificationMapper` renders as OS notifications, on every transport
/// (loopback self-serve, LAN/WSS, paired phone over WebRTC).
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
    // The unified task-lifecycle stream (queued → … → completed/failed, plus
    // typed task:message frames). The sealed base captures every subtype.
    _subs.add(_eventBus.on<TaskLifecycleEvent>().listen(_onTaskLifecycle));
    _subs.add(_eventBus.on<AgentRunCompleted>().listen(_onAgentRunCompleted));
    _subs.add(
      _eventBus.on<PullRequestPublished>().listen(_onPullRequestPublished),
    );
    _subs.add(_eventBus.on<PrMerged>().listen(_onPrMerged));
    _subs.add(_eventBus.on<PrMentioned>().listen(_onPrMentioned));
    _subs.add(_eventBus.on<PrReviewRequested>().listen(_onPrReviewRequested));
    _subs.add(_eventBus.on<ExternalPrMerged>().listen(_onExternalPrMerged));
    _subs.add(
      _eventBus.on<MeetingStartingSoon>().listen(_onMeetingStartingSoon),
    );
    _subs.add(
      _eventBus.on<CalendarAuthExpired>().listen(_onCalendarAuthExpired),
    );
  }

  void _onTaskLifecycle(TaskLifecycleEvent event) {
    _notify('notifications/task_${event.phase.wire}', event.toWire());
  }

  void _onMessageReceived(MessageReceived event) {
    _forward(messageReceivedFrame(event));
  }

  void _onTicketAssigned(TicketAssigned event) {
    _forward(ticketAssignedFrame(event));
  }

  void _onTicketStatusChanged(TicketStatusChanged event) {
    _forward(ticketStatusChangedFrame(event));
  }

  Future<void> _onTicketReassigned(TicketReassigned event) async {
    // TicketReassigned carries no workspace id; resolve it (when a resolver is
    // wired) only to populate the payload's workspace_id so the client can
    // filter — forwarding is unconditional (the server is stateless).
    final resolver = resolveTicketWorkspace;
    final workspaceId = resolver == null
        ? null
        : await resolver(event.ticketId);
    _forward(ticketReassignedFrame(event, workspaceId));
  }

  void _onAgentRunCompleted(AgentRunCompleted event) {
    _forward(agentRunCompletedFrame(event));
  }

  void _onPullRequestPublished(PullRequestPublished event) {
    _forward(prPublishedFrame(event));
  }

  void _onPrMerged(PrMerged event) {
    _forward(prMergedFrame(event));
  }

  void _onPrMentioned(PrMentioned event) {
    _forward(prMentionedFrame(event));
  }

  void _onPrReviewRequested(PrReviewRequested event) {
    _forward(prReviewRequestedFrame(event));
  }

  void _onExternalPrMerged(ExternalPrMerged event) {
    _forward(externalPrMergedFrame(event));
  }

  void _onMeetingStartingSoon(MeetingStartingSoon event) {
    _forward(meetingStartingSoonFrame(event));
  }

  void _onCalendarAuthExpired(CalendarAuthExpired event) {
    _forward(calendarAuthExpiredFrame(event));
  }

  void _forward(NotificationFrame? frame) {
    if (frame == null) {
      return;
    }
    _notify(frame.method, frame.params);
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
