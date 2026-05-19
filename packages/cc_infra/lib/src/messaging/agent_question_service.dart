import 'dart:async';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// Message metadata key marking the rendered question as answered.
const String kQuestionAnsweredKey = 'answered';

/// Message metadata key holding the serialized [AgentQuestionAnswer].
const String kQuestionAnswerKey = 'answer';

/// In-process implementation of [AgentQuestionPort].
///
/// When an agent asks a question, this posts an inline `user_question` message
/// into the conversation (rendered as a form by `QuestionBubble`) and blocks
/// on a [Completer] until the user submits the form via [submitAnswer]. The
/// asking agent — paused in its MCP tool call (Pi) or PTY relay (Claude) —
/// then receives the answer and continues.
///
/// Both the MCP server and the UI resolve the same singleton instance from the
/// provider, so the pending-question map is shared across them.
class AgentQuestionService implements AgentQuestionPort {
  /// Creates an [AgentQuestionService]. [timeout] bounds how long the asking
  /// agent waits for an answer (`Duration.zero` waits indefinitely).
  AgentQuestionService(
    this._messaging, {
    Duration timeout = const Duration(hours: 1),
  }) : _timeout = timeout;

  final MessagingRepository _messaging;
  final Duration _timeout;

  /// Pending questions keyed by the question message id.
  final Map<String, Completer<AgentQuestionAnswer?>> _pending = {};

  @override
  Future<AgentQuestionAnswer?> ask(AgentQuestionRequest request) async {
    if (request.spaceId.isEmpty) {
      // Without a conversation there is nowhere to render the form.
      return null;
    }

    final messageId = await _messaging.sendMessage(
      workspaceId: request.workspaceId,
      spaceId: request.spaceId,
      content: request.question,
      senderId: request.askedByAgentId ?? 'agent',
      senderType: 'agent',
      messageType: 'user_question',
      metadata: {
        'question': request.question,
        if (request.context != null) 'context': request.context,
        'options': request.options.map((o) => o.toJson()).toList(),
        'allowFreeText': request.allowFreeText,
        'multiSelect': request.multiSelect,
        if (request.askedByName != null) 'askedByName': request.askedByName,
        kQuestionAnsweredKey: false,
      },
    );

    final completer = Completer<AgentQuestionAnswer?>();
    _pending[messageId] = completer;
    try {
      if (_timeout == Duration.zero) {
        return await completer.future;
      }
      return await completer.future.timeout(_timeout, onTimeout: () => null);
    } finally {
      _pending.remove(messageId);
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
    if (metadata == null || metadata[kQuestionAnsweredKey] != true) {
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
