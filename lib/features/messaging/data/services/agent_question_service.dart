import 'dart:async';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/ports/agent_question_port.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';

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
    if (request.conversationId.isEmpty) {
      // Without a conversation there is nowhere to render the form.
      return null;
    }

    final messageId = await _messaging.sendMessage(
      channelId: request.conversationId,
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
      return await completer.future.timeout(
        _timeout,
        onTimeout: () => null,
      );
    } finally {
      _pending.remove(messageId);
    }
  }

  /// Whether the question rendered as [messageId] is still awaiting an answer.
  bool isPending(String messageId) => _pending.containsKey(messageId);

  /// Resolves the question rendered by [question] with [answer]: marks the
  /// message answered (so the form collapses to a read-only result) and
  /// unblocks the asking agent.
  Future<void> submitAnswer(
    ChannelMessage question,
    AgentQuestionAnswer answer,
  ) async {
    final merged = <String, dynamic>{
      ...?question.metadata,
      kQuestionAnsweredKey: true,
      kQuestionAnswerKey: answer.toJson(),
    };
    try {
      await _messaging.updateMessage(question.id, metadata: merged);
    } catch (_) {
      // Persisting the answered state is best-effort; still unblock the agent.
    }
    final completer = _pending.remove(question.id);
    if (completer != null && !completer.isCompleted) {
      completer.complete(answer);
    }
  }
}
