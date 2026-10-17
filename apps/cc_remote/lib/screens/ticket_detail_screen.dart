import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_remote/widgets/ticket_detail_body.dart';
import 'package:cc_remote/widgets/ticket_load_states.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'ticket_agent_chooser.dart';

/// `/tickets/:id` — detail view with status change and assign/reassign. The
/// ticket is resolved from the live ticket stream so it updates in place.
class TicketDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [TicketDetailScreen].
  const TicketDetailScreen({required this.ticketId, super.key});

  /// The ticket id from the route.
  final String ticketId;

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  bool _acting = false;
  bool _choosingAgent = false;
  String? _error;
  String? _workspaceId;

  Future<void> _run(
    String workspaceId,
    Future<void> Function(RemoteTicketRepository) action,
  ) async {
    final role = ref.read(workspaceRoleProvider);
    if (_acting ||
        ref.read(activeWorkspaceIdProvider).value != workspaceId ||
        role.isLoading ||
        role.value?.canWrite != true) {
      return;
    }
    final client = ref.read(rpcClientProvider).value;
    if (client == null) {
      setState(() => _error = AppLocalizations.of(context).connectionFailed);
      return;
    }
    setState(() {
      _acting = true;
      _error = null;
    });
    try {
      await action(RemoteTicketRepository(client));
    } catch (e) {
      if (mounted && ref.read(activeWorkspaceIdProvider).value == workspaceId) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted && ref.read(activeWorkspaceIdProvider).value == workspaceId) {
        setState(() => _acting = false);
      }
    }
  }

  Future<void> _changeStatus(
    TicketDto ticket,
    String status,
    String workspaceId,
  ) async {
    if (ticket.status == status) return;
    await _run(workspaceId, (repo) async {
      final json = ticket.toJson()..['status'] = status;
      await repo.update(
        TicketDto.fromJson(json),
        expectedVersion: ticket.version,
      );
    });
  }

  Future<void> _assign(AgentDto agent, String workspaceId) async {
    final notFound = AppLocalizations.of(context).mobileTicketNotFound;
    await _run(workspaceId, (repo) async {
      final updated = await repo.assign(
        widget.ticketId,
        workspaceId: workspaceId,
        agentId: agent.id,
      );
      if (updated == null) throw StateError(notFound);
      if (mounted && ref.read(activeWorkspaceIdProvider).value == workspaceId) {
        setState(() => _choosingAgent = false);
      }
    });
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
      _acting = false;
      _choosingAgent = false;
      _error = null;
    }
    final tickets = ref.watch(ticketsProvider);
    final ticket = workspaceId == null
        ? null
        : tickets.asData?.value
              .where(
                (tk) =>
                    tk.id == widget.ticketId && tk.workspaceId == workspaceId,
              )
              .firstOrNull;
    final agents = ref.watch(agentsProvider);
    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DetailHeader(
              title: ticket?.key.isNotEmpty == true ? ticket!.key : l10n.ticket,
            ),
            Expanded(
              child:
                  workspace.isLoading ||
                      (workspaceId != null && tickets.isLoading)
                  ? const Center(child: CcSpinner(size: 24))
                  : workspace.hasError || tickets.hasError
                  ? TicketLoadErrorState(
                      error:
                          workspace.error ??
                          tickets.error ??
                          l10n.ticketLoadFailed,
                      onRetry: () {
                        ref.invalidate(activeWorkspaceIdProvider);
                        ref.invalidate(ticketsProvider);
                      },
                    )
                  : workspaceId == null
                  ? CcEmptyState(
                      icon: AppIcons.ticket,
                      message: l10n.chooseWorkspace,
                      action: CcButton(
                        size: CcButtonSize.lg,
                        onPressed: () => context.go('/workspaces'),
                        child: Text(l10n.workspaces),
                      ),
                    )
                  : ticket == null
                  ? TicketMissingState(
                      onRetry: () => ref.invalidate(ticketsProvider),
                    )
                  : _choosingAgent
                  ? agents.isLoading
                        ? const Center(child: CcSpinner(size: 24))
                        : agents.hasError
                        ? CcEmptyState(
                            icon: AppIcons.triangleAlert,
                            message: l10n.noAgents,
                            description: agents.error.toString(),
                            action: Wrap(
                              spacing: 8,
                              children: [
                                CcButton(
                                  size: CcButtonSize.lg,
                                  variant: CcButtonVariant.secondary,
                                  onPressed: () =>
                                      setState(() => _choosingAgent = false),
                                  child: Text(l10n.cancel),
                                ),
                                CcButton(
                                  size: CcButtonSize.lg,
                                  onPressed: () =>
                                      ref.invalidate(agentsProvider),
                                  child: Text(l10n.retry),
                                ),
                              ],
                            ),
                          )
                        : _AgentChooser(
                            agents: agents.value ?? const [],
                            acting: _acting || !canWrite,
                            error: _error,
                            onPick: (agent) => _assign(agent, workspaceId),
                            onCancel: () =>
                                setState(() => _choosingAgent = false),
                          )
                  : TicketDetailBody(
                      ticket: ticket,
                      assigneeName: agents.asData?.value
                          .where((agent) => agent.id == ticket.assignee)
                          .firstOrNull
                          ?.name,
                      workspaceId: workspaceId,
                      acting: _acting,
                      canWrite: canWrite,
                      error: _error,
                      onStatusChanged: (status) =>
                          _changeStatus(ticket, status, workspaceId),
                      onChooseAgent: () =>
                          setState(() => _choosingAgent = true),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
