import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/ticketing/domain/entities/project.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/presentation/widgets/project_visuals.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_property_pickers.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_visuals.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Statuses a ticket can be created in, in display order. Started/terminal
/// states are not creation states — a ticket reaches them through its
/// lifecycle, not at birth.
const _creatableStatuses = [TicketStatus.open, TicketStatus.backlog];

/// Shows the Linear-style new-ticket dialog. Returns the created ticket id, or
/// null if cancelled / no active workspace. When [initialProjectId] is set the
/// ticket is created in that project (e.g. from a project's view).
Future<String?> showNewTicketDialog(
  BuildContext context, {
  String? initialProjectId,
}) {
  return showFDialog<String>(
    context: context,
    builder: (ctx, style, animation) =>
        _NewTicketDialog(initialProjectId: initialProjectId),
  );
}

class _NewTicketDialog extends ConsumerStatefulWidget {
  const _NewTicketDialog({this.initialProjectId});

  final String? initialProjectId;

  @override
  ConsumerState<_NewTicketDialog> createState() => _NewTicketDialogState();
}

class _NewTicketDialogState extends ConsumerState<_NewTicketDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocus = FocusNode();
  TicketPriority _priority = TicketPriority.none;
  TicketStatus _status = TicketStatus.open;
  String? _assignedAgentId;
  String? _projectId;
  bool _createMore = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _projectId = widget.initialProjectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  String? _assigneeName(Map<String, String> agentNames) {
    final id = _assignedAgentId;
    if (id == null) {
      return null;
    }
    if (id == TicketCollaborator.userSentinel) {
      return 'You';
    }
    return agentNames[id] ?? id;
  }

  Future<void> _submit() async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    final title = _titleController.text.trim();
    if (workspaceId == null || title.isEmpty || _submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final description = _descriptionController.text.trim();
      final ticket = await ref
          .read(ticketWorkflowServiceProvider)
          .createTicket(
            workspaceId: workspaceId,
            title: title,
            description: description.isEmpty ? null : description,
            provider: ref.read(activeTicketProviderProvider),
            priority: _priority,
            status: _status,
            assignedAgentId: _assignedAgentId,
            projectId: _projectId,
          );
      if (!mounted) {
        return;
      }
      if (_createMore) {
        // Keep the dialog open for rapid entry: clear the body, preserve the
        // chosen status/priority/assignee, and refocus the title.
        setState(() {
          _submitting = false;
          _titleController.clear();
          _descriptionController.clear();
        });
        _titleFocus.requestFocus();
      } else {
        Navigator.of(context).pop(ticket.id);
      }
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.failedWithError('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agents = workspaceId == null
        ? const <Agent>[]
        : ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
              const <Agent>[];
    final agentNames = {for (final a in agents) a.id: a.name};

    return FDialog.raw(
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 560),
      builder: (context, style) => Material(
        type: MaterialType.transparency,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter, meta: true):
                _submit,
            const SingleActivator(LogicalKeyboardKey.enter, control: true):
                _submit,
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(context).maybePop(),
          },
          child: SizedBox(
            width: 540,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.squarePen,
                        size: 14,
                        color: t.fgTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.newTicket,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: t.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: TextField(
                    controller: _titleController,
                    focusNode: _titleFocus,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    cursorColor: t.fgBrandPrimary,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: l10n.ticketTitlePlaceholder,
                      hintStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: t.textPlaceholder,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: TextField(
                    controller: _descriptionController,
                    minLines: 2,
                    maxLines: 6,
                    cursorColor: t.fgBrandPrimary,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: t.textSecondary,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: l10n.ticketDescriptionPlaceholder,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: t.textPlaceholder,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statusChip(l10n),
                      _priorityChip(l10n),
                      _assigneeChip(l10n, agents, agentNames),
                      _projectChip(l10n, workspaceId),
                    ],
                  ),
                ),
                Container(height: 1, color: t.borderSecondary),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
                  child: Row(
                    children: [
                      FSwitch(
                        value: _createMore,
                        onChange: (v) => setState(() => _createMore = v),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.createMore,
                        style: TextStyle(fontSize: 13, color: t.textTertiary),
                      ),
                      const Spacer(),
                      FButton(
                        variant: FButtonVariant.outline,
                        mainAxisSize: MainAxisSize.min,
                        onPress: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 8),
                      FButton(
                        mainAxisSize: MainAxisSize.min,
                        onPress: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: FCircularProgress(),
                              )
                            : Text(l10n.create),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(AppLocalizations l10n) {
    return TicketPropertyPicker(
      trigger: (context, toggle) => TicketTriggerChip(
        bordered: true,
        onTap: toggle,
        child: TicketStatusDot(
          status: _status,
          label: ticketStatusLabel(l10n, _status),
        ),
      ),
      menu: (context, toggle) => [
        FTileGroup(
          children: [
            for (final s in _creatableStatuses)
              FTile(
                selected: s == _status,
                prefix: TicketStatusDot(status: s),
                title: Text(ticketStatusLabel(l10n, s)),
                suffix: s == _status
                    ? const Icon(LucideIcons.check, size: 16)
                    : null,
                onPress: () {
                  setState(() => _status = s);
                  toggle();
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _priorityChip(AppLocalizations l10n) {
    return TicketPropertyPicker(
      trigger: (context, toggle) => TicketTriggerChip(
        bordered: true,
        onTap: toggle,
        child: TicketPriorityIndicator(priority: _priority),
      ),
      menu: (context, toggle) => [
        FTileGroup(
          children: [
            for (final p in TicketPriority.values)
              FTile(
                selected: p == _priority,
                prefix: TicketPriorityIndicator(priority: p, showLabel: false),
                title: Text(ticketPriorityLabel(l10n, p)),
                suffix: p == _priority
                    ? const Icon(LucideIcons.check, size: 16)
                    : null,
                onPress: () {
                  setState(() => _priority = p);
                  toggle();
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _projectChip(AppLocalizations l10n, String? workspaceId) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final projects = workspaceId == null
        ? const <Project>[]
        : (ref.watch(workspaceProjectsProvider(workspaceId)).asData?.value ??
                const <Project>[])
            .where((p) => p.status != ProjectStatus.archived)
            .toList();
    final current = projects.where((p) => p.id == _projectId).firstOrNull;
    return TicketPropertyPicker(
      trigger: (context, toggle) => TicketTriggerChip(
        bordered: true,
        onTap: toggle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (current != null) ...[
              ProjectGlyph(color: current.color, size: 16),
              const SizedBox(width: 6),
              Text(
                current.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: t.textSecondary,
                ),
              ),
            ] else ...[
              Icon(LucideIcons.box, size: 14, color: t.fgTertiary),
              const SizedBox(width: 6),
              Text(
                l10n.project,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: t.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
      menu: (context, toggle) => [
        FTileGroup(
          children: [
            FTile(
              selected: _projectId == null,
              prefix: Icon(
                LucideIcons.circleSlash,
                size: 16,
                color: t.fgQuaternary,
              ),
              title: Text(l10n.noProject),
              onPress: () {
                setState(() => _projectId = null);
                toggle();
              },
            ),
            for (final p in projects)
              FTile(
                selected: _projectId == p.id,
                prefix: ProjectGlyph(color: p.color),
                title: Text(p.name),
                suffix: _projectId == p.id
                    ? const Icon(LucideIcons.check, size: 16)
                    : null,
                onPress: () {
                  setState(() => _projectId = p.id);
                  toggle();
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _assigneeChip(
    AppLocalizations l10n,
    List<Agent> agents,
    Map<String, String> agentNames,
  ) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final name = _assigneeName(agentNames);
    return TicketPropertyPicker(
      trigger: (context, toggle) => TicketTriggerChip(
        bordered: true,
        onTap: toggle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TicketAssigneeAvatar(name: name, size: 18),
            const SizedBox(width: 6),
            Text(
              name ?? l10n.unassigned,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: name == null ? t.textTertiary : t.textSecondary,
              ),
            ),
          ],
        ),
      ),
      menu: (context, toggle) => [
        FTileGroup(
          children: [
            FTile(
              selected: _assignedAgentId == null,
              prefix: const TicketAssigneeAvatar(name: null, size: 20),
              title: Text(l10n.unassigned),
              onPress: () {
                setState(() => _assignedAgentId = null);
                toggle();
              },
            ),
          ],
        ),
        FTileGroup(
          label: Text(l10n.sectionMembers),
          children: [
            FTile(
              selected: _assignedAgentId == TicketCollaborator.userSentinel,
              prefix: const TicketAssigneeAvatar(name: 'You', size: 20),
              title: const Text('You'),
              onPress: () {
                setState(
                  () => _assignedAgentId = TicketCollaborator.userSentinel,
                );
                toggle();
              },
            ),
          ],
        ),
        if (agents.isNotEmpty)
          FTileGroup(
            label: Text(l10n.sectionAgents),
            children: [
              for (final a in agents)
                FTile(
                  selected: _assignedAgentId == a.id,
                  prefix: TicketAssigneeAvatar(name: a.name, size: 20),
                  title: Text(a.name),
                  suffix: _assignedAgentId == a.id
                      ? const Icon(LucideIcons.check, size: 16)
                      : null,
                  onPress: () {
                    setState(() => _assignedAgentId = a.id);
                    toggle();
                  },
                ),
            ],
          ),
      ],
    );
  }
}
