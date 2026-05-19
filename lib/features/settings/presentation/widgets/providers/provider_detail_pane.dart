import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/harness_provider_login.dart';
import 'package:control_center/features/settings/presentation/widgets/provider_plan_panel.dart';
import 'package:control_center/features/settings/presentation/widgets/providers/custom_provider_connection.dart';
import 'package:control_center/features/settings/presentation/widgets/providers/provider_confirm.dart';
import 'package:control_center/features/settings/presentation/widgets/providers/provider_generation_section.dart';
import 'package:control_center/features/settings/presentation/widgets/providers/provider_model_list.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/settings/providers/provider_policy_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The detail pane for the provider selected in the rail: its connection
/// state and credential controls on top, the models it serves in the middle
/// (the subject this surface exists for), and expert generation defaults
/// behind a disclosure at the bottom.
///
/// Replaces the old accordion tile: instead of eighteen expandable rows, the
/// reader picks one provider in the rail and everything here answers about
/// that one install.
class ProviderDetailPane extends ConsumerStatefulWidget {
  /// Creates a [ProviderDetailPane].
  const ProviderDetailPane({
    super.key,
    required this.info,
    required this.models,
    required this.catalog,
    required this.denied,
    required this.onRemoved,
  });

  /// The provider shown.
  final HarnessProviderInfo info;

  /// Its (override-merged) live model list.
  final List<HarnessModelInfo> models;

  /// The models.dev catalog, for price/context enrichment.
  final ModelCatalog? catalog;

  /// Whether a workspace policy denies `provider.use` for this id.
  final bool denied;

  /// Fired after a custom provider is removed, so the parent can reselect.
  final VoidCallback onRemoved;

  @override
  ConsumerState<ProviderDetailPane> createState() => _ProviderDetailPaneState();
}

class _ProviderDetailPaneState extends ConsumerState<ProviderDetailPane> {
  bool _busy = false;

  void _setBusy({required bool busy}) {
    if (mounted) {
      setState(() => _busy = busy);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final info = widget.info;
    final state = _state(l10n);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            info.displayName,
                            style: CcTypography.title.copyWith(
                              color: tokens.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        CcStatusTag(tone: state.tone, label: state.label),
                      ],
                    ),
                    if (_subtitle(l10n) case final subtitle?) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: CcTypography.caption.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // The workspace governance switch never leaves the top level:
              // "may agents here use this?" is the one fact that must not be
              // a disclosure away.
              Text(
                widget.denied ? l10n.denied : l10n.allowed,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CcSwitch(
                value: !widget.denied,
                semanticLabel: l10n.allowProviderSemantic(info.displayName),
                onChanged: (allow) => _setAllowed(info.id, allow),
              ),
            ],
          ),
          if (widget.denied) ...[
            const SizedBox(height: AppSpacing.md),
            CcAlert(
              title: l10n.providerDeniedHereTitle,
              variant: CcAlertVariant.warning,
              description: Text(
                l10n.providerDeniedHereBody,
                style: CcTypography.caption.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _connectionControls(),
          const SizedBox(height: AppSpacing.lg),
          const CcDivider(),
          const SizedBox(height: AppSpacing.lg),
          ProviderModelList(
            provider: info,
            models: widget.models,
            catalog: widget.catalog,
          ),
          const SizedBox(height: AppSpacing.md),
          const CcDivider(),
          ProviderGenerationSection(info: info),
          if (info.isCustom) ...[
            const CcDivider(),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: CcButton(
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                icon: AppIcons.trash2,
                onPressed: _busy ? null : _removeProvider,
                child: Text(l10n.removeProviderTooltip),
              ),
            ),
          ],
        ],
      ),
    );
  }

  ({String label, CcStatusTone tone}) _state(AppLocalizations l10n) {
    // Denied outranks connected in the marker, because the marker answers "can
    // an agent use this?" — reporting a denied provider as healthy green is the
    // one thing this pane must not do.
    if (widget.denied) {
      return (label: l10n.denied, tone: CcStatusTone.negative);
    }
    if (widget.info.enabled == HarnessProviderEnabled.disabled) {
      return (label: l10n.providerNotConnected, tone: CcStatusTone.neutral);
    }
    return (label: l10n.connectedLabel, tone: CcStatusTone.positive);
  }

  /// The one line that says how THIS install reaches the provider.
  String? _subtitle(AppLocalizations l10n) {
    final info = widget.info;
    switch (info.enabled) {
      case HarnessProviderEnabled.env:
        return l10n.enabledViaEnv(info.accountLabel ?? 'env');
      case HarnessProviderEnabled.account:
        return info.accountLabel ?? l10n.providerConnectedApiKey;
      case HarnessProviderEnabled.oauth:
        return info.accountLabel == null
            ? l10n.providerConnectedOauth
            : l10n.providerConnectedAccount(info.accountLabel!);
      case HarnessProviderEnabled.local:
        return info.baseUrl ?? l10n.providerLocalReady;
      case HarnessProviderEnabled.custom:
        return info.baseUrl;
      case HarnessProviderEnabled.disabled:
        return info.isCustom
            ? info.baseUrl
            : (info.supportsOAuth
                  ? l10n.providerNeedsSignIn
                  : l10n.providerNeedsApiKey);
    }
  }

  Widget _connectionControls() {
    final info = widget.info;
    if (info.isCustom) {
      return CustomProviderConnection(info: info);
    }

    // A connected plan reports its account and remaining quota instead of a
    // bare "connected" badge; a metered key has neither.
    final hasPlan = harnessPlanUsageIds.containsKey(info.id);
    final signedIn = info.hasCredential || info.connected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The shared login surface: the stored-credentials rotation list, the
        // add-key row and the browser-OAuth flow, each credential removable
        // from its own row.
        if (info.supportsApiKey || info.supportsOAuth)
          HarnessProviderLoginPanel(info: info),
        if (hasPlan && signedIn) ...[
          if (info.supportsApiKey) const SizedBox(height: AppSpacing.md),
          ProviderPlanPanel(
            providerId: info.id,
            accountLabel: info.accountLabel,
          ),
        ],
      ],
    );
  }

  Future<void> _setAllowed(String providerId, bool allow) async {
    final id = 'deny:$providerId';
    if (allow) {
      await deleteProviderPolicy(ref, id);
    } else {
      await upsertProviderPolicy(
        ref,
        id,
        PolicyStatement.denyProvider(providerId),
      );
    }
  }

  Future<void> _removeProvider() {
    final l10n = AppLocalizations.of(context);
    final name = widget.info.displayName;
    return confirmProviderAction(
      context,
      title: l10n.providerRemoveConfirmTitle(name),
      body: l10n.providerRemoveConfirmBody(name),
      confirmLabel: l10n.remove,
      setBusy: _setBusy,
      action: () async {
        await removeCustomHarnessProvider(ref, widget.info.id);
        widget.onRemoved();
      },
    );
  }
}
