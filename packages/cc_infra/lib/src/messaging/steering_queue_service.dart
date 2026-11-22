import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show SteeringNotYoursException;
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_lifecycle_states.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/steering_texts.dart';
import 'package:cc_harness/loop.dart' show SteeringChannel, SteeringMessage;
import 'package:cc_infra/src/dispatch/steering_session_view.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Outcome of a successful [SteeringQueueService.enqueue].
class EnqueueSteeringResult {
  /// Creates a result.
  const EnqueueSteeringResult({
    required this.messageId,
    required this.steerable,
  });

  /// The persisted steering message row id.
  final String messageId;

  /// Whether at least one live run can inject mid-run (built-in harness, or a
  /// `claude -p` turn with its stdin open). False for ACP: the card still
  /// queues and converts at run end, but a "steer now" affordance would be a
  /// lie, so the client offers to stop the run and send the card instead.
  final bool steerable;
}

/// The responder tail of a user message — see
/// `MessagingService.dispatchResponderForText`. A function type (not a class)
/// so the queue service depends on the seam, not the whole messaging service.
typedef DispatchResponder =
    Future<void> Function({
      required String workspaceId,
      required String spaceId,
      String? conversationId,
      required String content,
      String? senderUserId,
      List<MessageAttachment> attachments,
      List<String> promptImageRefs,
    });

/// Rewrites a card's `@[file:<name>]` references to the paths its
/// attachments were materialized to — see
/// `MessagingService.withAttachmentPaths`. A live run reads a card as text,
/// so a reference it cannot open would be a picture it never sees.
typedef AttachmentPathResolver =
    Future<String> Function({
      required String workspaceId,
      required String spaceId,
      required String text,
      required List<MessageAttachment> attachments,
    });

/// Makes the cards held at run `runId`'s usage limit agree with its pause
/// (`LimitParkService.reconcileCards`). Returns how many cards moved.
typedef LimitHoldReconciler =
    Future<int> Function({
      required String workspaceId,
      required String spaceId,
      required String conversationId,
      required String runId,
    });

/// Live sessions of a conversation, as seen by the steering queue.
typedef SteeringSessionsFor =
    List<SteeringSessionView> Function(String conversationId);

/// Merges `patch` into a steering card's metadata only while the card is in
/// `fromState`, onto the CURRENT row, returning whether it was — the
/// `MessagingDao.patchSteering` primitive. Every queue write goes through it,
/// so racing writers (a reorder, a live drain, the run-end conversion) can no
/// longer clobber each other with metadata read moments earlier.
typedef SteeringPatcher =
    Future<bool> Function(
      String workspaceId,
      String messageId, {
      required String fromState,
      required Map<String, dynamic> patch,
      String? content,
      String? messageType,
    });

/// The display name of person [userId] (a card's writer), for the line a
/// live run reads before another person's card; null when unknown.
typedef SteeringWriterName =
    Future<String?> Function(String workspaceId, String userId);

/// Whether a goal in [conversationId] is still active (will start its next
/// segment by itself).
typedef SteeringGoalContinues =
    Future<bool> Function(String workspaceId, String conversationId);

/// Posts a system line into a conversation (a failed run-end send).
typedef SteeringNotice =
    Future<void> Function({
      required String workspaceId,
      required String spaceId,
      required String conversationId,
      required String text,
    });

/// What `steering.forceSend` did with a card.
enum SteeringForceOutcome {
  /// A live run took the card and keeps working.
  delivered,

  /// The card is first in the queue and every live run was asked to stop;
  /// the run-end conversion sends it as the next turn.
  stopping,

  /// No run was live, so the queue was sent as a normal turn right away.
  sent,

  /// The card was handed to nothing: no longer queued (already injected,
  /// converted or deleted), or still queued because only a read-only run
  /// (a goal's review) is live, which neither takes it nor is stopped for
  /// it; it waits for the worker's next run.
  notQueued,

  /// Stopping the runs was needed but the caller may not stop runs.
  stopRefused;

  /// Wire value.
  String get wire => switch (this) {
    delivered => 'delivered',
    stopping => 'stopping',
    sent => 'sent',
    notQueued => 'not_queued',
    stopRefused => 'stop_refused',
  };
}

/// Durable conversation-scoped steering queue (`MessageType.steering`,
/// `metadata['steerState']`) shown in the strip until a run takes it.
///
/// `enqueue` persists + pushes into live run inboxes (`ref` = row id); drain →
/// `injected` (strip → trail). The harness drains at turn boundaries, a
/// `claude -p` turn as messages arrive. ACP has no mid-run lane — rows stay
/// queued/editable until last run ends, then convert to `text` in order and
/// dispatch like a typed message (never silently swallow).
/// `reorder` stamps `steerOrder`; `deliver` jumps to the front of live queues.
///
/// A run's end arrives as `AgentRunSettled` on the event bus. A person's stop
/// ([RunEndReason.stoppedByUser]) HOLDS the queue (`steerState: held`): the
/// cards wait, kept out of every run, until [releaseHeldBy] sends them or
/// they are deleted. A server stop leaves the cards queued for the next run. Every
/// other end converts them as described above. [handleHarnessStarted] is
/// wired from the dispatch adapter.
class SteeringQueueService {
  /// Creates the service, listening for run ends on [eventBus] (null in
  /// narrow tests, which call [handleRunSettled] directly).
  SteeringQueueService({
    required MessagingRepository messagingRepository,
    required AgentRunLogRepository runLogRepository,
    required this._dispatchResponder,
    required SteeringSessionsFor sessionsForConversation,
    required DomainEventBus? eventBus,
    required this._writerName,
    this._queuedSteering,
    this._resolveAttachmentPaths,
    this._patchSteering,
    this._postNotice,
  }) : _messaging = messagingRepository,
       _runLogs = runLogRepository,
       _sessionsFor = sessionsForConversation {
    _settledSub = eventBus?.on<AgentRunSettled>().listen(
      (event) => unawaited(handleRunSettled(event)),
    );
  }

