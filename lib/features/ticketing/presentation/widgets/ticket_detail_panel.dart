import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_activity_tab.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_changes_tab.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_issue_tab.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_terminal_tab.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The tabbed detail side panel for the selected ticket: Issue, Activity,
/// Changes and Terminal. Tab bodies live in an [IndexedStack] so the visited
/// tabs stay mounted — the terminal in particular keeps its PTY shell alive
/// when you switch tabs. Heavy tabs (Changes, Terminal) are started lazily on
/// first open, then kept alive.
class TicketDetailPanel extends ConsumerStatefulWidget {
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
  ConsumerState<TicketDetailPanel> createState() => _TicketDetailPanelState();
}

class _TicketDetailPanelState extends ConsumerState<TicketDetailPanel> {
  int _tab = 0;

  /// Tabs that have been opened at least once. Issue (0) and Activity (1) are
  /// cheap and always built; Changes (2) and Terminal (3) start lazily.
  final Set<int> _activated = {0, 1};

  @override
  void didUpdateWidget(TicketDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching to a different ticket resets the tab selection.
    if (oldWidget.ticketId != widget.ticketId) {
      _tab = 0;
      _activated
        ..clear()
        ..addAll({0, 1});
    }
  }

  void _select(int index) {
    setState(() {
      _tab = index;
      _activated.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final ticketId = widget.ticketId;

    if (ticketId == null) {
      return _SelectPrompt(message: l10n.ticketSelectPrompt);
    }

    final ticketAsync = ref.watch(ticketByIdProvider(
      (workspaceId: widget.workspaceId, ticketId: ticketId),
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
              _TabBar(
                selected: _tab,
                onSelected: _select,
                onClose: () {
                  ref.read(selectedTicketIdProvider.notifier).select(null);
                  context.go(ticketsRoute);
                },
              ),
              Container(height: 1, color: t.borderSecondary),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  sizing: StackFit.expand,
                  children: [
                    TicketIssueTab(ticket: ticket),
                    _activated.contains(1)
                        ? TicketActivityTab(ticket: ticket)
                        : const SizedBox.shrink(),
                    _activated.contains(2)
                        ? TicketChangesTab(ticket: ticket)
                        : const SizedBox.shrink(),
                    _activated.contains(3)
                        ? TicketTerminalTab(ticket: ticket)
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.selected,
    required this.onSelected,
    required this.onClose,
  });

  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final tabs = <(IconData, String)>[
      (LucideIcons.circleDot, l10n.ticketTabIssue),
      (LucideIcons.messagesSquare, l10n.ticketTabActivity),
      (LucideIcons.fileDiff, l10n.ticketTabChanges),
      (LucideIcons.terminal, l10n.ticketTabTerminal),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            _Tab(
              icon: tabs[i].$1,
              label: tabs[i].$2,
              selected: i == selected,
              onTap: () => onSelected(i),
            ),
            const SizedBox(width: 2),
          ],
          const Spacer(),
          CcTooltip(
            followerAnchor: Alignment.topCenter,
            targetAnchor: Alignment.bottomCenter,
            message: l10n.close,
            child: CcTappable(
              onPressed: onClose,
              builder: (context, states) => Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(LucideIcons.x, size: 16, color: t.fgTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? t.bgSecondary : Colors.transparent,
          borderRadius: AppRadii.brSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? t.fgBrandPrimary : t.fgQuaternary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? t.textPrimary : t.textTertiary,
              ),
            ),
          ],
        ),
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
            Icon(LucideIcons.ticket, size: 40, color: t.fgQuaternary),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: t.textTertiary)),
          ],
        ),
      ),
    );
  }
}
