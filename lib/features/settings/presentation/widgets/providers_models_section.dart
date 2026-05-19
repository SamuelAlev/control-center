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

/// Settings → Providers → "Providers and models" (PRD 05 + PRD 13).
///
/// A master-detail surface in the Z.ai model-settings pattern: the rail on the
/// left lists every provider the built-in harness can run — the built-in
/// catalog plus user-added **custom providers** (any OpenAI- or Anthropic-
/// compatible endpoint, with an optional API key) — with a live status dot
/// each, and the pane on the right answers for the selected one: connection
/// state, credentials / browser OAuth, plan quota, the workspace allow/deny
/// toggle and the model list, where every model can be edited (context window,
/// output ceiling, modalities) or hand-registered for endpoints that cannot
/// enumerate their own.
///
/// Model lists always come live from each provider's own endpoint, merged with
/// the stored per-model overrides; models.dev only enriches prices/context.
///
/// ## Why it looks like this
///
/// The previous version rendered every provider fully expanded: eighteen
/// API-key rows, eighteen collapsed sampling panels, eighteen allow switches,
/// in catalog order. Finding the two you had actually connected meant reading
/// all eighteen, and the one number that decides whether anything works at all
/// — how many are connected — was a sentence in 12px grey above the pile. The
/// accordion then replaced it, but expanding one provider still pushed the rest
/// of the page around, and the model list hid a level deep behind a disclosure.
///
/// So: the count comes first, the rail keeps every provider visible at once
/// (connected sort to the top), and the detail pane owns one provider at a
/// time — with the model list, the subject this surface exists for, always on
/// screen.
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
