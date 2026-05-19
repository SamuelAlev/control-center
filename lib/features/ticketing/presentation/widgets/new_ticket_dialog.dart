import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/ticketing/presentation/widgets/project_visuals.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_property_pickers.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_visuals.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_text_field.dart';
import 'package:control_center/shared/widgets/markdown/markdown_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Statuses a ticket can be created in, in display order. Started/terminal
/// states are not creation states — a ticket reaches them through its
/// lifecycle, not at birth.
const _creatableStatuses = [TicketStatus.open, TicketStatus.backlog];

/// Shows the Linear-style new-ticket dialog. Returns the created ticket id, or
/// null if cancelled. The [workspaceId] the ticket is created in is supplied by
/// the caller. When [initialProjectId] is set the ticket is created in that
/// project (e.g. from a project's view).
Future<String?> showNewTicketDialog(
  BuildContext context, {
  required String workspaceId,
  String? initialProjectId,
}) {
  return showCcDialog<String>(
    context: context,
    builder: (ctx) => _NewTicketDialog(
      workspaceId: workspaceId,
      initialProjectId: initialProjectId,
    ),
  );
}

class _NewTicketDialog extends ConsumerStatefulWidget {
  const _NewTicketDialog({required this.workspaceId, this.initialProjectId});

  final String workspaceId;
  final String? initialProjectId;

  @override
  ConsumerState<_NewTicketDialog> createState() => _NewTicketDialogState();
}

class _NewTicketDialogState extends ConsumerState<_NewTicketDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
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
    _descriptionFocus.dispose();
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
    final workspaceId = widget.workspaceId;
    final title = _titleController.text.trim();
    if (title.isEmpty || _submitting) {
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
      CcToastScope.of(
        context,
      ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = widget.workspaceId;
    final agents =
        ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
        const <Agent>[];
    final agentNames = {for (final a in agents) a.id: a.name};

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 560),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: t.borderPrimary),
          boxShadow: CcElevation.floating,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.brLg,
          child: Material(
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
                        AppIcons.squarePen,
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: MarkdownToolbar(
                          controller: _descriptionController,
                          focusNode: _descriptionFocus,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MarkdownTextField(
                        controller: _descriptionController,
                        focusNode: _descriptionFocus,
                        hintText: l10n.ticketDescriptionPlaceholder,
                        minLines: 3,
                        maxLines: 8,
                      ),
                    ],
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
                      _projectChip(l10n, widget.workspaceId),
                    ],
                  ),
                ),
                Container(height: 1, color: t.borderSecondary),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
                  child: Row(
                    children: [
                      CcSwitch(
                        value: _createMore,
                        onChanged: (v) => setState(() => _createMore = v),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.createMore,
                        style: TextStyle(fontSize: 13, color: t.textTertiary),
                      ),
                      const Spacer(),
                      CcButton(
                        variant: CcButtonVariant.secondary,
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 8),
                      CcButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CcSpinner(),
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
      menu: (context, toggle) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final s in _creatableStatuses)
              CcTile(
                selected: s == _status,
                leading: TicketStatusDot(status: s),
                title: ticketStatusLabel(l10n, s),
                trailing: s == _status
                    ? const Icon(AppIcons.check, size: 16)
                    : null,
                onTap: () {
                  setState(() => _status = s);
                  toggle();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _priorityChip(AppLocalizations l10n) {
    return TicketPropertyPicker(
      trigger: (context, toggle) => TicketTriggerChip(
        bordered: true,
        onTap: toggle,
        child: TicketPriorityIndicator(priority: _priority),
      ),
      menu: (context, toggle) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in TicketPriority.values)
              CcTile(
                selected: p == _priority,
                leading: TicketPriorityIndicator(priority: p, showLabel: false),
                title: ticketPriorityLabel(l10n, p),
                trailing: p == _priority
                    ? const Icon(AppIcons.check, size: 16)
                    : null,
                onTap: () {
                  setState(() => _priority = p);
                  toggle();
                },
              ),
          ],
        ),
      ),
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
              Icon(AppIcons.box, size: 14, color: t.fgTertiary),
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
      menu: (context, toggle) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CcTile(
              selected: _projectId == null,
              leadingIcon: AppIcons.circleSlash,
              title: l10n.noProject,
              onTap: () {
                setState(() => _projectId = null);
                toggle();
              },
            ),
            for (final p in projects)
              CcTile(
                selected: _projectId == p.id,
                leading: ProjectGlyph(color: p.color),
                title: p.name,
                trailing: _projectId == p.id
                    ? const Icon(AppIcons.check, size: 16)
                    : null,
                onTap: () {
                  setState(() => _projectId = p.id);
                  toggle();
                },
              ),
          ],
        ),
      ),
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
      menu: (context, toggle) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CcTile(
              selected: _assignedAgentId == null,
              leading: const TicketAssigneeAvatar(name: null, size: 20),
              title: l10n.unassigned,
              onTap: () {
                setState(() => _assignedAgentId = null);
                toggle();
              },
            ),
            const CcDivider(),
            _MenuSectionLabel(label: l10n.sectionMembers),
            CcTile(
              selected: _assignedAgentId == TicketCollaborator.userSentinel,
              leading: const TicketAssigneeAvatar(name: 'You', size: 20),
              title: 'You',
              onTap: () {
                setState(
                  () => _assignedAgentId = TicketCollaborator.userSentinel,
                );
                toggle();
              },
            ),
            if (agents.isNotEmpty) ...[
              const CcDivider(),
              _MenuSectionLabel(label: l10n.sectionAgents),
              for (final a in agents)
                CcTile(
                  selected: _assignedAgentId == a.id,
                  leading: TicketAssigneeAvatar(name: a.name, size: 20),
                  title: a.name,
                  trailing: _assignedAgentId == a.id
                      ? const Icon(AppIcons.check, size: 16)
                      : null,
                  onTap: () {
                    setState(() => _assignedAgentId = a.id);
                    toggle();
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small caption-cased header that titles a section of menu rows, used to
/// label a group of tiles within a menu.
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
