import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/core/domain/value_objects/agent_question_metadata.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Closes a question nobody answered: a CONDITIONAL write that only lands
/// while the question is still unanswered (`answered != 1`), returning
/// whether it did. Production binds the DAO's `expireQuestion`.
typedef QuestionExpirer =
    Future<bool> Function(String workspaceId, String messageId);

/// A pending question's give-up timer, and what moving it needs.
typedef _Deadline = ({
  Timer? timer,
  void Function() giveUp,
  Map<String, dynamic> metadata,
  String workspaceId,
});

/// How [AgentQuestionService.deliverAnswer] ended.
enum QuestionAnswerDelivery {
  /// The answer was persisted and the waiting agent received it.
  delivered,

  /// Nobody is waiting any more (timed out, abandoned, answered elsewhere, or
  /// the server restarted since). Nothing was written.
  notPending,

  /// The waiter was claimed but the conditional write refused (the row was
  /// closed underneath it). The agent was told there is no answer.
  notPersisted,
}

/// In-process implementation of [AgentQuestionPort].
///
/// When an agent asks a question, this posts an inline `user_question` message
/// into the conversation (rendered as an `AskUserCard` form) and blocks on a
/// [Completer] until a human's answer is delivered through [deliverAnswer]
/// (the `messaging.updateMessage` handler) or the wait ends.
///
/// Every way a wait can end — an answer, the timeout, the asker giving up —
/// first CLAIMS the waiter by removing it from the pending map. Exactly one
/// claim succeeds, so an answer can never be acknowledged to the human while
/// the agent was handed a timeout, and an expiry can never overwrite an answer
/// the agent received.
class AgentQuestionService implements AgentQuestionPort {
  /// Creates an [AgentQuestionService]. [_timeout] bounds how long the asking
  /// agent waits for an answer (`Duration.zero` waits indefinitely).
  /// [_expireQuestion] closes an unanswered question conditionally; without it
  /// the expiry goes through [MessagingRepository.updateMessage] (whose DAO
  /// write is conditional on `answered` too). [_onAsked] runs once each
  /// question is posted, with the id of the message it was posted as, so the
  /// host can tell the operator an agent is waiting on them; [_onClosed] runs
  /// with that id once the asker stops waiting, answered or not.
  AgentQuestionService(
    this._messaging, {
    required this._conversations,
    this._timeout = kAgentQuestionTimeout,
    this._expireQuestion,
    this._onAsked,
    this._onClosed,
  });

  final MessagingRepository _messaging;
  final ConversationRepository _conversations;
  final Duration _timeout;
  final QuestionExpirer? _expireQuestion;
  final void Function(AgentQuestionRequest request, String messageId)? _onAsked;
  final void Function(String messageId)? _onClosed;

  /// Asked before a question is posted: an answer it returns is the
  /// question's result at once, and no form is posted (nobody is there to
  /// answer it: an earlier request of its run went unanswered). Set once by
  /// the server.
  AgentQuestionAnswer? Function(AgentQuestionRequest request)? answerUnasked;

  /// Pending questions keyed by the question message id.
  final Map<String, Completer<AgentQuestionAnswer?>> _pending = {};

  /// Each pending question's give-up timer and form metadata, so its
  /// deadline can be moved ([waitUntil]).
  final Map<String, _Deadline> _deadlines = {};

  StreamController<void>? _pendingChanges;

  /// Emits when live waiters change, without replaying an initial value.
  ///
  /// Persisted unanswered messages can outlive the process awaiting them.
  Stream<void> get pendingChanges =>
      (_pendingChanges ??= StreamController<void>.broadcast()).stream;

  /// Removes [messageId]'s waiter when it is still [expected] (any waiter
  /// when null). The single claim every ending goes through.
  Completer<AgentQuestionAnswer?>? _claim(
    String messageId, [
    Completer<AgentQuestionAnswer?>? expected,
  ]) {
    final current = _pending[messageId];
    if (current == null ||
        current.isCompleted ||
        (expected != null && !identical(current, expected))) {
      return null;
    }
    _pending.remove(messageId);
    _pendingChanges?.add(null);
    return current;
  }

