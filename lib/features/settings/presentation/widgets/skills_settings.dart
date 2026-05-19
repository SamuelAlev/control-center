import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/scanner/installed_skill_status.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';

import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/skills/skill_scan_widgets.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/skills/skill_sources_panel.dart';
import 'package:control_center/features/settings/providers/skill_security_providers.dart';
import 'package:control_center/features/settings/providers/skill_source_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaml/yaml.dart';

/// Parsed skill metadata (name, content, description) plus its antivirus
/// posture (PRD 23): lock provenance and the freshest scan verdict for the
/// CURRENT on-disk bytes. Security fields are nullable — a server without the
/// `skills.*` scan surface (or the legacy fallback path) reports them absent.
class SkillInfo {
  /// Creates a [SkillInfo].
  const SkillInfo({
    required this.name,
    required this.content,
    required this.description,
    this.lockState,
    this.origin,
    this.trustTier,
    this.scanVerdict,
    this.scanFindings = const [],
    this.scanLlmReviewed = false,
    this.scanRulesStale = false,
  });

  /// Skill file name.
  final String name;

  /// Raw skill file content.
  final String content;

  /// Skill description extracted from YAML front-matter.
  final String description;

  /// How the skill relates to `skills-lock.json` (null on the legacy path).
  final InstalledSkillLockState? lockState;

  /// Lock-recorded origin (null when unmanaged / legacy path).
  final SkillOrigin? origin;

  /// Lock-recorded provenance trust tier (null when unmanaged / legacy path).
  final SkillTrustTier? trustTier;

  /// The freshest cached scan verdict for the current bytes (null = these
  /// exact bytes were never scanned).
  final SkillScanVerdict? scanVerdict;

  /// The findings of that cached scan.
  final List<SkillScanFinding> scanFindings;

  /// Whether the Layer 3 LLM review ran for that scan.
  final bool scanLlmReviewed;

  /// Whether the cached scan predates the current scanner rules version.
  final bool scanRulesStale;
}

/// Provides the list of skills for a workspace with their antivirus posture.
///
/// Prefers the `skills.installedList` op (one round trip: metadata + content +
/// verdicts). Falls back to the plain `fs.*` reads (no verdicts) when the
/// connected server predates the scan surface (`opUnknown`), so an older host
/// keeps the editor working.
final skillListProvider = FutureProvider.family<List<SkillInfo>, String>((
  ref,
  workspaceId,
) async {
  try {
    final dtos = await ref
        .watch(skillSecurityControlProvider)
        .listInstalled(workspaceId);
    final skills = <SkillInfo>[
      for (final d in dtos)
        if (d.content != null)
          SkillInfo(
            name: d.slug,
            content: d.content!,
            description: extractYamlField(d.content!, 'description') ?? '',
            lockState: d.lockState,
            origin: d.origin,
            trustTier: d.trustTier,
            scanVerdict: d.scanVerdict,
            scanFindings: d.scanFindings,
            scanLlmReviewed: d.scanLlmReviewed,
            scanRulesStale: d.scanRulesStale,
          ),
    ];
    skills.sort((a, b) => a.name.compareTo(b.name));
    return skills;
  } on RemoteRpcException catch (e) {
    if (e.code == RpcErrorCodes.opUnknown) {
      return _legacySkillList(ref, workspaceId);
    }
    rethrow;
  }
});

