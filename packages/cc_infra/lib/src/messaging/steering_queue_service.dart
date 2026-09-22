import 'dart:async';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
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

  /// Whether at least one live run can inject mid-run (built-in harness).
  /// False for external-CLI transports (`claude -p`, `codex -p`, …): the card
  /// still queues and converts at run end, but a "steer now" affordance would
  /// be a lie, so the client hides it.
  final bool steerable;
}

/// The responder tail of a user message — see
/// `MessagingService.dispatchResponderForText`. A function type (not a class)
/// so the queue service depends on the seam, not the whole messaging service.
typedef DispatchResponder = Future<void> Function({
  required String workspaceId,
  required String spaceId,
  String? conversationId,
  required String content,
  String? senderUserId,
});

/// Live sessions of a conversation, as seen by the steering queue.
typedef SteeringSessionsFor = List<SteeringSessionView> Function(
  String conversationId,
);

/// Durable conversation-scoped steering queue (`MessageType.steering`,
/// `metadata['steerState']`) shown in the strip until a run takes it.
///
/// `enqueue` persists + pushes into live harness inboxes (`ref` = row id);
/// drain → `injected` (strip → trail). External CLIs have no mid-run lane —
/// rows stay queued/editable until last run ends, then convert to `text` in
/// order and dispatch like a typed message (never silently swallow).
/// `reorder` stamps `steerOrder`; `deliver` jumps to the front of live queues.
/// Wire [handleHarnessStarted] / [handleRunEnded] from the dispatch stack.
class SteeringQueueService {
  /// Creates the service.
  SteeringQueueService({
    required MessagingRepository messagingRepository,
    required AgentRunLogRepository runLogRepository,
    required this._dispatchResponder,
    required SteeringSessionsFor sessionsForConversation,
    this._queuedSteering,
  }) : _messaging = messagingRepository,
       _runLogs = runLogRepository,
       _sessionsFor = sessionsForConversation;

  final MessagingRepository _messaging;
  final AgentRunLogRepository _runLogs;
  final DispatchResponder _dispatchResponder;
  final SteeringSessionsFor _sessionsFor;

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
  /// Returns null when no run is active (the caller falls through to a normal
  /// send) or the content is blank.
  Future<EnqueueSteeringResult?> enqueue({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
    required String senderUserId,
  }) async {
    final text = content.trim();
    if (text.isEmpty) {
      return null;
    }
    final active = await _runLogs.activeByConversation(
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
      metadata: {'steerState': 'queued', 'steerOrder': order},
    );
    return EnqueueSteeringResult(
      messageId: messageId,
      steerable: _pushToHarnessSessions(conversationId, text, messageId),
    );
  }

  /// Rewrites a still-queued card. Injected/converted rows are conversation
  /// history and are refused (returns false). A live queue holding the old
  /// text is updated too — the run must not inject what the user just
  /// retracted. The replacement rejoins its lane at the end.
  Future<bool> edit({
    required String workspaceId,
    required String conversationId,
    required String messageId,
    required String content,
  }) async {
    if (content.trim().isEmpty) {
      return false;
    }
    final row = await _findQueuedRow(workspaceId, conversationId, messageId);
    if (row == null) {
      return false;
    }
    await _messaging.updateMessage(
      workspaceId,
      messageId,
      content: content.trim(),
      metadata: {
        ...?row.metadata,
        'editedAt': DateTime.now().millisecondsSinceEpoch,
      },
    );
    for (final session in _harnessSessions(conversationId)) {
      session.steeringQueue.removeByRef(messageId);
      session.steeringQueue.pushSteering(content.trim(), ref: messageId);
    }
    return true;
  }

