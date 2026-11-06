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
import 'package:control_center/features/settings/presentation/widgets/sections/skills/skill_evaluation_panel.dart';
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
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaml/yaml.dart';

part 'skills_settings_editor.dart';
part 'skills_settings_rail.dart';

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
    this.computedHash = '',
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

  /// Exact current package hash supplied by the catalog; unavailable on legacy hosts.
  final String computedHash;

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
            computedHash: d.computedHash,
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
      // Seeded skills are readable. Writes stay closed: save, delete, scan
      // and the sources tab (a GitHub fetch) do not run on a demo.
      child: workspaceId == null
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
    _filterCtl.addListener(() => setState(() {}));
  }

  /// Driven by the fields' `onChanged`, not a controller listener: a controller
  /// also notifies on selection changes, so focusing a field would count.
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
    if (ref.read(isDemoServerProvider)) {
      return;
    }
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
            // AgentSkills.toList() is unmodifiable; copy before editing.
            final currentSkills = [...agent.skills.toList()];
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
    if (_selectedSkill == null || ref.read(isDemoServerProvider)) {
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
        await ref.read(skillSourceControlProvider).uninstall(_selectedSkill!);
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
    if (skill == null || _scanning || ref.read(isDemoServerProvider)) {
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
    if (_scanning || ref.read(isDemoServerProvider)) {
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
            alignment: AlignmentDirectional.centerStart,
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
              : ref.watch(isDemoServerProvider)
              ? const DemoUnavailable(capability: DemoCapability.skills)
              : SkillSourcesPanel(workspaceId: widget.workspaceId),
        ),
      ],
    );
  }

  Widget _buildInstalled(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final skillsAsync = ref.watch(skillListProvider(widget.workspaceId));
    final readOnly = ref.watch(isDemoServerProvider);

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
        final newSkill = CcButton(
          size: CcButtonSize.sm,
          onPressed: readOnly ? null : _startNew,
          icon: AppIcons.plus,
          semanticLabel: l10n.newSkill,
          child: Text(l10n.newItemAction),
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SectionCard(
            label: l10n.skills,
            // Top inset matches the card's 12 px header gap, so the header
            // sits evenly between the card edge and the divider.
            padding: const EdgeInsets.only(top: AppSpacing.md),
            headerPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 8, 0),
            headerAlignment: CrossAxisAlignment.center,
            expands: true,
            trailing: CcIconButton(
              icon: AppIcons.scanSearch,
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              tooltip: readOnly ? l10n.demoReadOnlySave : l10n.skillScanAll,
              semanticLabel: l10n.skillScanAll,
              onPressed: skills.isEmpty || _scanning || readOnly
                  ? null
                  : _scanAll,
              loading: _scanning,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CcDivider(),
                Expanded(
                  child: SettingsMasterDetail(
                    railWidth: 260,
                    // The rail owns its insets so the list's viewport, and
                    // with it the scrollbar, reaches the divider.
                    railPadding: EdgeInsets.zero,
                    rail: _SkillRailContent(
                      skills: filteredSkills,
                      selectedSkill: _selectedSkill,
                      filterController: _filterCtl,
                      filterAction: readOnly
                          ? CcTooltip(
                              message: l10n.demoReadOnlySave,
                              child: newSkill,
                            )
                          : newSkill,
                      onSelect: (name) => _loadSkill(name, skills),
                    ),
                    detail: editing
                        ? _SkillEditorContent(
                            isNew: _isNew,
                            selectedSkill: _selectedSkill,
                            currentHash:
                                skills
                                    .where((s) => s.name == _selectedSkill)
                                    .firstOrNull
                                    ?.computedHash ??
                                '',
                            availableSkills: [for (final s in skills) s.name],
                            nameCtl: _nameCtl,
                            descCtl: _descCtl,
                            bodyCtl: _bodyCtl,
                            attachedAgentIds: _attachedAgentIds,
                            dirty: _dirty,
                            saving: _saving,
                            scanning: _scanning,
                            onEdited: _markDirty,
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