Future<List<SkillInfo>> _legacySkillList(Ref ref, String workspaceId) async {
  final fs = ref.read(workspaceFilesystemPortProvider);
  // The caller falls back here when the modern skills op is absent — but on a
  // host with no workspace-filesystem port either (a demo server), the legacy
  // path is absent too and its `opUnknown` escaped as a raw transport error.
  // A fallback that fails differently is not a fallback.
  final List<String> slugs;
  try {
    slugs = await fs.listSkillSlugs(workspaceId);
  } on RemoteRpcException catch (e) {
    if (e.code == RpcErrorCodes.opUnknown) {
      return const [];
    }
    rethrow;
  }
  final skills = <SkillInfo>[];
  for (final slug in slugs) {
    final content = await fs.readSkillFile(workspaceId, slug);
    if (content == null) {
      continue;
    }
    final desc = extractYamlField(content, 'description') ?? '';
    skills.add(SkillInfo(name: slug, content: content, description: desc));
  }
  skills.sort((a, b) => a.name.compareTo(b.name));
  return skills;
}

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
  } on Object catch (_) {
    // Malformed skill front-matter — treat as absent.
  }
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
    final tokens = context.designSystem;
    // Route-driven provider (not GoRouterState.of): null-safe outside a router.
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    return PageWrapper(
      title: l10n.skills,
      subtitle: l10n.workspaceScopedSkills,
      // Installing a skill fetches and scans code, and `skills.*` is absent
      // from a demo server's registry. Keep the page chrome so the feature is
      // still discoverable, and say why the body is empty.
      child: ref.watch(isDemoServerProvider)
          ? const DemoUnavailable(capability: DemoCapability.skills)
          : workspaceId == null
          ? Center(
              child: Text(
                'No workspace selected',
                style: TextStyle(color: tokens?.textTertiary),
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

/// Which sub-view the Skills settings page shows: the workspace's installed
/// skills (view/edit) or the GitHub source browse-and-install surface.
enum _SkillsTab { installed, sources }

class _SkillsBodyState extends ConsumerState<_SkillsBody> {
  _SkillsTab _tab = _SkillsTab.installed;
  String? _selectedSkill;
  final _nameCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _bodyCtl = TextEditingController();
  final _filterCtl = TextEditingController();
  bool _dirty = false;
  bool _saving = false;
  bool _scanning = false;
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
      // _SkillsBody is only built with a resolved workspace id.
      final agents =
          ref.read(workspaceAgentsProvider(widget.workspaceId)).value ??
          const [];
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

  /// Writes the composed skill content through the antivirus gate
  /// (`skills.saveLocal`: scan → policy → write → pin). A quarantine verdict
  /// blocks the write and surfaces the findings + an explicit override; the
  /// legacy `fs.writeSkillFile` path remains only for servers without the scan
  /// surface. Returns true when the bytes reached disk.
  Future<bool> _writeSkillGated(String name, String content) async {
    final control = ref.read(skillSecurityControlProvider);
    try {
      var result = await control.saveLocal(widget.workspaceId, name, content);
      if (result.blocked) {
        final override = await _confirmQuarantinedSave(result);
        if (override != true) {
          return false;
        }
        result = await control.saveLocal(
          widget.workspaceId,
          name,
          content,
          allowQuarantineOverride: true,
        );
        if (result.blocked) {
          // The override was refused (e.g. a policy block, not the verdict) —
          // surface why instead of silently dropping the save.
          throw StateError(result.reason ?? result.verdict?.wire ?? 'blocked');
        }
      }
      return true;
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        // Older server: the ungated legacy write is all it has.
        final fs = ref.read(workspaceFilesystemPortProvider);
        await fs.writeSkillFile(widget.workspaceId, name, content);
        return true;
      }
      rethrow;
    }
  }

  /// The explicit "save anyway" acknowledgement for a quarantined save:
  /// findings first, then the override tick that arms the destructive retry.
  Future<bool?> _confirmQuarantinedSave(SkillSaveResult result) {
    return showCcDialog<bool>(
      context: context,
      builder: (dialogCtx) => _BlockedSaveDialog(result: result),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameCtl.text.trim();
    if (name.isEmpty) {
      CcToastScope.of(context).show(
        AppLocalizations.of(context).skillNameRequired,
        variant: CcToastVariant.neutral,
      );
      return;
    }

    setState(() => _saving = true);
    try {
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
        final fs = ref.read(workspaceFilesystemPortProvider);
        await fs.deleteSkillDir(widget.workspaceId, _selectedSkill!);
      }

      final wrote = await _writeSkillGated(name, content);
      if (!wrote) {
        // Blocked and not overridden — keep the editor open with the user's
        // content intact so they can adjust it.
        if (mounted) {
          setState(() => _saving = false);
        }
        return;
      }

      if (_attachedAgentIds.isNotEmpty) {
        final repo = ref.read(agentRepositoryProvider);
        final fs = ref.read(workspaceFilesystemPortProvider);
        for (final agentId in _attachedAgentIds) {
          final agent = await repo.getById(widget.workspaceId, agentId);
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
        CcToastScope.of(
          context,
        ).show(l10n.skillSaved(name), variant: CcToastVariant.success);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedSkill == null) {
      return;
    }
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.deleteConfirmName(_selectedSkill!),
        content: Text(AppLocalizations.of(context).thisCannotBeUndone),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.secondary,
            child: Text(AppLocalizations.of(context).cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      // Server-side uninstall: deletes the directory AND drops the lock pin
      // (the raw fs delete left a dangling pin). Falls back to the plain fs
      // path on a host that predates the op.
      try {
        await ref
            .read(skillSourceControlProvider)
            .uninstall(_selectedSkill!);
      } on RemoteRpcException catch (e) {
        if (e.code != RpcErrorCodes.opUnknown) {
          rethrow;
        }
        final fs = ref.read(workspaceFilesystemPortProvider);
        await fs.deleteSkillDir(widget.workspaceId, _selectedSkill!);
      }
      ref.invalidate(skillListProvider(widget.workspaceId));
      if (mounted) {
        _startNew();
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    }
  }

  /// Re-scans the currently selected skill's on-disk bytes and shows the full
  /// report. A `quarantine` verdict has already been enforced server-side (the
  /// skill is detached from its agents); the report names them.
  Future<void> _scanSkill() async {
    final skill = _selectedSkill;
    if (skill == null || _scanning) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _scanning = true);
    try {
      final report = await ref
          .read(skillSecurityControlProvider)
          .scanInstalled(widget.workspaceId, skill);
      ref.invalidate(skillListProvider(widget.workspaceId));
      if (mounted) {
        await showSkillScanReportDialog(context, title: skill, report: report);
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  /// Re-scans every installed skill and toasts the tally. One server-side
  /// `skills.analyze` pass (recorded as a skill_analysis pipeline run when the
  /// template is enabled); falls back to the per-slug scan loop on servers
  /// predating the op. One skill's failure never aborts the pass.
  Future<void> _scanAll() async {
    if (_scanning) {
      return;
    }
    final skills =
        ref.read(skillListProvider(widget.workspaceId)).value ?? const [];
    if (skills.isEmpty) {
      return;
    }
    setState(() => _scanning = true);
    try {
      final control = ref.read(skillSecurityControlProvider);
      try {
        final summary = await control.analyze(widget.workspaceId);
        ref.invalidate(skillListProvider(widget.workspaceId));
        if (mounted) {
          _toastScanTally(
            summary.passCount,
            summary.warnCount +
                summary.results.where((r) => r.error != null).length,
            summary.quarantineCount,
          );
        }
        return;
      } on RemoteRpcException catch (e) {
        if (e.code != RpcErrorCodes.opUnknown) {
          rethrow;
        }
        // Older server: scan each skill over the single-skill op instead.
      }
      var pass = 0;
      var warn = 0;
      var quarantined = 0;
      for (final skill in skills) {
        try {
          final report = await control.scanInstalled(
            widget.workspaceId,
            skill.name,
          );
          switch (report.verdict) {
            case SkillScanVerdict.pass:
              pass++;
            case SkillScanVerdict.warn:
              warn++;
            case SkillScanVerdict.quarantine:
              quarantined++;
          }
        } on Object {
          // Count a failed scan as a warning-level outcome for the tally.
          warn++;
        }
      }
      ref.invalidate(skillListProvider(widget.workspaceId));
      if (mounted) {
        _toastScanTally(pass, warn, quarantined);
      }
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  void _toastScanTally(int pass, int warn, int quarantined) {
    CcToastScope.of(context).show(
      AppLocalizations.of(context).skillScanAllSummary(pass, warn, quarantined),
      variant: quarantined > 0
          ? CcToastVariant.danger
          : warn > 0
          ? CcToastVariant.neutral
          : CcToastVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CcSegmentedToggle<_SkillsTab>(
              value: _tab,
              onChanged: (t) => setState(() => _tab = t),
              segments: [
                CcSegment(
                  value: _SkillsTab.installed,
                  label: l10n.skillsInstalledTab,
                ),
                CcSegment(
                  value: _SkillsTab.sources,
                  label: l10n.skillsSourcesTab,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _tab == _SkillsTab.installed
              ? _buildInstalled(context)
              : SkillSourcesPanel(workspaceId: widget.workspaceId),
        ),
      ],
    );
  }

  Widget _buildInstalled(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final skillsAsync = ref.watch(skillListProvider(widget.workspaceId));

    return skillsAsync.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => Center(child: Text(l10n.failedWithError('$e'))),
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
          child: SectionCard(
            label: l10n.skills,
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
            headerPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            expands: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CcIconButton(
                  icon: AppIcons.scanSearch,
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  tooltip: l10n.skillScanAll,
                  semanticLabel: l10n.skillScanAll,
                  onPressed: skills.isEmpty || _scanning ? null : _scanAll,
                  loading: _scanning,
                ),
                const SizedBox(width: 8),
                CcButton(
                  size: CcButtonSize.sm,
                  onPressed: _startNew,
                  icon: AppIcons.plus,
                  child: Text(l10n.newSkill),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CcDivider(),
                Expanded(
                  child: SettingsMasterDetail(
                    railWidth: 260,
                    rail: _SkillRailContent(
                      skills: filteredSkills,
                      selectedSkill: _selectedSkill,
                      filterController: _filterCtl,
                      onSelect: (name) => _loadSkill(name, skills),
                    ),
                    detail: editing
                        ? _SkillEditorContent(
                            isNew: _isNew,
                            selectedSkill: _selectedSkill,
                            nameCtl: _nameCtl,
                            descCtl: _descCtl,
                            bodyCtl: _bodyCtl,
                            attachedAgentIds: _attachedAgentIds,
                            dirty: _dirty,
                            saving: _saving,
                            scanning: _scanning,
                            onAttachedChange: (ids) => setState(() {
                              _attachedAgentIds = ids;
                              _dirty = true;
                            }),
                            onSave: _save,
                            onScan: _scanSkill,
                            onDelete: _delete,
                          )
                        : const _SkillEmptyContent(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Rail content ──────────────────────────────────────────────────────────

class _SkillRailContent extends StatelessWidget {
  const _SkillRailContent({
    required this.skills,
    required this.selectedSkill,
    required this.filterController,
    required this.onSelect,
  });

  final List<SkillInfo> skills;
  final String? selectedSkill;
  final TextEditingController filterController;
  final void Function(String name) onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcTextField(
          controller: filterController,
          hintText: l10n.filterSkillsPlaceholder,
          size: CcTextFieldSize.sm,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (skills.isEmpty)
          const SettingsRailEmptyNote(message: 'No matches.')
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
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
            border: Border(
              left: BorderSide(
                color: selected ? accentColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
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
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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

class _SkillEmptyContent extends StatelessWidget {
  const _SkillEmptyContent();

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.puzzle, size: 48, color: tokens?.textTertiary),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).selectLabel,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).briefDescription,
            style: TextStyle(fontSize: 13, color: tokens?.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ─── Editor ────────────────────────────────────────────────────────────────

class _SkillEditorContent extends ConsumerWidget {
  const _SkillEditorContent({
    required this.isNew,
    required this.selectedSkill,
    required this.nameCtl,
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
                  onPressed: scanning ? null : onScan,
                  loading: scanning,
                  icon: AppIcons.scanSearch,
                  child: Text(l10n.skillScanAction),
                ),
                const SizedBox(width: 8),
                CcButton(
                  variant: CcButtonVariant.destructive,
                  size: CcButtonSize.sm,
                  onPressed: onDelete,
                  icon: AppIcons.trash2,
                  child: Text(l10n.delete),
                ),
                const SizedBox(width: 8),
              ],
              CcButton(
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
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: tokens?.textTertiary,
      ),
    );
  }
}

/// The save-side quarantine flow: the antivirus blocked the write (nothing
/// reached disk); the operator sees the findings, then explicitly overrides or
/// cancels. Mirrors the browse panel's install dialog.
class _BlockedSaveDialog extends StatefulWidget {
  const _BlockedSaveDialog({required this.result});

  final SkillSaveResult result;

  @override
  State<_BlockedSaveDialog> createState() => _BlockedSaveDialogState();
}

class _BlockedSaveDialogState extends State<_BlockedSaveDialog> {
  bool _override = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final result = widget.result;
    return CcDialog(
      title: l10n.skillSaveBlockedTitle,
      onClose: () => Navigator.of(context).pop(false),
      maxWidth: 560,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.verdict != null) ...[
                SkillVerdictBadge(verdict: result.verdict!),
                const SizedBox(height: 12),
              ],
              if (result.findings.isEmpty)
                Text(
                  result.reason == null
                      ? l10n.skillSaveBlockedBody
                      : l10n.failedWithError(result.reason!),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: tokens?.textSecondary,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final f in result.findings)
                      SkillFindingTile(finding: f),
                  ],
                ),
              const SizedBox(height: 16),
              SkillQuarantineOverride(
                checked: _override,
                onChanged: (v) => setState(() => _override = v),
                checkboxLabel: Text(l10n.skillSaveAnywayOverride),
              ),
            ],
          ),
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        CcButton(
          variant: CcButtonVariant.destructive,
          onPressed: _override ? () => Navigator.of(context).pop(true) : null,
          icon: AppIcons.shieldOff,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
