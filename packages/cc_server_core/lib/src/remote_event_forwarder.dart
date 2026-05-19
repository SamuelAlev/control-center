import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/calendar_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/events/rig_events.dart';
import 'package:cc_domain/core/domain/events/task_lifecycle_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/notification_wire.dart';

/// Resolves the workspace id a ticket belongs to (for events that don't carry
/// one, e.g. [TicketReassigned]). Returning null skips the event.
typedef TicketWorkspaceResolver = Future<String?> Function(String ticketId);

/// Resolves whether the session user is a member of [workspaceId]. Bound
/// per-session at construction; null on hosts without identity wiring
/// (single-user), where forwarding stays unconditional.
typedef WorkspaceMembershipChecker = Future<bool> Function(String workspaceId);

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
    required RemoteRpcChannelPort space,
    required this.deviceId,
    required this.userId,
    this.isMember,
    this.resolveTicketWorkspace,
  }) : _eventBus = eventBus,
       _space = space;

  final DomainEventBus _eventBus;
  final RemoteRpcChannelPort _space;

  /// The paired-device id this forwarder serves (for logging).
  final String deviceId;

  /// The authenticated user behind the session — membership checks resolve
  /// against this principal, never a client-supplied id.
  final String userId;

  /// Membership check for the workspace an event targets; verdicts are cached
  /// per workspace and invalidated by this user's WorkspaceMemberAdded/Removed
  /// events, so revocation stops the flow within one event round-trip.
  final WorkspaceMembershipChecker? isMember;

  /// Optional resolver for events without a workspace id ([TicketReassigned]).
  final TicketWorkspaceResolver? resolveTicketWorkspace;

  final List<StreamSubscription> _subs = [];

  /// Per-workspace membership verdicts for [userId]. Entries are invalidated
  /// on this user's membership add/remove events — never cached across them.
  final Map<String, bool> _membershipCache = {};

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
    _subs.add(
      _eventBus.on<PrMergeReadinessChanged>().listen(_onPrMergeReadiness),
    );
    _subs.add(
      _eventBus.on<PrReviewDecisionChanged>().listen(_onPrReviewDecision),
    );
    _subs.add(
      _eventBus.on<PrChecksStatusChanged>().listen(_onPrChecksStatus),
    );
    _subs.add(
      _eventBus.on<PrCommentMentioned>().listen(_onPrCommentMentioned),
    );
    _subs.add(_eventBus.on<PrThreadReplied>().listen(_onPrThreadReplied));
    _subs.add(_eventBus.on<PrThreadResolved>().listen(_onPrThreadResolved));
    _subs.add(
      _eventBus.on<ReviewBecameStale>().listen(_onReviewBecameStale),
    );
    _subs.add(_eventBus.on<ExternalPrMerged>().listen(_onExternalPrMerged));
    _subs.add(
      _eventBus.on<MeetingStartingSoon>().listen(_onMeetingStartingSoon),
    );
    _subs.add(
      _eventBus.on<CalendarAuthExpired>().listen(_onCalendarAuthExpired),
    );
    // Enclosures: a machine taken over, reclaimed or died under an agent.
    _subs.add(_eventBus.on<RigControlChanged>().listen(_onRigControlChanged));
    _subs.add(_eventBus.on<RigReaped>().listen(_onRigReaped));
    _subs.add(_eventBus.on<RigClosedEvent>().listen(_onRigClosed));
    // Membership liveness: a cached verdict must not outlive the change.
    _subs.add(
      _eventBus.on<WorkspaceMemberAdded>().listen((e) {
        if (e.userId == userId) {
          _membershipCache.remove(e.workspaceId);
        }
      }),
    );
    _subs.add(
      _eventBus.on<WorkspaceMemberRemoved>().listen((e) {
        if (e.userId == userId) {
          _membershipCache.remove(e.workspaceId);
        }
      }),
    );
    // A ROLE change does not change "is a member", but the cached verdict is
    // the input to gates that do read the role downstream, and a demotion to
    // viewer/guest is exactly the moment a stale entry is worst. Cheap to drop.
    _subs.add(
      _eventBus.on<WorkspaceMemberRoleChanged>().listen((e) {
        if (e.userId == userId) {
          _membershipCache.remove(e.workspaceId);
        }
      }),
    );
  }

  void _onTaskLifecycle(TaskLifecycleEvent event) {
    _deliver('notifications/task_${event.phase.wire}', event.toWire());
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

  void _onPrMergeReadiness(PrMergeReadinessChanged event) {
    _forward(prMergeReadinessFrame(event));
  }

  void _onPrReviewDecision(PrReviewDecisionChanged event) {
    _forward(prReviewDecisionFrame(event));
  }

  void _onPrChecksStatus(PrChecksStatusChanged event) {
    _forward(prChecksStatusFrame(event));
  }

  void _onPrCommentMentioned(PrCommentMentioned event) {
    _forward(prCommentMentionedFrame(event));
  }

  void _onPrThreadReplied(PrThreadReplied event) {
    _forward(prThreadRepliedFrame(event));
  }

  void _onPrThreadResolved(PrThreadResolved event) {
    _forward(prThreadResolvedFrame(event));
  }

  void _onReviewBecameStale(ReviewBecameStale event) {
    _forward(reviewBecameStaleFrame(event));
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

  void _onRigControlChanged(RigControlChanged event) {
    _forward(rigControlChangedFrame(event));
  }

  void _onRigReaped(RigReaped event) {
    _forward(rigReapedFrame(event));
  }

  void _onRigClosed(RigClosedEvent event) {
    _forward(rigClosedFrame(event));
  }

  void _forward(NotificationFrame? frame) {
    if (frame == null) {
      return;
    }
    _deliver(frame.method, frame.params);
  }

  /// Delivers a notification frame when the session user is entitled to its
  /// workspace. A frame whose `workspace_id` names a workspace the user does
  /// NOT belong to is dropped server-side — the client never sees it. Frames
  /// without a workspace id are user-targeted (mentions, unresolved
  /// reassignments) and pass through, matching the pre-gate behavior.
  void _deliver(String method, Map<String, dynamic> params) {
    final checker = isMember;
    final workspaceId = params['workspace_id'];
    if (checker == null || workspaceId is! String || workspaceId.isEmpty) {
      _notify(method, params);
      return;
    }
    unawaited(() async {
      final cached = _membershipCache[workspaceId];
      final allowed = cached ?? await checker(workspaceId);
      _membershipCache[workspaceId] = allowed;
      if (allowed) {
        _notify(method, params);
      }
    }());
  }

  void _notify(String method, Map<String, dynamic> params) {
    if (!_space.isOpen) {
      return;
    }
    final frame = JsonRpcNotification(method: method, params: params).toJson();
    // Fire-and-forget: a transient send failure just drops one notification;
    // the phone resyncs its lists on reconnect.
    _space.send(frame).catchError((Object e) {
      CcHostLog.warning('RemoteControl: Forwarder($deviceId) send failed: $e');
    });
  }

  /// Stops forwarding and cancels all subscriptions.
  Future<void> dispose() async {
    await Future.wait(_subs.map((s) => s.cancel()));
    _subs.clear();
  }
}
