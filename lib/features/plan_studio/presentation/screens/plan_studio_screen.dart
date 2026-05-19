import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/services/plan_document_compiler.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/orchestration/providers/orchestration_providers.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/plan_studio/presentation/widgets/plan_approval_bar.dart';
import 'package:control_center/features/plan_studio/presentation/widgets/plan_canvas.dart';
import 'package:control_center/features/plan_studio/presentation/widgets/plan_node_inspector.dart';
import 'package:control_center/features/plan_studio/presentation/widgets/plan_node_visuals.dart';
import 'package:control_center/features/plan_studio/presentation/widgets/plan_version_panel.dart';
import 'package:control_center/features/plan_studio/providers/plan_studio_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Plan Studio for a single plan (PRD 17). [kind] is `orchestration` or
/// `document`; [id] is the orchestration or plan-document id.
///
/// Reached two ways: as the standalone `/plans/<kind>/<id>` route (a shareable
/// deep link) and — the everyday path — as an editor tab opened straight from
/// the conversation that produced the plan, where [showPageHeader] is false
/// because the tab strip already names it.
class PlanStudioScreen extends ConsumerStatefulWidget {
  /// Creates a [PlanStudioScreen].
  const PlanStudioScreen({
    super.key,
    required this.workspaceId,
    required this.kind,
    required this.id,
    this.showPageHeader = true,
  });

  /// The active workspace.
  final String workspaceId;

  /// `orchestration` or `document`.
  final String kind;

  /// The orchestration / plan-document id.
  final String id;

  /// Whether to render the page header (title row). False when hosted inside an
  /// editor tab.
  final bool showPageHeader;

  @override
  ConsumerState<PlanStudioScreen> createState() => _PlanStudioScreenState();
}

class _PlanStudioScreenState extends ConsumerState<PlanStudioScreen> {
  /// Local editable proposal draft (orchestration kind). Null until loaded.
  OrchestrationProposal? _draft;

  /// The revision the draft was loaded from (optimistic concurrency).
  int _baseRevision = 0;

  String? _selectedKey;
  int? _selectedRevisionForDiff;
  bool _busy = false;
  String? _actionError;
  PlanTotalEstimate? _total;

