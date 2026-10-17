import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/requests_activity_providers.dart';
import 'package:cc_remote/widgets/inbox/approval_card.dart';
import 'package:cc_remote/widgets/inbox/credential_block_card.dart';
import 'package:cc_remote/widgets/inbox/inbox_section_header.dart';
import 'package:cc_remote/widgets/messaging/user_question_tile.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Requests remain available even when the independently loaded PR lane fails.
class InboxRequestLanes extends StatelessWidget {
  const InboxRequestLanes({
    required this.approvals,
    required this.questions,
    required this.credentials,
    required this.syncFailures,
    super.key,
  });
  final List<ConfirmationRequestDto> approvals;
  final List<PendingQuestion> questions;
  final List<RunCredentialBlockDto> credentials;
  final List<TicketSyncLogEntry> syncFailures;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (approvals.isNotEmpty) ...[
          InboxSectionHeader(
            label: l10n.agentApprovalRequired,
            count: approvals.length,
            icon: AppIcons.bot,
            urgent: true,
          ),
          const SizedBox(height: 8),
          for (final request in approvals)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ApprovalCard(key: ValueKey(request.id), request: request),
            ),
          const SizedBox(height: 16),
        ],
        if (questions.isNotEmpty) ...[
          InboxSectionHeader(
            label: l10n.agentQuestionHeader,
            count: questions.length,
            icon: AppIcons.messageCircle,
            urgent: true,
          ),
          const SizedBox(height: 8),
          for (final question in questions)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UserQuestionTile(
                    key: ValueKey(question.message.id),
                    message: question.message,
                    workspaceId: question.workspaceId,
                  ),
                  if (question.message.spaceId != null)
                    CcButton(
                      fullWidth: true,
                      size: CcButtonSize.lg,
                      variant: CcButtonVariant.ghost,
                      onPressed: () => context.push(
                        remoteSpaceLocation(
                          workspaceId: question.workspaceId,
                          spaceId: question.message.spaceId!,
                          conversationId: question.message.conversationId,
                          messageId: question.message.id,
                        ),
                      ),
                      child: Text(l10n.openConversation),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
        if (credentials.isNotEmpty) ...[
          InboxSectionHeader(
            label: l10n.inboxCredentialsBlocked,
            count: credentials.length,
            icon: AppIcons.triangleAlert,
            urgent: true,
          ),
          const SizedBox(height: 8),
          for (final block in credentials)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CredentialBlockCard(key: ValueKey(block.id), block: block),
            ),
          const SizedBox(height: 16),
        ],
        if (syncFailures.isNotEmpty) ...[
          InboxSectionHeader(
            label: l10n.inboxSyncFailures,
            count: syncFailures.length,
            icon: AppIcons.triangleAlert,
            urgent: true,
          ),
          const SizedBox(height: 8),
          for (final failure in syncFailures)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      failure.vendor,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (failure.message != null)
                      Text(
                        failure.message!,
                        style: TextStyle(color: t.textSecondary),
                      ),
                    if (failure.ticketId != null)
                      CcButton(
                        size: CcButtonSize.lg,
                        variant: CcButtonVariant.ghost,
                        onPressed: () => context.push(
                          remoteWorkspaceLocation(
                            '/ticket/${Uri.encodeComponent(failure.ticketId!)}',
                            failure.workspaceId,
                          ),
                        ),
                        child: Text(l10n.openTicket),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
