import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_remote/analytics.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/plan_goal_providers.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_remote/widgets/plan_goal/confirm_operation.dart';
import 'package:cc_remote/widgets/plan_goal/plan_detail_content.dart';
import 'package:cc_remote/widgets/plan_goal/plan_review.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read and approve a plan document without an editor or implicit execution.
class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({required this.planId, super.key});

  final String planId;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  final Set<String> _selected = {};
  String? _scope;
  int? _revision;
  Map<String, dynamic>? _estimate;
  String? _error;
  String? _approvedExecutionId;
  bool _busy = false;

  Future<void> _act(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _stillAuthorized(String workspaceId) =>
      ref.read(activeWorkspaceIdProvider).value == workspaceId &&
      (ref.read(workspaceRoleProvider).value?.canWrite ?? false);

  Future<void> _approve(PlanDocument plan, String workspaceId) async {
    if (!_stillAuthorized(workspaceId) || _busy) return;
    final l10n = AppLocalizations.of(context);
    final client = ref.read(rpcClientProvider).value;
    if (client == null) return;
    final nodes = plan.graph.workNodes.map((n) => n.key).toSet();
    final selected = {..._selected};
    final partial = selected.isNotEmpty && selected.length < nodes.length;
    final approvedKeys = partial
        ? planDependencyClosure(plan, selected)
        : <String>{};
    final estimate = _estimate;
    if (estimate == null) {
      setState(() => _error = l10n.mobilePlanEstimateRequired);
      return;
    }
    final high = (estimate['total_cost_cents_high'] as num?)?.toInt();
    final ceiling = (estimate['budget_ceiling_cents'] as num?)?.toInt();
    final cost = high == null
        ? l10n.mobilePlanCostUnknown
        : planMoney(context, high);
    final cap = ceiling == null
        ? l10n.mobilePlanNoHardCap
        : planMoney(context, ceiling);
    final ok = await confirmOperation(
      context,
      title: partial
          ? l10n.mobilePlanConfirmSelected
          : l10n.mobilePlanConfirmAll,
      description:
          l10n.mobilePlanExecutionConfirmation(cost, cap) +
          (partial ? '\n${l10n.mobilePlanPartialEstimate}' : ''),
      action: partial
          ? l10n.mobilePlanApproveSelected
          : l10n.mobilePlanApproveAll,
    );
    if (!ok || !mounted || !_stillAuthorized(workspaceId)) return;
    final analytics = ref.read(analyticsProvider);
    await _act(() async {
      // Never execute a plan whose revision changed while the confirmation was open.
      final current = await RemotePlanStudioRepository(
        client,
      ).getPlan(plan.id, workspaceId: workspaceId);
      if (current?.revision != plan.revision ||
          current?.status != PlanDocumentStatus.proposed) {
        throw StateError(l10n.mobilePlanChanged);
      }
      final executionId = await recordPlanDecision(
        analytics,
        RemotePlanStudioRepository(client).approvePlan(
          plan.id,
          workspaceId: workspaceId,
          approvedNodeKeys: partial ? approvedKeys : null,
          maxCostCents: ceiling,
        ),
        ('approved', plan.id, workspaceId, partial),
      );
      if (mounted) setState(() => _approvedExecutionId = executionId);
    });
  }

  Future<void> _reject(PlanDocument plan, String workspaceId) async {
    if (!_stillAuthorized(workspaceId)) return;
    final l10n = AppLocalizations.of(context);
    if (!await confirmOperation(
      context,
      title: l10n.mobilePlanReject,
      description: l10n.mobilePlanRejectConfirm,
      action: l10n.mobilePlanReject,
      destructive: true,
    )) {
      return;
    }
    if (!mounted || !_stillAuthorized(workspaceId)) return;
    await _act(
      () => recordPlanDecision(
        ref.read(analyticsProvider),
        RemotePlanStudioRepository(
          ref.read(rpcClientProvider).requireValue,
        ).updatePlanStatus(
          plan.id,
          PlanDocumentStatus.rejected,
          workspaceId: workspaceId,
        ),
        ('rejected', plan.id, workspaceId, null),
      ),
    );
  }

  Future<void> _cancelExecution(String id, String workspaceId) async {
    if (!_stillAuthorized(workspaceId)) return;
    final l10n = AppLocalizations.of(context);
    if (!await confirmOperation(
      context,
      title: l10n.mobilePlanStop,
      description: l10n.mobilePlanStopConfirm,
      action: l10n.mobilePlanStop,
      destructive: true,
    )) {
      return;
    }
    if (!mounted || !_stillAuthorized(workspaceId)) return;
    await _act(
      () => RemotePlanStudioRepository(
        ref.read(rpcClientProvider).requireValue,
      ).cancel(id, workspaceId: workspaceId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspace = ref.watch(activeWorkspaceIdProvider);
    final workspaceId = workspace.value;
    final role = ref.watch(workspaceRoleProvider).value;
    if (workspaceId != _scope) {
      _scope = workspaceId;
      _revision = null;
      _estimate = null;
      _approvedExecutionId = null;
      _selected.clear();
      _error = null;
    }
    final planAsync = workspaceId == null
        ? null
        : ref.watch(
            phonePlanProvider((
              workspaceId: workspaceId,
              planId: widget.planId,
            )),
          );
    final plan = planAsync?.value;
    if (plan != null && plan.revision != _revision) {
      _revision = plan.revision;
      _estimate = null;
      _selected.clear();
    }
    final executionAsync =
        plan != null &&
            plan.status == PlanDocumentStatus.approved &&
            workspaceId != null
        ? ref.watch(
            phonePlanExecutionProvider((
              workspaceId: workspaceId,
              planId: plan.id,
            )),
          )
        : null;
    final execution = executionAsync?.value;
    _selected.removeAll(execution?.approvedNodeKeys ?? const <String>[]);
    final canWrite = role?.canWrite ?? false;
    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          children: [
            DetailHeader(title: l10n.mobilePlanTitle),
            Expanded(
              child: PhonePlanDetailContent(
                workspace: workspace,
                workspaceId: workspaceId,
                planAsync: planAsync,
                executionAsync: executionAsync,
                selected: _selected,
                canWrite: canWrite,
                estimate: _estimate,
                error: _error,
                approvedExecutionId: _approvedExecutionId,
                busy: _busy,
                onToggle: (key) => setState(
                  () => _selected.contains(key)
                      ? _selected.remove(key)
                      : _selected.add(key),
                ),
                onClearSelection: () => setState(_selected.clear),
                onEstimate: () => _act(() async {
                  final result = await RemotePlanStudioRepository(
                    ref.read(rpcClientProvider).requireValue,
                  ).estimatePlan(plan!.id, workspaceId: workspaceId!);
                  if (mounted &&
                      ref.read(activeWorkspaceIdProvider).value ==
                          workspaceId &&
                      _revision == plan.revision) {
                    setState(() => _estimate = result);
                  }
                }),
                onApprove: () => _approve(plan!, workspaceId!),
                onReject: () => _reject(plan!, workspaceId!),
                onStop: (id) => _cancelExecution(id, workspaceId!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
