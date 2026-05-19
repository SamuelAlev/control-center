import 'dart:convert';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_trigger.dart';
import 'package:control_center/features/pipelines/presentation/widgets/condition_config_editor.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Right-hand side panel for editing the selected node.
class NodeConfigEditor extends StatefulWidget {
  /// Creates a [NodeConfigEditor].
  const NodeConfigEditor({
    super.key,
    required this.step,
    required this.allSteps,
    required this.workspaceAgents,
    required this.onChange,
    required this.onDelete,
  });

  /// The currently selected step.
  final PipelineStepDefinition step;

  /// All steps in the template (used to populate the upstream picker).
  final List<PipelineStepDefinition> allSteps;

  /// Agents in the active workspace (for the agent autocomplete).
  final List<Agent> workspaceAgents;

  /// Called whenever the user edits a field.
  final void Function(PipelineStepDefinition updated) onChange;

  /// Called when the user clicks the delete button.
  final VoidCallback onDelete;

  @override
  State<NodeConfigEditor> createState() => _NodeConfigEditorState();
}

class _NodeConfigEditorState extends State<NodeConfigEditor> {
  late TextEditingController _labelCtrl;
  late TextEditingController _promptCtrl;
  late TextEditingController _scriptCtrl;
  late TextEditingController _inputsCtrl;
  late TextEditingController _outputCtrl;
  late TextEditingController _timeoutCtrl;
  late TextEditingController _retryCtrl;
  late TextEditingController _teamIdCtrl;
  late TextEditingController _schemaCtrl;
  String? _reducer;
  String? _dispatchMode;
  bool _continueOnFail = false;

  /// Body-specific config (e.g. the condition predicate / switch). Edited
  /// in-place by [ConditionConfigEditor] for router nodes.
  late Map<String, dynamic> _extras;

