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

/// Durable per-workspace notification feed from domain events (same mapping as live toasts).
///
/// Skips frames with no notification rendering and frames without `workspace_id`.
/// When an agent wait ends ([AgentInputResolved]) the row that announced it is
/// stamped resolved, so the bell stops counting it.
class NotificationFeedRecorder {
  /// Creates a [NotificationFeedRecorder].
  NotificationFeedRecorder({
    required this._eventBus,
    required this._repository,
  });

  final DomainEventBus _eventBus;
  final DaoNotificationFeedRepository _repository;
  final List<StreamSubscription<Object?>> _subs = [];

  /// Feed writes run one after another, in event order: a wait that resolves
  /// while its row is still being inserted must find the row.
  Future<void> _writes = Future<void>.value();

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
      )
      ..add(
        _eventBus.on<AgentAwaitingInput>().listen(
          (e) => _record(agentAwaitingInputFrame(e)),
        ),
      )
      ..add(
        _eventBus.on<AgentInputResolved>().listen(
          (e) => _write(
            'resolve',
            () => _repository.resolveAgentWait(e.workspaceId, e.waitId),
          ),
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
    _write(
      'record',
      () => _repository.record(workspaceId, frame.method, frame.params),
    );
  }

  // Fire-and-forget: a failed write drops one history row, never the event.
  void _write(String what, Future<Object?> Function() write) {
    _writes = _writes.then((_) async {
      try {
        await write();
      } catch (e) {
        CcHostLog.warning('NotificationFeedRecorder: $what failed: $e');
      }
    });
  }

  /// Stops recording and cancels all subscriptions.
  Future<void> dispose() async {
    await Future.wait(_subs.map((s) => s.cancel()));
    _subs.clear();
  }
}
