import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart'
    show BuiltInBodyKeys;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/condition_config_editor.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_field_label.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_repo_scope_field.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';

/// Right-hand side panel for editing the selected node.
class NodeConfigEditor extends StatefulWidget {
  /// Creates a [NodeConfigEditor].
  const NodeConfigEditor({
    super.key,
    required this.step,
    required this.allSteps,
    required this.workspaceAgents,
    required this.workspaceRepos,
    required this.onChange,
    required this.onDelete,
  });

  /// The currently selected step.
  final PipelineStepDefinition step;

  /// All steps in the template (used to populate the upstream picker).
  final List<PipelineStepDefinition> allSteps;

  /// Agents in the active workspace (for the agent autocomplete).
  final List<Agent> workspaceAgents;

  /// Repos in the active workspace, for the checkout-scope selector shown on
  /// the node that OPENS a conversation.
  final List<Repo> workspaceRepos;

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

  /// The name of the conversation this node works in: the stream a space node
  /// opens, or the one an agent node writes its turn into. Kept out of [_extras]
  /// until [_emit] so a half-typed title does not round-trip through the config
  /// on every keystroke.
  late TextEditingController _conversationTitleCtrl;

  /// The room's own name (`extras['spaceName']`), on the node that opens one.
  /// Empty falls back to the node's label — which is what every seeded template
  /// relies on, so the field is left blank rather than pre-filled with it.
  late TextEditingController _spaceNameCtrl;
  String? _reducer;
  String? _dispatchMode;
  bool _continueOnFail = false;

  /// Whether the space node also opens a conversation in the room
  /// (`extras['createConversation']`). Off means the room opens empty and each
  /// agent node downstream opens its own named stream.
  bool _createsConversation = false;

  /// Body-specific config (e.g. the condition predicate / switch). Edited
  /// in-place by [ConditionConfigEditor] for router nodes.
  late Map<String, dynamic> _extras;

  /// Inbound edges as `sourceStepId -> routeKey?`. One [StepTrigger] is emitted
  /// per entry; a non-null route key makes that edge conditional on an upstream
  /// router choosing it.
  late Map<String, String?> _edges;

