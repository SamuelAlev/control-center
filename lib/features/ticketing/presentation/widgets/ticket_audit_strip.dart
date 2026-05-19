import 'package:control_center/core/domain/entities/activity_entry.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// A compact, collapsible audit strip above a ticket's discussion: dispatch
/// attempts, status transitions, run completions, and orchestration steps,
/// read from the workspace-scoped audit trail.
class TicketAuditStrip extends ConsumerStatefulWidget {
  /// Creates a [TicketAuditStrip].
  const TicketAuditStrip({
    super.key,
    required this.workspaceId,
    required this.ticketId,
  });

  /// Workspace scope.
  final String workspaceId;

  /// The ticket whose audit entries are shown.
  final String ticketId;

  @override
  ConsumerState<TicketAuditStrip> createState() => _TicketAuditStripState();
}

class _TicketAuditStripState extends ConsumerState<TicketAuditStrip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entityActivityProvider((
      workspaceId: widget.workspaceId,
      entityType: 'ticket',
      entityId: widget.ticketId,
    )));
    final entries = entriesAsync.value ?? const <ActivityEntry>[];
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    final theme = Theme.of(context);
    final shown = _expanded ? entries : entries.take(1).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  Icon(Icons.history, size: 12, color: t.textQuaternary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _line(e),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: t.textTertiary),
                    ),
                  ),
                  Text(
                    DateFormat.Hm().format(e.createdAt.toLocal()),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: t.textQuaternary),
                  ),
                ],
              ),
            ),
          if (entries.length > 1)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _expanded
                      ? 'Show less'
                      : 'Show ${entries.length - 1} more audit entries',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: t.fgBrandPrimary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _line(ActivityEntry e) {
    final action = e.action.replaceAll('_', ' ');
    final actor = e.actorType == 'agent'
        ? 'agent'
        : e.actorType;
    final detail = e.details == null || e.details!.isEmpty ? '' : ' — ${e.details}';
    return '$actor: $action$detail';
  }
}
