import 'dart:async';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/calendar_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/events/rig_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/notification_wire.dart';

/// Records the durable per-workspace notification feed.
///
/// Subscribes ONCE to the domain-event bus (unlike `RemoteEventForwarder`,
/// which is per connected device) and writes one `notification_feed` row per
/// notification-class event into the owning workspace's database, via the
/// same event → frame mapping the forwarder pushes — so the stored history
/// and the live toasts always agree. Clients render rows through their own
/// frame mapper, which is where localization and the PRD 16 §7 principal
/// routing apply; read/cleared state is per user (`notification_read_marks`).
///
/// Only frames the client actually renders as notifications are recorded:
/// task-lifecycle frames and `ticket_reassigned` are pushed live for other
/// surfaces but have no notification rendering, so storing them would only
/// bloat the feed. A frame without a `workspace_id` (genuinely
/// cross-workspace, e.g. external-PR polling against an unlinked repo) has no
/// owning database file and stays toast-only.
///
/// Follows the long-lived listener shape of `WorktreeGcListener`.
class NotificationFeedRecorder {
  /// Creates a [NotificationFeedRecorder].
  NotificationFeedRecorder({
    required DomainEventBus eventBus,
    required DaoNotificationFeedRepository repository,
  }) : _eventBus = eventBus,
       _repository = repository;

  final DomainEventBus _eventBus;
  final DaoNotificationFeedRepository _repository;
  final List<StreamSubscription<Object?>> _subs = [];

  /// Begins recording. Idempotent per instance lifetime.
  void start() {
    if (_subs.isNotEmpty) {
      return;
    }
    _subs
      ..add(
        _eventBus.on<MessageReceived>().listen(
          (e) => _record(messageReceivedFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<TicketAssigned>().listen(
          (e) => _record(ticketAssignedFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<TicketStatusChanged>().listen(
          (e) => _record(ticketStatusChangedFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<AgentRunCompleted>().listen(
          (e) => _record(agentRunCompletedFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<PullRequestPublished>().listen(
          (e) => _record(prPublishedFrame(e)),
        ),
      )
      ..add(_eventBus.on<PrMerged>().listen((e) => _record(prMergedFrame(e))))
      ..add(
        _eventBus.on<PrMentioned>().listen((e) => _record(prMentionedFrame(e))),
      )
      ..add(
        _eventBus.on<PrMergeReadinessChanged>().listen(
          (e) => _record(prMergeReadinessFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<PrReviewDecisionChanged>().listen(
          (e) => _record(prReviewDecisionFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<PrChecksStatusChanged>().listen(
          (e) => _record(prChecksStatusFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<PrCommentMentioned>().listen(
          (e) => _record(prCommentMentionedFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<PrThreadReplied>().listen(
          (e) => _record(prThreadRepliedFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<PrThreadResolved>().listen(
          (e) => _record(prThreadResolvedFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<PrReviewRequested>().listen(
          (e) => _record(prReviewRequestedFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<ReviewBecameStale>().listen(
          (e) => _record(reviewBecameStaleFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<ExternalPrMerged>().listen(
          (e) => _record(externalPrMergedFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<MeetingStartingSoon>().listen(
          (e) => _record(meetingStartingSoonFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<CalendarAuthExpired>().listen(
          (e) => _record(calendarAuthExpiredFrame(e)),
        ),
      )
      // Enclosures. Recorded like everything else the client renders: "the
      // machine went away" is exactly the kind of thing a person reads later
      // and asks "when did that happen".
      ..add(
        _eventBus.on<RigControlChanged>().listen(
          (e) => _record(rigControlChangedFrame(e)),
        ),
      )
      ..add(_eventBus.on<RigReaped>().listen((e) => _record(rigReapedFrame(e))))
      ..add(
        _eventBus.on<RigClosedEvent>().listen(
          (e) => _record(rigClosedFrame(e)),
        ),
      );
  }

  void _record(NotificationFrame? frame) {
    if (frame == null) {
      return;
    }
    final workspaceId = frame.params['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return;
    }
    // Fire-and-forget: a failed write drops one history row, never the event.
    unawaited(() async {
      try {
        await _repository.record(workspaceId, frame.method, frame.params);
      } catch (e) {
        CcHostLog.warning('NotificationFeedRecorder: record failed: $e');
      }
    }());
  }

  /// Stops recording and cancels all subscriptions.
  Future<void> dispose() async {
    await Future.wait(_subs.map((s) => s.cancel()));
    _subs.clear();
  }
}
