import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/skills/skill_scan_widgets.dart';
import 'package:control_center/features/settings/presentation/widgets/skills_settings.dart';
import 'package:control_center/features/settings/providers/skill_source_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Skills → "Sources": the GitHub repositories the operator
/// registered as skill catalogs (the skills.sh registry replacement).
///
/// Left rail = the registered repositories (add by URL, remove); right pane =
/// a grid of the selected repository's skills; clicking a skill opens its
/// detail view (README rendered as markdown + the antivirus scan preview) with
/// install / update / uninstall actions.
///
/// Drives the `skills.sources*` / `skills.source*` ops through
/// [RpcSkillSourceControl], so it is identical on desktop and web. The
/// repository is UNTRUSTED: its name, description and star count are
/// provenance evidence only — the real safety signal is the scan verdict the
/// detail view surfaces prominently (never by colour alone).
class SkillSourcesPanel extends ConsumerStatefulWidget {
  /// Creates a [SkillSourcesPanel] scoped to [workspaceId] (used to refresh the
  /// installed-skills list after an install/uninstall).
  const SkillSourcesPanel({super.key, required this.workspaceId});

  /// The workspace the skills install into.
  final String workspaceId;

  @override
  ConsumerState<SkillSourcesPanel> createState() => _SkillSourcesPanelState();
}

class _SkillSourcesPanelState extends ConsumerState<SkillSourcesPanel> {
  String? _selectedSourceId;
  String? _selectedPath;

