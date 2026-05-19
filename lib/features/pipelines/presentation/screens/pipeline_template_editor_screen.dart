import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_config_editor.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_library_sidebar.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_canvas.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_settings_dialog.dart';
import 'package:control_center/features/pipelines/presentation/widgets/trigger_node_panel.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
///  - Left sidebar: draggable [NodeType] entries from the [NodeTypeLibrary].
///  - Centre canvas: renders the live graph; accepts node drops at the
///    drop offset; clicking a node opens the right panel.
///  - Right panel: form for the selected node's [PipelineNodeConfig] and
///    its inbound edges (multi-select upstream step IDs).
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
  bool _dirty = false;

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
    if (mounted && def != null) {
      setState(() => _draft = def);
    }
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
    _markDirty(draft.copyWith(steps: [...draft.steps, newStep]));
    setState(() => _selectedStepId = newId);
  }

  void _updateNode(PipelineStepDefinition updated) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    final next = draft.steps
        .map((s) => s.id == updated.id ? updated : s)
        .toList(growable: false);
    _markDirty(draft.copyWith(steps: next));
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
          return PipelineStepDefinition(
            id: s.id,
            kind: s.kind,
            bodyKey: s.bodyKey,
            triggers: remaining,
            waitForStepIds: s.waitForStepIds
                .where((id) => id != stepId)
                .toList(growable: false),
            config: s.config,
            x: s.x,
            y: s.y,
          );
        })
        .toList(growable: false);
    _markDirty(draft.copyWith(steps: filtered));
    setState(() {
      if (_selectedStepId == stepId) {
        _selectedStepId = null;
      }
    });
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

    if (draft == null) {
      return PageWrapper(
        title: widget.templateId,
        child: const Center(child: CcSpinner()),
      );
    }

    final selectedStep = _selectedStepId == null
        ? null
        : draft.step(_selectedStepId!);

    return PageWrapper(
      title: '${l10n.pipelineTemplateEditorTitle} — ${draft.name}',
      subtitle: l10n.pipelineTemplateEditorSubtitle,
      actions: [
        // The header spaces its own actions (AppSpacing.sm); adding spacers
        // here on top of that is what made this row read twice as loose as
        // every other page header.
        if (_dirty)
          Text(
            l10n.unsavedChanges,
            style: CcTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
            ),
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
              onSelect: (id) => setState(() => _selectedStepId = id),
              onDropNodeType: _addNodeAt,
            ),
          ),
          if (selectedStep != null) ...[
            const CcDivider(axis: Axis.vertical),
            SizedBox(
              width: 360,
              // The trigger entry node is configured by its triggers (manual /
              // event / schedule), not the generic node form.
              child: selectedStep.kind == StepKind.trigger
                  ? TriggerNodePanel(
                      workspaceId: draft.workspaceId,
                      templateId: draft.templateId,
                    )
                  : NodeConfigEditor(
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
