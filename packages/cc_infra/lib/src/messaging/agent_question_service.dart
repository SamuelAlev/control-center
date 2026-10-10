import 'dart:async';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// Message metadata key marking the rendered question as answered.
const String kQuestionAnsweredKey = 'answered';

/// Message metadata key holding the serialized [AgentQuestionAnswer].
const String kQuestionAnswerKey = 'answer';

/// Message metadata key marking a question that closed without an answer
/// (the asking agent stopped waiting: it timed out, gave up or was stopped).
/// Set together with [kQuestionAnsweredKey] so every "is this still open"
/// reader treats it as resolved.
const String kQuestionExpiredKey = 'expired';

/// Message metadata key holding the UTC ISO-8601 instant the asking agent
/// stops waiting. Absent when the service waits indefinitely.
const String kQuestionExpiresAtKey = 'expiresAt';

/// Message metadata key holding the full wait, in milliseconds, so a client
/// can draw how much of it is left.
const String kQuestionTimeoutMsKey = 'timeoutMs';

/// In-process implementation of [AgentQuestionPort].
///
/// When an agent asks a question, this posts an inline `user_question` message
/// into the conversation (rendered as an `AskUserCard` form) and blocks
/// on a [Completer] until the user submits the form via [submitAnswer]. The
/// asking agent — paused in its MCP tool call (Pi) or PTY relay (Claude) —
/// then receives the answer and continues.
///
/// Both the MCP server and the UI resolve the same singleton instance from the
/// provider, so the pending-question map is shared across them.
class AgentQuestionService implements AgentQuestionPort {
  /// Creates an [AgentQuestionService]. [_timeout] bounds how long the asking
  /// agent waits for an answer (`Duration.zero` waits indefinitely).
  /// [_onAsked] runs once each question is posted, with the id of the
  /// message it was posted as, so the host can tell the operator an agent is
  /// waiting on them; [_onClosed] runs with that id once the asker stops
  /// waiting, answered or not.
  AgentQuestionService(
    this._messaging, {
    this._timeout = const Duration(hours: 1),
    this._onAsked,
    this._onClosed,
  });

  final MessagingRepository _messaging;
  final Duration _timeout;
  final void Function(AgentQuestionRequest request, String messageId)? _onAsked;
  final void Function(String messageId)? _onClosed;

  /// Pending questions keyed by the question message id.
  final Map<String, Completer<AgentQuestionAnswer?>> _pending = {};

  @override
  Future<AgentQuestionAnswer?> ask(
    AgentQuestionRequest request, {
    Future<void>? abandoned,
  }) async {
    if (request.spaceId.isEmpty) {
      // Without a conversation there is nowhere to render the form.
      return null;
    }

    final waitsForever = _timeout == Duration.zero;
    final metadata = <String, dynamic>{
      'question': request.question,
      if (request.context != null) 'context': request.context,
      'options': request.options.map((o) => o.toJson()).toList(),
      'allowFreeText': request.allowFreeText,
      'multiSelect': request.multiSelect,
      if (request.askedByName != null) 'askedByName': request.askedByName,
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
      content: request.question,
      senderId: request.askedByAgentId ?? 'agent',
      senderType: 'agent',
      messageType: 'user_question',
      metadata: metadata,
    );

    final completer = Completer<AgentQuestionAnswer?>();
    _pending[messageId] = completer;
    _onAsked?.call(request, messageId);
    var closedUnanswered = false;
    // The asker can stop waiting long before the timeout: its MCP client gave
    // up on the call, or the run was stopped. An answer given after that
    // reaches nobody, so the form closes exactly as it does on timeout.
    void giveUp() {
      if (!completer.isCompleted) {
        closedUnanswered = true;
        completer.complete(null);
      }
    }

    unawaited(
      abandoned?.then((_) => giveUp(), onError: (Object _) => giveUp()),
    );
    try {
      if (waitsForever) {
        return await completer.future;
      }
      return await completer.future.timeout(
        _timeout,
        onTimeout: () {
          closedUnanswered = true;
          return null;
        },
      );
    } finally {
      _pending.remove(messageId);
      _onClosed?.call(messageId);
      if (closedUnanswered) {
        await _markExpired(request.workspaceId, messageId, metadata);
      }
    }
  }

  /// Closes the form of a question nobody answered while the asker waited, so
  /// the client collapses it instead of offering an answer the agent no
  /// longer reads.
  Future<void> _markExpired(
    String workspaceId,
    String messageId,
    Map<String, dynamic> metadata,
  ) async {
    try {
      await _messaging.updateMessage(
        workspaceId,
        messageId,
        metadata: {
          ...metadata,
          kQuestionAnsweredKey: true,
          kQuestionExpiredKey: true,
        },
      );
    } catch (_) {
      // Best-effort: the client also closes the form once expiresAt passes.
    }
  }

  /// Whether the question rendered as [messageId] is still awaiting an answer.
  bool isPending(String messageId) => _pending.containsKey(messageId);

  /// Unblocks the agent waiting on [messageId] using an answer that has ALREADY
  /// been persisted by someone else.
  ///
  /// This is the client/server seam. [ask] blocks on a `Completer` held in the
  /// process running the agent — the SERVER — but the human answers in a
  /// client, which persists the answer by writing the message's metadata over
  /// RPC. Nothing in that write reaches the server's completer map, so without
  /// this the asking agent waits out its full timeout while the form in front
  /// of the user already reads "answered".
  ///
  /// Called from the `messaging.updateMessage` handler after the write lands.
  /// A metadata blob that is not an answered question, or an id nobody is
  /// waiting on, is ignored — this runs on every message update.
  bool resolveFromMetadata(String messageId, Map<String, dynamic>? metadata) {
    if (metadata == null ||
        metadata[kQuestionAnsweredKey] != true ||
        metadata[kQuestionExpiredKey] == true) {
      return false;
    }
    final completer = _pending.remove(messageId);
    if (completer == null || completer.isCompleted) {
      return false;
    }
    final raw = metadata[kQuestionAnswerKey];
    completer.complete(
      raw is Map
          ? AgentQuestionAnswer.fromJson(raw.cast<String, dynamic>())
          : const AgentQuestionAnswer(),
    );
    return true;
  }

  /// Resolves the question rendered by [question] with [answer]: marks the
  /// message answered (so the form collapses to a read-only result) and
  /// unblocks the asking agent. [workspaceId] owns [question]'s space and
  /// selects the database the answered state is written back to.
  Future<void> submitAnswer(
    String workspaceId,
    Message question,
    AgentQuestionAnswer answer,
  ) async {
    final merged = <String, dynamic>{
      ...?question.metadata,
      kQuestionAnsweredKey: true,
      kQuestionAnswerKey: answer.toJson(),
    };
    try {
      await _messaging.updateMessage(
        workspaceId,
        question.id,
        metadata: merged,
      );
    } catch (_) {
      // Persisting the answered state is best-effort; still unblock the agent.
    }
    final completer = _pending.remove(question.id);
    if (completer != null && !completer.isCompleted) {
      completer.complete(answer);
    }
  }
}