  /// Throws [ArgumentError] when [request] names no space or conversation —
  /// there is nowhere to render the form, which is a caller bug and not a
  /// "timed out or dismissed" answer.
  @override
  Future<AgentQuestionAnswer?> ask(
    AgentQuestionRequest request, {
    Future<void>? abandoned,
  }) async {
    if (request.spaceId.isEmpty || request.conversationId.isEmpty) {
      throw ArgumentError(
        'ask_user needs the session space and conversation to render the '
        'question in.',
      );
    }
    final conversation = await _conversations.getById(
      workspaceId: request.workspaceId,
      conversationId: request.conversationId,
    );
    if (conversation == null) {
      throw const WorkspaceMismatchException(
        'Conversation not found in this workspace.',
      );
    }
    if (conversation.spaceId != request.spaceId) {
      throw const WorkspaceMismatchException(
        'Conversation does not belong to this space.',
      );
    }

    AgentQuestionAnswer? unasked;
    try {
      unasked = answerUnasked?.call(request);
    } on Object catch (e) {
      // A failing check posts the question as usual.
      CcInfraLog.warning('AgentQuestionService: answerUnasked failed: $e');
    }
    if (unasked != null) {
      return unasked;
    }
    final waitsForever = _timeout == Duration.zero;
    final metadata = <String, dynamic>{
      'question': request.question,
      if (request.context != null) 'context': request.context,
      'options': request.options.map((o) => o.toJson()).toList(),
      'allowFreeText': request.allowFreeText,
      'multiSelect': request.multiSelect,
      if (request.askedByName != null) 'askedByName': request.askedByName,
      // Set when a code mode script asked: the form says so and links to the
      // script's transcript row.
      'origin': ?request.origin?.toJson(),
      kQuestionAnsweredKey: false,
      if (!waitsForever) ...{
        kQuestionExpiresAtKey: DateTime.now()
            .toUtc()
            .add(_timeout)
            .toIso8601String(),
        kQuestionTimeoutMsKey: _timeout.inMilliseconds,
      },
    };
    final messageId = await _messaging.sendMessage(
      workspaceId: request.workspaceId,
      spaceId: request.spaceId,
      conversationId: request.conversationId,
      content: request.question,
      senderId: request.askedByAgentId ?? 'agent',
      senderType: 'agent',
      messageType: 'user_question',
      metadata: metadata,
    );

    final completer = Completer<AgentQuestionAnswer?>();
    _pending[messageId] = completer;
    _pendingChanges?.add(null);
    Timer? timer;
    AgentQuestionAnswer? answer;
    try {
      // A failing announcer must not strand a posted form with no waiter
      // ever completing it: the wait runs regardless.
      try {
        _onAsked?.call(request, messageId);
      } on Object catch (e) {
        CcInfraLog.warning('AgentQuestionService: onAsked failed: $e');
      }
      // The asker can stop waiting long before the timeout: its MCP client
      // gave up on the call, or the run was stopped. Both go through the same
      // claim an answer does, so whichever lands first wins.
      void giveUp() => _claim(messageId, completer)?.complete(null);
      unawaited(
        abandoned?.then((_) => giveUp(), onError: (Object _) => giveUp()),
      );
      if (!waitsForever) {
        timer = Timer(_timeout, giveUp);
      }
      _deadlines[messageId] = (
        timer: timer,
        giveUp: giveUp,
        metadata: metadata,
        workspaceId: request.workspaceId,
      );
      answer = await completer.future;
      return answer;
    } finally {
      timer?.cancel();
      _deadlines.remove(messageId)?.timer?.cancel();
      _claim(messageId, completer);
      _onClosed?.call(messageId);
      // A server notice is no person's answer: the form closes as expired.
      if (answer == null || answer.serverNotice != null) {
        await _markExpired(request.workspaceId, messageId, metadata);
      }
    }
  }

