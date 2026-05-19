import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_visuals.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shows a searchable picker of the workspace's tickets and returns the chosen
/// ticket id (or null if dismissed). [excludeTicketIds] hides tickets that
/// can't be picked (the subject ticket, already-linked tickets).
Future<String?> showTicketPickerDialog(
  BuildContext context, {
  required String workspaceId,
  required String title,
  Set<String> excludeTicketIds = const {},
}) {
  return showCcDialog<String>(
    context: context,
    builder: (ctx) => _TicketPickerDialog(
      workspaceId: workspaceId,
      title: title,
      excludeTicketIds: excludeTicketIds,
    ),
  );
}

class _TicketPickerDialog extends ConsumerStatefulWidget {
  const _TicketPickerDialog({
    required this.workspaceId,
    required this.title,
    required this.excludeTicketIds,
  });

  final String workspaceId;
  final String title;
  final Set<String> excludeTicketIds;

  @override
  ConsumerState<_TicketPickerDialog> createState() =>
      _TicketPickerDialogState();
}

class _TicketPickerDialogState extends ConsumerState<_TicketPickerDialog> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final all = ref.watch(workspaceTicketsProvider(widget.workspaceId)).asData
            ?.value ??
        const <Ticket>[];
    final q = _query.trim().toLowerCase();
    final results = [
      for (final ticket in all)
        if (!widget.excludeTicketIds.contains(ticket.id) &&
            (q.isEmpty ||
                ticket.title.toLowerCase().contains(q) ||
                ticket.displayKey.toLowerCase().contains(q)))
          ticket,
    ];

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.bgPrimary,
            borderRadius: AppRadii.brLg,
            border: Border.all(color: t.borderSecondary),
            boxShadow: AppShadows.golden,
          ),
          child: ClipRRect(
            borderRadius: AppRadii.brLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Row(
                    children: [
                      Icon(LucideIcons.search, size: 16, color: t.fgQuaternary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          cursorColor: t.fgBrandPrimary,
                          style: TextStyle(fontSize: 14, color: t.textPrimary),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: l10n.searchTicketsHint,
                            hintStyle: TextStyle(color: t.textPlaceholder),
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: t.borderSecondary),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: results.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Text(
                              l10n.noMatchingTickets,
                              style: TextStyle(
                                fontSize: 13,
                                color: t.textQuaternary,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: results.length,
                          itemBuilder: (context, i) {
                            final ticket = results[i];
                            return _ResultRow(
                              ticket: ticket,
                              onTap: () =>
                                  Navigator.of(context).pop(ticket.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.ticket, required this.onTap});

  final Ticket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          color: hovered ? t.bgPrimaryHover : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              TicketStatusDot(status: ticket.status),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ticket.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
