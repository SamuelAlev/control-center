import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/permission_providers.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/permission_audit.dart';
import 'package:cc_remote/widgets/permission_policy_matrix.dart';
import 'package:cc_remote/widgets/permission_scope_selector.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkspacePermissions extends ConsumerStatefulWidget {
  const WorkspacePermissions({super.key, required this.workspaceId});
  final String workspaceId;

  @override
  ConsumerState<WorkspacePermissions> createState() =>
      _WorkspacePermissionsState();
}

class _WorkspacePermissionsState extends ConsumerState<WorkspacePermissions> {
  ActionScopeType _scope = ActionScopeType.workspace;
  String? _target;
  String? _agentContext;
  late final Timer _expiryTick;

  @override
  void initState() {
    super.initState();
    _expiryTick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _expiryTick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final role = ref.watch(workspaceRoleProvider);
    final policies = role.asData?.value?.atLeast(WorkspaceRole.member) == true
        ? ref.watch(permissionRulesProvider(widget.workspaceId))
        : null;
    final (
      List<CcSelectOption<String>>? choices,
      Object? targetError,
    ) = switch (_scope) {
      ActionScopeType.agent =>
        ref
            .watch(agentsProvider)
            .when(
              data: (agents) => (
                <CcSelectOption<String>>[
                  for (final a in agents)
                    if (a.workspaceId == widget.workspaceId)
                      CcSelectOption(value: a.id, label: a.name),
                ],
                null,
              ),
              loading: () => (null, null),
              error: (e, _) => (null, e),
            ),
      ActionScopeType.space =>
        ref
            .watch(spacesProvider)
            .when(
              data: (spaces) => (
                <CcSelectOption<String>>[
                  for (final s in spaces)
                    if (s.workspaceId == widget.workspaceId)
                      CcSelectOption(value: s.id, label: s.name),
                ],
                null,
              ),
              loading: () => (null, null),
              error: (e, _) => (null, e),
            ),
      ActionScopeType.workspace => (null, null),
    };
    final agentData = _scope == ActionScopeType.space
        ? ref.watch(agentsProvider)
        : null;
    final agents = agentData?.asData?.value;
    final agentOptions = <CcSelectOption<String>>[
      if (agents != null)
        for (final agent in agents)
          if (agent.workspaceId == widget.workspaceId)
            CcSelectOption(value: agent.id, label: agent.name),
    ];
    final agentContextId =
        agentOptions.any((option) => option.value == _agentContext)
        ? _agentContext
        : null;
    final target = choices == null || choices.isEmpty
        ? null
        : choices.any((c) => c.value == _target)
        ? _target
        : choices.first.value;
    final space = _scope == ActionScopeType.space && target != null
        ? ref
              .watch(spacesProvider)
              .asData
              ?.value
              .where(
                (s) => s.id == target && s.workspaceId == widget.workspaceId,
              )
              .firstOrNull
        : null;
    final scopeId = _scope == ActionScopeType.workspace ? '' : target;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PermissionScopeSelector(
          scope: _scope,
          choices: choices,
          targetError: targetError,
          target: target,
          agentData: agentData,
          agentOptions: agentOptions,
          agentContextId: agentContextId,
          onScopeChanged: (choice) => setState(() {
            _scope = choice;
            _target = null;
            _agentContext = null;
          }),
          onTargetChanged: (value) => setState(() => _target = value),
          onAgentContextChanged: (value) =>
              setState(() => _agentContext = value),
        ),
        switch (role) {
          AsyncError(error: final error) => CcAlert(
            title: l.permissionRoleFailed,
            description: Text('$error'),
            variant: CcAlertVariant.danger,
            action: CcButton(
              size: CcButtonSize.lg,
              onPressed: () => ref.invalidate(workspaceRoleProvider),
              child: Text(l.retry),
            ),
          ),
          AsyncData(value: final WorkspaceRole? value)
              when value == null || !value.atLeast(WorkspaceRole.member) =>
            CcAlert(
              title: l.permissionMemberRequired,
              variant: CcAlertVariant.warning,
            ),
          AsyncData(value: final WorkspaceRole value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (scopeId != null &&
                  (_scope != ActionScopeType.space ||
                      agentData?.asData != null))
                switch (policies) {
                  AsyncData(value: final rules) => PermissionPolicyMatrix(
                    key: ValueKey(
                      '${widget.workspaceId}:${_scope.wire}:$scopeId:$agentContextId',
                    ),
                    workspaceId: widget.workspaceId,
                    scopeType: _scope,
                    scopeId: scopeId,
                    agentContextId: agentContextId,
                    mode: Mode.fromDbValue(space?.mode),
                    rules: rules,
                    canEdit:
                        value == WorkspaceRole.owner ||
                        value == WorkspaceRole.admin,
                  ),
                  AsyncError(error: final error) => CcAlert(
                    title: l.permissionRulesFailed,
                    description: Text('$error'),
                    variant: CcAlertVariant.danger,
                    action: CcButton(
                      size: CcButtonSize.lg,
                      onPressed: () => ref.invalidate(
                        permissionRulesProvider(widget.workspaceId),
                      ),
                      child: Text(l.retry),
                    ),
                  ),
                  _ => Text(
                    l.permissionLoading,
                    style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                  ),
                },
              const SizedBox(height: 24),
              if (value == WorkspaceRole.owner || value == WorkspaceRole.admin)
                PermissionAudit(workspaceId: widget.workspaceId)
              else
                Text(
                  l.permissionAuditAdminOnly,
                  style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                ),
            ],
          ),
          _ => Text(
            l.permissionLoading,
            style: CcTypography.bodySm.copyWith(color: t.textTertiary),
          ),
        },
      ],
    );
  }
}
