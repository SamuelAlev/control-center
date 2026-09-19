import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_start.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_config_editor.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_library_sidebar.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_canvas.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_geometry.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_graph_layout.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_settings_dialog.dart';
import 'package:control_center/features/pipelines/presentation/widgets/trigger_node_panel.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Tile size + overlap-nudge pitch. Lockstep with
/// [PipelineEditorCanvas.nodeWidth]/[PipelineEditorCanvas.nodeHeight] (220×72)
/// plus a 16px row gutter — so a drop that lands on an existing tile is
/// nudged down instead of stacking.
const double _tileWidth = 220;
const double _tileHeight = 72;
const double _afterDyNudge = 88;

/// Streams the agents in the active workspace for the editor's agent picker.
final _workspaceAgentsProvider = StreamProvider.family<List<Agent>, String>((
  ref,
  workspaceId,
) {
  return ref.watch(agentRepositoryProvider).watchByWorkspace(workspaceId);
});

/// Drag-and-drop editor for a single pipeline template.
///
/// Three columns:
///  - Left sidebar: draggable palette entries from the node-type library.
///  - Centre canvas: renders the live graph; palette drops land at the
///    pointer; dragging an output handle onto another node draws an edge,
///    or onto empty canvas opens a type picker that creates and links.
///  - Right panel: form for the selected node's config. Inbound edges are
///    drawn on the canvas (drag a handle onto another node). Hidden until
///    a node is selected.
class PipelineTemplateEditorScreen extends ConsumerStatefulWidget {
  /// Creates an editor for [templateId].
  const PipelineTemplateEditorScreen({super.key, required this.templateId});

  /// The template identifier.
  final String templateId;

  @override
  ConsumerState<PipelineTemplateEditorScreen> createState() =>
      _PipelineTemplateEditorScreenState();
}