  /// Moves the deadline of the question pending as [messageId] to [until]
  /// (a run the server started waits the workspace's expiry, not the
  /// default timeout), and the form's `expiresAt` with it. Returns false
  /// when the question is no longer pending.
  Future<bool> waitUntil(String messageId, DateTime until) async {
    final entry = _deadlines[messageId];
    if (entry == null || !isPending(messageId)) {
      return false;
    }
    entry.timer?.cancel();
    final left = until.difference(DateTime.now());
    final timer = Timer(left.isNegative ? Duration.zero : left, entry.giveUp);
    entry.metadata
      ..[kQuestionExpiresAtKey] = until.toUtc().toIso8601String()
      ..[kQuestionTimeoutMsKey] = left.isNegative ? 0 : left.inMilliseconds;
    _deadlines[messageId] = (
      timer: timer,
      giveUp: entry.giveUp,
      metadata: entry.metadata,
      workspaceId: entry.workspaceId,
    );
    try {
      await _messaging.updateMessage(
        entry.workspaceId,
        messageId,
        metadata: {...entry.metadata},
      );
    } on Object catch (e) {
      // The wait itself moved; only the form's countdown is stale.
      CcInfraLog.warning('AgentQuestionService: moving $messageId: $e');
    }
    return true;
  }

  /// Ends the wait on [messageId] with no person's answer: the asker reads
  /// [answer]'s [AgentQuestionAnswer.serverNotice] and the form closes as
  /// expired. Goes through the same claim an answer does, so a person's
  /// answer that landed first wins. Returns whether the wait was released.
  bool release(String messageId, AgentQuestionAnswer answer) {
    if (answer.serverNotice == null) {
      throw ArgumentError.value(answer, 'answer', 'must be a server notice');
    }
    final completer = _claim(messageId);
    if (completer == null) {
      return false;
    }
    completer.complete(answer);
    return true;
  }

  /// Closes the form of a question nobody answered while the asker waited, so
  /// the client collapses it instead of offering an answer the agent no
  /// longer reads. Conditional: an answer that already landed is kept.
  Future<void> _markExpired(
    String workspaceId,
    String messageId,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final expire = _expireQuestion;
      if (expire != null) {
        await expire(workspaceId, messageId);
        return;
      }
      await _messaging.updateMessage(
        workspaceId,
        messageId,
        metadata: {
          ...metadata,
          kQuestionAnsweredKey: true,
          kQuestionExpiredKey: true,
        },
      );
    } on Object catch (e) {
      // The client also closes the form once expiresAt passes, and the boot
      // sweep closes anything a crash left open.
      CcInfraLog.warning('AgentQuestionService: expiring $messageId: $e');
    }
  }

  /// Whether the question rendered as [messageId] is still awaiting an answer.
  bool isPending(String messageId) {
    final completer = _pending[messageId];
    return completer != null && !completer.isCompleted;
  }

  /// Hands [answer] to the agent waiting on [messageId].
  ///
  /// Claims the waiter FIRST, then runs [persist] (the conditional
  /// first-answer-wins write), then completes the waiter: with [answer] when
  /// the write landed, with no answer when it did not (or threw — rethrown).
  /// The returned outcome is what the human is told; only
  /// [QuestionAnswerDelivery.delivered] means the agent got their answer.
  Future<QuestionAnswerDelivery> deliverAnswer(
    String messageId,
    AgentQuestionAnswer answer, {
    required Future<bool> Function() persist,
  }) async {
    final completer = _claim(messageId);
    if (completer == null) {
      return QuestionAnswerDelivery.notPending;
    }
    var persisted = false;
    try {
      persisted = await persist();
    } finally {
      completer.complete(persisted ? answer : null);
    }
    return persisted
        ? QuestionAnswerDelivery.delivered
        : QuestionAnswerDelivery.notPersisted;
  }

  /// In-process answer (tests and same-process callers): writes the answered
  /// state through the messaging repository and delivers it. Persistence
  /// failures propagate, and the agent is then told there is no answer.
  Future<QuestionAnswerDelivery> submitAnswer(
    String workspaceId,
    Message question,
    AgentQuestionAnswer answer,
  ) => deliverAnswer(
    question.id,
    answer,
    persist: () async {
      await _messaging.updateMessage(
        workspaceId,
        question.id,
        metadata: {
          ...?question.metadata,
          kQuestionAnsweredKey: true,
          kQuestionAnswerKey: answer.toJson(),
        },
      );
      return true;
    },
  );
}
