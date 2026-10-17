import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/permission_class_row.dart';
import 'package:cc_remote/widgets/permission_special_row.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Effective decisions and the exact local rules at the selected scope.
/// Conditional grants are listed separately: a generic action-class picker
/// must never silently overwrite a remembered, argument-constrained grant.
class PermissionPolicyMatrix extends ConsumerStatefulWidget {
  const PermissionPolicyMatrix({
    super.key,
    required this.workspaceId,
    required this.scopeType,
    required this.scopeId,
    this.agentContextId,
    required this.mode,
    required this.rules,
    required this.canEdit,
  });

  final String workspaceId;
  final ActionScopeType scopeType;
  final String scopeId;
  final String? agentContextId;
  final Mode mode;
  final List<ActionPolicyRule> rules;
  final bool canEdit;

  @override
  ConsumerState<PermissionPolicyMatrix> createState() =>
      _PermissionPolicyMatrixState();
}

class _PermissionPolicyMatrixState
    extends ConsumerState<PermissionPolicyMatrix> {
  final _drafts = <ActionClass, ActionDecision>{};
  String? _revokeArmed;
  String? _busy;
  String? _error;

  bool get _authorized {
    final role = ref.read(workspaceRoleProvider).asData?.value;
    return widget.canEdit &&
        (role == WorkspaceRole.owner || role == WorkspaceRole.admin) &&
        ref.read(activeWorkspaceIdProvider).asData?.value == widget.workspaceId;
  }

  Future<void> _save(ActionClass cls, ActionPolicyRule? existing) async {
    final choice = _drafts[cls];
    if (!_authorized || choice == null || _busy != null) return;
    if (widget.rules.any(
      (r) =>
          r.workspaceId == widget.workspaceId &&
          r.scopeType == widget.scopeType &&
          r.scopeId == widget.scopeId &&
          r.actionClass == cls &&
          r.id != existing?.id,
    )) {
      setState(
        () => _error = AppLocalizations.of(context).permissionRevokeBeforeEdit,
      );
      return;
    }
    final id =
        existing?.id ??
        'ap_${widget.workspaceId}_${widget.scopeType.wire}_${widget.scopeId}_class:${cls.wire}';
    final now = DateTime.now();
    final rule = ActionPolicyRule(
      id: id,
      workspaceId: widget.workspaceId,
      scopeType: widget.scopeType,
      scopeId: widget.scopeId,
      actionClass: cls,
      decision: choice,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      createdBy: existing?.createdBy,
    );
    setState(() {
      _busy = id;
      _error = null;
    });
    try {
      // Recheck at dispatch, after any asynchronous UI interaction.
      if (!_authorized) return;
      final client = await ref.read(rpcClientProvider.future);
      if (!_authorized) return;
      await RpcActionPolicyRepository(client).upsertRule(rule);
      if (mounted) setState(() => _drafts.remove(cls));
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _revoke(ActionPolicyRule rule) async {
    if (!_authorized || _busy != null) return;
    if (_revokeArmed != rule.id) {
      setState(() => _revokeArmed = rule.id);
      return;
    }
    setState(() {
      _busy = rule.id;
      _error = null;
    });
    try {
      if (!_authorized ||
          rule.workspaceId != widget.workspaceId ||
          rule.scopeType != widget.scopeType ||
          rule.scopeId != widget.scopeId) {
        return;
      }
      final client = await ref.read(rpcClientProvider.future);
      if (!_authorized) return;
      await RpcActionPolicyRepository(
        client,
      ).deleteRule(widget.workspaceId, rule.id);
      if (mounted) setState(() => _revokeArmed = null);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final local = widget.rules
        .where(
          (r) =>
              r.workspaceId == widget.workspaceId &&
              r.scopeType == widget.scopeType &&
              r.scopeId == widget.scopeId,
        )
        .toList();
    final special = local
        .where(
          (r) =>
              r.provenance == 'remembered' ||
              r.constraint != null ||
              r.commandPrefix != null ||
              r.expiresAt != null,
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CcAlert(
              title: l.permissionChangeFailed,
              description: Text(_error!),
              variant: CcAlertVariant.danger,
            ),
          ),
        Text(
          l.permissionEffectiveDescription,
          style: CcTypography.bodySm.copyWith(color: t.textTertiary),
        ),
        if (widget.scopeType == ActionScopeType.space &&
            widget.agentContextId == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l.permissionSpaceAgentNote,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ),
        const SizedBox(height: 12),
        for (final cls in ActionClass.values)
          PermissionClassRow(
            actionClass: cls,
            rules: widget.rules,
            local: local,
            scopeType: widget.scopeType,
            scopeId: widget.scopeId,
            agentContextId: widget.agentContextId,
            mode: widget.mode,
            canEdit: widget.canEdit,
            draft: _drafts[cls],
            busy: _busy != null,
            revokeArmed: _revokeArmed,
            onDraftChanged: (choice) => setState(() => _drafts[cls] = choice),
            onSave: (plain) => _save(cls, plain),
            onRevoke: _revoke,
          ),
        if (special.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            l.permissionScopedGrants,
            style: CcTypography.body.copyWith(color: t.textPrimary),
          ),
          for (final rule in special)
            PermissionSpecialRow(
              rule: rule,
              canEdit: widget.canEdit,
              busy: _busy != null,
              revokeArmed: _revokeArmed,
              onRevoke: () => _revoke(rule),
            ),
        ],
      ],
    );
  }
}
