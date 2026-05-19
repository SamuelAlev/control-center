import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/utils/string_utils.dart';
import 'package:cc_domain/features/settings/domain/entities/acp_model.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/sandboxing/presentation/capability_toggles.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/model_select.dart';
import 'package:control_center/features/settings/presentation/widgets/skill_assignment_section.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Agent settings form.
class AgentSettingsForm extends ConsumerStatefulWidget {
  /// Creates a new [AgentSettingsForm].
  const AgentSettingsForm({
    super.key,
    required this.agent,
    required this.availableSkills,
  });

  /// The agent being edited.
  final Agent agent;

  /// All skill slugs available in the current workspace.
  final List<String> availableSkills;

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
    _nameCtl = TextEditingController(text: widget.agent.name);
    _titleCtl = TextEditingController(text: widget.agent.title);
    _systemPromptCtl = TextEditingController(
      text: widget.agent.systemPrompt ?? '',
    );
    _selectedSkills = widget.agent.skills.toList().toSet();
    _reportsToController = TextEditingController(text: '');
    _reportsToId = widget.agent.reportsTo;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _reportsToController.text = _resolveReportsToName(_reportsToId);
      }
    });
    _personaCtl = TextEditingController(text: widget.agent.persona ?? '');
    _selectedAdapterId = widget.agent.adapterId;
    _selectedModelId = widget.agent.modelId;
    _strictMode = widget.agent.strictMode;
    _effort = widget.agent.effort;
    _contextSize = widget.agent.contextSize;
    _silenceTimeout = widget.agent.silenceTimeoutMinutes;
    _capabilities = widget.agent.capabilities;
    _useCustomCapabilities = widget.agent.capabilities != null;
    _contextSizeCtl = TextEditingController(
      text: _contextSize?.toString() ?? '',
    );
    _contextSizeCtl.addListener(_onContextSizeChanged);
    _silenceTimeoutCtl = TextEditingController(
      text: _silenceTimeout?.toString() ?? '',
    );
    _silenceTimeoutCtl.addListener(() {
      final v = int.tryParse(_silenceTimeoutCtl.text.trim());
      _silenceTimeout = (v != null && v >= 1 && v <= 240) ? v : null;
    });
  }

  @override
  void didUpdateWidget(covariant AgentSettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agent.id != widget.agent.id) {
      _nameCtl.text = widget.agent.name;
      _titleCtl.text = widget.agent.title;
      _systemPromptCtl.text = widget.agent.systemPrompt ?? '';
      _selectedSkills = widget.agent.skills.toList().toSet();
      _reportsToId = widget.agent.reportsTo;
      _reportsToController.text = _resolveReportsToName(widget.agent.reportsTo);
      _personaCtl.text = widget.agent.persona ?? '';
      _selectedAdapterId = widget.agent.adapterId;
      _selectedModelId = widget.agent.modelId;
      _strictMode = widget.agent.strictMode;
      _effort = widget.agent.effort;
      _contextSize = widget.agent.contextSize;
      _capabilities = widget.agent.capabilities;
      _useCustomCapabilities = widget.agent.capabilities != null;
      _contextSizeCtl.text = _contextSize?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _titleCtl.dispose();
    _systemPromptCtl.dispose();
    _reportsToController.dispose();
    _personaCtl.dispose();
    _contextSizeCtl.removeListener(_onContextSizeChanged);
    _contextSizeCtl.dispose();
    _silenceTimeoutCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final detected = ref.watch(detectedAdaptersProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agentsAsync = workspaceId != null
        ? ref.watch(workspaceAgentsProvider(workspaceId))
        : ref.watch(agentsProvider);
    final adapterOptions = <String, String>{
      for (final a in detected) a.adapter.name: a.adapter.id,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(
            l10n.nameLabel,
            Semantics(
              label: l10n.agentName,
              textField: true,
              child: CcTextField(
                controller: _nameCtl,
                hintText: l10n.egArchitect,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _field(
            l10n.titleLabel,
            Semantics(
              label: l10n.agentTitle,
              textField: true,
              child: CcTextField(
                controller: _titleCtl,
                hintText: l10n.egSoftwareArchitect,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _field(
            l10n.systemPromptLabel,
            Semantics(
              label: l10n.systemPrompt,
              textField: true,
              child: CcTextArea(
                controller: _systemPromptCtl,
                hintText: l10n.customSystemPrompt,
                maxLines: 6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _field(
            l10n.adapterLabel,
            adapterOptions.isEmpty
                ? FieldPlaceholder(text: l10n.detectingAdapters)
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
          const SizedBox(height: 16),
          _field(
            l10n.modelLabel,
            ModelSelect(
              adapterId: _selectedAdapterId,
              selectedModelId: _selectedModelId,
              onChange: _onModelChanged,
            ),
          ),
          const SizedBox(height: 16),
          _field(
            l10n.skills,
            SkillAssignmentSection(
              selectedSkills: _selectedSkills,
              availableSkills: widget.availableSkills,
              onChanged: (skills) => setState(() => _selectedSkills = skills),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  l10n.reportsTo,
                  agentsAsync.when(
                    loading: () => FieldPlaceholder(text: l10n.loadingAgents),
                    error: (e, _) =>
                        FieldPlaceholder(text: l10n.failedWithError('$e')),
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
                        // Commits go through the component's API: a row
                        // selection, a committed typed name, or the clear ✕
                        // (unsets). Free text naming no agent is ignored.
                        onSelected: _stageReportsToName,
                        onCustomValue: _stageReportsToName,
                        onCleared: () => _stageReportsToName(null),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  l10n.persona,
                  CcTextArea(
                    controller: _personaCtl,
                    hintText: l10n.optionalPersonaDescription,
                    maxLines: 3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.strictIdentityCheck,
                  style: TextStyle(fontSize: 13, color: tokens.textPrimary),
                ),
              ),
              CcSwitch(
                value: _strictMode,
                onChanged: (v) => setState(() => _strictMode = v),
              ),
            ],
          ),
          if (_resolveSelectedModel()?.thinkingLevels case final levels?
              when levels.isNotEmpty) ...[
            const SizedBox(height: 16),
            _field(
              l10n.reasoningEffort,
              CcSelect<String>(
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
          ],
          const SizedBox(height: 16),
          _field(
            l10n.contextWindowSize,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CcTextField(
                  controller: _contextSizeCtl,
                  hintText: l10n.egTokenLimit,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
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
                        onTap: () {
                          _contextSizeCtl.text = modelContext.toString();
                          setState(() => _contextSize = modelContext);
                        },
                      ),
                    for (final preset in [200000, 500000, 1000000])
                      CcChip(
                        label: _compactTokens(preset),
                        selected: _contextSize == preset,
                        onTap: () {
                          _contextSizeCtl.text = preset.toString();
                          setState(() => _contextSize = preset);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _field(
            l10n.silenceTimeoutLabel,
            CcTextField(
              controller: _silenceTimeoutCtl,
              hintText: l10n.silenceTimeoutHint,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 24),
          _field(
            l10n.sandboxPermissions,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _useCustomCapabilities
                            ? l10n.customCapabilitiesDescription
                            : l10n.useWorkspaceDefault,
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.textTertiary,
                        ),
                      ),
                    ),
                    CcSwitch(
                      value: _useCustomCapabilities,
                      onChanged: (v) {
                        setState(() {
                          _useCustomCapabilities = v;
                          if (v && _capabilities == null) {
                            _capabilities = ref.read(
                              defaultCapabilitiesProvider,
                            );
                          }
                        });
                      },
                    ),
                  ],
                ),
                if (_useCustomCapabilities) ...[
                  const SizedBox(height: 12),
                  CapabilityToggles(
                    value: _capabilities ?? AgentCapabilities.safeDefault,
                    compact: true,
                    onChanged: (next) => setState(() => _capabilities = next),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          CcButton(
            onPressed: _saving ? null : _save,
            child: Semantics(
              label: _saving ? l10n.savingChanges : l10n.saveChanges,
              button: true,
              child: Text(_saving ? l10n.savingEllipsis : l10n.saveChanges),
            ),
          ),
        ],
      ),
    );
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

  Widget _field(String label, Widget child) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: tokens.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
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

  void _onContextSizeChanged() {
    final parsed = int.tryParse(_contextSizeCtl.text);
    if (parsed != _contextSize) {
      setState(() => _contextSize = parsed);
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
      _contextSize = contextWindow;
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
        systemPrompt: _systemPromptCtl.text.trim().isEmpty
            ? null
            : _systemPromptCtl.text.trim(),
        adapterId: _selectedAdapterId,
        modelId: _selectedModelId,
        skills: AgentSkills(_selectedSkills.toList()),
        reportsTo: _reportsToId,
        persona: _personaCtl.text.trim().isEmpty
            ? null
            : _personaCtl.text.trim(),
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