  bool get _isOrchestration => widget.kind == 'orchestration';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isOrchestration) {
      final async = ref.watch(
        orchestrationProvider((workspaceId: widget.workspaceId, id: widget.id)),
      );
      return async.when(
        loading: () => _wrap(context, const Center(child: CcSpinner())),
        error: (e, _) => _wrap(context, Center(child: Text('$e'))),
        data: (orchestration) {
          if (orchestration == null) {
            return _wrap(context, Center(child: Text(l10n.planNotFound)));
          }
          _syncDraft(orchestration);
          return _buildOrchestration(context, orchestration);
        },
      );
    }
    final async = ref.watch(planDocumentProvider(widget.id));
    return async.when(
      loading: () => _wrap(context, const Center(child: CcSpinner())),
      error: (e, _) => _wrap(context, Center(child: Text('$e'))),
      data: (doc) {
        if (doc == null) {
          return _wrap(context, Center(child: Text(l10n.planNotFound)));
        }
        return _buildDocument(context, doc);
      },
    );
  }

  void _syncDraft(Orchestration o) {
    // Adopt the server proposal only when we have no local edits for this
    // revision (never clobber an in-progress edit; a bumped revision from a
    // replan replaces the base — the version panel surfaces the diff).
    if (_draft == null || _baseRevision != o.revision) {
      _draft = o.proposal;
      _baseRevision = o.revision;
    }
  }

  Widget _wrap(BuildContext context, Widget child) => widget.showPageHeader
      ? PageWrapper(
          title: AppLocalizations.of(context).planStudioTitle,
          child: child,
        )
      : child;

  // ── Orchestration plan ──

  Widget _buildOrchestration(BuildContext context, Orchestration o) {
    final proposal = _draft ?? o.proposal;
    final graph = PlanGraph.fromProposal(proposal);
    final validationErrors = orchestrationValidate(ref, proposal);
    final executing =
        o.status == OrchestrationStatus.executing ||
        o.status == OrchestrationStatus.synthesizing;
    final proposed = o.status == OrchestrationStatus.proposed;

    final revisions =
        ref.watch(orchestrationRevisionsProvider(o.id)).value ?? const [];
    final divergence = executing
        ? ref.watch(planDivergenceProvider(o.id)).value ?? const {}
        : const <String, dynamic>{};
    final List<PipelineStepRun> stepRuns = o.pipelineRunId == null
        ? const []
        : ref.watch(pipelineStepRunsForRunProvider(o.pipelineRunId!)).value ??
              const [];
    final agents =
        ref.watch(workspaceAgentsProvider(widget.workspaceId)).value ??
        const [];

    final divergedKeys = {
      for (final e in divergence.entries)
        if (e.value is Map && (e.value as Map)['held'] == true) e.key,
    };
    // Nodes whose work step already ran are read-only (edit forks the plan).
    final readOnly = <String>{
      for (final sr in stepRuns)
        if (sr.stepId.startsWith('sub_') && _startedStatus(sr.status))
          sr.stepId.substring('sub_'.length),
    };

    final selected = _selectedKey == null ? null : graph.node(_selectedKey!);

    return _wrap(
      context,
      Column(
        children: [
          if (executing &&
              o.approvedRevision != null &&
              o.revision > o.approvedRevision!)
            _ReplanBanner(
              approvedRevision: o.approvedRevision!,
              currentRevision: o.revision,
            ),
          Expanded(
            child: Row(
              children: [
                if (revisions.isNotEmpty)
                  PlanVersionPanel(
                    revisions: revisions,
                    current: proposal,
                    currentRevision: _baseRevision,
                    selectedRevision: _selectedRevisionForDiff,
                    canRewind: proposed,
                    onSelectRevision: (r) =>
                        setState(() => _selectedRevisionForDiff = r),
                    onRewind: (rev) => _run(() async {
                      await ref
                          .read(planStudioRepositoryProvider)
                          .saveRevision(
                            orchestrationId: o.id,
                            proposal: rev.proposal,
                            baseRevision: _baseRevision,
                          );
                    }),
                  ),
                Expanded(
                  child: PlanCanvas(
                    graph: graph,
                    selectedKey: _selectedKey,
                    onSelect: (k) => setState(() => _selectedKey = k),
                    editable: proposed,
                    readOnlyKeys: readOnly,
                    divergedKeys: divergedKeys,
                    runStateOf: (k) => resolvePlanNodeRunState(
                      k,
                      stepRuns: stepRuns.cast(),
                      approvedNodeKeys: o.approvedNodeKeys,
                      divergence: divergence,
                    ),
                    estimateOf: (k) => graph.node(k)?.estimate,
                    onConnect: (from, to) => _editNode(
                      to,
                      (n) => n.copyWith(dependsOn: [...n.dependsOn, from]),
                    ),
                    onDisconnect: (from, to) => _editNode(
                      to,
                      (n) => n.copyWith(
                        dependsOn: n.dependsOn.where((d) => d != from).toList(),
                      ),
                    ),
                    onAddNode: _addNode,
                    onDeleteNode: _deleteNode,
                  ),
                ),
                if (selected != null)
                  PlanNodeInspector(
                    graph: graph,
                    node: selected,
                    agents: agents,
                    editable: proposed,
                    readOnly: readOnly.contains(selected.key),
                    onNodeChanged: _replaceNode,
                    liveInfo: _liveInfo(context, selected.key, o),
                  ),
              ],
            ),
          ),
          PlanApprovalBar(
            total: _total,
            canApprove: proposed,
            isExecuting: executing,
            hasSelection: selected != null && selected.isWork,
            busy: _busy,
            validationError: validationErrors.isEmpty
                ? _actionError
                : validationErrors.first,
            showContinueNode:
                selected != null && divergedKeys.contains(selected.key),
            onContinueNode: () => _run(
              () => ref
                  .read(planStudioRepositoryProvider)
                  .continueNode(o.id, _selectedKey!),
            ),
            onEstimate: () => _run(() async {
              final wire = await ref
                  .read(planStudioRepositoryProvider)
                  .estimateOrchestration(o.id);
              setState(() => _total = PlanTotalEstimate.fromWire(wire));
            }),
            onApprovePlan: () => _saveThenApprove(o, null),
            onApproveSelectedNodes: () => _run(
              () => ref
                  .read(planStudioRepositoryProvider)
                  .approveNodes(o.id, _closure(graph, _selectedKey!)),
            ),
            onCancelOrReject: () =>
                _run(() => ref.read(planStudioRepositoryProvider).cancel(o.id)),
          ),
        ],
      ),
    );
  }

  // ── Plan-mode document ──

  Widget _buildDocument(BuildContext context, PlanDocument doc) {
    final graph = doc.graph;
    final agents =
        ref.watch(workspaceAgentsProvider(widget.workspaceId)).value ??
        const [];
    final proposed = doc.status == PlanDocumentStatus.proposed;
    final selected = _selectedKey == null ? null : graph.node(_selectedKey!);
    final clarifications = doc.clarifications;

    // An approved plan is a RUNNING plan: it compiles into an orchestration
    // whose id is derived from the plan id, so follow that row for live per-node
    // state and — the part that was missing entirely — a way to cancel. Without
    // this the studio went inert the moment you approved: no progress, no stop,
    // nothing to do but watch the conversation and hope.
    final execution = doc.status == PlanDocumentStatus.approved
        ? ref
              .watch(
                orchestrationProvider((
                  workspaceId: widget.workspaceId,
                  id: PlanDocumentCompiler.orchestrationIdFor(doc.id),
                )),
              )
              .value
        : null;
    final executing =
        execution != null &&
        (execution.status == OrchestrationStatus.executing ||
            execution.status == OrchestrationStatus.synthesizing);
    final runId = execution?.pipelineRunId;
    final List<PipelineStepRun> stepRuns = runId == null
        ? const []
        : ref.watch(pipelineStepRunsForRunProvider(runId)).value ?? const [];

    return _wrap(
      context,
      Column(
        children: [
          // The clarifying questions the planner asked, and the answers it got.
          // They shape the whole plan and were previously stored and never
          // shown, so a reviewer could not see what the plan was predicated on.
          if (clarifications.isNotEmpty) _Clarifications(items: clarifications),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PlanCanvas(
                    graph: graph,
                    selectedKey: _selectedKey,
                    onSelect: (k) => setState(() => _selectedKey = k),
                    // Plan documents are agent-authored; the operator reviews,
                    // estimates, and approves — editing lives on the
                    // orchestration path.
                    editable: false,
                    runStateOf: (k) => execution == null
                        ? PlanNodeRunState.none
                        : resolvePlanNodeRunState(
                            k,
                            stepRuns: stepRuns.cast(),
                            approvedNodeKeys: execution.approvedNodeKeys,
                            divergence: const {},
                          ),
                    estimateOf: (k) => graph.node(k)?.estimate,
                  ),
                ),
                if (selected != null)
                  PlanNodeInspector(
                    graph: graph,
                    node: selected,
                    agents: agents,
                    editable: false,
                    readOnly: false,
                    onNodeChanged: (_) {},
                  ),
              ],
            ),
          ),
          PlanApprovalBar(
            total: _total,
            canApprove: proposed,
            isExecuting: executing,
            hasSelection: selected != null && selected.isWork,
            busy: _busy,
            validationError: _actionError,
            onEstimate: () => _run(() async {
              final wire = await ref
                  .read(planStudioRepositoryProvider)
                  .estimatePlan(doc.id);
              setState(() => _total = PlanTotalEstimate.fromWire(wire));
            }),
            onApprovePlan: () => _run(
              () => ref.read(planStudioRepositoryProvider).approvePlan(doc.id),
            ),
            // A plan document is approved whole (there is no partial approval to
            // widen), so the executing bar is Cancel only.
            onApproveSelectedNodes: null,
            onCancelOrReject: () => _run(() {
              final repo = ref.read(planStudioRepositoryProvider);
              // Executing ⇒ stop the work. Not yet running ⇒ reject the plan.
              return execution != null && !execution.status.isTerminal
                  ? repo.cancel(execution.id)
                  : repo.updatePlanStatus(doc.id, PlanDocumentStatus.rejected);
            }),
          ),
        ],
      ),
    );
  }

  // ── Edit helpers (orchestration draft) ──

  void _replaceNode(PlanNode node) {
    final draft = _draft;
    if (draft == null || !node.isWork) {
      return;
    }
    setState(() {
      _draft = draft.copyWith(
        subTickets: [
          for (final t in draft.subTickets)
            if (t.key == node.key) node.toSubTicket() else t,
        ],
      );
    });
    _debouncedSave();
  }

  void _editNode(String key, PlanNode Function(PlanNode) edit) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    final node = PlanGraph.fromProposal(draft).node(key);
    if (node == null || !node.isWork) {
      return;
    }
    _replaceNode(edit(node));
  }

  Future<void> _addNode() async {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final key =
        'node_${draft.subTickets.length + 1}_${DateTime.now().millisecondsSinceEpoch % 100000}';
    final roleKey = draft.roles.isNotEmpty
        ? draft.roles.first.roleKey
        : draft.synthesis.roleKey;
    setState(() {
      _draft = draft.copyWith(
        subTickets: [
          ...draft.subTickets,
          ProposedSubTicket(
            key: key,
            title: l10n.planNewNodeTitle,
            roleKey: roleKey,
          ),
        ],
      );
      _selectedKey = key;
    });
    _debouncedSave();
  }

  void _deleteNode(String key) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    setState(() {
      _draft = draft.copyWith(
        subTickets: [
          for (final t in draft.subTickets)
            if (t.key != key)
              t.copyWith(
                dependsOn: t.dependsOn.where((d) => d != key).toList(),
              ),
        ],
      );
      if (_selectedKey == key) {
        _selectedKey = null;
      }
    });
    _debouncedSave();
  }

  DateTime _lastEdit = DateTime.fromMillisecondsSinceEpoch(0);
  void _debouncedSave() {
    // Coalesce rapid edits: only the final state is saved as a revision.
    final now = DateTime.now();
    _lastEdit = now;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (_lastEdit == now && mounted) {
        _saveRevision();
      }
    });
  }

  Future<void> _saveRevision() async {
    final draft = _draft;
    if (draft == null || _busy) {
      return;
    }
    final errors = orchestrationValidate(ref, draft);
    if (errors.isNotEmpty) {
      setState(() => _actionError = errors.first);
      return;
    }
    await _run(() async {
      await ref
          .read(planStudioRepositoryProvider)
          .saveRevision(
            orchestrationId: widget.id,
            proposal: draft,
            baseRevision: _baseRevision,
          );
    });
  }

  Future<void> _saveThenApprove(Orchestration o, Set<String>? nodeKeys) async {
    final draft = _draft;
    if (draft != null && draft.toJsonString() != o.proposal.toJsonString()) {
      await _saveRevision();
    }
    if (_actionError != null) {
      return;
    }
    await _run(
      () => ref
          .read(planStudioRepositoryProvider)
          .approve(o.id, approvedNodeKeys: nodeKeys),
    );
  }

  String? _liveInfo(BuildContext context, String key, Orchestration o) {
    final runId = o.pipelineRunId;
    if (runId == null) {
      return null;
    }
    final cost = ref
        .watch(
          pipelineStepCostProvider((
            workspaceId: widget.workspaceId,
            runId: runId,
          )),
        )
        .value;
    final cents = cost?['sub_$key'];
    if (cents == null) {
      return null;
    }
    final actual = (cents / 100).toStringAsFixed(2);
    return AppLocalizations.of(context).planLiveActualCost(actual);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await action();
    } on RemoteRpcException catch (e) {
      if (mounted) {
        setState(() => _actionError = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionError = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// The dependency-closed set for a subtree approval: the node plus every
  /// transitive dependency it needs to run.
  Set<String> _closure(PlanGraph graph, String key) {
    final result = <String>{};
    final queue = [key];
    while (queue.isNotEmpty) {
      final k = queue.removeLast();
      if (!result.add(k)) {
        continue;
      }
      final node = graph.node(k);
      if (node != null) {
        queue.addAll(node.dependsOn);
      }
    }
    // Only work nodes are approvable (structural frame is implicit).
    return {
      for (final k in result)
        if (graph.node(k)?.isWork ?? false) k,
    };
  }

  static bool _startedStatus(PipelineStepStatus status) =>
      status == PipelineStepStatus.completed ||
      status == PipelineStepStatus.running ||
      status == PipelineStepStatus.suspended ||
      status == PipelineStepStatus.failed;
}

/// Runs the client-side validator on a proposal, returning inline errors.
List<String> orchestrationValidate(WidgetRef ref, OrchestrationProposal p) {
  return ref.read(orchestrationProposalValidatorProvider).validate(p);
}

class _ReplanBanner extends StatelessWidget {
  const _ReplanBanner({
    required this.approvedRevision,
    required this.currentRevision,
  });

  final int approvedRevision;
  final int currentRevision;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      color: ds.bgWarningPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        l10n.planReplanBanner(approvedRevision, currentRevision),
        style: TextStyle(
          fontSize: 12,
          color: ds.textWarningPrimary,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

/// The planner's clarifying questions and the answers it received.
class _Clarifications extends StatelessWidget {
  const _Clarifications({required this.items});

  final List<PlanClarification> items;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: ds.bgSecondary,
        border: Border(bottom: BorderSide(color: ds.borderSecondary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.question,
                    style: TextStyle(
                      fontFamily: CcFonts.uiFamily,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: ds.textSecondary,
                    ),
                  ),
                  if (c.answer.isNotEmpty)
                    Text(
                      c.answer,
                      style: TextStyle(
                        fontFamily: CcFonts.uiFamily,
                        fontSize: 12,
                        height: 1.45,
                        color: ds.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
