import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/providers/add_provider_pane.dart';
import 'package:control_center/features/settings/presentation/widgets/providers/provider_detail_pane.dart';
import 'package:control_center/features/settings/presentation/widgets/providers/provider_rail.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/settings/providers/model_catalog_providers.dart';
import 'package:control_center/features/settings/providers/provider_policy_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Providers → providers and models (master-detail).
///
/// Rail: built-in + custom providers (status, connected first). Pane: one
/// provider — credentials/OAuth, quota, allow/deny, models. Model lists from
/// the provider endpoint merged with stored overrides; models.dev for
/// prices/context only. Count first; model list always on screen.
class ProvidersModelsSection extends ConsumerStatefulWidget {
  /// Creates a [ProvidersModelsSection].
  const ProvidersModelsSection({super.key});

  @override
  ConsumerState<ProvidersModelsSection> createState() =>
      _ProvidersModelsSectionState();
}

class _ProvidersModelsSectionState
    extends ConsumerState<ProvidersModelsSection> {
  static const _insets = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

  String _query = '';

  /// The selected provider id; null means "auto" (first connected, else first
  /// in the list). Auto keeps a sensible pane showing across provider-list
  /// refreshes without pinning a stale id.
  String? _selectedId;

  /// Whether the add-provider form is showing in the detail pane.
  bool _addingProvider = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final providersAsync = ref.watch(harnessProvidersProvider);
    final modelsAsync = ref.watch(harnessModelsProvider);
    final catalog = ref.watch(rawModelCatalogProvider).asData?.value;
    final policies =
        ref.watch(workspaceProviderPoliciesProvider).asData?.value ??
        const <WorkspaceProviderPolicy>[];

    // Provider ids explicitly denied by a workspace `deny provider.use <id>`.
    final deniedIds = <String>{
      for (final p in policies)
        if (p.statement.effect == PolicyEffect.deny &&
            p.statement.action == 'provider.use' &&
            !p.statement.resource.contains('*') &&
            !p.statement.resource.contains('?'))
          p.statement.resource,
    };

    // Group the live model list by provider id.
    final modelsByProvider = <String, List<HarnessModelInfo>>{};
    for (final model
        in modelsAsync.asData?.value ?? const <HarnessModelInfo>[]) {
      modelsByProvider.putIfAbsent(model.providerId, () => []).add(model);
    }

    return SectionCard(
      label: l10n.providersAndModels,
      count: providersAsync.asData?.value.length,
      subtitle: Text(l10n.providersAndModelsDescription),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      headerPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      trailing: CcIconButton(
        icon: AppIcons.refreshCw,
        size: CcButtonSize.sm,
        tooltip: l10n.syncNow,
        onPressed: () {
          refreshModelCatalog(ref);
          ref
            ..invalidate(harnessProvidersProvider)
            ..invalidate(harnessModelsProvider);
        },
      ),
      child: providersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Center(child: CcSpinner()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: CcAlert(
            title: l10n.failedWithError('$e'),
            variant: CcAlertVariant.danger,
          ),
        ),
        data: (providers) => _body(
          context,
          l10n,
          providers,
          modelsByProvider,
          catalog,
          deniedIds,
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    List<HarnessProviderInfo> providers,
    Map<String, List<HarnessModelInfo>> modelsByProvider,
    ModelCatalog? catalog,
    Set<String> deniedIds,
  ) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final connectedCount = providers.where(_isConnected).length;

    // Selection: the pinned id when it still exists, else the first connected
    // provider, else the first row — there is always at least one built-in.
    final selected = _addingProvider || providers.isEmpty
        ? null
        : providers.firstWhereOrNull((p) => p.id == _selectedId) ??
              providers.where(_isConnected).firstOrNull ??
              providers.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The counts the strip used to carry (connected, models, denied) are
        // all per-row state the rail already shows. The one thing it said that
        // the rail cannot is the consequence of an empty list, so that stays.
        if (connectedCount == 0) ...[
          Padding(
            padding: _insets,
            child: Text(
              l10n.providersNoneConnectedNote,
              style: CcTypography.caption.copyWith(
                color: tokens.textTertiary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        const CcDivider(),
        SettingsMasterDetail(
          rail: ProviderRail(
            providers: providers,
            deniedIds: deniedIds,
            query: _query,
            onQueryChanged: (q) => setState(() => _query = q),
            selectedId: selected?.id,
            addingProvider: _addingProvider,
            onSelected: (id) => setState(() {
              _selectedId = id;
              _addingProvider = false;
            }),
            onAddProvider: () => setState(() {
              _addingProvider = true;
            }),
          ),
          detail: _addingProvider || selected == null
              ? AddProviderPane(
                  onAdded: (id) => setState(() {
                    _addingProvider = false;
                    _selectedId = id;
                  }),
                  onCancel: () => setState(() {
                    _addingProvider = false;
                  }),
                )
              : ProviderDetailPane(
                  key: ValueKey(selected.id),
                  info: selected,
                  models:
                      modelsByProvider[selected.id] ??
                      const <HarnessModelInfo>[],
                  catalog: catalog,
                  denied: deniedIds.contains(selected.id),
                  onRemoved: () => setState(() {
                    _selectedId = null;
                  }),
                ),
        ),
      ],
    );
  }

  static bool _isConnected(HarnessProviderInfo info) =>
      info.enabled != HarnessProviderEnabled.disabled;
}
