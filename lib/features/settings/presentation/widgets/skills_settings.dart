import 'dart:io';

import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:yaml/yaml.dart';

class SkillInfo {
  const SkillInfo({
    required this.name,
    required this.content,
    required this.description,
  });

  final String name;
  final String content;
  final String description;
}

final skillListProvider = FutureProvider.family<List<SkillInfo>, String>((
  ref,
  workspaceId,
) async {
  final fs = ref.read(workspaceFilesystemPortProvider);
  final slugs = await fs.listSkillSlugs(workspaceId);
  final skills = <SkillInfo>[];
  for (final slug in slugs) {
    final file = await fs.readSkillFile(workspaceId, slug);
    if (file == null) {
      continue;
    }
    final content = await file.readAsString();
    final desc = extractYamlField(content, 'description') ?? '';
    skills.add(SkillInfo(name: slug, content: content, description: desc));
  }
  skills.sort((a, b) => a.name.compareTo(b.name));
  return skills;
});

/// Extracts the value of [field] from a YAML front-matter block.
String? extractYamlField(String content, String field) {
  final trimmed = content.trim();
  if (!trimmed.startsWith('---')) {
    return null;
  }
  final secondDelim = trimmed.indexOf('---', 3);
  if (secondDelim == -1) {
    return null;
  }
  final yamlStr = trimmed.substring(3, secondDelim).trim();
  try {
    final parsed = loadYaml(yamlStr);
    if (parsed is YamlMap) {
      if (parsed.containsKey(field)) {
        return (parsed[field] ?? '').toString();
      }
      return null;
    }
  } on Object catch (_) {}
  return null;
}

/// Returns the Markdown body after stripping YAML front-matter.
String extractMarkdownBody(String content) {
  final trimmed = content.trim();
  if (!trimmed.startsWith('---')) {
    return trimmed;
  }
  final secondDelim = trimmed.indexOf('---', 3);
  if (secondDelim == -1) {
    return trimmed;
  }
  return trimmed.substring(secondDelim + 3).trim();
}

/// Settings screen for managing workspace-scoped skill files.
class SkillsSettings extends ConsumerWidget {
  /// Creates a new [SkillsSettings].
  const SkillsSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = FTheme.of(context).colors;
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    return PageWrapper(
      title: l10n.skills,
      subtitle: l10n.workspaceScopedSkills,
      child: workspaceId == null
          ? Center(
              child: Text(
                'No workspace selected',
                style: TextStyle(color: colors.mutedForeground),
              ),
            )
          : _SkillsBody(workspaceId: workspaceId),
    );
  }
}

class _SkillsBody extends ConsumerStatefulWidget {
  const _SkillsBody({required this.workspaceId});

  final String workspaceId;

  @override
  ConsumerState<_SkillsBody> createState() => _SkillsBodyState();
}

class _SkillsBodyState extends ConsumerState<_SkillsBody> {
  String? _selectedSkill;
  final _nameCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _bodyCtl = TextEditingController();
  final _filterCtl = TextEditingController();
  bool _dirty = false;
  bool _saving = false;
  bool _isNew = false;
  Set<String> _attachedAgentIds = const {};

  @override
  void initState() {
    super.initState();
    _nameCtl.addListener(_markDirty);
    _descCtl.addListener(_markDirty);
    _bodyCtl.addListener(_markDirty);
    _filterCtl.addListener(() => setState(() {}));
  }