  void _selectSource(String? id) {
    if (id == _selectedSourceId) {
      return;
    }
    setState(() {
      _selectedSourceId = id;
      _selectedPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sourcesAsync = ref.watch(skillSourcesProvider(widget.workspaceId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SectionCard(
        label: l10n.skills,
        expands: true,
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
        headerPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Text(
                l10n.skillSourcesDisclaimer,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: context.designSystem?.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const CcDivider(),
            Expanded(
              child: sourcesAsync.when(
                loading: () => const Center(child: CcSpinner()),
                error: (e, _) => _SourcesEmptyMessage(
                  icon: AppIcons.alertTriangle,
                  text: l10n.failedWithError('$e'),
                ),
                data: (sources) {
                  // Auto-select the first source so the pane opens on a
                  // catalog instead of an empty prompt (post-frame: never
                  // setState during build).
                  if (_selectedSourceId == null && sources.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _selectedSourceId == null) {
                        setState(() => _selectedSourceId = sources.first.id);
                      }
                    });
                  }
                  return SettingsMasterDetail(
                  railWidth: 250,
                  railPadding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  rail: _SourceRail(
                    sources: sources,
                    selectedSourceId: _selectedSourceId,
                    workspaceId: widget.workspaceId,
                    onSelect: _selectSource,
                    onAdded: _selectSource,
                  ),
                  detail: _SourceDetailPane(
                    sources: sources,
                    sourceId: _selectedSourceId,
                    selectedPath: _selectedPath,
                    workspaceId: widget.workspaceId,
                    onOpenSkill: (path) =>
                        setState(() => _selectedPath = path),
                    onBack: () => setState(() => _selectedPath = null),
                    onSourcesChanged: () => ref.invalidate(
                      skillSourcesProvider(widget.workspaceId),
                    ),
                  ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The left rail: the "add repository" action and the registered sources.
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
        CcButton(
          size: CcButtonSize.sm,
          icon: AppIcons.plus,
          onPressed: () => _addSource(context, ref),
          child: Text(l10n.skillSourceAdd),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (sources.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: SettingsRailEmptyNote(message: l10n.skillSourcesEmptyHint),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
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
          variant:
              alreadyExists ? CcToastVariant.neutral : CcToastVariant.success,
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

/// The add-repository dialog: one URL field. The server parses + validates the
/// URL (owner/repo) and rejects unknown repositories.
class _AddSourceDialog extends ConsumerStatefulWidget {
  const _AddSourceDialog();

  @override
  ConsumerState<_AddSourceDialog> createState() => _AddSourceDialogState();
}

class _AddSourceDialogState extends ConsumerState<_AddSourceDialog> {
  final _ctl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcDialog(
      title: l10n.skillSourceAddTitle,
      onClose: () => Navigator.of(context).pop(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.skillSourcesDisclaimer,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: context.designSystem?.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          CcTextField(
            controller: _ctl,
            hintText: l10n.skillSourceAddHint,
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          loading: _busy,
          icon: AppIcons.plus,
          onPressed: _submit,
          child: Text(l10n.skillSourceAdd),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    // Client-side shape check for instant feedback; the server re-validates
    // and remains the authority.
    final l10n = AppLocalizations.of(context);
    final url = _ctl.text.trim();
    if (!RegExp(
      r'^(https://github\.com/|git@github\.com:)?[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/?$',
    ).hasMatch(url)) {
      CcToastScope.of(
        context,
      ).show(l10n.skillSourceInvalidUrl, variant: CcToastVariant.danger);
      return;
    }
    setState(() => _busy = true);
    Navigator.of(context).pop(url);
  }
}

/// The right pane: the selected source's header + skills grid, or the selected
/// skill's detail view.
class _SourceDetailPane extends ConsumerWidget {
  const _SourceDetailPane({
    required this.sources,
    required this.sourceId,
    required this.selectedPath,
    required this.workspaceId,
    required this.onOpenSkill,
    required this.onBack,
    required this.onSourcesChanged,
  });

  final List<SkillSourceDto> sources;
  final String? sourceId;
  final String? selectedPath;
  final String workspaceId;
  final ValueChanged<String> onOpenSkill;
  final VoidCallback onBack;
  final VoidCallback onSourcesChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    SkillSourceDto? source;
    for (final s in sources) {
      if (s.id == sourceId) {
        source = s;
        break;
      }
    }
    if (source == null) {
      return _SourcesEmptyMessage(
        icon: AppIcons.gitBranch,
        text: l10n.skillSourcesEmpty,
        hint: l10n.skillSourcesEmptyHint,
      );
    }
    if (selectedPath != null) {
      return _SkillDetailView(
        source: source,
        path: selectedPath!,
        workspaceId: workspaceId,
        onBack: onBack,
      );
    }
    return _SourceBrowsePane(
      source: source,
      workspaceId: workspaceId,
      onOpenSkill: onOpenSkill,
      onRemoved: onSourcesChanged,
    );
  }
}

/// Header (repo name/description, refresh, remove) + a filter field + the
/// skills grid.
class _SourceBrowsePane extends ConsumerStatefulWidget {
  const _SourceBrowsePane({
    required this.source,
    required this.workspaceId,
    required this.onOpenSkill,
    required this.onRemoved,
  });

  final SkillSourceDto source;
  final String workspaceId;
  final ValueChanged<String> onOpenSkill;
  final VoidCallback onRemoved;

  @override
  ConsumerState<_SourceBrowsePane> createState() => _SourceBrowsePaneState();
}

class _SourceBrowsePaneState extends ConsumerState<_SourceBrowsePane> {
  final _filterCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filterCtl.addListener(_onFilterChanged);
  }

  @override
  void didUpdateWidget(_SourceBrowsePane oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A filter is about THIS repository's catalog; switching sources resets it.
    if (oldWidget.source.id != widget.source.id) {
      _filterCtl.clear();
    }
  }

  void _onFilterChanged() => setState(() {});

  @override
  void dispose() {
    _filterCtl.removeListener(_onFilterChanged);
    _filterCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final source = widget.source;
    final listingsAsync = ref.watch(skillSourceListingsProvider(source.id));

    // The server persists the discovered skill count when a listing succeeds;
    // refresh the sources list so the rail count catches up (the listings
    // family stays cached, so this cannot loop).
    ref.listen<AsyncValue<List<SourceSkillDto>>>(
      skillSourceListingsProvider(source.id),
      (previous, next) {
        if (next.asData?.value != null) {
          ref.invalidate(skillSourcesProvider(widget.workspaceId));
        }
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            source.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tokens?.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          AppIcons.star,
                          size: 12,
                          color: tokens?.textTertiary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${source.starCount}',
                          style: TextStyle(
                            fontSize: 11,
                            color: tokens?.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    if (source.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        source.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: tokens?.textTertiary,
                        ),
                      ),
                    ],
                    if (source.lastError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.failedWithError(source.lastError!),
                        style: TextStyle(
                          fontSize: 11,
                          color: tokens?.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CcIconButton(
                icon: AppIcons.refreshCw,
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                tooltip: l10n.skillSourceRefresh,
                semanticLabel: l10n.skillSourceRefresh,
                onPressed: () => ref.invalidate(
                  skillSourceListingsProvider(source.id),
                ),
              ),
              const SizedBox(width: 8),
              CcIconButton(
                icon: AppIcons.trash2,
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                tooltip: l10n.skillSourceRemove,
                semanticLabel: l10n.skillSourceRemove,
                onPressed: () => _confirmRemove(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const CcDivider(),
          const SizedBox(height: 12),
          CcTextField(
            controller: _filterCtl,
            hintText: l10n.filterSkillsPlaceholder,
            size: CcTextFieldSize.sm,
            prefix: Icon(
              AppIcons.search,
              size: 16,
              color: tokens?.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: listingsAsync.when(
              loading: () => const Center(child: CcSpinner()),
              error: (e, _) => _SourcesEmptyMessage(
                icon: AppIcons.alertTriangle,
                text: l10n.failedWithError('$e'),
              ),
              data: (listings) {
                if (listings.isEmpty) {
                  return _SourcesEmptyMessage(
                    icon: AppIcons.gitBranch,
                    text: l10n.skillSourceNoSkills,
                  );
                }
                final filter = _filterCtl.text.trim().toLowerCase();
                final filtered = filter.isEmpty
                    ? listings
                    : listings
                          .where(
                            (s) =>
                                s.name.toLowerCase().contains(filter) ||
                                s.description.toLowerCase().contains(filter) ||
                                s.slug.toLowerCase().contains(filter),
                          )
                          .toList();
                if (filtered.isEmpty) {
                  return _SourcesEmptyMessage(
                    icon: AppIcons.search,
                    text: l10n.skillSourceNoMatches,
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 1.55,
                      ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _SkillCard(
                    skill: filtered[index],
                    onTap: () => widget.onOpenSkill(filtered[index].path),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.skillSourceRemoveConfirmTitle(widget.source.fullName),
        content: Text(l10n.skillSourceRemoveConfirmBody),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.skillSourceRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(skillSourceControlProvider).removeSource(widget.source.id);
    widget.onRemoved();
    ref.invalidate(skillSourcesProvider(widget.workspaceId));
    if (context.mounted) {
      CcToastScope.of(context).show(
        l10n.skillSourceRemoved(widget.source.fullName),
        variant: CcToastVariant.success,
      );
    }
  }
}

/// One skill in the grid: name, description and an install-state footer.
class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.skill, required this.onTap});

  final SourceSkillDto skill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    return CcTappable(
      onPressed: onTap,
      semanticLabel: skill.name,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: pressed
                ? tokens?.hoverStrong
                : hovered
                ? tokens?.hover
                : tokens?.bgSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens?.borderSecondary ?? const Color(0x00000000)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                skill.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens?.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  skill.description.isEmpty ? skill.path : skill.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: tokens?.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (skill.updateAvailable || skill.installed || skill.slugTaken)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (skill.updateAvailable)
                      CcChip(label: l10n.skillSourceUpdateBadge)
                    else if (skill.installed)
                      CcChip(label: l10n.skillSourceInstalledBadge)
                    else if (skill.slugTaken)
                      CcChip(label: l10n.skillSourceSlugTaken),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The skill detail view: README markdown + the antivirus scan preview, with
/// install / update / uninstall actions. A `quarantine` verdict requires an
/// explicit override tick before install.
class _SkillDetailView extends ConsumerStatefulWidget {
  const _SkillDetailView({
    required this.source,
    required this.path,
    required this.workspaceId,
    required this.onBack,
  });

  final SkillSourceDto source;
  final String path;
  final String workspaceId;
  final VoidCallback onBack;

  @override
  ConsumerState<_SkillDetailView> createState() => _SkillDetailViewState();
}

class _SkillDetailViewState extends ConsumerState<_SkillDetailView> {
  bool _override = false;
  bool _busy = false;
  String? _error;
  SkillInstallResultDto? _lastResult;

  SourceSkillDto? _listing(List<SourceSkillDto> listings) {
    for (final l in listings) {
      if (l.path == widget.path) {
        return l;
      }
    }
    return null;
  }

  /// Whether the skill currently reads as quarantined: from a blocked
  /// install/update retry when there is one, otherwise from the loaded
  /// detail's scan preview.
  bool _isQuarantine(SourceSkillDetailDto? detail) {
    if (_lastResult?.blocked == true) {
      return _lastResult?.verdict == SkillScanVerdict.quarantine;
    }
    return detail?.scan.verdict == SkillScanVerdict.quarantine;
  }
  Future<void> _install({required bool update}) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final control = ref.read(skillSourceControlProvider);
      final result = update
          ? await control.updateSkill(
              _slugOfPath(),
              allowQuarantineOverride: _override,
            )
          : await control.install(
              widget.source.id,
              widget.path,
              allowQuarantineOverride: _override,
            );
      if (!mounted) {
        return;
      }
      setState(() => _lastResult = result);
      if (result.blocked) {
        return; // Findings + the override checkbox render inline.
      }
      ref.invalidate(skillListProvider(widget.workspaceId));
      ref.invalidate(skillSourceListingsProvider(widget.source.id));
      CcToastScope.of(context).show(
        AppLocalizations.of(context).skillInstalled(result.slug),
        variant: CcToastVariant.success,
      );
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _slugOfPath() {
    final slash = widget.path.lastIndexOf('/');
    final dir = slash == -1 ? '' : widget.path.substring(0, slash);
    return dir.isEmpty ? 'skill' : dir.split('/').last;
  }

  Future<void> _uninstall() async {
    if (_busy) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final slug = _slugOfPath();
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.skillUninstallConfirmTitle(slug),
        content: Text(l10n.thisCannotBeUndone),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.skillUninstallAction),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(skillSourceControlProvider).uninstall(slug);
      ref.invalidate(skillListProvider(widget.workspaceId));
      ref.invalidate(skillSourceListingsProvider(widget.source.id));
      if (mounted) {
        CcToastScope.of(context).show(
          l10n.skillUninstalled(slug),
          variant: CcToastVariant.success,
        );
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final listingsAsync = ref.watch(
      skillSourceListingsProvider(widget.source.id),
    );
    final listings = listingsAsync.asData?.value;
    final listing = listings == null ? null : _listing(listings);
    final detailAsync = ref.watch(
      skillSourceDetailProvider(
        (sourceId: widget.source.id, path: widget.path),
      ),
    );
    final detail = detailAsync.asData?.value;
    final quarantined = _isQuarantine(detail);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, l10n, listing, quarantined),
          const SizedBox(height: 12),
          const CcDivider(),
          const SizedBox(height: 12),
          Expanded(
            child: detailAsync.when(
              loading: () => Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CcSpinner(),
                    const SizedBox(width: 12),
                    Text(
                      l10n.skillPreviewScanning,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.designSystem?.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              error: (e, _) => _SourcesEmptyMessage(
                icon: AppIcons.alertTriangle,
                text: l10n.failedWithError('$e'),
              ),
              data: (detail) => _buildBody(context, l10n, detail),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    SourceSkillDto? listing,
    bool quarantined,
  ) {
    final tokens = context.designSystem;
    return Row(
      children: [
        CcIconButton(
          icon: AppIcons.arrowLeft,
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          tooltip: l10n.back,
          semanticLabel: l10n.back,
          onPressed: widget.onBack,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing?.name ?? _slugOfPath(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tokens?.textPrimary,
                ),
              ),
              Text(
                '${widget.source.fullName} · ${widget.path}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: tokens?.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (listing?.installed == true) ...[
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: AppIcons.trash2,
            loading: _busy,
            onPressed: _uninstall,
            child: Text(l10n.skillUninstallAction),
          ),
          const SizedBox(width: 8),
          CcButton(
            size: CcButtonSize.sm,
            icon: AppIcons.download,
            loading: _busy,
            onPressed: quarantined && !_override
                ? null
                : () => _install(update: true),
            child: Text(l10n.skillUpdateAction),
          ),
        ] else
          CcButton(
            size: CcButtonSize.sm,
            icon: AppIcons.download,
            loading: _busy,
            onPressed: quarantined && !_override
                ? null
                : () => _install(update: false),
            child: Text(l10n.install),
          ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    SourceSkillDetailDto detail,
  ) {
    final tokens = context.designSystem;
    final scan = detail.scan;
    final quarantined = scan.verdict == SkillScanVerdict.quarantine;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkillFieldLabel(text: l10n.skillPreviewVerdictLabel),
          const SizedBox(height: 6),
          Row(
            children: [
              SkillVerdictBadge(verdict: scan.verdict),
              if (scan.llmReviewed) ...[
                const SizedBox(width: 10),
                Text(
                  l10n.skillPreviewLlmReviewed,
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens?.textTertiary,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                l10n.skillSourceFilesCount(detail.fileCount),
                style: TextStyle(
                  fontSize: 11,
                  color: tokens?.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SkillFieldLabel(text: l10n.skillPreviewCapabilities),
          const SizedBox(height: 6),
          if (scan.capabilities.isEmpty)
            Text(
              l10n.skillPreviewNoCapabilities,
              style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final cap in scan.capabilities) CcChip(label: cap),
              ],
            ),
          if (scan.requiredActionClasses.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.skillPreviewGuardedActions}: '
              '${scan.requiredActionClasses.join(', ')}',
              style: TextStyle(fontSize: 11, color: tokens?.textTertiary),
            ),
          ],
          const SizedBox(height: 14),
          SkillFieldLabel(text: l10n.skillPreviewFindings),
          const SizedBox(height: 6),
          if (scan.findings.isEmpty)
            Text(
              l10n.skillPreviewNoFindings,
              style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in scan.findings) SkillFindingTile(finding: f),
              ],
            ),
          if (quarantined) ...[
            const SizedBox(height: 14),
            SkillQuarantineOverride(
              checked: _override,
              onChanged: _busy ? null : (v) => setState(() => _override = v),
              checkboxLabel: Text(l10n.skillInstallAnywayOverride),
            ),
          ],
          if (_lastResult?.blocked == true && _lastResult?.reason != null) ...[
            const SizedBox(height: 10),
            Text(
              l10n.failedWithError(_lastResult!.reason!),
              style: TextStyle(fontSize: 12, color: tokens?.danger),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              l10n.failedWithError(_error!),
              style: TextStyle(fontSize: 12, color: tokens?.danger),
            ),
          ],
          const SizedBox(height: 16),
          const CcDivider(),
          const SizedBox(height: 16),
          if (detail.readme.trim().isEmpty)
            Text(
              l10n.skillSourceNoReadme,
              style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
            )
          else ...[
            SkillFieldLabel(text: l10n.skillSourceReadme),
            const SizedBox(height: 8),
            StyledMarkdownBody(data: detail.readme),
          ],
        ],
      ),
    );
  }
}

/// A centered icon + message used for the panel's empty / error states.
class _SourcesEmptyMessage extends StatelessWidget {
  const _SourcesEmptyMessage({required this.icon, required this.text, this.hint});

  final IconData icon;
  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: tokens?.textTertiary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: tokens?.textSecondary),
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
