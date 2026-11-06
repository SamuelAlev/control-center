part of 'skill_sources_panel.dart';

class _SourceRail extends ConsumerWidget {
  const _SourceRail({
    required this.sources,
    required this.selectedSourceId,
    required this.workspaceId,
    required this.onSelect,
    required this.onAdded,
  });

  final List<SkillSourceDto> sources;
  final String? selectedSourceId;
  final String workspaceId;
  final ValueChanged<String?> onSelect;
  final ValueChanged<String> onAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: CcButton(
            size: CcButtonSize.sm,
            icon: AppIcons.plus,
            onPressed: () => _addSource(context, ref),
            child: Text(l10n.skillSourceAdd),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (sources.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.sm,
              end: 8,
            ),
            child: SettingsRailEmptyNote(message: l10n.skillSourcesEmptyHint),
          )
        else
          Expanded(
            child: ListView.separated(
              // The insets live inside the scroll view: rows keep their gap
              // from the divider while the thumb runs in that gutter.
              padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 8, 12),
              itemCount: sources.length,
              separatorBuilder: (_, _) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final source = sources[index];
                return SettingsRailItem(
                  label: source.fullName,
                  icon: AppIcons.gitBranch,
                  selected: source.id == selectedSourceId,
                  onPressed: () => onSelect(source.id),
                  trailing: Text(
                    '${source.skillCount}',
                    style: CcTypography.caption.copyWith(
                      color: context.designSystem?.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _addSource(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final url = await showCcDialog<String>(
      context: context,
      builder: (_) => const _AddSourceDialog(),
    );
    if (url == null || url.trim().isEmpty) {
      return;
    }
    try {
      final (source, alreadyExists) = await ref
          .read(skillSourceControlProvider)
          .addSource(url.trim());
      ref.invalidate(skillSourcesProvider(workspaceId));
      onAdded(source.id);
      if (context.mounted) {
        CcToastScope.of(context).show(
          alreadyExists
              ? l10n.skillSourceAlreadyAdded(source.fullName)
              : l10n.skillSourceAdded(source.fullName),
          variant: alreadyExists
              ? CcToastVariant.neutral
              : CcToastVariant.success,
        );
      }
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    }
  }
}
