import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/utils/string_utils.dart';
import 'package:cc_domain/features/agents/domain/constants/builtin_agent_seeds.dart';
import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/presentation/widgets/skill_assignment_section.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/model_select.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/capability_toggles.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The agent's configuration form — the Settings tab of the agent registry.
///
/// ## Why it looks like this
///
/// It used to be a flat column of eighteen ad-hoc rows: a hand-rolled 12px
/// tertiary label above every control, two switches with no shared anatomy,
/// and a Save button parked at the bottom of a scroll long enough that the
/// widget test had to `scrollUntilVisible` to reach it. Beside Skills, Model
/// providers and Detected runners — which all read as one system — the agent
/// registry read as a different product.
///
/// So it is built from the same kit as those surfaces: [SettingsGroup] blocks
/// (identity, runtime, skills, guardrails) of [SettingsField] rows, so every
/// label lands on the same vertical line and the form scans as a list of
/// values; [SettingsToggle] for the two switches; [SettingsDisclosure] for the
/// capability matrix, which is expert and per-agent; and a [SettingsSaveBar]
/// pinned below the scroll, so unsaved work announces itself instead of hiding
/// at the end of a column.
class AgentSettingsForm extends ConsumerStatefulWidget {
  /// Creates a new [AgentSettingsForm].
  const AgentSettingsForm({
    super.key,
    required this.agent,
    required this.availableSkills,
    this.onDelete,
  });

  /// The agent being edited.
  final Agent agent;

  /// All skill slugs available in the current workspace.
  final List<String> availableSkills;

  /// Deletes this agent (the host owns the confirmation and the write). When
  /// null the danger zone is not rendered at all — a Delete that cannot delete
  /// is worse than no Delete.
  final VoidCallback? onDelete;

  @override
  ConsumerState<AgentSettingsForm> createState() => _AgentSettingsFormState();
}

