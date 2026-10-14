import 'dart:async';
import 'dart:math' as math;

import 'package:cc_domain/cc_domain.dart' show ConfirmationRequestDto;
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/ask_user/ask_user_card.dart';
import 'package:control_center/features/messaging/providers/pending_confirmations_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-conversation permission prompt: pending agent-action approvals for
/// [spaceId], rendered as a FIFO [AskUserCard] above the composer.
///
/// The global overlay hides the same requests while this widget's space is
/// mounted, so a person looking at the chat is not also staring at a floating
/// deck in the corner.
class ConversationPermissionPrompt extends ConsumerStatefulWidget {
  /// Creates a [ConversationPermissionPrompt].
  const ConversationPermissionPrompt({
    super.key,
    required this.spaceId,
    this.maxHeight,
  });

  /// The space whose blocked actions this prompt answers.
  final String spaceId;

  /// Height budget from the conversation pane, not the whole app window.
  final double? maxHeight;

  @override
  ConsumerState<ConversationPermissionPrompt> createState() =>
      _ConversationPermissionPromptState();
}

class _ConversationPermissionPromptState
    extends ConsumerState<ConversationPermissionPrompt> {
  final Set<String> _responding = {};

  Future<void> _respond(
    String id, {
    required bool approved,
    bool remember = false,
  }) async {
    if (_responding.contains(id)) {
      return;
    }
    setState(() => _responding.add(id));
    try {
      await ref
          .read(confirmationRepositoryProvider)
          .respond(
            id,
            approved: approved,
            rememberForSeconds: remember ? kApprovalRememberSeconds : null,
          );
    } finally {
      if (mounted) {
        setState(() => _responding.remove(id));
      }
    }
  }

  void _onAnswer(ConfirmationRequestDto request, AgentQuestionAnswer answer) {
    final value = answer.selectedLabels.firstOrNull;
    switch (value) {
      case 'deny':
        unawaited(_respond(request.id, approved: false));
      case 'remember':
        unawaited(_respond(request.id, approved: true, remember: true));
      case 'approve':
        unawaited(_respond(request.id, approved: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending =
        ref.watch(pendingConfirmationsProvider).asData?.value ?? const [];
    final mine = [
      for (final request in pending)
        if (request.spaceId == widget.spaceId) request,
    ];
    if (mine.isEmpty) {
      return const SizedBox.shrink();
    }
    final request = mine.first;
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: math.min(
          520,
          widget.maxHeight ?? MediaQuery.sizeOf(context).height * 0.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mine.length > 1) ...[
              Text(
                l10n.agentApprovalsMoreWaiting(mine.length - 1),
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Flexible(
              child: _PermissionCard(
                key: ValueKey(request.id),
                request: request,
                submitting: _responding.contains(request.id),
                onSubmit: (answer) => _onAnswer(request, answer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    super.key,
    required this.request,
    required this.submitting,
    required this.onSubmit,
  });

  final ConfirmationRequestDto request;
  final bool submitting;
  final ValueChanged<AgentQuestionAnswer> onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final command = request.command;
    final explanation = [
      if (request.detail.isNotEmpty) request.detail,
      if (request.isRememberable)
        '${l10n.approveAndRemember}: ${l10n.approveAndRememberTooltip}',
    ].join('\n\n');
    return AskUserCard(
      question: request.title.isEmpty
          ? l10n.agentApprovalRequired
          : request.title,
      contextText: explanation.isEmpty ? null : explanation,
      caption: l10n.agentApprovalRequired,
      allowSkip: false,
      allowFreeText: false,
      multiSelect: false,
      submitting: submitting,
      extraBody: command == null || command.isEmpty
          ? null
          : buildSharedCodeBlock(
              context,
              command,
              'bash',
              showFullSource: true,
            ),
      options: [
        AgentQuestionOption(label: l10n.deny, value: 'deny'),
        AgentQuestionOption(label: l10n.approve, value: 'approve'),
        if (request.isRememberable)
          AgentQuestionOption(
            label: l10n.approveAndRemember,
            value: 'remember',
          ),
      ],
      onSubmit: submitting ? null : onSubmit,
    );
  }
}
