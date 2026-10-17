import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/screens/session_utils.dart';
import 'package:cc_remote/widgets/phone_markdown.dart';
import 'package:cc_remote/widgets/ticket_fields_form.dart';
import 'package:cc_remote/widgets/ticket_status_badge.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Ticket content and actions. Mutations remain in the owning screen.
class TicketDetailBody extends StatelessWidget {
  const TicketDetailBody({
    super.key,
    required this.ticket,
    this.assigneeName,
    required this.workspaceId,
    required this.acting,
    required this.canWrite,
    required this.onStatusChanged,
    required this.onChooseAgent,
    this.error,
  });

  final TicketDto ticket;
  final String? assigneeName;
  final String workspaceId;
  final bool acting;
  final bool canWrite;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onChooseAgent;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          ticket.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TicketStatusBadge(status: ticket.status),
            CcBadge(
              label: TicketFieldsForm.priorityLabel(l10n, ticket.priority),
              variant: CcBadgeVariant.neutral,
            ),
            CcBadge(
              label: ticket.provider == 'local'
                  ? l10n.mobileTicketProviderLocal
                  : ticket.provider,
              variant: CcBadgeVariant.brand,
            ),
            if (ticket.assignee != null)
              CcBadge(label: l10n.assignedTo(assigneeName ?? ticket.assignee!)),
            for (final label in ticket.labels) CcBadge(label: label),
          ],
        ),
        if (ticket.description?.isNotEmpty == true) ...[
          const SizedBox(height: 20),
          PhoneMarkdown(data: ticket.description!),
        ],
        if (ticket.url != null) ...[
          const SizedBox(height: 16),
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            icon: AppIcons.externalLink,
            onPressed: () => openExternal(ticket.url),
            child: Text(l10n.openInBrowser),
          ),
        ],
        if (ticket.spaceId != null) ...[
          const SizedBox(height: 16),
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            icon: AppIcons.messageSquare,
            onPressed: () => context.push(
              remoteSpaceLocation(
                workspaceId: workspaceId,
                spaceId: ticket.spaceId!,
              ),
            ),
            child: Text(l10n.mobileTicketOpenLinkedSpace),
          ),
        ],
        const SizedBox(height: 24),
        CcButton(
          fullWidth: true,
          size: CcButtonSize.lg,
          variant: CcButtonVariant.secondary,
          onPressed: !canWrite || acting
              ? null
              : () => context.push(
                  remoteWorkspaceLocation(
                    '/ticket/${Uri.encodeComponent(ticket.id)}/edit',
                    workspaceId,
                  ),
                ),
          child: Text(l10n.mobileTicketEdit),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.status,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: t.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in ticketStatuses)
              CcButton(
                size: CcButtonSize.lg,
                variant: ticket.status == status
                    ? CcButtonVariant.line
                    : CcButtonVariant.secondary,
                onPressed: !canWrite || acting
                    ? null
                    : () => onStatusChanged(status),
                child: Text(ticketStatusLabel(l10n, status)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        CcButton(
          fullWidth: true,
          size: CcButtonSize.lg,
          variant: CcButtonVariant.secondary,
          loading: acting,
          icon: AppIcons.userCheck,
          onPressed: !canWrite || acting ? null : onChooseAgent,
          child: Text(ticket.assignee == null ? l10n.assign : l10n.reassign),
        ),
        if (!canWrite) ...[
          const SizedBox(height: 12),
          Text(
            l10n.mobileTicketReadOnly,
            style: TextStyle(color: t.textSecondary),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: TextStyle(color: t.textErrorPrimary)),
        ],
      ],
    );
  }
}
