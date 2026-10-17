part of 'skills_settings.dart';

class _SkillEditorContent extends ConsumerWidget {
  const _SkillEditorContent({
    required this.isNew,
    required this.selectedSkill,
    required this.nameCtl,
    required this.currentHash,
    required this.availableSkills,
    required this.descCtl,
    required this.bodyCtl,
    required this.attachedAgentIds,
    required this.dirty,
    required this.saving,
    required this.scanning,
    required this.onAttachedChange,
    required this.onSave,
    required this.onScan,
    required this.onDelete,
  });

  final bool isNew;
  final String? selectedSkill;
  final TextEditingController nameCtl;
  final String currentHash;
  final List<String> availableSkills;
  final TextEditingController descCtl;
  final TextEditingController bodyCtl;
  final Set<String> attachedAgentIds;
  final bool dirty;
  final bool saving;
  final bool scanning;
  final ValueChanged<Set<String>> onAttachedChange;
  final VoidCallback onSave;
  final VoidCallback onScan;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final readOnly = ref.watch(isDemoServerProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agents = workspaceId != null
        ? ref.watch(workspaceAgentsProvider(workspaceId)).value ?? const []
        : ref.watch(agentsProvider).value ?? const [];
    final agentItems = <String, String>{for (final a in agents) a.name: a.id};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isNew ? l10n.newSkill : (selectedSkill ?? ''),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: tokens?.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isNew) ...[
                CcButton(
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  onPressed: scanning || readOnly ? null : onScan,
                  loading: scanning,
                  icon: AppIcons.scanSearch,
                  child: Text(l10n.skillScanAction),
                ),
                const SizedBox(width: 8),
                readOnly
                    ? CcTooltip(
                        message: l10n.demoReadOnlySave,
                        child: CcButton(
                          variant: CcButtonVariant.destructive,
                          size: CcButtonSize.sm,
                          onPressed: null,
                          icon: AppIcons.trash2,
                          child: Text(l10n.delete),
                        ),
                      )
                    : CcButton(
                        variant: CcButtonVariant.destructive,
                        size: CcButtonSize.sm,
                        onPressed: onDelete,
                        icon: AppIcons.trash2,
                        child: Text(l10n.delete),
                      ),
                const SizedBox(width: 8),
              ],
              readOnly
                  ? CcTooltip(
                      message: l10n.demoReadOnlySave,
                      child: CcButton(
                        size: CcButtonSize.sm,
                        onPressed: null,
                        child: Text(l10n.save),
                      ),
                    )
                  : CcButton(
                      size: CcButtonSize.sm,
                      onPressed: (saving || !dirty) ? null : onSave,
                      child: Text(saving ? l10n.savingEllipsis : l10n.save),
                    ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(text: l10n.nameLabel),
                    const SizedBox(height: 6),
                    CcTextField(
                      controller: nameCtl,
                      hintText: l10n.egArchitect,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(text: l10n.descriptionLabel),
                    const SizedBox(height: 6),
                    CcTextField(
                      controller: descCtl,
                      hintText: l10n.briefDescription,
                    ),
                  ],
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
              style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: CcMultiSelect<String>(
                options: [
                  for (final entry in agentItems.entries)
                    CcSelectOption(value: entry.value, label: entry.key),
                ],
                values: attachedAgentIds,
                onChanged: onAttachedChange,
                hintText: l10n.selectAgents,
                countLabel: l10n.agentCountPlural,
              ),
            ),
          const SizedBox(height: 16),
          _SectionLabel(text: l10n.contentMarkdown),
          const SizedBox(height: 6),
          CcTextArea(
            controller: bodyCtl,
            hintText: l10n.writeSkillContent,
            minLines: 14,
          ),
          if (dirty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(AppIcons.circleDot, size: 12, color: tokens?.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'Unsaved changes',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: tokens?.textTertiary,
                  ),
                ),
              ],
            ),
          ],
          if (!isNew && selectedSkill != null && workspaceId != null)
            SkillEvaluationPanel(
              workspaceId: workspaceId,
              slug: selectedSkill!,
              currentHash: currentHash,
              availableSkills: availableSkills,
              dirty: dirty,
            ),
        ],
      ),
    );
  }
}