  /// Inbound edges as `sourceStepId -> routeKey?`. One [StepTrigger] is emitted
  /// per entry; a non-null route key makes that edge conditional on an upstream
  /// router choosing it.
  late Map<String, String?> _edges;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant NodeConfigEditor old) {
    super.didUpdateWidget(old);
    if (old.step.id != widget.step.id) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _initControllers() {
    final c = widget.step.config;
    _labelCtrl = TextEditingController(text: c.label ?? widget.step.id);
    _promptCtrl = TextEditingController(text: c.prompt ?? '');
    _scriptCtrl = TextEditingController(text: c.script ?? '');
    _inputsCtrl = TextEditingController(text: c.inputKeys.join(', '));
    _outputCtrl = TextEditingController(text: c.outputKey ?? '');
    _timeoutCtrl = TextEditingController(
        text: c.timeoutMs == null ? '' : '${c.timeoutMs}');
    _retryCtrl = TextEditingController(
        text: c.retryPolicy == null ? '' : '${c.retryPolicy!.maxAttempts}');
    _teamIdCtrl = TextEditingController(text: c.teamId ?? '');
    _schemaCtrl = TextEditingController(
        text: c.outputSchema == null ? '' : jsonEncode(c.outputSchema));
    _reducer = c.reducer;
    _dispatchMode = c.dispatchMode;
    _continueOnFail = c.continueOnFail;
    _extras = Map<String, dynamic>.from(c.extras);
    _edges = _edgesFromTriggers(widget.step.triggers);
    for (final ctrl in [
      _labelCtrl,
      _promptCtrl,
      _scriptCtrl,
      _inputsCtrl,
      _outputCtrl,
      _timeoutCtrl,
      _retryCtrl,
      _teamIdCtrl,
      _schemaCtrl,
    ]) {
      ctrl.addListener(_emit);
    }
  }

  void _disposeControllers() {
    for (final ctrl in [
      _labelCtrl,
      _promptCtrl,
      _scriptCtrl,
      _inputsCtrl,
      _outputCtrl,
      _timeoutCtrl,
      _retryCtrl,
      _teamIdCtrl,
      _schemaCtrl,
    ]) {
      ctrl.removeListener(_emit);
      ctrl.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _emit({String? agentId}) {
    final cleanInputs = _inputsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    final timeoutMs = int.tryParse(_timeoutCtrl.text.trim());
    final maxAttempts = int.tryParse(_retryCtrl.text.trim());
    // Parse the output-schema JSON leniently; keep the prior value if invalid
    // so a half-typed schema doesn't wipe the field.
    Map<String, dynamic>? outputSchema = widget.step.config.outputSchema;
    final schemaText = _schemaCtrl.text.trim();
    if (schemaText.isEmpty) {
      outputSchema = null;
    } else {
      try {
        final decoded = jsonDecode(schemaText);
        if (decoded is Map<String, dynamic>) {
          outputSchema = decoded;
        }
      } on FormatException {
        // keep previous value
      }
    }
    widget.onChange(PipelineStepDefinition(
      id: widget.step.id,
      kind: widget.step.kind,
      bodyKey: widget.step.bodyKey,
      triggers: _buildTriggers(),
      waitForStepIds: widget.step.kind == StepKind.join
          ? _edges.keys.toList(growable: false)
          : const [],
      x: widget.step.x,
      y: widget.step.y,
      config: PipelineNodeConfig(
        label: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
        prompt: _promptCtrl.text.isEmpty ? null : _promptCtrl.text,
        script: _scriptCtrl.text.isEmpty ? null : _scriptCtrl.text,
        agentId: agentId ?? widget.step.config.agentId,
        inputKeys: cleanInputs,
        outputKey:
            _outputCtrl.text.trim().isEmpty ? null : _outputCtrl.text.trim(),
        outputSchema: outputSchema,
        reducer: _reducer,
        retryPolicy:
            maxAttempts == null ? null : StepRetryPolicy(maxAttempts: maxAttempts),
        continueOnFail: _continueOnFail,
        timeoutMs: timeoutMs,
        teamId: _teamIdCtrl.text.trim().isEmpty ? null : _teamIdCtrl.text.trim(),
        dispatchMode: _dispatchMode,
        extras: _extras,
      ),
    ));
  }

  void _updateKind(StepKind kind) {
    widget.onChange(PipelineStepDefinition(
      id: widget.step.id,
      kind: kind,
      bodyKey: widget.step.bodyKey,
      triggers: _buildTriggers(),
      waitForStepIds:
          kind == StepKind.join ? _edges.keys.toList(growable: false) : const [],
      x: widget.step.x,
      y: widget.step.y,
      config: widget.step.config,
    ));
  }

  /// Flattens the step's triggers into the editable `sourceId -> routeKey` map.
  Map<String, String?> _edgesFromTriggers(List<StepTrigger> triggers) {
    final edges = <String, String?>{};
    for (final t in triggers) {
      for (final src in t.sourceStepIds) {
        edges[src] = t.routeKey;
      }
    }
    return edges;
  }

  /// Emits one [StepTrigger] per edge, carrying its (optional) route key.
  List<StepTrigger> _buildTriggers() {
    return [
      for (final e in _edges.entries)
        StepTrigger(
          sourceStepIds: [e.key],
          routeKey: (e.value == null || e.value!.isEmpty) ? null : e.value,
        ),
    ];
  }

  void _toggleSource(String sourceId) {
    setState(() {
      if (_edges.containsKey(sourceId)) {
        _edges.remove(sourceId);
      } else {
        _edges[sourceId] = null;
      }
    });
    _emit();
  }

  void _setRouteKey(String sourceId, String value) {
    _edges[sourceId] = value.trim().isEmpty ? null : value.trim();
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final upstreamCandidates = widget.allSteps
        .where((s) => s.id != widget.step.id && s.kind != StepKind.terminal)
        .toList();
    final byId = {for (final s in widget.allSteps) s.id: s};

    final agentItems = <String, String>{
      for (final a in widget.workspaceAgents) '${a.name} · ${a.title}': a.id,
    };
    final bodyKey = widget.step.bodyKey;
    final isBashScript = bodyKey == 'pipeline.bashScript';
    final usesAgent = bodyKey == 'pipeline.promptAgent';
    final usesPrompt = usesAgent;
    final isCondition = bodyKey == 'pipeline.condition';

    return Container(
      color: colors.background,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.nodeConfigTitle} · ${widget.step.id}',
                  style: TextStyle(
                    color: colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FButton.icon(
                onPress: widget.onDelete,
                variant: FButtonVariant.ghost,
                child: Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: colors.destructive,
                ),
              ),
            ],
          ),
          if (widget.step.kind == StepKind.listen ||
              widget.step.kind == StepKind.join) ...[
            const SizedBox(height: 12),
            FSelect<StepKind>(
              items: const {
                'listen': StepKind.listen,
                'join': StepKind.join,
              },
              label: Text(l10n.nodeConfigKind),
              control: FSelectControl<StepKind>.lifted(
                value: widget.step.kind,
                onChange: (k) {
                  if (k != null) {
                    _updateKind(k);
                  }
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _labelCtrl),
            label: Text(l10n.nodeConfigLabel),
            size: FTextFieldSizeVariant.sm,
          ),
          if (usesAgent) ...[
            const SizedBox(height: 12),
            FSelect<String>.search(
              items: agentItems,
              filter: (query) {
                if (query.isEmpty) {
                  return agentItems.values;
                }
                final q = query.toLowerCase();
                return widget.workspaceAgents
                    .where((a) =>
                        a.name.toLowerCase().contains(q) ||
                        a.title.toLowerCase().contains(q))
                    .map((a) => a.id);
              },
              label: Text(l10n.nodeConfigAgent),
              hint: l10n.nodeConfigAgentHint,
              control: FSelectControl<String>.lifted(
                value: widget.step.config.agentId,
                onChange: (id) => _emit(agentId: id ?? ''),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _inputsCtrl),
            label: Text(l10n.nodeConfigInputKeys),
            hint: 'repoLocalPath, prTitle, prNumber',
            description: Text(l10n.nodeConfigInputKeysHelp),
            size: FTextFieldSizeVariant.sm,
          ),
          const SizedBox(height: 12),
          if (isCondition)
            ConditionConfigEditor(
              extras: _extras,
              onChanged: (extras) {
                _extras = extras;
                _emit();
              },
            )
          else
            FTextField(
              control: FTextFieldControl.managed(controller: _outputCtrl),
              label: Text(l10n.nodeConfigOutputKey),
              hint: 'qa_findings',
              size: FTextFieldSizeVariant.sm,
            ),
          if (usesPrompt) ...[
            const SizedBox(height: 12),
            FTextField.multiline(
              control: FTextFieldControl.managed(controller: _promptCtrl),
              label: Text(l10n.nodeConfigPrompt),
              description: Text(l10n.nodeConfigPromptHelp),
              minLines: 4,
              maxLines: 14,
            ),
          ],
          if (isBashScript) ...[
            const SizedBox(height: 12),
            FTextField.multiline(
              control: FTextFieldControl.managed(controller: _scriptCtrl),
              label: Text(l10n.nodeConfigScript),
              description: Text(l10n.nodeConfigScriptHelp),
              minLines: 4,
              maxLines: 18,
            ),
          ],
          const SizedBox(height: 20),
          Text(
            l10n.nodeConfigAdvanced,
            style: TextStyle(
              color: colors.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FSelect<String>(
            items: const {
              'override': 'override',
              'append': 'append',
              'mergeLists': 'mergeLists',
              'mergeMaps': 'mergeMaps',
              'sum': 'sum',
            },
            label: Text(l10n.nodeConfigReducer),
            description: Text(l10n.nodeConfigReducerHelp),
            control: FSelectControl<String>.lifted(
              value: _reducer,
              onChange: (v) {
                setState(() => _reducer = v);
                _emit();
              },
            ),
          ),
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _timeoutCtrl),
            label: Text(l10n.nodeConfigTimeoutMs),
            hint: '900000',
            keyboardType: TextInputType.number,
            size: FTextFieldSizeVariant.sm,
          ),
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _retryCtrl),
            label: Text(l10n.nodeConfigRetryAttempts),
            hint: '3',
            keyboardType: TextInputType.number,
            size: FTextFieldSizeVariant.sm,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FCheckbox(
                value: _continueOnFail,
                onChange: (v) {
                  setState(() => _continueOnFail = v);
                  _emit();
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.nodeConfigContinueOnFail,
                  style: TextStyle(color: colors.foreground, fontSize: 13),
                ),
              ),
            ],
          ),
          if (widget.step.bodyKey == 'team.dispatch') ...[
            const SizedBox(height: 12),
            FTextField(
              control: FTextFieldControl.managed(controller: _teamIdCtrl),
              label: Text(l10n.nodeConfigTeamId),
              size: FTextFieldSizeVariant.sm,
            ),
            const SizedBox(height: 12),
            FSelect<String>(
              items: const {
                'allParallel': 'allParallel',
                'manager': 'manager',
              },
              label: Text(l10n.nodeConfigDispatchMode),
              control: FSelectControl<String>.lifted(
                value: _dispatchMode,
                onChange: (v) {
                  setState(() => _dispatchMode = v);
                  _emit();
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          FTextField.multiline(
            control: FTextFieldControl.managed(controller: _schemaCtrl),
            label: Text(l10n.nodeConfigOutputSchema),
            description: Text(l10n.nodeConfigOutputSchemaHelp),
            minLines: 2,
            maxLines: 8,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.nodeConfigTriggers,
            style: TextStyle(
              color: colors.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (upstreamCandidates.isEmpty)
            Text(
              l10n.nodeConfigNoUpstream,
              style: TextStyle(
                color: colors.mutedForeground,
                fontSize: 12,
              ),
            )
          else ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final candidate in upstreamCandidates)
                  _TriggerChip(
                    label: candidate.config.label ?? candidate.id,
                    selected: _edges.containsKey(candidate.id),
                    onTap: () => _toggleSource(candidate.id),
                  ),
              ],
            ),
            ..._routeKeyEditors(l10n, colors, byId),
          ],
        ],
      ),
    );
  }

  /// For each selected edge whose source is a router, a field to set the route
  /// key the edge listens for (e.g. `true` from an "if file exists" node). The
  /// edge only fires when the upstream router selects this exact key.
  List<Widget> _routeKeyEditors(
    AppLocalizations l10n,
    FColors colors,
    Map<String, PipelineStepDefinition> byId,
  ) {
    final routerEdges = _edges.keys
        .where((src) => byId[src]?.kind == StepKind.router)
        .toList();
    if (routerEdges.isEmpty) {
      return const [];
    }
    return [
      const SizedBox(height: 12),
      Text(
        l10n.nodeConfigRouteKeys,
        style: TextStyle(
          color: colors.mutedForeground,
          fontSize: 11,
        ),
      ),
      for (final src in routerEdges)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextFormField(
            key: ValueKey('routeKey_${widget.step.id}_$src'),
            initialValue: _edges[src] ?? '',
            onChanged: (v) => _setRouteKey(src, v),
            style: TextStyle(color: colors.foreground, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.nodeConfigRouteKeyFrom(byId[src]?.config.label ?? src),
              hintText: 'true',
              border: const OutlineInputBorder(),
            ),
          ),
        ),
    ];
  }
}

class _TriggerChip extends StatelessWidget {
  const _TriggerChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.primaryForeground : colors.foreground,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
