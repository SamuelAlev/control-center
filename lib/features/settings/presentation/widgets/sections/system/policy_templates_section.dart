import 'dart:convert';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/providers/governance_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Starting postures and policy portability.
///
/// A workspace otherwise starts at the built-in defaults and an admin has to
/// re-derive the same thirteen decisions by hand, per workspace — which is
/// how a policy surface ends up configured once and never again. Export/import
/// carries a posture between workspaces (and between installs) as plain JSON:
/// a posture, not rows, so importing mints fresh rules rather than colliding.
class PolicyTemplatesSection extends ConsumerStatefulWidget {
  /// Creates a [PolicyTemplatesSection].
  const PolicyTemplatesSection({super.key});

  @override
  ConsumerState<PolicyTemplatesSection> createState() =>
      _PolicyTemplatesSectionState();
}

class _PolicyTemplatesSectionState
    extends ConsumerState<PolicyTemplatesSection> {
  String _template = 'balanced';
  bool _busy = false;

  /// Runs [action] and reports its outcome.
  ///
  /// The toast is shown HERE rather than inside each action so there is one
  /// `mounted` check on this State after the await, instead of a BuildContext
  /// captured across an async gap in every closure.
  Future<void> _run(
    Future<String?> Function(String workspaceId) action,
  ) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final message = await action(workspaceId);
      if (mounted && message != null) {
        CcToastScope.of(context).show(message);
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show(
          AppLocalizations.of(context).failedWithError('$e'),
          variant: CcToastVariant.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    // Policy is admin-gated server-side; render the controls honestly rather
    // than offering an action that ends in a refusal. The demo server denies
    // the whole `action_policy.` family (its lockdown is exactly the posture
    // that must not be editable from inside the demo), so the controls are
    // inert there rather than failing on press.
    final isDemo = ref.watch(isDemoServerProvider);
    final isAdmin =
        !isDemo &&
        workspaceId != null &&
        (ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false);

    return SectionCard(
      label: l10n.policyTemplatesLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.policyTemplatesDescription,
            style: CcTypography.bodySm.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: CcSelect<String>(
                  semanticLabel: l10n.policyTemplatesLabel,
                  enabled: isAdmin && !_busy,
                  value: _template,
                  options: [
                    CcSelectOption(
                      value: 'strict',
                      label: l10n.policyTemplateStrict,
                    ),
                    CcSelectOption(
                      value: 'balanced',
                      label: l10n.policyTemplateBalanced,
                    ),
                    CcSelectOption(
                      value: 'permissive',
                      label: l10n.policyTemplatePermissive,
                    ),
                  ],
                  onChanged: (value) => setState(() => _template = value),
                ),
              ),
              const SizedBox(width: 8),
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: isAdmin && !_busy
                    ? () => _run((ws) async {
                        final applied = await applyPolicyTemplate(
                          ref.read(rpcClientProvider),
                          workspaceId: ws,
                          template: _template,
                        );
                        return l10n.policyTemplateApplied(applied);
                      })
                    : null,
                child: Text(l10n.policyTemplateApply),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CcButton(
                variant: CcButtonVariant.ghost,
                onPressed: isAdmin && !_busy
                    ? () => _run((ws) async {
                        final policy = await exportPolicy(
                          ref.read(rpcClientProvider),
                          workspaceId: ws,
                        );
                        await Clipboard.setData(
                          ClipboardData(text: jsonEncode(policy)),
                        );
                        return l10n.policyExported;
                      })
                    : null,
                child: Text(l10n.policyExport),
              ),
              const SizedBox(width: 8),
              CcButton(
                variant: CcButtonVariant.ghost,
                onPressed: isAdmin && !_busy
                    ? () => _run((ws) async {
                        final data = await Clipboard.getData(
                          Clipboard.kTextPlain,
                        );
                        final text = data?.text ?? '';
                        if (text.isEmpty) {
                          return null;
                        }
                        final decoded = jsonDecode(text);
                        if (decoded is! List) {
                          throw const FormatException(
                            'expected a JSON array of rules',
                          );
                        }
                        final imported = await importPolicy(
                          ref.read(rpcClientProvider),
                          workspaceId: ws,
                          policy: decoded,
                        );
                        return l10n.policyImported(imported);
                      })
                    : null,
                child: Text(l10n.policyImport),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
