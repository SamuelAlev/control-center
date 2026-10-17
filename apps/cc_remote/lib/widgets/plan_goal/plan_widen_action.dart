import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/plan_goal/confirm_operation.dart';
import 'package:cc_remote/widgets/plan_goal/plan_review.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Releases selected suspended work nodes on an executing partial plan.
class PhonePlanWidenAction extends ConsumerStatefulWidget {
  const PhonePlanWidenAction({
    super.key,
    required this.plan,
    required this.execution,
    required this.workspaceId,
    required this.selected,
    required this.onCleared,
  });

  final PlanDocument plan;
  final OrchestrationDto execution;
  final String workspaceId;
  final Set<String> selected;
  final VoidCallback onCleared;

  @override
  ConsumerState<PhonePlanWidenAction> createState() =>
      _PhonePlanWidenActionState();
}

class _PhonePlanWidenActionState extends ConsumerState<PhonePlanWidenAction> {
  bool _busy = false;
  String? _error;

  Future<void> _widen() async {
    final l10n = AppLocalizations.of(context);
    final oldKeys = widget.execution.approvedNodeKeys?.toSet();
    if (oldKeys == null) return;
    final selected = widget.selected.difference(oldKeys);
    if (selected.isEmpty) return;
    final next = <String>{...oldKeys};
    void add(String key) {
      if (!next.add(key)) return;
      for (final dependency
          in widget.plan.graph.node(key)?.dependsOn ?? const <String>[]) {
        add(dependency);
      }
    }

    for (final key in selected) {
      add(key);
    }
    final additions = next.difference(oldKeys);
    final cap = widget.execution.maxCostCents;
    final label = cap == null
        ? l10n.mobilePlanNoHardCap
        : planMoney(context, cap);
    final count = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(additions.length);
    final confirmed = await confirmOperation(
      context,
      title: l10n.mobilePlanWiden,
      description: l10n.mobilePlanWidenConfirm(count, label),
      action: l10n.mobilePlanWiden,
    );
    if (!confirmed ||
        !mounted ||
        ref.read(activeWorkspaceIdProvider).value != widget.workspaceId ||
        !(ref.read(workspaceRoleProvider).value?.canWrite ?? false)) {
      return;
    }
    final client = ref.read(rpcClientProvider).value;
    if (client == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await RemotePlanStudioRepository(client).approveNodes(
        widget.execution.id,
        additions,
        workspaceId: widget.workspaceId,
      );
      if (mounted) widget.onCleared();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final role = ref.watch(workspaceRoleProvider).value;
    if (!(role?.canWrite ?? false) ||
        widget.selected.isEmpty ||
        widget.execution.approvedNodeKeys == null ||
        !const {
          'executing',
          'synthesizing',
        }.contains(widget.execution.status)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) Text(_error!, style: TextStyle(color: t.danger)),
          CcButton(
            fullWidth: true,
            size: CcButtonSize.lg,
            loading: _busy,
            onPressed: _busy ? null : _widen,
            child: Text(l10n.mobilePlanWiden),
          ),
        ],
      ),
    );
  }
}
