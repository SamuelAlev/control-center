import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/screens/session_utils.dart';
import 'package:cc_remote/widgets/ticket_fields_form.dart';
import 'package:cc_remote/widgets/ticket_list_parts.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Live workspace tickets, searchable and filterable by task state.
class TicketsScreen extends ConsumerStatefulWidget {
  /// Creates a [TicketsScreen].
  const TicketsScreen({super.key});

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
  final _search = TextEditingController();
  String? _workspaceId;
  String _query = '';
  String _status = '';
  String _assignee = '';
  String _priority = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final workspace = ref.watch(activeWorkspaceIdProvider);
    final workspaceId = workspace.value;
    final role = ref.watch(workspaceRoleProvider);
    final canWrite = !role.isLoading && role.value?.canWrite == true;
    if (_workspaceId != workspaceId) {
      _workspaceId = workspaceId;
      _search.clear();
      _query = '';
      _status = '';
      _assignee = '';
      _priority = '';
    }
    final async = ref.watch(ticketsProvider);
    final agents = ref.watch(agentsProvider);
    final agentNames = {
      for (final agent in agents.asData?.value ?? const <AgentDto>[])
        agent.id: agent.name,
    };
    final q = _query.trim().toLowerCase();
    final hasFilters =
        q.isNotEmpty ||
        _status.isNotEmpty ||
        _assignee.isNotEmpty ||
        _priority.isNotEmpty;
    final tickets =
        async.asData?.value.where((ticket) {
          if (ticket.workspaceId != workspaceId ||
              (_status.isNotEmpty && ticket.status != _status) ||
              (_assignee == 'assigned' && ticket.assignee == null) ||
              (_assignee == 'unassigned' && ticket.assignee != null) ||
              (_assignee.isNotEmpty &&
                  _assignee != 'assigned' &&
                  _assignee != 'unassigned' &&
                  ticket.assignee != _assignee) ||
              (_priority.isNotEmpty && ticket.priority != _priority)) {
            return false;
          }
          return q.isEmpty ||
              [
                ticket.key,
                ticket.title,
                ticket.description ?? '',
                ticket.assignee ?? '',
                agentNames[ticket.assignee] ?? '',
                ...ticket.labels,
              ].any((field) => field.toLowerCase().contains(q));
        }).toList() ??
        const <TicketDto>[];
    return ColoredBox(
      color: t.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 8),
            child: CcButton(
              size: CcButtonSize.lg,
              fullWidth: true,
              icon: AppIcons.plus,
              onPressed: !canWrite || workspaceId == null
                  ? null
                  : () => context.push(
                      remoteWorkspaceLocation('/ticket/new', workspaceId),
                    ),
              child: Text(l10n.mobileTicketNew),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: CcTextField(
              controller: _search,
              label: l10n.mobileTicketSearch,
              hintText: l10n.mobileTicketSearchHint,
              suffix: _query.isEmpty
                  ? null
                  : PhoneIconButton(
                      icon: AppIcons.x,
                      borderRadius: BorderRadius.zero,
                      semanticLabel: l10n.mobileTicketClearSearch,
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          TicketFilterBar(
            title: l10n.status,
            options: ['', ...ticketStatuses],
            selected: _status,
            label: (value) =>
                value.isEmpty ? l10n.all : ticketStatusLabel(l10n, value),
            onChanged: (value) => setState(() => _status = value),
          ),
          TicketFilterBar(
            title: l10n.assign,
            options: [
              '',
              'assigned',
              'unassigned',
              ...agentNames.keys,
              if (_assignee.isNotEmpty &&
                  _assignee != 'assigned' &&
                  _assignee != 'unassigned' &&
                  !agentNames.containsKey(_assignee))
                _assignee,
            ],
            selected: _assignee,
            label: (value) => switch (value) {
              'assigned' => l10n.mobileTicketAssignedFilter,
              'unassigned' => l10n.mobileTicketUnassigned,
              '' => l10n.all,
              _ => agentNames[value] ?? value,
            },
            onChanged: (value) => setState(() => _assignee = value),
          ),
          if (agents.hasError)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
              child: CcAlert(
                variant: CcAlertVariant.danger,
                title: l10n.mobileTicketAgentsLoadFailed,
                description: Text(agents.error.toString()),
                action: CcButton(
                  size: CcButtonSize.lg,
                  variant: CcButtonVariant.secondary,
                  onPressed: () => ref.invalidate(agentsProvider),
                  child: Text(l10n.retry),
                ),
              ),
            ),
          TicketFilterBar(
            title: l10n.mobileTicketPriority,
            options: const ['', ...TicketFieldsForm.priorities],
            selected: _priority,
            label: (value) => value.isEmpty
                ? l10n.all
                : TicketFieldsForm.priorityLabel(l10n, value),
            onChanged: (value) => setState(() => _priority = value),
          ),
          Expanded(
            child:
                workspace.isLoading || (workspaceId != null && async.isLoading)
                ? const Center(child: CcSpinner(size: 24))
                : workspaceId == null && !workspace.hasError
                ? CcEmptyState(
                    icon: AppIcons.ticket,
                    message: l10n.chooseWorkspace,
                    action: CcButton(
                      size: CcButtonSize.lg,
                      onPressed: () => context.push('/workspaces'),
                      child: Text(l10n.workspaces),
                    ),
                  )
                : workspace.hasError || async.hasError
                ? CcEmptyState(
                    icon: AppIcons.triangleAlert,
                    message: l10n.ticketsLoadFailed,
                    description: (workspace.error ?? async.error).toString(),
                    action: CcButton(
                      size: CcButtonSize.lg,
                      onPressed: () {
                        ref.invalidate(activeWorkspaceIdProvider);
                        ref.invalidate(ticketsProvider);
                      },
                      child: Text(l10n.retry),
                    ),
                  )
                : tickets.isEmpty
                ? CcEmptyState(
                    icon: AppIcons.ticket,
                    message: hasFilters
                        ? l10n.mobileTicketNoMatches
                        : l10n.noTickets,
                    description: hasFilters
                        ? l10n.mobileTicketAdjustFilters
                        : l10n.ticketsEmptyDescription,
                    action: hasFilters
                        ? CcButton(
                            size: CcButtonSize.lg,
                            onPressed: () {
                              _search.clear();
                              setState(() {
                                _query = '';
                                _status = '';
                                _assignee = '';
                                _priority = '';
                              });
                            },
                            child: Text(l10n.mobileTicketClearFilters),
                          )
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: tickets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => TicketListCard(
                      ticket: tickets[i],
                      assigneeName: agentNames[tickets[i].assignee],
                      onOpen: () => context.push(
                        remoteWorkspaceLocation(
                          '/ticket/${Uri.encodeComponent(tickets[i].id)}',
                          workspaceId!,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