  void _markDirty() {
    if (!_dirty) {
      setState(() => _dirty = true);
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _descCtl.dispose();
    _bodyCtl.dispose();
    _filterCtl.dispose();
    super.dispose();
  }

  void _loadSkill(String name, List<SkillInfo> skills) {
    final skill = skills.firstWhere((s) => s.name == name);
    setState(() {
      _selectedSkill = name;
      _isNew = false;
      _nameCtl.text = skill.name;
      _descCtl.text = skill.description;
      _bodyCtl.text = extractMarkdownBody(skill.content);
      _dirty = false;
      final workspaceId = ref.read(activeWorkspaceIdProvider);
      final agents = workspaceId != null
          ? ref.read(workspaceAgentsProvider(workspaceId)).value ?? const []
          : ref.read(agentsProvider).value ?? const [];
      _attachedAgentIds = agents
          .where((a) => a.hasSkill(name))
          .map((a) => a.id)
          .toSet();
    });
  }

  void _startNew() {
    setState(() {
      _selectedSkill = null;
      _isNew = true;
      _nameCtl.clear();
      _descCtl.clear();
      _bodyCtl.clear();
      _dirty = false;
      _attachedAgentIds = const {};
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameCtl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).skillNameRequired)));
      return;
    }

    setState(() => _saving = true);
    try {
      final fs = ref.read(workspaceFilesystemPortProvider);
      final description = _descCtl.text.trim();
      final body = _bodyCtl.text;

      final frontmatter = <String, String>{'name': name};
      if (description.isNotEmpty) {
        frontmatter['description'] = description;
      }
      final yamlLines = frontmatter.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
      final content = '---\n$yamlLines\n---\n\n$body';

      if (_selectedSkill != null && _selectedSkill != name) {
        await fs.deleteSkillDir(widget.workspaceId, _selectedSkill!);
      }

      await fs.writeSkillFile(widget.workspaceId, name, content);

      if (_attachedAgentIds.isNotEmpty) {
        final repo = ref.read(agentRepositoryProvider);
        for (final agentId in _attachedAgentIds) {
          final agent = await repo.getById(agentId);
          if (agent != null) {
            final currentSkills = agent.skills.toList();
            if (_selectedSkill != null && _selectedSkill != name) {
              currentSkills.remove(_selectedSkill);
            }
            if (!currentSkills.contains(name)) {
              currentSkills.add(name);
            }
            await repo.upsert(
              agent.copyWith(skills: AgentSkills(currentSkills)),
            );
            await fs.syncAgentSkillLinks(
              widget.workspaceId,
              agent.name,
              currentSkills,
            );
          }
        }
      }

      ref.invalidate(skillListProvider(widget.workspaceId));

      if (mounted) {
        setState(() {
          _selectedSkill = name;
          _isNew = false;
          _dirty = false;
          _saving = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.skillSaved(name))));
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.failedWithError('$e'))));
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedSkill == null) {
      return;
    }
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.deleteConfirmName(_selectedSkill!)),
        body: Text(AppLocalizations.of(context).thisCannotBeUndone),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  onPress: () => Navigator.pop(ctx, false),
                  variant: FButtonVariant.outline,
                  mainAxisSize: MainAxisSize.min,
                  child: Text(AppLocalizations.of(context).cancel),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: () => Navigator.pop(ctx, true),
                  variant: FButtonVariant.destructive,
                  mainAxisSize: MainAxisSize.min,
                  child: Text(AppLocalizations.of(context).delete),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      final fs = ref.read(workspaceFilesystemPortProvider);
      await fs.deleteSkillDir(widget.workspaceId, _selectedSkill!);
      ref.invalidate(skillListProvider(widget.workspaceId));
      if (mounted) {
        _startNew();
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.failedWithError('$e'))));
      }
    }
  }

  Future<void> _openSkillFolder() async {
    if (_selectedSkill == null) {
      return;
    }
    final fs = ref.read(workspaceFilesystemPortProvider);
    final dir = await fs.skillDir(widget.workspaceId, _selectedSkill!);
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [dir.path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [dir.path]);
      } else {
        await Process.run('xdg-open', [dir.path]);
      }
    } on Object catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(skillListProvider(widget.workspaceId));

    return skillsAsync.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (e, _) => Center(child: Text(AppLocalizations.of(context).failedWithError('$e'))),
      data: (skills) {
        final editing = _selectedSkill != null || _isNew;
        final filter = _filterCtl.text.toLowerCase();
        final filteredSkills = skills
            .where(
              (s) =>
                  s.name.toLowerCase().contains(filter) ||
                  s.description.toLowerCase().contains(filter),
            )
            .toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 260,
                child: _SkillsListPane(
                  skills: filteredSkills,
                  selectedSkill: _selectedSkill,
                  filterController: _filterCtl,
                  onSelect: (name) => _loadSkill(name, skills),
                  onNew: _startNew,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: editing
                    ? _SkillEditor(
                        isNew: _isNew,
                        selectedSkill: _selectedSkill,
                        nameCtl: _nameCtl,
                        descCtl: _descCtl,
                        bodyCtl: _bodyCtl,
                        attachedAgentIds: _attachedAgentIds,
                        dirty: _dirty,
                        saving: _saving,
                        onAttachedChange: (ids) => setState(() {
                          _attachedAgentIds = ids;
                          _dirty = true;
                        }),
                        onSave: _save,
                        onDelete: _delete,
                        onOpenFolder: _openSkillFolder,
                      )
                    : const _SkillEmptyState(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── List pane ─────────────────────────────────────────────────────────────

class _SkillsListPane extends StatelessWidget {
  const _SkillsListPane({
    required this.skills,
    required this.selectedSkill,
    required this.filterController,
    required this.onSelect,
    required this.onNew,
  });

  final List<SkillInfo> skills;
  final String? selectedSkill;
  final TextEditingController filterController;
  final void Function(String name) onSelect;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = FTheme.of(context).colors;
    return SectionCard(
      label: l10n.skills,
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      headerPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      expands: true,
      trailing: FButton(
        variant: FButtonVariant.outline,
        size: FButtonSizeVariant.sm,
        onPress: onNew,
        mainAxisSize: MainAxisSize.min,
        prefix: const Icon(LucideIcons.plus, size: 14),
        child: Text(l10n.newLabel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: FTextField(
              control: FTextFieldControl.managed(controller: filterController),
              hint: l10n.filterSkillsPlaceholder,
              size: FTextFieldSizeVariant.sm,
            ),
          ),
          const FDivider(),
          Expanded(
            child: skills.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No matches.',
                        style: TextStyle(color: colors.mutedForeground),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: skills.length,
                    separatorBuilder: (_, _) => const FDivider(),
                    itemBuilder: (context, index) {
                      final skill = skills[index];
                      final selected = skill.name == selectedSkill;
                      return _SkillsListTile(
                        skill: skill,
                        selected: selected,
                        onTap: () => onSelect(skill.name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SkillsListTile extends StatelessWidget {
  const _SkillsListTile({
    required this.skill,
    required this.selected,
    required this.onTap,
  });

  final SkillInfo skill;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.10) : null,
          border: Border(
            left: BorderSide(
              color: selected ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              skill.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: colors.foreground,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (skill.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                skill.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkillEmptyState extends StatelessWidget {
  const _SkillEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;
    return SectionCard(
      label: AppLocalizations.of(context).skillEditor,
      expands: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.puzzle,
              size: 48,
              color: colors.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).selectLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).briefDescription,
              style: TextStyle(fontSize: 13, color: colors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Editor ────────────────────────────────────────────────────────────────

class _SkillEditor extends ConsumerWidget {
  const _SkillEditor({
    required this.isNew,
    required this.selectedSkill,
    required this.nameCtl,
    required this.descCtl,
    required this.bodyCtl,
    required this.attachedAgentIds,
    required this.dirty,
    required this.saving,
    required this.onAttachedChange,
    required this.onSave,
    required this.onDelete,
    required this.onOpenFolder,
  });

  final bool isNew;
  final String? selectedSkill;
  final TextEditingController nameCtl;
  final TextEditingController descCtl;
  final TextEditingController bodyCtl;
  final Set<String> attachedAgentIds;
  final bool dirty;
  final bool saving;
  final ValueChanged<Set<String>> onAttachedChange;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onOpenFolder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agents = workspaceId != null
        ? ref.watch(workspaceAgentsProvider(workspaceId)).value ?? const []
        : ref.watch(agentsProvider).value ?? const [];
    final agentItems = <String, String>{for (final a in agents) a.name: a.id};

    return SectionCard(
      label: isNew ? 'New skill' : (selectedSkill ?? ''),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      headerPadding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isNew) ...[
            FButton(
              variant: FButtonVariant.outline,
              size: FButtonSizeVariant.sm,
              onPress: onOpenFolder,
              mainAxisSize: MainAxisSize.min,
              prefix: const Icon(LucideIcons.folderOpen, size: 14),
              child: Text(l10n.openFolder),
            ),
            const SizedBox(width: 8),
            FButton(
              variant: FButtonVariant.destructive,
              size: FButtonSizeVariant.sm,
              onPress: onDelete,
              mainAxisSize: MainAxisSize.min,
              prefix: const Icon(LucideIcons.trash2, size: 14),
              child: Text(l10n.delete),
            ),
            const SizedBox(width: 8),
          ],
          FButton(
            size: FButtonSizeVariant.sm,
            onPress: (saving || !dirty) ? null : onSave,
            mainAxisSize: MainAxisSize.min,
            child: Text(saving ? l10n.savingEllipsis : l10n.save),
          ),
        ],
      ),
      child: SizedBox(
        height: 540,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FTextField(
                      control: FTextFieldControl.managed(controller: nameCtl),
                      label: Text(l10n.nameLabel),
                      hint: l10n.egArchitect,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FTextField(
                      control: FTextFieldControl.managed(controller: descCtl),
                      label: Text(l10n.descriptionLabel),
                      hint: l10n.briefDescription,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionLabel(text: l10n.attachedAgents),
              const SizedBox(height: 6),
              if (agentItems.isEmpty)
                Text(
                  'No agents registered yet.',
                  style: TextStyle(
                    fontSize: 12,
                    color: FTheme.of(context).colors.mutedForeground,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: FMultiSelect<String>(
                    items: agentItems,
                    hint: Text(
                      attachedAgentIds.isEmpty
                          ? 'Select agents'
                          : '${attachedAgentIds.length} agent${attachedAgentIds.length == 1 ? '' : 's'}',
                    ),
                    clearable: true,
                    tagBuilder: (_, _, _, _, _, _) => const SizedBox.shrink(),
                    control: FMultiValueControl<String>.lifted(
                      value: attachedAgentIds,
                      onChange: onAttachedChange,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _SectionLabel(text: l10n.contentMarkdown),
              const SizedBox(height: 6),
              SizedBox(
                height: 320,
                child: FTextField(
                  control: FTextFieldControl.managed(controller: bodyCtl),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  hint: l10n.writeSkillContent,
                ),
              ),
              if (dirty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      LucideIcons.circleDot,
                      size: 12,
                      color: FTheme.of(context).colors.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Unsaved changes',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: FTheme.of(context).colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colors.mutedForeground,
      ),
    );
  }
}

