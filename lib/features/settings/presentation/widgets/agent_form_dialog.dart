import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/sandboxing/presentation/capability_toggles.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/model_select.dart';
import 'package:control_center/features/settings/presentation/widgets/skill_assignment_section.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

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
  late final FAutocompleteController _reportsToController;
  String? _reportsToId;
  late final TextEditingController _personaCtl;
  String? _selectedAdapterId;
  String? _selectedModelId;
  bool _strictMode = false;
  AgentEffort? _effort;
  int? _contextSize;
  AgentCapabilities? _capabilities;
  bool _useCustomCapabilities = false;
  late final TextEditingController _contextSizeCtl;
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
    _reportsToController = FAutocompleteController(text: '');
    _reportsToId = widget.agent.reportsTo;
    _reportsToController.addListener(_onReportsToChanged);
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
    _capabilities = widget.agent.capabilities;
    _useCustomCapabilities = widget.agent.capabilities != null;
    _contextSizeCtl = TextEditingController(
      text: _contextSize?.toString() ?? '',
    );
    _contextSizeCtl.addListener(_onContextSizeChanged);
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
    _reportsToController.removeListener(_onReportsToChanged);
    _reportsToController.dispose();
    _personaCtl.dispose();
    _contextSizeCtl.removeListener(_onContextSizeChanged);
    _contextSizeCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
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
              child: FTextField(
                control: FTextFieldControl.managed(controller: _nameCtl),
                hint: l10n.egArchitect,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _field(
            l10n.titleLabel,
            Semantics(
              label: l10n.agentTitle,
              textField: true,
              child: FTextField(
                control: FTextFieldControl.managed(controller: _titleCtl),
                hint: l10n.egSoftwareArchitect,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _field(
            l10n.systemPromptLabel,
            Semantics(
              label: l10n.systemPrompt,
              textField: true,
              child: FTextField(
                control: FTextFieldControl.managed(controller: _systemPromptCtl),
                hint: l10n.customSystemPrompt,
                maxLines: 6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _field(
            l10n.adapterLabel,
            adapterOptions.isEmpty
                ? FieldPlaceholder(text: l10n.detectingAdapters, colors: colors)
                : FSelect<String>(
                    items: adapterOptions,
                    hint: l10n.selectAdapter,
                    control: FSelectControl<String>.managed(
                      initial: _selectedAdapterId != null
                          ? adapterOptions.entries
                                .where((e) => e.value == _selectedAdapterId)
                                .firstOrNull
                                ?.value
                          : null,
                      onChange: (v) => setState(() {
                        _selectedAdapterId = v;
                        _selectedModelId = null;
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          _field(
            l10n.modelLabel,
            ModelSelect(
              adapterId: _selectedAdapterId,
              selectedModelId: _selectedModelId,
              onChange: (v) => setState(() => _selectedModelId = v),
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
                    loading: () => FieldPlaceholder(
                      text: l10n.loadingAgents,
                      colors: colors,
                    ),
                    error: (e, _) => FieldPlaceholder(
                      text: l10n.failedWithError('$e'),
                      colors: colors,
                    ),
                    data: (agents) {
                      final otherAgents = agents
                          .where((a) => a.id != widget.agent.id)
                          .toList();
                      final agentNames =
                          otherAgents.map((a) => a.name).toList();
                      return FAutocomplete.text(
                        items: agentNames,
                        hint: l10n.selectAgentToReportTo,
                        control: FAutocompleteControl.managed(
                          controller: _reportsToController,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _field(
                  l10n.persona,
                  FTextField(
                    control: FTextFieldControl.managed(controller: _personaCtl),
                    hint: l10n.optionalPersonaDescription,
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
                  style: TextStyle(fontSize: 13, color: colors.foreground),
                ),
              ),
              FSwitch(
                value: _strictMode,
                onChange: (v) => setState(() => _strictMode = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _field(
            l10n.reasoningEffort,
            FSelect<AgentEffort>(
              items: {
                l10n.low: AgentEffort.low,
                l10n.medium: AgentEffort.medium,
                l10n.high: AgentEffort.high,
              },
              hint: l10n.selectEffortLevel,
              control: FSelectControl<AgentEffort>.managed(
                initial: _effort,
                onChange: (v) => setState(() => _effort = v),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _field(
            l10n.contextWindowSize,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FTextField(
                  control: FTextFieldControl.managed(
                    controller: _contextSizeCtl,
                  ),
                  hint: l10n.egTokenLimit,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final preset in [200000, 500000, 1000000])
                      InputChip(
                        label: Text(
                          '${preset ~/ 1000}k',
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                        selected: _contextSize == preset,
                        onSelected: (_) {
                          _contextSizeCtl.text = preset.toString();
                          setState(() => _contextSize = preset);
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
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
                        style: TextStyle(fontSize: 12, color: colors.mutedForeground),
                      ),
                    ),
                    FSwitch(
                      value: _useCustomCapabilities,
                      onChange: (v) {
                        setState(() {
                          _useCustomCapabilities = v;
                          if (v && _capabilities == null) {
                            _capabilities =
                                ref.read(defaultCapabilitiesProvider);
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
                    onChanged: (next) =>
                        setState(() => _capabilities = next),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          FButton(
            onPress: _saving ? null : _save,
            mainAxisSize: MainAxisSize.min,
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

  Widget _field(String label, Widget child) {
    final colors = context.theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  void _onReportsToChanged() {
    final text = _reportsToController.text;
    final String? newId;
    if (text.isEmpty) {
      newId = null;
    } else {
      final workspaceId = ref.read(activeWorkspaceIdProvider);
      final List<Agent> agents = workspaceId != null
          ? ref.read(workspaceAgentsProvider(workspaceId)).value ?? const []
          : ref.read(agentsProvider).value ?? const [];
      if (agents.isEmpty) {
        return;
      }
      final Agent? match = agents.where(
        (a) => a.name == text && a.id != widget.agent.id,
      ).firstOrNull;
      newId = match?.id;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nameAndTitleRequired)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final nameChanged = name != widget.agent.name;
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.agentUpdated)));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.failedWithError('$e'))));
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