  StreamSubscription<AgentRunSettled>? _settledSub;

  /// Conversations (`workspaceId/conversationId`) where [forceSend] is
  /// stopping the runs to send a card, and when it started: those stops
  /// convert the queue (that is what the person asked for) instead of
  /// holding it. A mark older than [_stopAndSendWindow] is stale (its stop
  /// never settled) and is ignored.
  final Map<String, DateTime> _stopAndSend = {};

  static const Duration _stopAndSendWindow = Duration(minutes: 2);

  /// Stops listening for run ends.
  Future<void> dispose() async {
    await _settledSub?.cancel();
    _settledSub = null;
  }

  final MessagingRepository _messaging;
  final AgentRunLogRepository _runLogs;
  final DispatchResponder _dispatchResponder;
  final SteeringSessionsFor _sessionsFor;
  final SteeringWriterName _writerName;

  /// Whether a goal goes on after its review ended: when it does not, the
  /// cards its review kept queued are held as a Stop's. Late-bound (the
  /// goal side is built after this queue); unwired keeps them queued.
  SteeringGoalContinues? goalContinues;

  /// The metadata key set (true) on a card whose writer held the write grant
  /// on the space's repositories when it was queued: only such a card enters
  /// a live run that does not act for its writer.
  static const String writerWriteKey = 'steerWriterWrite';

  /// Resolves attachment references for live injection. Null injects the
  /// stored text as-is.
  final AttachmentPathResolver? _resolveAttachmentPaths;

  /// The conditional write behind every queue mutation. Null falls back to
  /// a fresh read + check + [MessagingRepository.updateMessage] (tests); the
  /// server wires the transactional DAO primitive.
  final SteeringPatcher? _patchSteering;

  /// Where a failure the user must see is reported. Null only logs.
  final SteeringNotice? _postNotice;

  /// Queued steering cards without a full-conversation scan. Null keeps
  /// [MessagingRepository.getMessages], which tests use.
  final Future<List<Message>> Function({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
  })?
  _queuedSteering;

  /// Queues [content] against the runs live in [conversationId].
  ///
  /// [attachments] are the uploaded `metadata['attachments']` entries of a
  /// normal send; they are stored on the card, injected as paths and handed
  /// to the follow-up turn when the card converts at run end.
  ///
  /// Returns null when no run is active (the caller falls through to a normal
  /// send) or there is nothing to send.
  Future<EnqueueSteeringResult?> enqueue({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
    required String senderUserId,
    required bool writerMayDirect,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    final text = content.trim();
    final stored = MessageAttachment.attachmentsFromMetadata({
      'attachments': attachments,
    });
    // A card is sent only as its writer: none is stored without one.
    if ((text.isEmpty && stored.isEmpty) || senderUserId.trim().isEmpty) {
      return null;
    }
    final active = await _liveRuns(
      workspaceId,
      conversationId,
    );
    if (active.isEmpty) {
      return null;
    }
    final order = await _nextOrder(workspaceId, spaceId, conversationId);
    final messageId = await _messaging.insertSteeringMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      content: text,
      senderId: senderUserId,
      metadata: {
        'steerState': 'queued',
        'steerOrder': order,
        if (writerMayDirect) writerWriteKey: true,
        if (stored.isNotEmpty)
          'attachments': [for (final a in stored) a.toJson()],
      },
    );
    final laneText = await _laneText(
      workspaceId: workspaceId,
      spaceId: spaceId,
      content: text,
      attachments: stored,
    );
    return EnqueueSteeringResult(
      messageId: messageId,
      steerable: await _pushCard(
        workspaceId,
        conversationId,
        ref: messageId,
        writer: senderUserId,
        writerWrite: writerMayDirect,
        laneText: laneText,
      ),
    );
  }

  /// Whether a live run in [conversationId] that takes cards mid-run does
  /// not act for [callerId] (another person's, or one acting for no one):
  /// text the caller queues or sends now would reach it, which needs their
  /// write grant. A run that takes no card (a review, a CLI run) is not
  /// reached: what it leaves becomes the writer's own turn.
  Future<bool> steersAnother(
    String workspaceId,
    String conversationId,
    String callerId,
  ) async => _harnessSessions(
    workspaceId,
    conversationId,
  ).any((s) => s.requestedByUserId != callerId);

  /// Rewrites a still-queued card. Injected/converted rows are conversation
  /// history and are refused (returns false). A live queue holding the old
  /// text is updated too — the run must not inject what the user just
  /// retracted. The replacement rejoins its lane at the end. Only its
  /// writer edits a card (it is sent as them): another caller is refused
  /// with [SteeringNotYoursException].
  Future<bool> edit({
    required String workspaceId,
    required String conversationId,
    required String messageId,
    required String content,
    required String callerId,
  }) async {
    if (content.trim().isEmpty) {
      return false;
    }
    final row = await _findQueuedRow(workspaceId, conversationId, messageId);
    if (row == null) {
      return false;
    }
    if (row.senderId != callerId) {
      throw const SteeringNotYoursException(othersHeld: 1);
    }
    if (!await _patch(
      workspaceId,
      messageId,
      fromState: 'queued',
      patch: {'editedAt': DateTime.now().millisecondsSinceEpoch},
      content: content.trim(),
    )) {
      return false; // Injected or converted in the meantime.
    }
    final laneText = await _laneText(
      workspaceId: workspaceId,
      spaceId: row.spaceId,
      content: content.trim(),
      attachments: row.attachments,
    );
    for (final session in _harnessSessions(workspaceId, conversationId)) {
      session.steeringQueue.removeByRef(messageId);
    }
    await _pushCard(
      workspaceId,
      conversationId,
      ref: messageId,
      writer: row.senderId,
      writerWrite: _writerWrite(row),
      laneText: laneText,
    );
    return true;
  }