  /// The node's checkout scope, as [NodeRepoScopeField] last emitted it: one
  /// `<repoId>` or `<repoId>@<branch>` entry per repo, empty for "every
  /// workspace repo". The field owns the picker, the branch controllers and
  /// the normalization; this is only what comes back out of it.
  late List<String> _repoIds;

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
      text: c.timeoutMs == null ? '' : '${c.timeoutMs}',
    );
    _retryCtrl = TextEditingController(
      text: c.retryPolicy == null ? '' : '${c.retryPolicy!.maxAttempts}',
    );
    _teamIdCtrl = TextEditingController(text: c.teamId ?? '');
    _schemaCtrl = TextEditingController(
      text: c.outputSchema == null ? '' : jsonEncode(c.outputSchema),
    );
    _conversationTitleCtrl = TextEditingController(
      text: c.conversationTitle ?? '',
    );
    _spaceNameCtrl = TextEditingController(
      text: c.extras['spaceName'] is String
          ? c.extras['spaceName'] as String
          : '',
    );
    _reducer = c.reducer;
    _dispatchMode = c.dispatchMode;
    _continueOnFail = c.continueOnFail;
    _createsConversation = c.createsConversation;
    _extras = Map<String, dynamic>.from(c.extras);
    _edges = _edgesFromTriggers(widget.step.triggers);
    _repoIds = c.repoIds;
    for (final ctrl in _listenedControllers) {
      ctrl.addListener(_emit);
    }
  }

  /// Every controller whose edits are pushed straight back into the config.
  List<TextEditingController> get _listenedControllers => [
    _labelCtrl,
    _promptCtrl,
    _scriptCtrl,
    _inputsCtrl,
    _outputCtrl,
    _timeoutCtrl,
    _retryCtrl,
    _teamIdCtrl,
    _schemaCtrl,
    _conversationTitleCtrl,
    _spaceNameCtrl,
  ];


  void _disposeControllers() {
    for (final ctrl in _listenedControllers) {
      ctrl.removeListener(_emit);
      ctrl.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  /// Whether this node is the one that OPENS a conversation for the run. Only
  /// there do the repo scope and the conversation toggle mean anything: an
  /// agent node joins a room somebody else opened.
  bool get _opensConversation =>
      widget.step.bodyKey == BuiltInBodyKeys.createSpace;

  /// Whether this node dispatches agents INTO a room somebody else opened, and
  /// so names the stream its turn is written to (`extras['conversationTitle']`).
  ///
  /// Without a name the step writes into the space's standing conversation, so
  /// a fan-out of steps interleaves every agent's turn into one thread. That
  /// makes the title part of the node's configuration, not an internal detail.
  bool get _namesAStream => const {
    BuiltInBodyKeys.promptAgent,
    BuiltInBodyKeys.teamDispatch,
    BuiltInBodyKeys.forEach,
    BuiltInBodyKeys.humanGate,
  }.contains(widget.step.bodyKey);

  void _emit({String? agentId}) {
    final title = _conversationTitleCtrl.text.trim();
    // The conversation TOGGLE lives on the space node only. Its title is shared
    // vocabulary: on a space node it names the stream the node opens, on an
    // agent node the stream it writes into — and a node that is neither must
    // not have either key written by a control it never shows.
    if (widget.step.bodyKey == BuiltInBodyKeys.createSpace) {
      if (_createsConversation) {
        _extras['createConversation'] = true;
      } else {
        _extras.remove('createConversation');
      }
      if (_createsConversation && title.isNotEmpty) {
        _extras['conversationTitle'] = title;
      } else {
        _extras.remove('conversationTitle');
      }
      final spaceName = _spaceNameCtrl.text.trim();
      if (spaceName.isNotEmpty) {
        _extras['spaceName'] = spaceName;
      } else {
        _extras.remove('spaceName');
      }
    } else if (_namesAStream) {
      if (title.isNotEmpty) {
        _extras['conversationTitle'] = title;
      } else {
        _extras.remove('conversationTitle');
      }
    }
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
    widget.onChange(
      PipelineStepDefinition(
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
          repoIds: _repoIds,
          outputKey: _outputCtrl.text.trim().isEmpty
              ? null
              : _outputCtrl.text.trim(),
          outputSchema: outputSchema,
          reducer: _reducer,
          retryPolicy: maxAttempts == null
              ? null
              : StepRetryPolicy(maxAttempts: maxAttempts),
          continueOnFail: _continueOnFail,
          timeoutMs: timeoutMs,
          teamId: _teamIdCtrl.text.trim().isEmpty
              ? null
              : _teamIdCtrl.text.trim(),
          dispatchMode: _dispatchMode,
          extras: _extras,
        ),
      ),
    );
  }

  void _updateKind(StepKind kind) {
    widget.onChange(
      PipelineStepDefinition(
        id: widget.step.id,
        kind: kind,
        bodyKey: widget.step.bodyKey,
        triggers: _buildTriggers(),
        waitForStepIds: kind == StepKind.join
            ? _edges.keys.toList(growable: false)
            : const [],
        x: widget.step.x,
        y: widget.step.y,
        config: widget.step.config,
      ),
    );
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
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final upstreamCandidates = widget.allSteps
        .where((s) => s.id != widget.step.id && s.kind != StepKind.terminal)
        .toList();
    final byId = {for (final s in widget.allSteps) s.id: s};

    final agentItems = <String, String>{
      for (final a in widget.workspaceAgents) '${a.name} · ${a.title}': a.id,
    };
    final bodyKey = widget.step.bodyKey;
    final isBashScript = bodyKey == 'pipeline.bashScript';
    final usesAgent = bodyKey == 'conversation.promptAgent';
    final usesPrompt = usesAgent;
    final isCondition = bodyKey == 'pipeline.condition';
    // Repo scope belongs to the node that OPENS the conversation, because a
    // conversation is a checkout. An agent node joins a room someone else
    // opened, so a scope set on one would be read by nothing — offering the
    // control there invites an author to set it and watch it do nothing.
    final opensConversation = _opensConversation;

    return Container(
      color: ds.bgPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.nodeConfigTitle} · ${widget.step.id}',
                  style: TextStyle(
                    color: ds.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CcIconButton(
                icon: AppIcons.trash2,
                tooltip: l10n.delete,
                onPressed: widget.onDelete,
              ),
            ],
          ),
          if (widget.step.kind == StepKind.listen ||
              widget.step.kind == StepKind.join) ...[
            const SizedBox(height: 12),
            NodeFieldLabel(
              label: l10n.nodeConfigKind,
              child: CcSelect<StepKind>(
                options: const [
                  CcSelectOption(value: StepKind.listen, label: 'listen'),
                  CcSelectOption(value: StepKind.join, label: 'join'),
                ],
                value: widget.step.kind,
                onChanged: _updateKind,
              ),
            ),
          ],
          const SizedBox(height: 12),
          NodeFieldLabel(
            label: l10n.nodeConfigLabel,
            child: CcTextField(controller: _labelCtrl),
          ),
          if (usesAgent) ...[
            const SizedBox(height: 12),
            NodeFieldLabel(
              label: l10n.nodeConfigAgent,
              child: _AgentPicker(
                // Re-seed the field when the selected node (and thus its staged
                // agent) changes.
                key: ValueKey('agent-${widget.step.id}'),
                agents: agentItems,
                selectedAgentId: widget.step.config.agentId,
                hint: l10n.nodeConfigAgentHint,
                onSelected: (id) => _emit(agentId: id),
              ),
            ),
          ],
          const SizedBox(height: 12),
          NodeFieldLabel(
            label: l10n.nodeConfigInputKeys,
            description: l10n.nodeConfigInputKeysHelp,
            child: CcTextField(
              controller: _inputsCtrl,
              hintText: 'repo_local_path, pr_title, pr_number',
            ),
          ),
          if (opensConversation) ...[
            const SizedBox(height: 12),
            NodeFieldLabel(
              label: l10n.nodeConfigRepos,
              description: l10n.nodeConfigReposHelp,
              child: NodeRepoScopeField(
                // Re-seeded when the selected node changes, so a scope typed
                // on one node cannot follow the panel to the next.
                key: ValueKey('repos-${widget.step.id}'),
                configured: widget.step.config.repoIds,
                workspaceRepos: widget.workspaceRepos,
                onChanged: (ids) {
                  _repoIds = ids;
                  _emit();
                },
              ),
            ),
          ],
          // What the room is called, and what its first stream is called.
          // Both are `{{placeholder}}` templates rendered against run state, so
          // a run can name its room after the repo or PR it is working on.
          if (bodyKey == BuiltInBodyKeys.createSpace) ...[
            const SizedBox(height: 12),
            NodeFieldLabel(
              label: l10n.nodeConfigSpaceName,
              description: l10n.nodeConfigSpaceNameHelp,
              child: CcTextField(
                controller: _spaceNameCtrl,
                hintText: l10n.nodeConfigSpaceNameHint,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CcCheckbox(
                  value: _createsConversation,
                  onChanged: (v) {
                    setState(() => _createsConversation = v);
                    _emit();
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.nodeConfigCreateConversation,
                    style: TextStyle(color: ds.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.nodeConfigCreateConversationHelp,
              style: TextStyle(color: ds.textTertiary, fontSize: 11),
            ),
            if (_createsConversation) ...[
              const SizedBox(height: 12),
              NodeFieldLabel(
                label: l10n.nodeConfigConversationTitle,
                description: l10n.nodeConfigConversationTitleHelp,
                child: CcTextField(
                  controller: _conversationTitleCtrl,
                  hintText: l10n.nodeConfigConversationTitleHint,
                ),
              ),
            ],
          ],
          // An agent node joins a room it did not open. The stream it writes
          // into is named here — without one, a fan-out of steps interleaves
          // every agent's turn into the room's standing conversation.
          if (_namesAStream) ...[
            const SizedBox(height: 12),
            NodeFieldLabel(
              label: l10n.nodeConfigStreamTitle,
              description: l10n.nodeConfigStreamTitleHelp,
              child: CcTextField(
                controller: _conversationTitleCtrl,
                hintText: l10n.nodeConfigConversationTitleHint,
              ),
            ),
          ],
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
            NodeFieldLabel(
              label: l10n.nodeConfigOutputKey,
              child: CcTextField(
                controller: _outputCtrl,
                hintText: 'qa_findings',
              ),
            ),
          if (usesPrompt) ...[
            const SizedBox(height: 12),
            NodeFieldLabel(
              label: l10n.nodeConfigPrompt,
              description: l10n.nodeConfigPromptHelp,
              child: CcTextArea(
                controller: _promptCtrl,
                minLines: 4,
                maxLines: 14,
              ),
            ),
          ],
          if (isBashScript) ...[
            const SizedBox(height: 12),
            NodeFieldLabel(
              label: l10n.nodeConfigScript,
              description: l10n.nodeConfigScriptHelp,
              child: CcTextArea(
                controller: _scriptCtrl,
                minLines: 4,
                maxLines: 18,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            l10n.nodeConfigAdvanced,
            style: TextStyle(
              color: ds.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          NodeFieldLabel(
            label: l10n.nodeConfigReducer,
            description: l10n.nodeConfigReducerHelp,
            child: CcSelect<String>(
              options: const [
                CcSelectOption(value: 'override', label: 'override'),
                CcSelectOption(value: 'append', label: 'append'),
                CcSelectOption(value: 'mergeLists', label: 'mergeLists'),
                CcSelectOption(value: 'mergeMaps', label: 'mergeMaps'),
                CcSelectOption(value: 'sum', label: 'sum'),
              ],
              value: _reducer,
              onChanged: (v) {
                setState(() => _reducer = v);
                _emit();
              },
            ),
          ),
          const SizedBox(height: 12),
          NodeFieldLabel(
            label: l10n.nodeConfigTimeoutMs,
            child: CcTextField(
              controller: _timeoutCtrl,
              hintText: '900000',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 12),
          NodeFieldLabel(
            label: l10n.nodeConfigRetryAttempts,
            child: CcTextField(
              controller: _retryCtrl,
              hintText: '3',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CcCheckbox(
                value: _continueOnFail,
                onChanged: (v) {
                  setState(() => _continueOnFail = v);
                  _emit();
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.nodeConfigContinueOnFail,
                  style: TextStyle(color: ds.textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
          if (widget.step.bodyKey == 'team.dispatch') ...[
            const SizedBox(height: 12),
            NodeFieldLabel(
              label: l10n.nodeConfigTeamId,
              child: CcTextField(controller: _teamIdCtrl),
            ),
            const SizedBox(height: 12),
            NodeFieldLabel(
              label: l10n.nodeConfigDispatchMode,
              child: CcSelect<String>(
                options: const [
                  CcSelectOption(value: 'allParallel', label: 'allParallel'),
                  CcSelectOption(value: 'manager', label: 'manager'),
                ],
                value: _dispatchMode,
                onChanged: (v) {
                  setState(() => _dispatchMode = v);
                  _emit();
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          NodeFieldLabel(
            label: l10n.nodeConfigOutputSchema,
            description: l10n.nodeConfigOutputSchemaHelp,
            child: CcTextArea(
              controller: _schemaCtrl,
              minLines: 2,
              maxLines: 8,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.nodeConfigTriggers,
            style: TextStyle(
              color: ds.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (upstreamCandidates.isEmpty)
            Text(
              l10n.nodeConfigNoUpstream,
              style: TextStyle(color: ds.textTertiary, fontSize: 12),
            )
          else ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final candidate in upstreamCandidates)
                  CcChip(
                    label: candidate.config.label ?? candidate.id,
                    selected: _edges.containsKey(candidate.id),
                    onPressed: () => _toggleSource(candidate.id),
                  ),
              ],
            ),
            ..._routeKeyEditors(l10n, ds, byId),
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
    DesignSystemTokens ds,
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
        style: TextStyle(color: ds.textTertiary, fontSize: 11),
      ),
      for (final src in routerEdges)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CcTextFormField(
            key: ValueKey('routeKey_${widget.step.id}_$src'),
            initialValue: _edges[src] ?? '',
            onChanged: (v) => _setRouteKey(src, v),
            label: l10n.nodeConfigRouteKeyFrom(byId[src]?.config.label ?? src),
            hintText: 'true',
          ),
        ),
    ];
  }
}

/// A typeahead agent picker. [agents] maps each agent's display label to its
/// id. The field is seeded with the label of [selectedAgentId] (when present),
/// and selecting a row emits that agent's id.
class _AgentPicker extends StatefulWidget {
  const _AgentPicker({
    super.key,
    required this.agents,
    required this.selectedAgentId,
    required this.hint,
    required this.onSelected,
  });

  /// Maps each agent's display label to its id.
  final Map<String, String> agents;
  final String? selectedAgentId;
  final String hint;
  final ValueChanged<String> onSelected;

  @override
  State<_AgentPicker> createState() => _AgentPickerState();
}

class _AgentPickerState extends State<_AgentPicker> {
  late final TextEditingController _controller = TextEditingController(
    text: _initialLabel(),
  );

  String _initialLabel() {
    for (final entry in widget.agents.entries) {
      if (entry.value == widget.selectedAgentId) {
        return entry.key;
      }
    }
    return '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CcAutocomplete<String>(
      controller: _controller,
      hintText: widget.hint,
      options: [
        for (final entry in widget.agents.entries)
          CcSelectOption<String>(value: entry.value, label: entry.key),
      ],
      onSelected: widget.onSelected,
    );
  }
}

/// Stacks a field label (and optional help text) above a form control,
/// giving every field a consistent label-above-field layout.
