import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scope and optional agent context for the effective-policy view.
class PermissionScopeSelector extends ConsumerWidget {
  const PermissionScopeSelector({
    super.key,
    required this.scope,
    required this.choices,
    required this.targetError,
    required this.target,
    required this.agentData,
    required this.agentOptions,
    required this.agentContextId,
    required this.onScopeChanged,
    required this.onTargetChanged,
    required this.onAgentContextChanged,
  });

  final ActionScopeType scope;
  final List<CcSelectOption<String>>? choices;
  final Object? targetError;
  final String? target;
  final AsyncValue<List<AgentDto>>? agentData;
  final List<CcSelectOption<String>> agentOptions;
  final String? agentContextId;
  final ValueChanged<ActionScopeType> onScopeChanged;
  final ValueChanged<String> onTargetChanged;
  final ValueChanged<String?> onAgentContextChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.permissionScopeDescription,
          style: CcTypography.bodySm.copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: 12),
        Text(
          l.permissionScope,
          style: CcTypography.caption.copyWith(color: t.textSecondary),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 48,
          child: CcSelect<ActionScopeType>(
            value: scope,
            options: [
              CcSelectOption(
                value: ActionScopeType.workspace,
                label: l.permissionWorkspaceScope,
              ),
              CcSelectOption(
                value: ActionScopeType.agent,
                label: l.permissionAgentScope,
              ),
              CcSelectOption(
                value: ActionScopeType.space,
                label: l.permissionSpaceScope,
              ),
            ],
            onChanged: onScopeChanged,
          ),
        ),
        if (scope != ActionScopeType.workspace) ...[
          const SizedBox(height: 12),
          if (targetError != null)
            CcAlert(
              title: l.permissionTargetsFailed,
              description: Text('$targetError'),
              variant: CcAlertVariant.danger,
              action: CcButton(
                size: CcButtonSize.lg,
                onPressed: () => ref.invalidate(
                  scope == ActionScopeType.agent
                      ? agentsProvider
                      : spacesProvider,
                ),
                child: Text(l.retry),
              ),
            )
          else if (choices == null)
            Text(
              l.permissionLoading,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            )
          else if (choices!.isEmpty)
            Text(
              l.permissionNoTargets,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  scope == ActionScopeType.agent
                      ? l.permissionAgentScope
                      : l.permissionSpaceScope,
                  style: CcTypography.caption.copyWith(color: t.textSecondary),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 48,
                  child: CcSelect<String>(
                    value: target,
                    options: choices!,
                    onChanged: onTargetChanged,
                  ),
                ),
              ],
            ),
        ],
        if (scope == ActionScopeType.space && target != null) ...[
          const SizedBox(height: 12),
          if (agentData?.asError case final failure?)
            CcAlert(
              title: l.permissionTargetsFailed,
              description: Text('${failure.error}'),
              variant: CcAlertVariant.danger,
              action: CcButton(
                size: CcButtonSize.lg,
                onPressed: () => ref.invalidate(agentsProvider),
                child: Text(l.retry),
              ),
            )
          else if (agentData?.asData == null)
            Text(
              l.permissionLoading,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.permissionAgentContext,
                  style: CcTypography.caption.copyWith(color: t.textSecondary),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 48,
                  child: CcSelect<String>(
                    value: agentContextId ?? '',
                    options: [
                      CcSelectOption(
                        value: '',
                        label: l.permissionNoAgentContext,
                      ),
                      ...agentOptions,
                    ],
                    onChanged: (value) =>
                        onAgentContextChanged(value.isEmpty ? null : value),
                  ),
                ),
              ],
            ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}
