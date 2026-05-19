import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/ticketing/presentation/widgets/new_project_dialog.dart';
import 'package:control_center/features/ticketing/presentation/widgets/project_visuals.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_linked_prs_card.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_property_pickers.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_relations_card.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_visuals.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _selectableStatuses = [
  TicketStatus.backlog,
  TicketStatus.open,
  TicketStatus.inProgress,
  TicketStatus.blocked,
  TicketStatus.inReview,
  TicketStatus.done,
  TicketStatus.cancelled,
];

/// The properties sidebar for the Issue tab: status, priority and assignee
/// live in one card, collaborators in another, linked PRs in a third, with the
/// destructive delete action sitting below. Rendered as a content-sized
/// `Column` of cards so the parent (the Issue tab) can place it inside a
/// scrolling sidebar (wide layout) or stack it under the description (narrow).
class TicketPropertiesRail extends ConsumerWidget {
  /// Creates a [TicketPropertiesRail].
  const TicketPropertiesRail({
    super.key,
    required this.ticket,
    required this.workspaceId,
  });

  /// The ticket whose properties are shown.
  final Ticket ticket;

  /// The workspace that owns the ticket.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workflow = ref.read(ticketWorkflowServiceProvider);
    final agents =
        ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
        const <Agent>[];
    final agentNames = {for (final a in agents) a.id: a.name};
    final collaborators =
        ref.watch(ticketCollaboratorsProvider(ticket.id)).asData?.value ??
        const <TicketCollaborator>[];
    final projects =
        (ref.watch(workspaceProjectsProvider(workspaceId)).asData?.value ??
                const <Project>[])
            .where((p) => p.status != ProjectStatus.archived)
            .toList();
    final currentProject =
        projects.where((p) => p.id == ticket.projectId).firstOrNull;