class _AgentSettingsFormState extends ConsumerState<AgentSettingsForm> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _titleCtl;
  late final TextEditingController _systemPromptCtl;
  Set<String> _selectedSkills = {};
  late final TextEditingController _reportsToController;
  String? _reportsToId;
  late final TextEditingController _personaCtl;
  String? _selectedAdapterId;
  String? _selectedModelId;
  bool _strictMode = false;
  String? _effort;

  /// True once the user has chosen an effort level, so model-driven
  /// auto-default never overrides a deliberate selection.
  bool _effortUserEdited = false;
  int? _contextSize;
  int? _silenceTimeout;
  AgentCapabilities? _capabilities;
  bool _useCustomCapabilities = false;
  late final TextEditingController _contextSizeCtl;
  late final TextEditingController _silenceTimeoutCtl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController();
    _titleCtl = TextEditingController();
    _systemPromptCtl = TextEditingController();
    _reportsToController = TextEditingController();
    _personaCtl = TextEditingController();
    _contextSizeCtl = TextEditingController();
    _silenceTimeoutCtl = TextEditingController();
    _loadFrom(widget.agent);

    // Every text control repaints the form, because the save bar's presence is
    // derived from a comparison against the agent rather than from a sticky
    // "touched" flag — typing a change and typing it back out has to make the
    // bar go away again, which a flag cannot do.
    for (final c in _textControllers) {
      c.addListener(_onFieldChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _reportsToController.text = _resolveReportsToName(_reportsToId);
      }
    });
  }

  List<TextEditingController> get _textControllers => [
    _nameCtl,
    _titleCtl,
    _systemPromptCtl,
    _personaCtl,
    _contextSizeCtl,
    _silenceTimeoutCtl,
  ];

  /// Stages every editable value from [agent]. Shared by the initial load, the
  /// agent-switch path and Discard, so the three cannot drift apart.
  void _loadFrom(Agent agent) {
    _nameCtl.text = agent.name;
    _titleCtl.text = agent.title;
    _systemPromptCtl.text = agent.systemPrompt ?? '';
    _personaCtl.text = agent.persona ?? '';
    _selectedSkills = agent.skills.toList().toSet();
    _reportsToId = agent.reportsTo;
    _reportsToController.text = _resolveReportsToName(agent.reportsTo);
    _selectedAdapterId = agent.adapterId;
    _selectedModelId = agent.modelId;
    _strictMode = agent.strictMode;
    _effort = agent.effort;
    _effortUserEdited = false;
    _contextSize = agent.contextSize;
    _contextSizeCtl.text = agent.contextSize?.toString() ?? '';
    _silenceTimeout = agent.silenceTimeoutMinutes;
    _silenceTimeoutCtl.text = agent.silenceTimeoutMinutes?.toString() ?? '';
    _capabilities = agent.capabilities;
    _useCustomCapabilities = agent.capabilities != null;
  }

  void _onFieldChanged() {
    final contextWindow = int.tryParse(_contextSizeCtl.text.trim());
    final silence = int.tryParse(_silenceTimeoutCtl.text.trim());
    setState(() {
      _contextSize = contextWindow;
      _silenceTimeout = (silence != null && silence >= 1 && silence <= 240)
          ? silence
          : null;
    });
  }

  @override
  void didUpdateWidget(covariant AgentSettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agent.id != widget.agent.id) {
      setState(() => _loadFrom(widget.agent));
    }
  }

  @override
  void dispose() {
    for (final c in _textControllers) {
      c
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    _reportsToController.dispose();
    super.dispose();
  }

  /// Whether the staged values differ from the persisted agent.
  ///
  /// Derived rather than flagged: it is what makes Discard meaningful and what
  /// keeps the save bar honest when an edit is undone by hand.
  bool get _dirty {
    final a = widget.agent;
    return _nameCtl.text.trim() != a.name ||
        _titleCtl.text.trim() != a.title ||
        _trimmedOrNull(_systemPromptCtl) != a.systemPrompt ||
        _trimmedOrNull(_personaCtl) != a.persona ||
        !setEquals(_selectedSkills, a.skills.toList().toSet()) ||
        _reportsToId != a.reportsTo ||
        _selectedAdapterId != a.adapterId ||
        _selectedModelId != a.modelId ||
        _strictMode != a.strictMode ||
        _effort != a.effort ||
        _contextSize != a.contextSize ||
        _silenceTimeout != a.silenceTimeoutMinutes ||
        (_useCustomCapabilities ? _capabilities : null) != a.capabilities;
  }

  static String? _trimmedOrNull(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _identityGroup(l10n),
                const SizedBox(height: AppSpacing.xl),
                _runtimeGroup(l10n),
                const SizedBox(height: AppSpacing.xl),
                _skillsGroup(l10n),
                const SizedBox(height: AppSpacing.xl),
                _guardrailsGroup(l10n),
                if (widget.onDelete != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _dangerZone(l10n),
                ],
              ],
            ),
          ),
        ),
        // Pinned below the scroll, and pinned whether or not there is anything
        // to commit: this tab's whole subject is the form, and Save parked at
        // the end of a long column is a scroll you have to take on faith.
        SettingsSaveBar(
          dirty: _dirty,
          busy: _saving,
          persistentSave: true,
          onSave: _save,
          onDiscard: () => setState(() => _loadFrom(widget.agent)),
          saveLabel: l10n.saveChanges,
          secondaryActions: [
            if (_seed case final seed?)
              CcButton(
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                icon: AppIcons.rotateCcw,
                onPressed: _saving ? null : () => _resetToSeed(seed),
                child: Text(l10n.resetToDefault),
              ),
          ],
        ),
      ],
    );
  }

  /// What this agent was seeded with, or null if nobody seeded it.
  BuiltinAgentSeed? get _seed => builtinAgentSeedFor(widget.agent.name);

  /// Stages the seeded identity back onto the form — it does NOT write.
  ///
  /// Reset is destructive of hand-tuning, so it lands in the same place an
  /// edit does: the fields change, the bar says there is unsaved work, and
  /// Discard is still there. A reset that wrote straight through would be a
  /// one-press irreversible action wearing a ghost button.
  ///
  /// Only the values seeding actually chose are restored. The adapter, model,
  /// reasoning effort, context window and capabilities are not part of a seed
  /// — silently re-picking someone's runner because they asked for the default
  /// PROFILE would be answering a question they did not ask.
  void _resetToSeed(BuiltinAgentSeed seed) {
    setState(() {
      _titleCtl.text = seed.title;
      _personaCtl.text = seed.agentMdBody;
      _systemPromptCtl.text = '';
      _selectedSkills = seed.skillSlugs.toSet();
    });
    // Reporting line last: it resolves a NAME against this workspace's roster,
    // and its own staging hop already schedules the rebuild.
    _stageReportsToName(seed.reportsToSlug);
    _reportsToController.text = seed.reportsToSlug == null
        ? ''
        : _resolveReportsToName(_reportsToId);
  }

  // ─── Groups ──────────────────────────────────────────────────────────────

  Widget _identityGroup(AppLocalizations l10n) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agentsAsync = workspaceId != null
        ? ref.watch(workspaceAgentsProvider(workspaceId))
        : ref.watch(agentsProvider);

    return SettingsGroup(
      title: l10n.agentSectionIdentity,
      children: [
        SettingsField(
          label: l10n.nameLabel,
          child: Semantics(
            label: l10n.agentName,
            textField: true,
            child: CcTextField(
              controller: _nameCtl,
              hintText: l10n.egArchitect,
            ),
          ),
        ),
        SettingsField(
          label: l10n.titleLabel,
          child: Semantics(
            label: l10n.agentTitle,
            textField: true,
            child: CcTextField(
              controller: _titleCtl,
              hintText: l10n.egSoftwareArchitect,
            ),
          ),
        ),
        SettingsField(
          label: l10n.reportsTo,
          child: agentsAsync.when(
            loading: () => FieldPlaceholder(
              text: l10n.loadingAgents,
              kind: FieldPlaceholderKind.loading,
            ),
            error: (e, _) => FieldPlaceholder(
              text: l10n.failedWithError('$e'),
              kind: FieldPlaceholderKind.error,
            ),
            data: (agents) {
              final otherAgents = agents
                  .where((a) => a.id != widget.agent.id)
                  .toList();
              return CcAutocomplete<String>(
                controller: _reportsToController,
                hintText: l10n.selectAgentToReportTo,
                options: [
                  for (final a in otherAgents)
                    CcSelectOption(value: a.name, label: a.name),
                ],
                // Commits go through the component's API: a row selection, a
                // committed typed name, or the clear ✕ (unsets). Free text
                // naming no agent is ignored.
                onSelected: _stageReportsToName,
                onCustomValue: _stageReportsToName,
                onCleared: () => _stageReportsToName(null),
              );
            },
          ),
        ),
        // Prose gets the full width: an inline control column turns a six-line
        // prompt into a letterbox.
        SettingsField(
          label: l10n.systemPromptLabel,
          layout: SettingsFieldLayout.stacked,
          optional: true,
          child: Semantics(
            label: l10n.systemPrompt,
            textField: true,
            child: CcTextArea(
              controller: _systemPromptCtl,
              hintText: l10n.customSystemPrompt,
              maxLines: 6,
            ),
          ),
        ),
        SettingsField(
          label: l10n.persona,
          layout: SettingsFieldLayout.stacked,
          optional: true,
          child: CcTextArea(
            controller: _personaCtl,
            hintText: l10n.optionalPersonaDescription,
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _runtimeGroup(AppLocalizations l10n) {
    // Installed runners only — an agent pointed at a runner the server does not
    // have cannot dispatch, and the failure would surface at run time rather
    // than here.
    final available = ref.watch(availableAdaptersProvider);
    final pending = ref.watch(adapterDetectionPendingProvider);
    final adapterOptions = <String, String>{
      for (final a in available) a.name: a.id,
    };
    final levels = _resolveSelectedModel()?.thinkingLevels ?? const [];

    return SettingsGroup(
      title: l10n.agentSectionRuntime,
      showRule: true,
      children: [
        SettingsField(
          label: l10n.adapterLabel,
          child: adapterOptions.isEmpty
              ? FieldPlaceholder(
                  // Empty means two different things and they read differently:
                  // detection still running, or it finished and the server has
                  // no runner installed. A spinner on the second one promises a
                  // result that is never coming — and in a widget test it is a
                  // frame scheduled forever, so `pumpAndSettle` never settles.
                  text: pending
                      ? l10n.detectingAdapters
                      : l10n.noRunnersDetected,
                  kind: pending
                      ? FieldPlaceholderKind.loading
                      : FieldPlaceholderKind.idle,
                )
              : CcSelect<String>(
                  hintText: l10n.selectAdapter,
                  options: [
                    for (final e in adapterOptions.entries)
                      CcSelectOption(value: e.value, label: e.key),
                  ],
                  value: adapterOptions.values.contains(_selectedAdapterId)
                      ? _selectedAdapterId
                      : null,
                  onChanged: (v) => setState(() {
                    _selectedAdapterId = v;
                    _selectedModelId = null;
                  }),
                ),
        ),
        SettingsField(
          label: l10n.modelLabel,
          child: ModelSelect(
            adapterId: _selectedAdapterId,
            selectedModelId: _selectedModelId,
            onChange: _onModelChanged,
          ),
        ),
        if (levels.isNotEmpty)
          SettingsField(
            label: l10n.reasoningEffort,
            child: CcSelect<String>(
              hintText: l10n.selectEffortLevel,
              options: [
                for (final lvl in levels)
                  CcSelectOption(value: lvl.id, label: lvl.label),
              ],
              value: levels.any((l) => l.id == _effort) ? _effort : null,
              onChanged: (v) => setState(() {
                _effortUserEdited = true;
                _effort = v;
              }),
            ),
          ),
        SettingsField(
          label: l10n.contextWindowSize,
          layout: SettingsFieldLayout.stacked,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CcTextField(
                controller: _contextSizeCtl,
                hintText: l10n.egTokenLimit,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs + 2,
                runSpacing: AppSpacing.xs + 2,
                children: [
                  // The selected model's own context window first, so a
                  // customized value is one tap from the model default.
                  if (_resolveSelectedModel()?.contextWindow
                      case final modelContext?)
                    CcChip(
                      label: l10n.modelContextChip(
                        _compactTokens(modelContext),
                      ),
                      selected: _contextSize == modelContext,
                      onPressed: () => _setContextSize(modelContext),
                    ),
                  for (final preset in [200000, 500000, 1000000])
                    CcChip(
                      label: _compactTokens(preset),
                      selected: _contextSize == preset,
                      onPressed: () => _setContextSize(preset),
                    ),
                ],
              ),
            ],
          ),
        ),
        SettingsField(
          label: l10n.silenceTimeoutLabel,
          optional: true,
          controlWidth: 260,
          child: CcTextField(
            controller: _silenceTimeoutCtl,
            hintText: l10n.silenceTimeoutHint,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _skillsGroup(AppLocalizations l10n) {
    // The group heading IS the field label here — a `SettingsField` labelled
    // "Skills" inside a group titled "Skills" would say it twice.
    return SettingsGroup(
      title: l10n.skills,
      showRule: true,
      children: [
        SkillAssignmentSection(
          selectedSkills: _selectedSkills,
          availableSkills: widget.availableSkills,
          onChanged: (skills) => setState(() => _selectedSkills = skills),
        ),
      ],
    );
  }

  Widget _guardrailsGroup(AppLocalizations l10n) {
    return SettingsGroup(
      title: l10n.agentSectionGuardrails,
      showRule: true,
      gap: AppSpacing.sm,
      children: [
        SettingsToggle(
          title: l10n.strictIdentityCheck,
          value: _strictMode,
          onChanged: (v) => setState(() => _strictMode = v),
        ),
        SettingsToggle(
          title: l10n.sandboxPermissions,
          description: _useCustomCapabilities
              ? l10n.customCapabilitiesDescription
              : l10n.useWorkspaceDefault,
          value: _useCustomCapabilities,
          onChanged: (v) => setState(() {
            _useCustomCapabilities = v;
            if (v && _capabilities == null) {
              _capabilities = ref.read(defaultCapabilitiesProvider);
            }
          }),
        ),
        if (_useCustomCapabilities)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              top: AppSpacing.xs,
            ),
            child: CapabilityToggles(
              value: _capabilities ?? AgentCapabilities.safeDefault,
              compact: true,
              onChanged: (next) => setState(() => _capabilities = next),
            ),
          ),
      ],
    );
  }

  /// The last block of the form: the one action here that is not a setting.
  ///
  /// It reads as a group like the others rather than as a red-boxed panel —
  /// the destructive weight is carried by the button and by the sentence that
  /// says what is lost, which is what a reader actually needs before pressing
  /// it. A tinted box around a heading says "be careful" without saying of
  /// what.
  Widget _dangerZone(AppLocalizations l10n) {
    return SettingsGroup(
      title: l10n.dangerZone,
      description: l10n.agentDeleteLongDescription(widget.agent.name),
      showRule: true,
      trailing: CcButton(
        variant: CcButtonVariant.destructive,
        size: CcButtonSize.sm,
        onPressed: widget.onDelete,
        icon: AppIcons.trash2,
        child: Text(l10n.delete),
      ),
      children: const [],
    );
  }

  // ─── Staging helpers ─────────────────────────────────────────────────────

  void _setContextSize(int tokens) {
    // Writing the controller fires `_onFieldChanged`, which is what actually
    // commits `_contextSize` — set it there, not twice.
    _contextSizeCtl.text = tokens.toString();
  }

  /// Formats a token count compactly for the preset chips (200000 → "200k",
  /// 1000000 → "1M").
  static String _compactTokens(int tokens) {
    if (tokens >= 1000000) {
      final m = tokens / 1000000;
      return '${m == m.roundToDouble() ? m.toInt() : m.toStringAsFixed(1)}M';
    }
    if (tokens >= 1000) {
      return '${(tokens / 1000).round()}k';
    }
    return '$tokens';
  }

  /// Stages a reports-to change from the autocomplete's commit callbacks:
  /// [name] is a selected agent's name, a committed free text, or null when
  /// the field was cleared. Free text that names no agent changes nothing.
  void _stageReportsToName(String? name) {
    final String? newId;
    if (name == null || name.isEmpty) {
      newId = null;
    } else {
      final workspaceId = ref.read(activeWorkspaceIdProvider);
      final List<Agent> agents = workspaceId != null
          ? ref.read(workspaceAgentsProvider(workspaceId)).value ?? const []
          : ref.read(agentsProvider).value ?? const [];
      if (agents.isEmpty) {
        return;
      }
      final Agent? match = agents
          .where((a) => a.name == name && a.id != widget.agent.id)
          .firstOrNull;
      if (match == null) {
        return;
      }
      newId = match.id;
    }
    if (newId != _reportsToId) {
      _reportsToId = newId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  /// Resolves the currently-selected [AcpModel] (from the selected adapter's
  /// catalog), or null when adapter/model is unset or not in the list.
  AcpModel? _resolveSelectedModel() {
    final adapterId = _selectedAdapterId;
    final modelId = _selectedModelId;
    if (adapterId == null || modelId == null) {
      return null;
    }
    final models =
        ref.read(adapterModelsProvider(adapterId)).value ?? const <AcpModel>[];
    return models.where((m) => m.id == modelId).firstOrNull;
  }

  /// Applies model-driven inference when the selected model changes: default
  /// the effort level to the model's default (unless the user chose one) and
  /// refresh the context window to the model's size. The context field stays
  /// freely editable — a value typed *after* picking the model wins until the
  /// next model change re-fills it.
  void _onModelChanged(String? modelId) {
    setState(() => _selectedModelId = modelId);
    final model = _resolveSelectedModel();
    if (model == null) {
      return;
    }
    if (!_effortUserEdited &&
        model.defaultThinkingLevel != null &&
        _effort != model.defaultThinkingLevel) {
      _effort = model.defaultThinkingLevel;
    }
    final contextWindow = model.contextWindow;
    if (contextWindow != null && contextWindow != _contextSize) {
      _contextSizeCtl.text = contextWindow.toString();
    }
  }

  String _resolveReportsToName(String? agentId) {
    if (agentId == null) {
      return '';
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    final List<Agent> agents = workspaceId != null
        ? ref.read(workspaceAgentsProvider(workspaceId)).value ?? const []
        : ref.read(agentsProvider).value ?? const [];
    if (agents.isEmpty) {
      return '';
    }
    return agents.where((a) => a.id == agentId).firstOrNull?.name ?? '';
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameCtl.text.trim();
    final title = _titleCtl.text.trim();
    if (name.isEmpty || title.isEmpty) {
      CcToastScope.of(
        context,
      ).show(l10n.nameAndTitleRequired, variant: CcToastVariant.neutral);
      return;
    }
    setState(() => _saving = true);
    try {
      final nameChanged = name != widget.agent.name;
      // Source the workspace from the canonical active-workspace provider (the
      // same value build() already reads) rather than GoRouterState — the
      // provider is the app's single source of truth and does not require a
      // GoRouter ancestor to resolve.
      final workspaceId = ref.read(activeWorkspaceIdProvider);
      final oldSlug = slugify(widget.agent.name);
      final newSlug = slugify(name);
      var updated = widget.agent.copyWith(
        name: name,
        title: title,
        systemPrompt: _trimmedOrNull(_systemPromptCtl),
        adapterId: _selectedAdapterId,
        modelId: _selectedModelId,
        skills: AgentSkills(_selectedSkills.toList()),
        reportsTo: _reportsToId,
        persona: _trimmedOrNull(_personaCtl),
        strictMode: _strictMode,
        effort: _effort,
        contextSize: _contextSize,
        silenceTimeoutMinutes: _silenceTimeout,
        removeSilenceTimeoutMinutes: _silenceTimeout == null,
        capabilities: _useCustomCapabilities ? _capabilities : null,
        removeCapabilities: !_useCustomCapabilities,
      );
      if (workspaceId != null) {
        final fs = ref.read(workspaceFilesystemPortProvider);
        final newPath = await fs.agentFilePath(workspaceId, newSlug);
        await fs.writeAgentFile(workspaceId, newSlug, _buildAgentMd(updated));
        if (nameChanged && oldSlug != newSlug) {
          await fs.deleteAgentDir(workspaceId, oldSlug);
        }
        updated = updated.copyWith(agentMdPath: newPath);
        await fs.syncAgentSkillLinks(
          workspaceId,
          newSlug,
          updated.skills.toList(),
        );
      }
      final repo = ref.read(agentRepositoryProvider);
      await repo.upsert(updated);
      if (!mounted) {
        return;
      }

      CcToastScope.of(
        context,
      ).show(l10n.agentUpdated, variant: CcToastVariant.success);
    } catch (e) {
      if (!mounted) {
        return;
      }

      CcToastScope.of(
        context,
      ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _buildAgentMd(Agent agent) {
    final buf = StringBuffer();
    buf.writeln('---');
    buf.writeln('name: ${agent.name}');
    buf.writeln('title: ${agent.title}');
    if (agent.reportsTo != null && agent.reportsTo!.isNotEmpty) {
      buf.writeln('reportsTo: ${agent.reportsTo}');
    }
    if (agent.skills.isNotEmpty) {
      buf.writeln('skills:');
      for (final skill in agent.skills.toList()) {
        buf.writeln('  - $skill');
      }
    }
    buf.writeln('---');
    buf.writeln();
    if (agent.persona != null && agent.persona!.isNotEmpty) {
      buf.writeln(agent.persona);
    } else {
      buf.writeln('# ${agent.title}');
      buf.writeln();
      buf.writeln('Agent profile for **${agent.name}**.');
    }
    return buf.toString();
  }
}
