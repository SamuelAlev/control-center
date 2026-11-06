part of 'skills_settings.dart';

class _SkillRailContent extends StatelessWidget {
  const _SkillRailContent({
    required this.skills,
    required this.selectedSkill,
    required this.filterController,
    required this.filterAction,
    required this.onSelect,
  });

  final List<SkillInfo> skills;
  final String? selectedSkill;
  final TextEditingController filterController;
  final Widget filterAction;
  final void Function(String name) onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: CcTextField(
                  controller: filterController,
                  hintText: l10n.filterSkillsPlaceholder,
                  size: CcTextFieldSize.sm,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              filterAction,
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (skills.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SettingsRailEmptyNote(message: 'No matches.'),
          )
        else
          Expanded(
            child: ListView.separated(
              // The insets live inside the scroll view: rows keep their gap
              // from the divider while the thumb runs in that gutter.
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                6,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              itemCount: skills.length,
              separatorBuilder: (_, _) => const CcDivider(),
              itemBuilder: (context, index) {
                final skill = skills[index];
                return _SkillsListTile(
                  skill: skill,
                  selected: skill.name == selectedSkill,
                  onTap: () => onSelect(skill.name),
                );
              },
            ),
          ),
      ],
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
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final accentColor = tokens?.textPrimary ?? DesignSystemPalette.gray900;
    // Provenance/state line under the description: origin · lock state ·
    // scan-freshness. Absent entirely on the legacy (no-scan-surface) path.
    final meta = <String>[
      if (skill.origin != null)
        switch (skill.origin!) {
          SkillOrigin.manual => l10n.skillOriginManual,
          SkillOrigin.registry => l10n.skillOriginRegistry,
          SkillOrigin.github => l10n.skillOriginGithub,
          SkillOrigin.runtimeLocal => l10n.skillOriginRuntimeLocal,
        },
      if (skill.lockState == InstalledSkillLockState.drifted)
        l10n.skillStateDrifted
      else if (skill.lockState == InstalledSkillLockState.unmanaged)
        l10n.skillStateUnmanaged,
      if (skill.scanVerdict == null && skill.lockState != null)
        l10n.skillNotScanned
      else if (skill.scanRulesStale)
        l10n.skillRulesStale,
    ].join('  ·  ');
    final metaColor = skill.lockState == InstalledSkillLockState.drifted
        ? tokens?.textWarningPrimary
        : tokens?.textTertiary;
    // Same interaction treatment as the agent roster / provider / adapter
    // rails: a hover wash, a stronger wash while pressed or selected, and the
    // left accent bar for the selected row.
    return CcTappable(
      onPressed: onTap,
      semanticLabel: skill.name,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        return Container(
          decoration: BoxDecoration(
            color: selected || pressed
                ? tokens?.hoverStrong
                : hovered
                ? tokens?.hover
                : null,
            border: BorderDirectional(
              start: BorderSide(
                color: selected ? accentColor : const Color(0x00000000),
                width: 2,
              ),
            ),
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      skill.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: tokens?.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (skill.scanVerdict != null) ...[
                    const SizedBox(width: 6),
                    SkillVerdictBadge(
                      verdict: skill.scanVerdict!,
                      compact: true,
                    ),
                  ],
                ],
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
                    color: tokens?.textTertiary,
                  ),
                ),
              ],
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: metaColor),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