  /// Deletes a still-queued card, from the row store AND every live queue.
  Future<bool> delete({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async {
    final row = await _findQueuedRow(workspaceId, conversationId, messageId);
    if (row == null) {
      return false;
    }
    for (final session in _harnessSessions(conversationId)) {
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
    for (final row in ordered) {
      await _messaging.updateMessage(
        workspaceId,
        row.id,
        metadata: {...?row.metadata, 'steerOrder': index++},
      );
    }
    for (final session in _harnessSessions(conversationId)) {
      final queue = session.steeringQueue;
      for (final row in ordered) {
        queue.removeByRef(row.id);
      }
      for (final row in ordered) {
        queue.pushSteering(row.content, ref: row.id);
      }
    }
  }

  /// Jump-to-front delivery ("steer now"): [messageId] becomes the next
  /// queued message every live harness run injects. Returns false when no
  /// live run can take mid-run steering (external-CLI transport, or none).
  Future<bool> deliver({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async {
    final row = await _findQueuedRow(workspaceId, conversationId, messageId);
    if (row == null) {
      return false;
    }
    var delivered = false;
    for (final session in _harnessSessions(conversationId)) {
      final queue = session.steeringQueue;
      queue.removeByRef(row.id);
      queue.pushFront(
        SteeringMessage(
          content: row.content,
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
    if (workspaceId == null || conversationId == null || spaceId == null) {
      return;
    }
    unawaited(() async {
      final queued = await _queuedRows(workspaceId, spaceId, conversationId);
      for (final row in queued) {
        // Skip what is already in the lane: enqueue pushed it when the row
        // was written, and a double push would inject the text twice.
        final alreadyQueued = queue
            .peek(SteeringChannel.steering)
            .any((m) => m.ref == row.id);
        if (!alreadyQueued) {
          queue.pushSteering(row.content, ref: row.id);
        }
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
      final row = await _messaging.getMessageById(workspaceId, ref);
      if (row == null ||
          row.conversationId != conversationId ||
          !row.isSteeringQueued) {
        return;
      }
      await _messaging.updateMessage(
        workspaceId,
        ref,
        metadata: {
          ...?row.metadata,
          'steerState': 'injected',
          'steerInjectedAt': DateTime.now().millisecondsSinceEpoch,
          if (session.runLogId != null) 'steerRunId': session.runLogId,
        },
      );
    }());
  }

  /// The last run in a conversation ended: convert what is still queued into
  /// normal user messages (in queue order) and dispatch whoever should answer
  /// them — the "keep typing to queue follow-up changes" promise.
  ///
  /// Runtime wiring: the dispatch service's `onRunEnded` hook, fired after
  /// the run log row is stamped terminal.
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
      final active = await _runLogs.activeByConversation(
        workspaceId,
        conversationId,
      );
      if (active.isNotEmpty) {
        // Another run carries the conversation; its turn boundaries (or the
        // harness-start flush, when it has not reached the harness yet) are
        // still the delivery path.
        return;
      }
      final texts = <String>[];
      for (final row in queued) {
        await _messaging.updateMessage(
          workspaceId,
          row.id,
          messageType: 'text',
          metadata: {
            ...?row.metadata,
            'steerState': 'converted',
            'convertedFromSteering': true,
            'convertedAt': DateTime.now().millisecondsSinceEpoch,
          },
        );
        texts.add(row.content);
      }
      await _dispatchResponder(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        content: texts.join('\n\n'),
        senderUserId: queued.first.senderId,
      );
    } on Object catch (e) {
      CcInfraLog.warning('SteeringQueueService: run-end conversion failed: $e');
    }
  }

  /// Live harness sessions for a conversation. Workspace-checked: a
  /// conversation id from another workspace must never receive this one's
  /// steering, even though uuid collisions are not a practical concern.
  List<SteeringSessionView> _harnessSessions(String conversationId) => [
    for (final s in _sessionsFor(conversationId))
      if (s.isHarnessActive && s.workspaceId != null) s,
  ];

  /// Pushes [content] (correlated by [ref]) into every live harness session
  /// for the conversation. Returns whether any session took it.
  bool _pushToHarnessSessions(
    String conversationId,
    String content,
    String ref,
  ) {
    var pushed = false;
    for (final session in _harnessSessions(conversationId)) {
      session.steeringQueue.pushSteering(content, ref: ref);
      pushed = true;
    }
    return pushed;
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
  /// in [conversationId].
  Future<Message?> _findQueuedRow(
    String workspaceId,
    String conversationId,
    String messageId,
  ) async {
    final row = await _messaging.getMessageById(workspaceId, messageId);
    if (row == null ||
        row.conversationId != conversationId ||
        !row.isSteeringQueued) {
      return null;
    }
    return row;
  }

  /// Resolves the space that owns [conversationId] from its active run logs.
  Future<String?> _spaceIdFor(String workspaceId, String conversationId) async {
    final active = await _runLogs.activeByConversation(
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
