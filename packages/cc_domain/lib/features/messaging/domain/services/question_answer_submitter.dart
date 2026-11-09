import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/core/domain/value_objects/agent_question_metadata.dart';

export 'package:cc_domain/core/domain/value_objects/agent_question_metadata.dart';

/// Writes a message's metadata on the server — `messaging.updateMessage` over
/// whichever RPC repository the client holds.
typedef QuestionMetadataWriter =
    Future<void> Function(
      String workspaceId,
      String messageId,
      Map<String, dynamic> metadata,
    );

/// A client's half of `ask_user`: hands the human's answer to the server.
///
/// The waiter lives in the server process, and the server's first-answer-wins
/// write is the authority on whether an answer counts. So this only sends the
/// answer and lets every refusal propagate (already answered elsewhere, the
/// agent stopped waiting, no repo grant): a form that swallowed them would
/// collapse to "answered" while the agent never received anything.
class QuestionAnswerSubmitter {
  /// Creates a submitter over a metadata writer (the messaging RPC).
  const QuestionAnswerSubmitter(this._write);

  final QuestionMetadataWriter _write;

  /// Answers the question posted as [messageId], whose current metadata is
  /// [metadata]. Throws the server's refusal.
  Future<void> submit({
    required String workspaceId,
    required String messageId,
    required Map<String, dynamic>? metadata,
    required AgentQuestionAnswer answer,
  }) => _write(workspaceId, messageId, {
    ...?metadata,
    kQuestionAnsweredKey: true,
    kQuestionAnswerKey: answer.toJson(),
  });
}
