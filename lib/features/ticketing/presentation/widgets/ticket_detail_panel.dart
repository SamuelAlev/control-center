import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_issue_tab.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The detail side panel for the selected ticket. Tickets are dumb
/// issue-tracking artifacts now, so the panel renders the single **Issue**
/// view (editable title/description + properties). Agent work lives in
/// conversations; the Activity / Changes / Terminal tabs were removed.
class TicketDetailPanel extends ConsumerWidget {
  /// Creates a [TicketDetailPanel].
  const TicketDetailPanel({
    super.key,
    required this.ticketId,
    required this.workspaceId,
  });

  /// The id of the selected ticket, or null when nothing is selected.
  final String? ticketId;

  /// The active workspace.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    final ticketId = this.ticketId;
    if (ticketId == null) {
      return _SelectPrompt(message: l10n.ticketSelectPrompt);
    }

    final ticketAsync = ref.watch(ticketByIdProvider(
      (workspaceId: workspaceId, ticketId: ticketId),
    ));

    return ColoredBox(
      color: t.bgPrimary,
      child: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.failedWithError('$e'))),
        data: (ticket) {
          if (ticket == null) {
            return _SelectPrompt(message: l10n.ticketSelectPrompt);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                onClose: () {
                  ref.read(selectedTicketIdProvider.notifier).select(null);
                  context.go(ticketsRoute(workspaceId));
                },
              ),
              Container(height: 1, color: t.borderSecondary),
              Expanded(child: TicketIssueTab(ticket: ticket)),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      child: Row(
        children: [
          Icon(AppIcons.circleDot, size: 15, color: t.fgBrandPrimary),
          const SizedBox(width: 8),
          Text(
            l10n.ticketTabIssue,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
          const Spacer(),
          CcTooltip(
            followerAnchor: Alignment.topCenter,
            targetAnchor: Alignment.bottomCenter,
            message: l10n.close,
            child: CcTappable(
              onPressed: onClose,
              builder: (context, states) => Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(AppIcons.x, size: 16, color: t.fgTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectPrompt extends StatelessWidget {
  const _SelectPrompt({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ColoredBox(
      color: t.bgPrimary,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.ticket, size: 40, color: t.fgQuaternary),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: t.textTertiary)),
          ],
        ),
      ),
    );
  }
}