  /// Deletes a still-queued or held card, from the row store AND every live
  /// queue.
  Future<bool> delete({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async {
    final row = await _findQueuedRow(
      workspaceId,
      conversationId,
      messageId,
      orHeld: true,
    );
    if (row == null) {
      return false;
    }
    for (final session in _harnessSessions(workspaceId, conversationId)) {
      session.steeringQueue.removeByRef(messageId);
    }
    await _messaging.deleteSteeringMessage(workspaceId, messageId);
    return true;
  }

  /// Persists a manual order ([orderedIds], ascending delivery priority) for
  /// the conversation's queued cards, and rebuilds every live queue's lane to
  /// match. Ids not named (or no longer queued) keep their relative order
  /// behind the named ones.
  Future<void> reorder({
    required String workspaceId,
    required String conversationId,
    required List<String> orderedIds,
  }) async {
    final spaceId = await _spaceIdFor(workspaceId, conversationId);
    if (spaceId == null) {
      return;
    }
    final queued = await _queuedRows(workspaceId, spaceId, conversationId);
    if (queued.isEmpty) {
      return;
    }
    final byId = {for (final row in queued) row.id: row};
    final ordered = <Message>[];
    for (final id in orderedIds) {
      final row = byId.remove(id);
      if (row != null) {
        ordered.add(row);
      }
    }
    queued.sort((a, b) => a.steerOrder.compareTo(b.steerOrder));
    ordered.addAll(byId.values);

    var index = 0;
    final stillQueued = <Message>[];
    for (final row in ordered) {
      // Only cards still queued move; one a run drained meanwhile keeps its
      // `injected` state instead of being written back to `queued`.
      if (await _patch(
        workspaceId,
        row.id,
        fromState: 'queued',
        patch: {'steerOrder': index},
      )) {
        stillQueued.add(row);
        index++;
      }
    }
    ordered
      ..clear()
      ..addAll(stillQueued);
    final sessions = _harnessSessions(workspaceId, conversationId);
    if (sessions.isEmpty) {
      return;
    }
    final laneTexts = [
      for (final row in ordered) await _rowLaneText(workspaceId, row),
    ];
    for (final session in sessions) {
      final queue = session.steeringQueue;
      for (final row in ordered) {
        queue.removeByRef(row.id);
      }
      for (var i = 0; i < ordered.length; i++) {
        final row = ordered[i];
        if (_mayEnter(session, row.senderId, _writerWrite(row))) {
          queue.pushSteering(
            await _textFor(workspaceId, session, row.senderId, laneTexts[i]),
            ref: row.id,
          );
        }
      }
    }
  }

  /// Jump-to-front delivery ("steer now"): [messageId] becomes the next
  /// queued message every live run injects. Returns false when no live run
  /// can take mid-run steering (ACP, or none).
  Future<bool> deliver({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async {
    final row = await _findQueuedRow(workspaceId, conversationId, messageId);
    if (row == null) {
      return false;
    }
    final sessions = [
      for (final s in _harnessSessions(workspaceId, conversationId))
        if (_mayEnter(s, row.senderId, _writerWrite(row))) s,
    ];
    if (sessions.isEmpty) {
      return false;
    }
    final laneText = await _rowLaneText(workspaceId, row);
    var delivered = false;
    for (final session in sessions) {
      final queue = session.steeringQueue;
      queue.removeByRef(row.id);
      queue.pushFront(
        SteeringMessage(
          content: await _textFor(
            workspaceId,
            session,
            row.senderId,
            laneText,
          ),
          channel: SteeringChannel.steering,
          enqueuedAt: DateTime.now(),
          ref: row.id,
        ),
      );
      delivered = true;
    }
    return delivered;
  }

  /// Wires drain notifications for a just-started harness run and flushes any
  /// persisted-but-undelivered rows into it — the delivery path for cards
  /// queued before this dispatch existed (a sibling run's leftovers, or rows
  /// orphaned by a server restart).
  ///
  /// Runtime wiring: the dispatch adapter's `onSessionHarnessStarted` hook.
  void handleHarnessStarted(SteeringSessionView session) {
    final queue = session.steeringQueue;
    queue.onDrained = (message) => _handleDrained(session, message);
    final workspaceId = session.workspaceId;
    final conversationId = session.conversationId;
    final spaceId = session.spaceId;
    if (workspaceId == null ||
        conversationId == null ||
        spaceId == null ||
        !_takesCards(session, workspaceId)) {
      return;
    }
    unawaited(() async {
      try {
        final queued = await _queuedRows(workspaceId, spaceId, conversationId);
        for (final row in queued) {
          // Skip what is already in the lane: enqueue pushed it when the row
          // was written, and a double push would inject the text twice.
          final alreadyQueued = queue
              .peek(SteeringChannel.steering)
              .any((m) => m.ref == row.id);
          if (!alreadyQueued &&
              _mayEnter(session, row.senderId, _writerWrite(row))) {
            queue.pushSteering(
              await _textFor(
                workspaceId,
                session,
                row.senderId,
                await _rowLaneText(workspaceId, row),
              ),
              ref: row.id,
            );
          }
        }
      } on Object catch (e) {
        CcInfraLog.warning(
          'SteeringQueueService: replaying queued cards failed: $e',
        );
      }
    }());
  }

  /// A run drained a message: flip its row to `injected` so every client
  /// moves it from the queue strip into the trail. Idempotent across the
  /// multiple sessions that may each hold a copy.
  void _handleDrained(SteeringSessionView session, SteeringMessage message) {
    final ref = message.ref;
    final workspaceId = session.workspaceId;
    final conversationId = session.conversationId;
    final spaceId = session.spaceId;
    if (ref == null ||
        workspaceId == null ||
        conversationId == null ||
        spaceId == null) {
      return;
    }
    unawaited(() async {
      try {
        final row = await _messaging.getMessageById(workspaceId, ref);
        if (row == null || row.conversationId != conversationId) {
          return;
        }
        await _patch(
          workspaceId,
          ref,
          fromState: 'queued',
          patch: {
            'steerState': 'injected',
            'steerInjectedAt': DateTime.now().millisecondsSinceEpoch,
            if (session.runLogId != null) 'steerRunId': session.runLogId,
          },
        );
      } on Object catch (e) {
        CcInfraLog.warning(
          'SteeringQueueService: marking card $ref injected failed: $e',
        );
      }
    }());
  }

  /// A run ended ([event], published after its terminal row was written).
  ///
  /// - A person's stop holds the conversation's queued cards (unless the
  ///   stop was [forceSend]'s, which converts them as asked), once no other
  ///   run is live in the conversation.
  /// - A server stop leaves them queued: the server is going away, and the
  ///   next run in the conversation picks them up at its start.
  /// - A provider usage limit holds them as a stop does (a run now would
  ///   meet the same limit), marked with the run ([heldRunKey]); a pause of
  ///   that run adopts them ([limitHoldReconciler]).
  /// - Any other end converts and sends them ([handleRunEnded]).
  Future<void> handleRunSettled(AgentRunSettled event) async {
    final conversationId = event.conversationId;
    final spaceId = event.spaceId;
    if (conversationId == null ||
        conversationId.isEmpty ||
        spaceId == null ||
        spaceId.isEmpty) {
      return;
    }
    final workspaceId = event.workspaceId;
    // A goal's review: its cards wait for the goal's next segment.
    final goalReview = event.wakeReason == WakeReason.goalReview;
    switch (event.endReason) {
      case RunEndReason.serverStopped:
        return;
      case RunEndReason.stoppedByUser:
        final key = _conversationKey(workspaceId, conversationId);
        final markedAt = _stopAndSend[key];
        if (markedAt != null &&
            DateTime.now().difference(markedAt) > _stopAndSendWindow) {
          _stopAndSend.remove(key);
        } else if (markedAt != null) {
          final active = await _liveRuns(
            workspaceId,
            conversationId,
          );
          if (active.isNotEmpty) {
            return; // The last of the stopped runs sends the queue.
          }
          _stopAndSend.remove(key);
          await handleRunEnded(workspaceId, conversationId, spaceId);
          return;
        }
        await _hold(workspaceId, spaceId, conversationId, heldBy: heldByStop);
      case RunEndReason.usageLimit:
        // Never sent now: a run started now would meet the same limit. Held
        // as a Stop's (the person sends them when they choose), marked with
        // the run; a pause of that run makes them its own (`limit:<runId>`,
        // sent when it resumes) through [limitHoldReconciler], here and
        // whenever the pause is written or ends. A goal review's cards are
        // not its own: they wait for the worker. Any other read-only run's
        // (a learning review's) are held like any run's.
        if (goalReview) {
          return;
        }
        final held = await _hold(
          workspaceId,
          spaceId,
          conversationId,
          heldBy: heldByStop,
          heldRun: event.runId,
        );
        final reconcile = limitHoldReconciler;
        if (held > 0 && reconcile != null) {
          await reconcile(
            workspaceId: workspaceId,
            spaceId: spaceId,
            conversationId: conversationId,
            runId: event.runId,
          );
        }
      case RunEndReason.completed ||
          RunEndReason.error ||
          RunEndReason.budget ||
          RunEndReason.silence:
        // A goal's review never takes a card, and its end sends none: they
        // wait for the goal's next segment (its harness start), not an
        // ordinary turn to the reviewer or outside the goal. Any other
        // read-only run (a learning review) has no segment coming: its end
        // converts like any run's.
        if (goalReview) {
          await _holdUnlessGoalGoesOn(event, spaceId, conversationId);
          return;
        }
        await handleRunEnded(workspaceId, conversationId, spaceId);
    }
  }

  /// A goal's review ended and kept its cards queued for the next segment:
  /// when the goal goes on no further by itself ([goalContinues] says so),
  /// they are held as a Stop's instead, for their writers. The goal side
  /// does the same when the goal leaves `active` ([holdKeptCards]); each
  /// acts after its own write, so the order does not matter.
  Future<void> _holdUnlessGoalGoesOn(
    AgentRunSettled event,
    String spaceId,
    String conversationId,
  ) async {
    final goesOn = goalContinues;
    try {
      if (goesOn == null ||
          await goesOn(event.workspaceId, conversationId)) {
        return;
      }
    } on Object catch (e) {
      CcInfraLog.warning('SteeringQueueService: goal state unread: $e');
      return;
    }
    await holdKeptCards(event.workspaceId, spaceId, conversationId);
  }

  /// A goal stopped between segments (completed, failed, cancelled, out of
  /// budget, or paused): the cards its review kept queued are held as a
  /// Stop's, so no other run takes them and each writer sends their own.
  /// Nothing moves while a run is live (it takes or converts them).
  /// Returns how many cards were held.
  Future<int> holdKeptCards(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) => _hold(workspaceId, spaceId, conversationId, heldBy: heldByStop);

  /// The `steerHeldBy` of a card a person's stop held.
  static const String heldByStop = 'stop';

  /// The metadata key that says which hold a held card is under:
  /// [heldByStop], or a park's `limit:<runId>` (`LimitPark.dedupKey`).
  static const String heldByKey = 'steerHeldBy';

  /// The provider's reported reset (ISO 8601 UTC) on a card a park holds.
  static const String heldResetsAtKey = 'steerLimitResetsAt';

  /// The run whose end at a usage limit held a card: what ties the card to
  /// that run's pause, whichever hold it is under now.
  static const String heldRunKey = 'steerHeldRun';

  /// Makes the cards held at a run's usage limit agree with that run's
  /// pause (`LimitParkService.reconcileCards`). Late-bound: the park
  /// service is built after this queue.
  LimitHoldReconciler? limitHoldReconciler;

  /// Holds the conversation's queued cards after a person's stop or at a
  /// provider's usage limit, when no other run is live (a live run still
  /// delivers them at its boundaries), marking each with [heldBy] and, at a
  /// limit, the run ([heldRunKey]). Returns how many it held.
  Future<int> _hold(
    String workspaceId,
    String spaceId,
    String conversationId, {
    required String heldBy,
    String? heldRun,
  }) async {
    var held = 0;
    try {
      final active = await _liveRuns(
        workspaceId,
        conversationId,
      );
      if (active.isNotEmpty) {
        return 0;
      }
      final queued = await _queuedRows(workspaceId, spaceId, conversationId);
      for (final row in queued) {
        if (await _patch(
          workspaceId,
          row.id,
          fromState: SteeringState.queued.wire,
          patch: {
            'steerState': SteeringState.held.wire,
            'steerHeldAt': DateTime.now().millisecondsSinceEpoch,
            heldByKey: heldBy,
            heldRunKey: ?heldRun,
          },
        )) {
          held++;
        }
      }
    } on Object catch (e) {
      CcInfraLog.warning('SteeringQueueService: holding the queue failed: $e');
    }
    return held;
  }

  /// Releases, in order, only [senderId]'s cards held under [heldBy]:
  /// [heldByStop] (`steering.release`, the person sends what they wrote) or
  /// a park's `limit:<runId>` (the park's resume, for the person it acts
  /// for). A release starts a run on its sender's sign-in, so nobody sends
  /// another person's card. Each goes back to `queued`; with no run live
  /// they are converted and sent the way a run's end sends them, and a live
  /// run gets them in its lane. Other people's cards, and cards under
  /// another hold, stay held. Returns how many cards were released.
  Future<int> releaseHeldBy({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String heldBy,
    required String senderId,
  }) async {
    final held = await _heldBy(workspaceId, spaceId, conversationId, heldBy);
    final released = <Message>[];
    for (final row in held) {
      if (row.senderId != senderId) {
        continue;
      }
      if (await _patch(
        workspaceId,
        row.id,
        fromState: SteeringState.held.wire,
        patch: {
          'steerState': SteeringState.queued.wire,
          'steerReleasedAt': DateTime.now().millisecondsSinceEpoch,
        },
      )) {
        released.add(row);
      }
    }
    if (released.isEmpty) {
      return 0;
    }
    final active = await _liveRuns(
      workspaceId,
      conversationId,
    );
    if (active.isEmpty) {
      // Only these cards, as their writer: never the generic conversion,
      // which would take other people's leftover queued cards along.
      await _sendTurns(workspaceId, spaceId, conversationId, released);
    } else {
      for (final row in released) {
        await _pushCard(
          workspaceId,
          conversationId,
          ref: row.id,
          writer: row.senderId,
          writerWrite: _writerWrite(row),
          laneText: await _rowLaneText(workspaceId, row),
        );
      }
    }
    return released.length;
  }

  /// Puts every card held at [runId]'s usage limit (marked [heldRunKey],
  /// or under its `limit:<runId>`) under [heldBy]: the run's pause
  /// (`limit:<runId>`, waiting for [resetsAt]) while one waits, else
  /// [heldByStop] with no reset (the person's to send). Under a pause only
  /// the cards of the person it acts for ([pausePerson]) wait with it;
  /// every other writer's card (every card, when it acts for no one) is a
  /// Stop's at once, so its writer can send or remove it while the pause
  /// stays open. Nothing is sent. Returns how many cards moved.
  Future<int> holdRunCards({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String runId,
    required String heldBy,
    required DateTime? resetsAt,
    required String? pausePerson,
  }) async {
    final pauseKey = LimitPark.dedupKey(runId);
    final pauseReset = resetsAt?.toUtc().toIso8601String();
    var moved = 0;
    for (final row in await _messaging.getMessages(
      workspaceId,
      spaceId,
      conversationId: conversationId,
    )) {
      final meta = row.metadata;
      final theirs =
          heldBy != pauseKey ||
          (pausePerson != null &&
              pausePerson.isNotEmpty &&
              row.senderId == pausePerson);
      final holder = theirs ? heldBy : heldByStop;
      final reset = theirs ? pauseReset : null;
      if (!row.isSteeringHeld ||
          row.conversationId != conversationId ||
          (meta?[heldRunKey] != runId && meta?[heldByKey] != pauseKey) ||
          (meta?[heldByKey] == holder && meta?[heldResetsAtKey] == reset)) {
        continue;
      }
      if (await _patch(
        workspaceId,
        row.id,
        fromState: SteeringState.held.wire,
        patch: {heldByKey: holder, heldResetsAtKey: reset},
      )) {
        moved++;
      }
    }
    return moved;
  }

  /// The conversation's cards held under [heldBy], in queue order (each
  /// says whose it is: [Message.senderId]).
  Future<List<Message>> heldCards({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String heldBy,
  }) => _heldBy(workspaceId, spaceId, conversationId, heldBy);

  /// The reset a park's cards held under [heldBy] (`limit:<runId>`) wait
  /// for, as the provider reported it; null when none says one.
  Future<DateTime?> heldResetAt({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String heldBy,
  }) async {
    for (final m in await _heldBy(
      workspaceId,
      spaceId,
      conversationId,
      heldBy,
    )) {
      final at = DateTime.tryParse('${m.metadata?[heldResetsAtKey]}');
      if (at != null) {
        return at.toUtc();
      }
    }
    return null;
  }

  /// The conversation's cards held under [heldBy], in queue order.
  Future<List<Message>> _heldBy(
    String workspaceId,
    String spaceId,
    String conversationId,
    String heldBy,
  ) async =>
      (await _messaging.getMessages(
          workspaceId,
          spaceId,
          conversationId: conversationId,
        ))
        .where(
          (m) =>
              m.isSteeringHeld &&
              m.conversationId == conversationId &&
              m.metadata?[heldByKey] == heldBy,
        )
        .toList()
      ..sort((a, b) => a.steerOrder.compareTo(b.steerOrder));

  static String _conversationKey(String workspaceId, String conversationId) =>
      '$workspaceId/$conversationId';

  /// The last run in a conversation ended: convert what is still queued into
  /// normal user messages (in queue order) and dispatch whoever should answer
  /// them — the "keep typing to queue follow-up changes" promise.
  ///
  /// Called from [handleRunSettled] for a run that ended on its own, from
  /// [releaseHeldBy], and by [forceSend] when no run is live.
  Future<void> handleRunEnded(
    String workspaceId,
    String conversationId,
    String? spaceId,
  ) async {
    if (conversationId.isEmpty || spaceId == null || spaceId.isEmpty) {
      return;
    }
    try {
      final queued = await _queuedRows(workspaceId, spaceId, conversationId);
      if (queued.isEmpty) {
        return;
      }
      final active = await _liveRuns(
        workspaceId,
        conversationId,
      );
      if (active.isNotEmpty) {
        // Another run carries the conversation; its turn boundaries (or the
        // harness-start flush, when it has not reached the harness yet) are
        // still the delivery path.
        return;
      }
      await _sendTurns(workspaceId, spaceId, conversationId, queued);
    } on Object catch (e) {
      CcInfraLog.warning('SteeringQueueService: run-end conversion failed: $e');
    }
  }

  /// Sends [rows] (queued cards, in queue order) as one turn per writer,
  /// each as its writer (sender and requester), in the order the writers
  /// first appear. Never a join of two people's text, never one person's
  /// words under another's sign-in.
  ///
  /// Every card is claimed first by converting it (conditional on
  /// `queued`, so two endings racing here cannot both send it), so a turn's
  /// run starting cannot take another writer's card from the queue. The
  /// follow-up turn reads the conversation, so the cards must be ordinary
  /// messages by the time it is dispatched. A failed dispatch rolls back
  /// only that writer's claim: a card stays `converted` only when its turn
  /// was sent. A card with no writer is never sent: it is held, as a
  /// Stop's, for a space member to delete.
  Future<void> _sendTurns(
    String workspaceId,
    String spaceId,
    String conversationId,
    List<Message> rows,
  ) async {
    final byWriter = <String, List<Message>>{};
    for (final row in rows) {
      final writer = row.senderId.trim();
      if (writer.isEmpty) {
        await _patch(
          workspaceId,
          row.id,
          fromState: SteeringState.queued.wire,
          patch: {
            'steerState': SteeringState.held.wire,
            'steerHeldAt': DateTime.now().millisecondsSinceEpoch,
            heldByKey: heldByStop,
          },
        );
        continue;
      }
      if (await _patch(
        workspaceId,
        row.id,
        fromState: 'queued',
        messageType: 'text',
        patch: {
          'steerState': 'converted',
          'convertedFromSteering': true,
          'convertedAt': DateTime.now().millisecondsSinceEpoch,
        },
      )) {
        (byWriter[writer] ??= []).add(row);
      }
    }
    for (final MapEntry(key: writer, value: claimed) in byWriter.entries) {
      final texts = [
        for (final row in claimed)
          if (row.content.isNotEmpty) row.content,
      ];
      final attachments = [for (final row in claimed) ...row.attachments];
      try {
        // The follow-up turn sees the cards' pictures the way a typed
        // message's would: as images on the turn, and as paths where the
        // text names them.
        await _dispatchResponder(
          workspaceId: workspaceId,
          spaceId: spaceId,
          conversationId: conversationId,
          content: texts.join('\n\n'),
          senderUserId: writer,
          attachments: attachments,
          promptImageRefs: [
            for (final a in attachments)
              if (a.isImage && a.isUploaded) a.path,
          ],
        );
      } on Object catch (e) {
        for (final row in claimed) {
          await _patch(
            workspaceId,
            row.id,
            fromState: 'converted',
            messageType: 'steering',
            patch: {
              'steerState': 'queued',
              'convertedFromSteering': false,
              'steerFailedAt': DateTime.now().millisecondsSinceEpoch,
            },
          );
        }
        await _report(
          workspaceId: workspaceId,
          spaceId: spaceId,
          conversationId: conversationId,
          text:
              "Queued messages couldn't be sent to the agent ($e). They are "
              'still in the queue.',
        );
      }
    }
  }

  /// Stop-and-send ("send now" on a card no run can take mid-turn), as one
  /// server-side step: a run that can take the card takes it; otherwise the
  /// card moves to the front of the queue and every live run is stopped, so
  /// the run-end conversion sends it as the next turn. With no run live the
  /// queue is sent at once.
  ///
  /// [mayStop] is the caller's right to stop runs (the `dispatch.stopRun`
  /// permission), checked before anything is stopped.
  Future<SteeringForceOutcome> forceSend({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
    required String callerId,
    required bool mayStop,
    required Future<void> Function(String runId) stopRun,
  }) async {
    if (await deliver(
      workspaceId: workspaceId,
      conversationId: conversationId,
      messageId: messageId,
    )) {
      return SteeringForceOutcome.delivered;
    }
    final card = await _findQueuedRow(workspaceId, conversationId, messageId);
    if (card == null) {
      return SteeringForceOutcome.notQueued;
    }
    // Sending or stopping for a card starts a run with its writer's words:
    // only its writer does that.
    if (card.senderId != callerId) {
      throw const SteeringNotYoursException(othersHeld: 1);
    }
    final runs = await _liveRuns(
      workspaceId,
      conversationId,
    );
    if (runs.isEmpty) {
      // Only the caller's own cards, the pressed one first, as the caller.
      await _promote(workspaceId, spaceId, conversationId, messageId);
      await _sendTurns(workspaceId, spaceId, conversationId, [
        for (final row in await _queuedRows(
          workspaceId,
          spaceId,
          conversationId,
        ))
          if (row.senderId == callerId) row,
      ]);
      return SteeringForceOutcome.sent;
    }
    // A read-only run (a goal's or a learning review) is never stopped to
    // send a card: it stays queued until the review ends.
    final readOnlyRuns = {
      for (final s in _sessionsFor(conversationId))
        if (s.readOnly) s.runLogId,
    };
    if (runs.any((r) => readOnlyRuns.contains(r.id))) {
      return SteeringForceOutcome.notQueued;
    }
    if (!mayStop) {
      return SteeringForceOutcome.stopRefused;
    }
    await _promote(workspaceId, spaceId, conversationId, messageId);
    // These stops are the person asking for the card to be sent: their
    // settlement converts the queue rather than holding it.
    _stopAndSend[_conversationKey(workspaceId, conversationId)] =
        DateTime.now();
    for (final run in runs) {
      await stopRun(run.id);
    }
    return SteeringForceOutcome.stopping;
  }

  /// Moves [messageId] to the front of the conversation's queued cards.
  Future<void> _promote(
    String workspaceId,
    String spaceId,
    String conversationId,
    String messageId,
  ) async {
    final queued = await _queuedRows(workspaceId, spaceId, conversationId);
    final ordered = [
      ...queued.where((r) => r.id == messageId),
      ...queued.where((r) => r.id != messageId),
    ];
    var index = 0;
    for (final row in ordered) {
      if (await _patch(
        workspaceId,
        row.id,
        fromState: 'queued',
        patch: {'steerOrder': index},
      )) {
        index++;
      }
    }
  }

  /// Applies [patch] through the wired [SteeringPatcher], or — unwired, in
  /// tests — a fresh read + state check + update.
  Future<bool> _patch(
    String workspaceId,
    String messageId, {
    required String fromState,
    required Map<String, dynamic> patch,
    String? content,
    String? messageType,
  }) async {
    final wired = _patchSteering;
    if (wired != null) {
      return wired(
        workspaceId,
        messageId,
        fromState: fromState,
        patch: patch,
        content: content,
        messageType: messageType,
      );
    }
    final row = await _messaging.getMessageById(workspaceId, messageId);
    // The raw metadata, not [Message.steerState]: that getter answers only
    // for `steering`-typed rows, and a converted card is `text`.
    if (row == null || row.metadata?['steerState'] != fromState) {
      return false;
    }
    await _messaging.updateMessage(
      workspaceId,
      messageId,
      content: content,
      metadata: {...?row.metadata, ...patch},
      messageType: messageType,
    );
    return true;
  }

  Future<void> _report({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String text,
  }) async {
    CcInfraLog.warning('SteeringQueueService: $text');
    try {
      await _postNotice?.call(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        text: text,
      );
    } on Object catch (e) {
      CcInfraLog.warning('SteeringQueueService: posting the notice failed: $e');
    }
  }

  /// What a live run is handed for [row]: its text with attachment
  /// references resolved to paths.
  Future<String> _rowLaneText(String workspaceId, Message row) => _laneText(
    workspaceId: workspaceId,
    spaceId: row.spaceId,
    content: row.content,
    attachments: row.attachments,
  );

  Future<String> _laneText({
    required String workspaceId,
    required String spaceId,
    required String content,
    required List<MessageAttachment> attachments,
  }) async {
    final resolve = _resolveAttachmentPaths;
    if (resolve == null || attachments.isEmpty) {
      return content;
    }
    final text = await resolve(
      workspaceId: workspaceId,
      spaceId: spaceId,
      text: content,
      attachments: attachments,
    );
    // An attachment the text never names (a picture pasted with no prose)
    // would otherwise reach the run as nothing at all.
    final unnamed = [
      for (final a in attachments)
        if (!content.contains('@[file:${a.name}]')) a,
    ];
    if (unnamed.isEmpty) {
      return text;
    }
    final paths = await resolve(
      workspaceId: workspaceId,
      spaceId: spaceId,
      text: [for (final a in unnamed) '@[file:${a.name}]'].join('\n'),
      attachments: unnamed,
    );
    return text.isEmpty ? paths : '$text\n$paths';
  }

  /// Live sessions for a conversation that take a person's steering: of
  /// [workspaceId] (a conversation id from another workspace never receives
  /// this one's cards), and not read-only (a goal's or a learning review),
  /// which must not take instructions for the work it judges. Any other run
  /// takes them: a fresh goal segment, a space's checker, a bot run.
  List<SteeringSessionView> _harnessSessions(
    String workspaceId,
    String conversationId,
  ) => [
    for (final s in _sessionsFor(conversationId))
      if (_takesCards(s, workspaceId)) s,
  ];

  static bool _takesCards(SteeringSessionView s, String workspaceId) =>
      s.acceptsSteering &&
      s.workspaceId == workspaceId &&
      !s.readOnly;

  /// Pushes the card [ref] of [writer] into every live harness session of
  /// the conversation it may enter ([_mayEnter]), each with the text that
  /// run reads ([_textFor]). Returns whether any session took it.
  Future<bool> _pushCard(
    String workspaceId,
    String conversationId, {
    required String ref,
    required String writer,
    required bool writerWrite,
    required String laneText,
  }) async {
    var pushed = false;
    for (final session in _harnessSessions(workspaceId, conversationId)) {
      if (_mayEnter(session, writer, writerWrite)) {
        session.steeringQueue.pushSteering(
          await _textFor(workspaceId, session, writer, laneText),
          ref: ref,
        );
        pushed = true;
      }
    }
    return pushed;
  }

  /// Whether a card of [writer] may enter [s]: a run that acts for its
  /// writer, or any run when its writer held the write grant on the space's
  /// repositories when queuing it ([writerWrite]). A read-only member's text
  /// never steers a run acting on someone else's forge sign-in (nor a run
  /// acting for no one).
  static bool _mayEnter(
    SteeringSessionView s,
    String writer,
    bool writerWrite,
  ) => writerWrite || s.requestedByUserId == writer;

  static bool _writerWrite(Message row) => row.metadata?[writerWriteKey] == true;

  /// What [s] reads for a card of [writer] whose text is [laneText]: the
  /// text itself when the run acts for its writer, else the text after a
  /// line naming the writer ([steeringFromAnotherPerson]). Only the model
  /// reads that line; the stored row keeps the text as typed.
  Future<String> _textFor(
    String workspaceId,
    SteeringSessionView s,
    String writer,
    String laneText,
  ) async {
    if (s.requestedByUserId == writer) {
      return laneText;
    }
    String? name;
    try {
      name = await _writerName(workspaceId, writer);
    } on Object catch (e) {
      CcInfraLog.warning('SteeringQueueService: writer name unread: $e');
    }
    return '${steeringFromAnotherPerson(name)}\n\n$laneText';
  }

  /// The conversation's queued steering rows, in delivery order.
  Future<List<Message>> _queuedRows(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) async {
    final load = _queuedSteering;
    final rows = load == null
        ? await _messaging.getMessages(
            workspaceId,
            spaceId,
            conversationId: conversationId,
          )
        : await load(
            workspaceId: workspaceId,
            spaceId: spaceId,
            conversationId: conversationId,
          );
    final queued = rows.where((m) => m.isSteeringQueued).toList()
      ..sort((a, b) => a.steerOrder.compareTo(b.steerOrder));
    return queued;
  }

  /// Loads [messageId] and returns it ONLY while it is still queued steering
  /// in [conversationId] (or held, with [orHeld]).
  Future<Message?> _findQueuedRow(
    String workspaceId,
    String conversationId,
    String messageId, {
    bool orHeld = false,
  }) async {
    final row = await _messaging.getMessageById(workspaceId, messageId);
    if (row == null ||
        row.conversationId != conversationId ||
        !(row.isSteeringQueued || (orHeld && row.isSteeringHeld))) {
      return null;
    }
    return row;
  }

  /// The conversation's live top-level runs. A subagent's child row ends
  /// inside its parent's run (and may still be open while the parent's
  /// teardown closes it), so it never counts as a run of the conversation.
  Future<List<AgentRunLog>> _liveRuns(
    String workspaceId,
    String conversationId,
  ) async => [
    for (final run in await _runLogs.activeByConversation(
      workspaceId,
      conversationId,
    ))
      if (run.role != AgentRunRole.sub && run.parentRunId == null) run,
  ];

  /// Resolves the space that owns [conversationId] from its active run logs.
  Future<String?> _spaceIdFor(String workspaceId, String conversationId) async {
    final active = await _liveRuns(
      workspaceId,
      conversationId,
    );
    return active.firstOrNull?.spaceId;
  }

  /// One past the highest queued `steerOrder` in the conversation.
  Future<int> _nextOrder(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) async {
    final queued = await _queuedRows(workspaceId, spaceId, conversationId);
    return (queued.lastOrNull?.steerOrder ?? -1) + 1;
  }
}
