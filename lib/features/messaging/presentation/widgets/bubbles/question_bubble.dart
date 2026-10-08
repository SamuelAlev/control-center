import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:control_center/features/messaging/presentation/widgets/ask_user/ask_user_card.dart';
import 'package:control_center/features/messaging/presentation/widgets/ask_user/ask_user_summary.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders an agent's `user_question` message as an [AskUserCard].
///
/// Submit hands the answer back to the blocked agent via [AgentQuestionPort].
/// Once answered, skipped or timed out, the form gives way to a compact
/// [AskUserSummary] of the question and what the agent received.
class QuestionBubble extends ConsumerStatefulWidget {
  /// Creates a [QuestionBubble].
  const QuestionBubble({super.key, required this.message});

  /// The `user_question` space message.
  final Message message;

  @override
  ConsumerState<QuestionBubble> createState() => _QuestionBubbleState();
}

class _QuestionBubbleState extends ConsumerState<QuestionBubble> {
  bool _submitting = false;

  /// Set when the countdown runs out here, before the server's own expiry
  /// write arrives — or when it never will (the server restarted mid-wait).
  bool _expiredLocally = false;

  Map<String, dynamic> get _meta => widget.message.metadata ?? const {};

  String get _question =>
      (_meta['question'] as String?) ?? widget.message.content;

  List<AgentQuestionOption> get _options {
    final raw = _meta['options'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final o in raw)
        if (o is Map) AgentQuestionOption.fromJson(o.cast<String, dynamic>()),
    ];
  }

  bool get _expired {
    if (widget.message.isQuestionAnswered) {
      return widget.message.isQuestionExpired;
    }
    if (_expiredLocally) {
      return true;
    }
    final expiresAt = widget.message.questionExpiresAt;
    return expiresAt != null && !DateTime.now().isBefore(expiresAt);
  }

  AgentQuestionAnswer? get _answered {
    if (!widget.message.isQuestionAnswered ||
        widget.message.isQuestionExpired) {
      return null;
    }
    final raw = _meta['answer'];
    return raw is Map
        ? AgentQuestionAnswer.fromJson(raw.cast<String, dynamic>())
        : const AgentQuestionAnswer();
  }

  Future<void> _submit(AgentQuestionAnswer answer) async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(agentQuestionServiceProvider)
          .submitAnswer(ref.requireWorkspaceId(), widget.message, answer);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _meta['questionIndex'];
    final count = _meta['questionCount'];
    final answered = _answered;
    final expired = _expired;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: answered != null || expired
          ? AskUserSummary(
              question: _question,
              options: _options,
              answer: answered,
              expired: expired,
            )
          : AskUserCard(
              question: _question,
              contextText: _meta['context'] as String?,
              options: _options,
              allowFreeText: _meta['allowFreeText'] == true,
              multiSelect: _meta['multiSelect'] == true,
              questionIndex: index is int ? index : int.tryParse('$index'),
              questionCount: count is int ? count : int.tryParse('$count'),
              submitting: _submitting,
              onSubmit: _submit,
              expiresAt: widget.message.questionExpiresAt,
              timeout: widget.message.questionTimeout,
              onExpired: () => setState(() => _expiredLocally = true),
            ),
    );
  }
}