    String? assigneeName() {
      final id = ticket.assignedAgentId;
      if (id == null) {
        return null;
      }
      if (id == TicketCollaborator.userSentinel) {
        return 'You';
      }
      return agentNames[id] ?? id;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SidebarCard(
          title: l10n.ticketProperties,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _PropertyRow(
                label: l10n.status,
                picker: TicketPropertyPicker(
                  trigger: (context, toggle) => TicketTriggerChip(
                    onTap: toggle,
                    child: TicketStatusDot(
                      status: ticket.status,
                      label: ticketStatusLabel(l10n, ticket.status),
                    ),
                  ),
                  menu: (context, toggle) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final s in _selectableStatuses)
                          CcTile(
                            selected: s == ticket.status,
                            leading: TicketStatusDot(status: s),
                            title: ticketStatusLabel(l10n, s),
                            trailing: s == ticket.status
                                ? const Icon(AppIcons.check, size: 16)
                                : null,
                            onTap: () {
                              workflow.transitionStatus(
                                ticket.id,
                                s,
                                workspaceId: workspaceId,
                                force: true,
                              );
                              toggle();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              _PropertyRow(
                label: l10n.priority,
                picker: TicketPropertyPicker(
                  trigger: (context, toggle) => TicketTriggerChip(
                    onTap: toggle,
                    child: TicketPriorityIndicator(priority: ticket.priority),
                  ),
                  menu: (context, toggle) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final p in TicketPriority.values)
                          CcTile(
                            selected: p == ticket.priority,
                            leading: TicketPriorityIndicator(
                              priority: p,
                              showLabel: false,
                            ),
                            title: ticketPriorityLabel(l10n, p),
                            trailing: p == ticket.priority
                                ? const Icon(AppIcons.check, size: 16)
                                : null,
                            onTap: () {
                              workflow.updateDetails(
                                ticket.id,
                                workspaceId: workspaceId,
                                priority: p,
                              );
                              toggle();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              _PropertyRow(
                label: l10n.assignee,
                picker: TicketPropertyPicker(
                  trigger: (context, toggle) => TicketTriggerChip(
                    onTap: toggle,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TicketAssigneeAvatar(name: assigneeName(), size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            assigneeName() ?? l10n.unassigned,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: assigneeName() == null
                                  ? t.textQuaternary
                                  : t.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  menu: (context, toggle) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CcTile(
                          selected: ticket.assignedAgentId == null,
                          leading: const TicketAssigneeAvatar(
                            name: null,
                            size: 20,
                          ),
                          title: l10n.unassigned,
                          onTap: () {
                            workflow.assign(
                              ticket.id,
                              workspaceId: workspaceId,
                            );
                            toggle();
                          },
                        ),
                        const CcDivider(),
                        _MenuSectionLabel(label: l10n.sectionMembers),
                        CcTile(
                          selected:
                              ticket.assignedAgentId ==
                              TicketCollaborator.userSentinel,
                          leading: const TicketAssigneeAvatar(
                            name: 'You',
                            size: 20,
                          ),
                          title: 'You',
                          onTap: () {
                            workflow.assign(
                              ticket.id,
                              workspaceId: workspaceId,
                              agentId: TicketCollaborator.userSentinel,
                            );
                            toggle();
                          },
                        ),
                        if (agents.isNotEmpty) ...[
                          const CcDivider(),
                          _MenuSectionLabel(label: l10n.sectionAgents),
                          for (final a in agents)
                            CcTile(
                              selected: ticket.assignedAgentId == a.id,
                              leading: TicketAssigneeAvatar(
                                name: a.name,
                                size: 20,
                              ),
                              title: a.name,
                              trailing: ticket.assignedAgentId == a.id
                                  ? const Icon(AppIcons.check, size: 16)
                                  : null,
                              onTap: () {
                                workflow.assign(
                                  ticket.id,
                                  workspaceId: workspaceId,
                                  agentId: a.id,
                                );
                                toggle();
                              },
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              _PropertyRow(
                label: l10n.project,
                picker: TicketPropertyPicker(
                  trigger: (context, toggle) => TicketTriggerChip(
                    onTap: toggle,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (currentProject != null) ...[
                          ProjectGlyph(color: currentProject.color, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              currentProject.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: t.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ] else
                          Text(
                            l10n.noProject,
                            style: TextStyle(
                              fontSize: 13,
                              color: t.textQuaternary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  menu: (context, toggle) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CcTile(
                          selected: ticket.projectId == null,
                          leadingIcon: AppIcons.circleSlash,
                          title: l10n.noProject,
                          onTap: () {
                            workflow.setProject(
                              ticket.id,
                              null,
                              workspaceId: workspaceId,
                            );
                            toggle();
                          },
                        ),
                        for (final p in projects)
                          CcTile(
                            selected: ticket.projectId == p.id,
                            leading: ProjectGlyph(color: p.color),
                            title: p.name,
                            trailing: ticket.projectId == p.id
                                ? const Icon(AppIcons.check, size: 16)
                                : null,
                            onTap: () {
                              workflow.setProject(
                                ticket.id,
                                p.id,
                                workspaceId: workspaceId,
                              );
                              toggle();
                            },
                          ),
                        const CcDivider(),
                        CcTile(
                          leadingIcon: AppIcons.plus,
                          title: l10n.newProject,
                          onTap: () async {
                            toggle();
                            final id = await showProjectDialog(
                              context,
                              workspaceId: workspaceId,
                            );
                            if (id != null) {
                              unawaited(
                                workflow.setProject(
                                  ticket.id,
                                  id,
                                  workspaceId: workspaceId,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TicketRelationsCard(ticket: ticket, workspaceId: workspaceId),
        const SizedBox(height: 12),
        _SidebarCard(
          title: l10n.addCollaborator,
          trailing: TicketPropertyPicker(
            trigger: (context, toggle) => CcTappable(
              onPressed: toggle,
              builder: (context, states) => Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  AppIcons.userPlus,
                  size: 16,
                  color: t.fgTertiary,
                ),
              ),
            ),
            menu: (context, toggle) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final a in agents)
                    CcTile(
                      leading: TicketAssigneeAvatar(name: a.name, size: 20),
                      title: a.name,
                      onTap: () {
                        workflow.addCollaborator(
                          ticket.id,
                          workspaceId: workspaceId,
                          agentId: a.id,
                        );
                        toggle();
                      },
                    ),
                ],
              ),
            ),
          ),
          child: collaborators.isEmpty
              ? Text(
                  l10n.noCollaborators,
                  style: TextStyle(fontSize: 13, color: t.textQuaternary),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final c in collaborators)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            TicketAssigneeAvatar(
                              name: c.isUser
                                  ? 'You'
                                  : (agentNames[c.agentId] ?? c.agentId),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.isUser
                                    ? 'You'
                                    : (agentNames[c.agentId] ?? c.agentId),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: t.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              c.role.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: t.textQuaternary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        TicketLinkedPrsCard(ticket: ticket, workspaceId: workspaceId),
        const SizedBox(height: 12),
        CcButton(
          onPressed: () => _confirmDelete(context, ref, l10n),
          variant: CcButtonVariant.destructive,
          icon: AppIcons.trash2,
          child: Text(l10n.deleteTicket),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.deleteTicket,
        content: Text(l10n.deleteTicketConfirm(ticket.title)),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(ticketWorkflowServiceProvider)
          .deleteTicket(ticket.id, workspaceId: workspaceId);
      if (!context.mounted) {
        return;
      }
      ref.read(selectedTicketIdProvider.notifier).select(null);
      context.go(ticketsRoute(workspaceId));
    } on Object catch (e) {
      if (!context.mounted) {
        return;
      }
      CcToastScope.of(
        context,
      ).show(l10n.errorDeletingTicket('$e'), variant: CcToastVariant.danger);
    }
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({required this.label, required this.picker});
  final String label;
  final Widget picker;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: t.textTertiary),
            ),
          ),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: picker),
          ),
        ],
      ),
    );
  }
}

/// A titled card used to group a section of the properties sidebar. Renders a
/// bordered container with a section header (and an optional [trailing] action,
/// e.g. the add-collaborator button) above its [child].
class _SidebarCard extends StatelessWidget {
  const _SidebarCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      decoration: BoxDecoration(
        color: t.bgPrimary,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: t.borderSecondary),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: t.textTertiary,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// A small caption-cased header that titles a section of menu rows.
class _MenuSectionLabel extends StatelessWidget {
  const _MenuSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: t.textTertiary,
        ),
      ),
    );
  }
}
