import 'package:cc_domain/core/domain/entities/message.dart';

/// The two facts a human send needs before it decides who answers.
///
/// Loaded without message bodies. A long conversation's transcripts are not
/// part of deciding whether the previous message is a pending plan, or which
/// agent spoke last.
class DispatchReplyHints {
  /// Creates reply hints for one send.
  const DispatchReplyHints({
    required this.previousIsPendingPlan,
    this.lastAgentSenderId,
  });

  /// Whether the message before the one just sent is a plan still awaiting
  /// approval.
  ///
  /// A missing `planStatus` counts as pending, matching [Message.planStatus].
  final bool previousIsPendingPlan;

  /// Sender of the newest live agent text or agent-turn in the conversation.
  ///
  /// Null when the conversation has no such message. Steering rows and
  /// reverted rows do not count.
  final String? lastAgentSenderId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DispatchReplyHints &&
          previousIsPendingPlan == other.previousIsPendingPlan &&
          lastAgentSenderId == other.lastAgentSenderId;

  @override
  int get hashCode => Object.hash(previousIsPendingPlan, lastAgentSenderId);
}