class _PipelineTemplateEditorScreenState
    extends ConsumerState<PipelineTemplateEditorScreen> {
  PipelineDefinition? _draft;
  String? _selectedStepId;
  String? _selectedTriggerId;
  bool _dirty = false;

  /// Step and trigger selections are mutually exclusive: picking one clears
  /// the other so the right panel never shows two configs at once.
  void _selectStep(String id) {
    setState(() {
      _selectedStepId = id;
      _selectedTriggerId = null;
    });
  }

  void _selectTrigger(String id) {
    setState(() {
      _selectedTriggerId = id;
      _selectedStepId = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final repo = ref.read(pipelineTemplateRepositoryProvider);
    final def = await repo.getById(workspaceId, widget.templateId);
    if (!mounted || def == null) {
      return;
    }
    final rows =
        (await ref
                .read(pipelineTriggerRepositoryProvider)
                .forWorkspace(workspaceId))
            .where((t) => t.templateId == widget.templateId)
            .toList();
    final synced = syncPipelineTriggerSteps(
      def: def,
      rows: rows,
      stackPitch: kPipelineEditorTriggerPitch,
    );
    final next = synced == def ? def : _reconcileTerminal(synced);
    if (!mounted) {
      return;
    }
    setState(() {
      _draft = next;
      _dirty = next != def;
    });
  }

  void _markDirty(PipelineDefinition next) {
    setState(() {
      _draft = next;
      _dirty = true;
    });
  }

  /// Opens the manual-run settings: whether the template appears on the run
  /// page (persisted immediately as a `manual` trigger), how many runs may
  /// execute at once, and the input fields a manual run collects. The last two
  /// are template fields, so they land on the draft and save with it.
  Future<void> _openRunSettings(PipelineDefinition draft) async {
    final result = await showPipelineRunSettingsDialog(
      context: context,
      ref: ref,
      workspaceId: draft.workspaceId,
      templateId: draft.templateId,
      inputs: draft.inputs,
      maxParallelRuns: draft.maxParallelRuns,
    );
    if (result == null ||
        (_listsEqual(result.inputs, draft.inputs) &&
            result.maxParallelRuns == draft.maxParallelRuns)) {
      return;
    }
    _markDirty(
      draft.copyWith(
        inputs: result.inputs,
        maxParallelRuns: result.maxParallelRuns,
      ),
    );
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    try {
      await ref
          .read(pipelineTemplateRepositoryProvider)
          .upsert(
            // Saving an edited copy clears the built-in flag so the bootstrap
            // won't overwrite the user's changes. copyWith preserves the
            // declared inputs.
            draft.copyWith(isBuiltIn: false),
          );
    } on Object catch (e) {
      // The repository validates the graph and rejects a broken pipeline
      // (e.g. an undeclared route key or a dangling edge). Surface it.
      if (mounted) {
        CcToastScope.of(context).show(
          AppLocalizations.of(context).errorWithDetail('$e'),
          variant: CcToastVariant.danger,
        );
      }
      return;
    }
    if (mounted) {
      setState(() => _dirty = false);
      // Re-watching the templates stream will reflect the persisted copy.
    }
  }

  void _addNodeAt(NodeType type, Offset offset) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    final newId = _allocateStepId(draft, type.id);
    final newStep = PipelineStepDefinition(
      id: newId,
      // The trigger is a fixed entry node; dropped palette nodes are always
      // work nodes (listen / join / router / forEach).
      kind: type.defaultKind == StepKind.trigger
          ? StepKind.listen
          : type.defaultKind,
      bodyKey: type.defaultBodyKey,
      config: type.defaultConfig,
      x: offset.dx,
      y: offset.dy,
    );
    _markDirty(
      _reconcileTerminal(draft.copyWith(steps: [...draft.steps, newStep])),
    );
    _selectStep(newId);
  }

  void _updateNode(PipelineStepDefinition updated) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    final next = [
      for (final s in draft.steps)
        if (s.id == updated.id) updated else s,
    ];
    _markDirty(_reconcileTerminal(draft.copyWith(steps: next)));
  }

  void _moveNode(String id, Offset pos) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    final next = [
      for (final s in draft.steps)
        if (s.id == id) _copyStep(s, x: pos.dx, y: pos.dy) else s,
    ];
    _markDirty(draft.copyWith(steps: next));
  }

  void _connect(String from, String to) {
    final draft = _draft;
    if (draft == null || from == to) {
      return;
    }
    final target = draft.step(to);
    if (target == null ||
        target.kind == StepKind.trigger ||
        target.kind == StepKind.terminal) {
      return;
    }
    if (target.triggers.any((t) => t.sourceStepIds.contains(from))) {
      return;
    }
    final triggers = [
      ...target.triggers,
      StepTrigger(sourceStepIds: [from]),
    ];
    final next = [
      for (final s in draft.steps)
        if (s.id == to)
          _copyStep(
            s,
            triggers: triggers,
            waitForStepIds: s.kind == StepKind.join
                ? [for (final t in triggers) ...t.sourceStepIds]
                : s.waitForStepIds,
          )
        else
          s,
    ];
    _markDirty(_reconcileTerminal(draft.copyWith(steps: next)));
  }

  void _disconnect(String from, String to) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    final target = draft.step(to);
    if (target == null) {
      return;
    }
    final remaining = <StepTrigger>[];
    for (final t in target.triggers) {
      if (!t.sourceStepIds.contains(from)) {
        remaining.add(t);
        continue;
      }
      final kept = [
        for (final id in t.sourceStepIds)
          if (id != from) id,
      ];
      if (kept.isNotEmpty) {
        remaining.add(StepTrigger(sourceStepIds: kept, routeKey: t.routeKey));
      }
    }
    final next = [
      for (final s in draft.steps)
        if (s.id == to)
          _copyStep(
            s,
            triggers: remaining,
            waitForStepIds: s.kind == StepKind.join
                ? [for (final t in remaining) ...t.sourceStepIds]
                : s.waitForStepIds,
          )
        else
          s,
    ];
    _markDirty(_reconcileTerminal(draft.copyWith(steps: next)));
  }

  void _insertLinked(NodeType type, String fromStepId, Offset canvasOffset) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    if (draft.step(fromStepId) == null) {
      return;
    }
    final newId = _allocateStepId(draft, type.id);
    final kind = type.defaultKind == StepKind.trigger
        ? StepKind.listen
        : type.defaultKind;
    final x = canvasOffset.dx;
    var y = canvasOffset.dy;
    while (_tileOverlaps(draft, x, y)) {
      y += _afterDyNudge;
    }
    final newStep = PipelineStepDefinition(
      id: newId,
      kind: kind,
      bodyKey: type.defaultBodyKey,
      triggers: [
        StepTrigger(sourceStepIds: [fromStepId]),
      ],
      waitForStepIds: kind == StepKind.join ? [fromStepId] : const [],
      config: type.defaultConfig,
      x: x,
      y: y,
    );
    _markDirty(
      _reconcileTerminal(draft.copyWith(steps: [...draft.steps, newStep])),
    );
    _selectStep(newId);
  }

  void _deleteNode(String stepId) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    final filtered = draft.steps
        .where((s) => s.id != stepId)
        .map((s) {
          // Strip any triggers that reference the deleted node.
          final remaining = s.triggers
              .map(
                (t) => StepTrigger(
                  sourceStepIds: t.sourceStepIds
                      .where((id) => id != stepId)
                      .toList(growable: false),
                  routeKey: t.routeKey,
                ),
              )
              .where((t) => t.sourceStepIds.isNotEmpty)
              .toList(growable: false);
          if (remaining.length == s.triggers.length &&
              remaining.every(
                (t) => s.triggers.any(
                  (o) => _listsEqual(o.sourceStepIds, t.sourceStepIds),
                ),
              )) {
            return s;
          }
          return _copyStep(
            s,
            triggers: remaining,
            waitForStepIds: s.waitForStepIds
                .where((id) => id != stepId)
                .toList(growable: false),
          );
        })
        .toList(growable: false);
    _markDirty(_reconcileTerminal(draft.copyWith(steps: filtered)));
    setState(() {
      if (_selectedStepId == stepId) {
        _selectedStepId = null;
      }
    });
  }

  /// Default schedule expression used by the add-trigger dialog.
  static const _defaultScheduleExpression = 'every:86400';

  Future<void> _addTrigger(String eventType, [Offset? canvasOffset]) async {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    final id = const Uuid().v4();
    final trigger = switch (eventType) {
      PipelineTrigger.manualEventType => PipelineTrigger(
        id: id,
        eventType: PipelineTrigger.manualEventType,
        templateId: draft.templateId,
        workspaceId: draft.workspaceId,
        enabled: true,
      ),
      PipelineTrigger.scheduleEventType => PipelineTrigger(
        id: id,
        eventType: PipelineTrigger.scheduleEventType,
        templateId: draft.templateId,
        workspaceId: draft.workspaceId,
        enabled: false,
        cronExpression: _defaultScheduleExpression,
      ),
      PipelineTrigger.webhookEventType => PipelineTrigger(
        id: id,
        eventType: PipelineTrigger.webhookEventType,
        templateId: draft.templateId,
        workspaceId: draft.workspaceId,
        enabled: false,
        webhookToken: const Uuid().v4().replaceAll('-', ''),
      ),
      _ => PipelineTrigger(
        id: id,
        eventType: eventType,
        templateId: draft.templateId,
        workspaceId: draft.workspaceId,
        enabled: false,
      ),
    };
    try {
      await ref.read(pipelineTriggerRepositoryProvider).insert(trigger);
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show(
          AppLocalizations.of(context).errorWithDetail('$e'),
          variant: CcToastVariant.danger,
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }
    final rows = [
      for (final t in _triggersOf(draft))
        if (t.id != trigger.id) t,
      trigger,
    ];
    _applyTriggerSync(draft, rows);
    if (canvasOffset != null) {
      final placed = _draft;
      if (placed != null && placed.step(id) != null) {
        _moveNode(id, canvasOffset);
      }
    }
    _selectTrigger(id);
  }

  Future<void> _deleteTrigger(String triggerId) async {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    try {
      await ref
          .read(pipelineTriggerRepositoryProvider)
          .deleteById(draft.workspaceId, triggerId);
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show(
          AppLocalizations.of(context).errorWithDetail('$e'),
          variant: CcToastVariant.danger,
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }
    final draftAfter = _draft;
    if (draftAfter != null) {
      final remaining = [
        for (final t in _triggersOf(draftAfter))
          if (t.id != triggerId) t,
      ];
      if (remaining.isEmpty) {
        final next = removePipelineTriggerStep(draftAfter, triggerId);
        if (next != draftAfter) {
          _markDirty(_reconcileTerminal(next));
        }
      } else {
        _applyTriggerSync(draftAfter, remaining);
      }
    }
    setState(() {
      if (_selectedTriggerId == triggerId) {
        _selectedTriggerId = null;
      }
    });
  }

  void _tidy() {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    final visible = [
      for (final s in draft.steps)
        if (s.kind != StepKind.terminal) s,
    ];
    final positions = PipelineGraphLayout.compute(
      visible,
      nodeWidths: {
        for (final s in visible) s.id: PipelineEditorCanvas.nodeWidth,
      },
      nodeHeight: PipelineEditorCanvas.nodeHeight,
    );
    final next = [
      for (final s in draft.steps)
        if (s.kind == StepKind.terminal)
          s
        else
          _copyStep(
            s,
            x: positions[s.id]?.dx ?? s.x,
            y: positions[s.id]?.dy ?? s.y,
          ),
    ];
    _markDirty(draft.copyWith(steps: next));
  }

  /// Rewrites the hidden terminal so it waits on every live sink.
  ///
  /// The downstream planner treats a terminal as reached when **all** of one
  /// trigger's sources sit in completed∪skipped and **at least one** genuinely
  /// completed. Skipped router branches therefore satisfy the source set
  /// without finishing the run by themselves; terminals are also exempt from
  /// dead-propagation, so a skipped incoming leaf cannot kill the terminal.
  /// Orphans are left out of the source set because they never run — waiting
  /// on one would hang the pipeline. An empty graph (trigger with no work
  /// successors) lists the trigger itself so the run completes immediately.
  PipelineDefinition _reconcileTerminal(PipelineDefinition def) {
    final terminals = [
      for (final s in def.steps)
        if (s.kind == StepKind.terminal) s,
    ];
    if (terminals.length != 1) {
      return def;
    }
    final terminal = terminals.single;
    final triggerIds = [
      for (final s in def.steps)
        if (s.kind == StepKind.trigger) s.id,
    ];
    if (triggerIds.isEmpty) {
      return def;
    }

    final nonTerminal = [
      for (final s in def.steps)
        if (s.kind != StepKind.terminal) s,
    ];
    final successors = <String, Set<String>>{
      for (final s in nonTerminal) s.id: <String>{},
    };
    for (final s in nonTerminal) {
      for (final t in s.triggers) {
        for (final src in t.sourceStepIds) {
          successors[src]?.add(s.id);
        }
      }
    }

    final reachable = <String>{...triggerIds};
    final queue = <String>[...triggerIds];
    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      for (final next in successors[id] ?? const <String>{}) {
        if (reachable.add(next)) {
          queue.add(next);
        }
      }
    }

    final sinks = [
      for (final s in nonTerminal)
        if (s.kind != StepKind.trigger &&
            reachable.contains(s.id) &&
            (successors[s.id]?.isEmpty ?? true))
          s.id,
    ];
    final disconnectedStarts = [
      for (final id in triggerIds)
        if (successors[id]?.isEmpty ?? true) id,
    ];
    if (sinks.isEmpty) {
      // Empty graph: the run completes when its start node does. Separate
      // triggers so a schedule start does not wait on the manual node.
      final expected = [
        for (final id in triggerIds) StepTrigger(sourceStepIds: [id]),
      ];
      final alreadyEmpty =
          terminal.triggers.length == expected.length &&
          Iterable<int>.generate(expected.length).every(
            (i) =>
                terminal.triggers[i].routeKey == null &&
                _listsEqual(
                  terminal.triggers[i].sourceStepIds,
                  expected[i].sourceStepIds,
                ),
          );
      if (alreadyEmpty) {
        return def;
      }
      return def.copyWith(
        steps: [
          for (final s in def.steps)
            if (s.id == terminal.id) _copyStep(s, triggers: expected) else s,
        ],
      );
    }
    final expected = [
      StepTrigger(sourceStepIds: sinks),
      for (final id in disconnectedStarts) StepTrigger(sourceStepIds: [id]),
    ];
    final already =
        terminal.triggers.length == expected.length &&
        Iterable<int>.generate(expected.length).every(
          (i) =>
              terminal.triggers[i].routeKey == expected[i].routeKey &&
              _listsEqual(
                terminal.triggers[i].sourceStepIds,
                expected[i].sourceStepIds,
              ),
        );
    if (already) {
      return def;
    }

    return def.copyWith(
      steps: [
        for (final s in def.steps)
          if (s.id == terminal.id) _copyStep(s, triggers: expected) else s,
      ],
    );
  }

  String _allocateStepId(PipelineDefinition def, String base) {
    var i = 1;
    final taken = def.steps.map((s) => s.id).toSet();
    var candidate = '${base}_$i';
    while (taken.contains(candidate)) {
      i += 1;
      candidate = '${base}_$i';
    }
    return candidate;
  }

  /// Element-wise list equality, used on both the declared inputs and a step's
  /// source ids.
  bool _listsEqual<T>(List<T> a, List<T> b) =>
      a.length == b.length &&
      Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);

  List<PipelineTrigger> _triggersOf(PipelineDefinition draft) {
    return ref
            .read(pipelineTriggersForWorkspaceProvider(draft.workspaceId))
            .value
            ?.where((t) => t.templateId == draft.templateId)
            .toList() ??
        const [];
  }

  void _applyTriggerSync(PipelineDefinition draft, List<PipelineTrigger> rows) {
    final next = syncPipelineTriggerSteps(
      def: draft,
      rows: rows,
      stackPitch: kPipelineEditorTriggerPitch,
    );
    if (next == draft) {
      return;
    }
    _markDirty(_reconcileTerminal(next));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = _draft;
    final library = ref.watch(nodeTypeLibraryProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agentsAsync = workspaceId == null
        ? const AsyncValue<List<Agent>>.data([])
        : ref.watch(_workspaceAgentsProvider(workspaceId));
    final reposAsync = workspaceId == null
        ? const AsyncValue<List<Repo>>.data([])
        : ref.watch(reposForWorkspaceProvider(workspaceId));
    final triggers = workspaceId == null
        ? const <PipelineTrigger>[]
        : ref
                  .watch(pipelineTriggersForWorkspaceProvider(workspaceId))
                  .value
                  ?.where((t) => t.templateId == widget.templateId)
                  .toList() ??
              const <PipelineTrigger>[];

    if (workspaceId != null) {
      ref.listen(pipelineTriggersForWorkspaceProvider(workspaceId), (
        prev,
        next,
      ) {
        final current = _draft;
        if (current == null) {
          return;
        }
        final rows = next.value
            ?.where((t) => t.templateId == widget.templateId)
            .toList();
        if (rows == null) {
          return;
        }
        _applyTriggerSync(current, rows);
      });
    }

    if (draft == null) {
      return PageWrapper(
        title: widget.templateId,
        child: const Center(child: CcSpinner()),
      );
    }

    final selectedStep = _selectedStepId == null
        ? null
        : draft.step(_selectedStepId!);
    final ds = context.designSystem ?? DesignSystemTokens.light();

    return PageWrapper(
      titleWidget: _InlinePipelineTitle(
        name: draft.name,
        subtitle: l10n.pipelineTemplateEditorSubtitle,
        onCommit: (name) => _markDirty(draft.copyWith(name: name)),
      ),
      actions: [
        // The header spaces its own actions (AppSpacing.sm); adding spacers
        // here on top of that is what made this row read twice as loose as
        // every other page header.
        if (_dirty)
          Text(
            l10n.unsavedChanges,
            style: CcTypography.caption.copyWith(color: ds.fgBrandSecondary),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CcSwitch(
              value: draft.isEnabled,
              onChanged: (value) =>
                  _markDirty(draft.copyWith(isEnabled: value)),
              semanticLabel: l10n.enabled,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.enabled,
              style: CcTypography.body.copyWith(color: ds.textPrimary),
            ),
          ],
        ),
        CcButton(
          onPressed: () => _openRunSettings(draft),
          icon: AppIcons.slidersHorizontal,
          size: CcButtonSize.sm,
          variant: CcButtonVariant.secondary,
          child: Text(l10n.pipelineRunSettingsTitle),
        ),
        CcButton(
          onPressed: () =>
              context.go(settingsPipelinesRoute(context.currentWorkspaceId!)),
          size: CcButtonSize.sm,
          variant: CcButtonVariant.secondary,
          child: Text(l10n.back),
        ),
        CcButton(
          onPressed: _dirty ? _save : null,
          icon: AppIcons.save,
          size: CcButtonSize.sm,
          variant: CcButtonVariant.primary,
          child: Text(l10n.save),
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 240, child: NodeLibrarySidebar(library: library)),
          const CcDivider(axis: Axis.vertical),
          Expanded(
            child: PipelineEditorCanvas(
              definition: draft,
              selectedStepId: _selectedStepId,
              selectedTriggerId: _selectedTriggerId,
              library: library,
              triggers: triggers,
              onSelect: _selectStep,
              onSelectTrigger: _selectTrigger,
              onAddTrigger: _addTrigger,
              onDeleteTrigger: _deleteTrigger,
              onDropNodeType: _addNodeAt,
              onMoveNode: _moveNode,
              onConnect: _connect,
              onDisconnect: _disconnect,
              onInsertLinked: _insertLinked,
              onDeleteStep: _deleteNode,
              onTidy: _tidy,
            ),
          ),
          if (_selectedTriggerId != null) ...[
            const CcDivider(axis: Axis.vertical),
            SizedBox(
              width: 360,
              child: TriggerNodePanel(
                workspaceId: draft.workspaceId,
                templateId: draft.templateId,
                triggerId: _selectedTriggerId!,
                onDelete: () => _deleteTrigger(_selectedTriggerId!),
              ),
            ),
          ] else if (selectedStep != null &&
              selectedStep.kind != StepKind.trigger) ...[
            const CcDivider(axis: Axis.vertical),
            SizedBox(
              width: 360,
              child: NodeConfigEditor(
                step: selectedStep,
                allSteps: draft.steps,
                workspaceAgents: agentsAsync.maybeWhen(
                  data: (a) => a,
                  orElse: () => const [],
                ),
                workspaceRepos: reposAsync.maybeWhen(
                  data: (r) => r,
                  orElse: () => const [],
                ),
                onChange: _updateNode,
                onDelete: () => _deleteNode(selectedStep.id),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

bool _tileOverlaps(PipelineDefinition def, double x, double y) {
  for (final s in def.steps) {
    if (s.kind == StepKind.terminal) {
      continue;
    }
    final sx = s.x;
    final sy = s.y;
    if (sx == null || sy == null) {
      continue;
    }
    if (!(x + _tileWidth <= sx ||
        sx + _tileWidth <= x ||
        y + _tileHeight <= sy ||
        sy + _tileHeight <= y)) {
      return true;
    }
  }
  return false;
}

PipelineStepDefinition _copyStep(
  PipelineStepDefinition s, {
  List<StepTrigger>? triggers,
  List<String>? waitForStepIds,
  double? x,
  double? y,
}) {
  return PipelineStepDefinition(
    id: s.id,
    kind: s.kind,
    bodyKey: s.bodyKey,
    triggers: triggers ?? s.triggers,
    waitForStepIds: waitForStepIds ?? s.waitForStepIds,
    config: s.config,
    x: x ?? s.x,
    y: y ?? s.y,
  );
}

/// Page-header title that swaps to a field so renaming never needs a dialog.
class _InlinePipelineTitle extends StatefulWidget {
  const _InlinePipelineTitle({
    required this.name,
    required this.subtitle,
    required this.onCommit,
  });

  final String name;
  final String subtitle;
  final ValueChanged<String> onCommit;

  @override
  State<_InlinePipelineTitle> createState() => _InlinePipelineTitleState();
}

class _InlinePipelineTitleState extends State<_InlinePipelineTitle> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
    // Handle Escape on the focus node so it cancels *before* blur; a blur
    // listener would otherwise commit the in-progress name.
    _focus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        _cancel();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus && _editing) {
      _commit();
    }
  }

  void _start() {
    _controller.text = widget.name;
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    setState(() => _editing = true);
  }

  void _commit() {
    if (!_editing) {
      return;
    }
    final trimmed = _controller.text.trim();
    setState(() => _editing = false);
    if (trimmed.isEmpty || trimmed == widget.name) {
      return;
    }
    widget.onCommit(trimmed);
  }

  void _cancel() {
    if (!_editing) {
      return;
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final titleStyle = CcTypography.display.copyWith(
      fontWeight: FontWeight.w700,
      color: tokens.textPrimary,
      height: 1.25,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_editing)
          CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): _cancel,
            },
            child: CcTextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              size: CcTextFieldSize.sm,
              textStyle: titleStyle,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _commit(),
            ),
          )
        else
          Row(
            children: [
              Flexible(
                child: Text(
                  widget.name,
                  style: titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              CcIconButton(
                icon: AppIcons.pencil,
                tooltip: l10n.rename,
                size: CcButtonSize.sm,
                onPressed: _start,
              ),
            ],
          ),
        const SizedBox(height: 8),
        Text(
          widget.subtitle,
          style: CcTypography.body.copyWith(
            color: tokens.textTertiary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
