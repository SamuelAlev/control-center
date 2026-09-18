import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show ConfirmationRequestDto;
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/ask_user/ask_user_card.dart';
import 'package:control_center/features/messaging/providers/pending_confirmations_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-conversation permission prompt: pending agent-action approvals for
/// [spaceId], rendered as [AskUserCard]s above the composer.
///
/// The global overlay hides the same requests while this widget's space is
/// mounted, so a person looking at the chat is not also staring at a floating
/// deck in the corner.
class ConversationPermissionPrompt extends ConsumerStatefulWidget {
  /// Creates a [ConversationPermissionPrompt].
  const ConversationPermissionPrompt({super.key, required this.spaceId});

  /// The space whose blocked actions this prompt answers.
  final String spaceId;

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < mine.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _PermissionCard(
              request: mine[i],
              submitting: _responding.contains(mine[i].id),
              onSubmit: (answer) => _onAnswer(mine[i], answer),
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
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
    final t = context.designSystem ?? DesignSystemTokens.light();
    final command = request.command;
    return AskUserCard(
      question: request.title.isEmpty
          ? l10n.agentApprovalRequired
          : request.title,
      contextText: request.detail.isEmpty ? null : request.detail,
      caption: l10n.agentApprovalRequired,
      allowSkip: false,
      allowFreeText: false,
      multiSelect: false,
      submitting: submitting,
      extraBody: command == null || command.isEmpty
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: t.bgSecondary,
                border: Border.all(color: t.borderSecondary),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  command,
                  style: CcFonts.code(
                    textStyle: CcTypography.bodySm.copyWith(
                      color: t.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
      options: [
        AgentQuestionOption(label: l10n.deny, value: 'deny'),
        AgentQuestionOption(label: l10n.approve, value: 'approve'),
        if (request.isRememberable)
          AgentQuestionOption(
            label: l10n.approveAndRemember,
            value: 'remember',
            description: l10n.approveAndRememberTooltip,
          ),
      ],
      onSubmit: submitting ? null : onSubmit,
    );
  }
}
