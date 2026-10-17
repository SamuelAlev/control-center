import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/ticket_fields_form.dart';
import 'package:cc_remote/widgets/ticket_status_badge.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

/// A horizontal, 48pt high filter strip that fits a narrow viewport.
class TicketFilterBar extends StatelessWidget {
  const TicketFilterBar({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final String selected;
  final String Function(String) label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        children: [
          Center(
            child: Text(
              title,
              style: TextStyle(fontSize: 12, color: t.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          for (final value in options)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Center(
                child: CcButton(
                  size: CcButtonSize.lg,
                  variant: selected == value
                      ? CcButtonVariant.line
                      : CcButtonVariant.secondary,
                  onPressed: () => onChanged(value),
                  child: Text(label(value)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Isolated interactive reference for the touch-sized filter strip.
@Preview(name: 'Ticket filter', size: Size(390, 96))
Widget ticketFilterPreview() {
  var selected = 'open';
  return Directionality(
    textDirection: TextDirection.ltr,
    child: StatefulBuilder(
      builder: (context, setState) => TicketFilterBar(
        title: 'Status',
        options: const ['all', 'open', 'done'],
        selected: selected,
        label: (value) => value,
        onChanged: (value) => setState(() => selected = value),
      ),
    ),
  );
}

/// A full-row ticket link; status and ownership remain visible while scanning.
class TicketListCard extends StatelessWidget {
  const TicketListCard({
    super.key,
    required this.ticket,
    required this.onOpen,
    this.assigneeName,
  });

  final TicketDto ticket;
  final VoidCallback onOpen;
  final String? assigneeName;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcCard(
      interactive: true,
      semanticLabel: ticket.title,
      onPressed: onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.ticket, size: 18, color: t.fgSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ticket.key.isNotEmpty)
                  Text(
                    ticket.key,
                    style: TextStyle(fontSize: 12, color: t.textTertiary),
                  ),
                Text(
                  ticket.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    TicketStatusBadge(status: ticket.status),
                    if (ticket.priority != 'none')
                      CcBadge(
                        label: TicketFieldsForm.priorityLabel(
                          AppLocalizations.of(context),
                          ticket.priority,
                        ),
                        variant: CcBadgeVariant.neutral,
                      ),
                    if (ticket.assignee != null)
                      CcBadge(
                        label: assigneeName ?? ticket.assignee!,
                        variant: CcBadgeVariant.neutral,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
