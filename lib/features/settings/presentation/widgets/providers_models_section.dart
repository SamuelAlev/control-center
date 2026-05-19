import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/harness_provider_login.dart';
import 'package:control_center/features/settings/presentation/widgets/provider_plan_panel.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/settings/providers/model_catalog_providers.dart';
import 'package:control_center/features/settings/providers/provider_policy_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Adapters → "Providers & models" (PRD 05 + PRD 13).
///
/// Lists every provider the built-in harness can run — the built-in catalog
/// plus user-added **custom providers** (any OpenAI- or Anthropic-compatible
/// endpoint, with an optional API key): live connection state, an API-key
/// field / browser OAuth login / base URL, a workspace-scoped allow/deny
/// governance toggle, and — for connected providers — the models they serve
/// with price + context. Model lists always come live from each provider's own
/// endpoint; models.dev only enriches prices/context.
class ProvidersModelsSection extends ConsumerWidget {
  /// Creates a [ProvidersModelsSection].
  const ProvidersModelsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      headerPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      subtitle: Text(l10n.providersAndModelsDescription),
      child: providersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Center(child: CcSpinner()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(l10n.failedWithError('$e')),
        ),
        data: (providers) {
          final builtIns = [
            for (final p in providers)
              if (!p.isCustom) p,
          ];
          final customs = [
            for (final p in providers)
              if (p.isCustom) p,
          ];
          final connectedCount = providers.where((p) => p.connected).length;
          final modelCount = modelsByProvider.values.fold<int>(
            0,
            (sum, list) => sum + list.length,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.modelsCountFromProviders(
                          modelCount,
                          connectedCount,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.designSystem?.textTertiary,
                        ),
                      ),
                    ),
                    CcButton(
                      variant: CcButtonVariant.secondary,
                      icon: AppIcons.refreshCw,
                      onPressed: () {
                        refreshModelCatalog(ref);
                        ref
                          ..invalidate(harnessProvidersProvider)
                          ..invalidate(harnessModelsProvider);
                      },
                      child: Text(l10n.syncNow),
                    ),
                  ],
                ),
              ),
              for (final provider in builtIns) ...[
                const CcDivider(),
                _HarnessProviderTile(
                  info: provider,
                  models: modelsByProvider[provider.id] ?? const [],
                  catalog: catalog,
                  denied: deniedIds.contains(provider.id),
                ),
              ],
              const CcDivider(),
              _CustomProvidersHeader(),
              if (customs.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    l10n.noCustomProviders,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.designSystem?.textTertiary,
                    ),
                  ),
                ),
              for (final provider in customs) ...[
                const CcDivider(),
                _HarnessProviderTile(
                  info: provider,
                  models: modelsByProvider[provider.id] ?? const [],
                  catalog: catalog,
                  denied: deniedIds.contains(provider.id),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HarnessProviderTile extends ConsumerStatefulWidget {
  const _HarnessProviderTile({
    required this.info,
    required this.models,
    required this.catalog,
    required this.denied,
  });

  final HarnessProviderInfo info;
  final List<HarnessModelInfo> models;
  final ModelCatalog? catalog;
  final bool denied;

  @override
  ConsumerState<_HarnessProviderTile> createState() =>
      _HarnessProviderTileState();
}

class _HarnessProviderTileState extends ConsumerState<_HarnessProviderTile> {
  final _keyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _maxTokensController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _topPController = TextEditingController();
  final _topKController = TextEditingController();
  bool _expanded = false;
  bool _generationOpen = false;
  String? _generationError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _baseUrlController.text = widget.info.baseUrl ?? '';
    final gen = widget.info.generation;
    // Empty means "unset" throughout, so a blank field round-trips to null
    // rather than to a zero the endpoint would reject.
    _maxTokensController.text = gen.maxTokens?.toString() ?? '';
    _temperatureController.text = gen.temperature?.toString() ?? '';
    _topPController.text = gen.topP?.toString() ?? '';
    _topKController.text = gen.topK?.toString() ?? '';
  }

  @override
  void dispose() {
    _keyController.dispose();
    _baseUrlController.dispose();
    _maxTokensController.dispose();
    _temperatureController.dispose();
    _topPController.dispose();
    _topKController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final info = widget.info;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CcIconButton(
                icon: _expanded ? AppIcons.chevronDown : AppIcons.chevronRight,
                onPressed: widget.models.isEmpty
                    ? null
                    : () => setState(() => _expanded = !_expanded),
                tooltip: l10n.toggleDetails,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _ProvenanceBadge(info: info),
                        if (info.dialect != null)
                          CcChip(
                            label: switch (info.dialect!) {
                              CustomProviderDialect.openai =>
                                l10n.dialectOpenAiCompatible,
                              CustomProviderDialect.anthropic =>
                                l10n.dialectAnthropicCompatible,
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                widget.denied ? l10n.denied : l10n.allowed,
                style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
              ),
              const SizedBox(width: 8),
              CcSwitch(
                value: !widget.denied,
                semanticLabel: l10n.allowProviderSemantic(info.displayName),
                onChanged: (allow) => _setAllowed(info.id, allow),
              ),
              if (info.isCustom) ...[
                const SizedBox(width: 4),
                CcIconButton(
                  icon: AppIcons.trash2,
                  tooltip: l10n.removeProviderTooltip,
                  onPressed: _busy ? null : _removeProvider,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: _connectionControls(l10n),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: _generationControls(l10n, tokens),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            for (final model in widget.models)
              _ModelRow(model: model, catalog: widget.catalog),
          ],
        ],
      ),
    );
  }

  /// Keeps a button at its natural width. `CcButton` paints through a
  /// `Container` with an `alignment`, which makes it greedy: given the bounded
  /// width a Column hands down it stretches edge to edge and centres its label.
  /// A `Row` with `mainAxisSize.min` hands it unbounded width instead, so it
  /// hugs its content the way it does everywhere else in this screen.
  static Widget _hug(Widget button) =>
      Row(mainAxisSize: MainAxisSize.min, children: [button]);

  Widget _connectionControls(AppLocalizations l10n) {
    final info = widget.info;
    if (info.isCustom) {
      // Custom providers: editable base URL + optional API key (private
      // endpoints), each saved independently.
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CcTextField(
                  controller: _baseUrlController,
                  hintText: l10n.providerBaseUrlHint,
                ),
              ),
              const SizedBox(width: 8),
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: _busy ? null : _saveBaseUrl,
                child: Text(l10n.save),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CcTextField(
                  controller: _keyController,
                  hintText: info.hasCredential
                      ? l10n.providerApiKeyStoredHint
                      : l10n.providerApiKeyOptionalHint,
                  obscureText: true,
                ),
              ),
              const SizedBox(width: 8),
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: _busy ? null : _saveApiKey,
                child: Text(l10n.save),
              ),
              if (info.hasCredential) ...[
                const SizedBox(width: 8),
                CcButton(
                  variant: CcButtonVariant.destructive,
                  onPressed: _busy ? null : _remove,
                  child: Text(l10n.remove),
                ),
              ],
            ],
          ),
        ],
      );
    }

    // A connected plan reports its account and remaining quota instead of a
    // bare "connected" badge; a metered key has neither.
    final hasPlan = harnessPlanUsageIds.containsKey(info.id);
    final signedIn = info.hasCredential || info.connected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The shared login surface (API-key row and/or browser-OAuth flow).
        // For a key provider the disconnect action stays on the key row
        // beside Save; only an OAuth plan, which has no key row, carries it
        // below.
        if (info.supportsApiKey || info.supportsOAuth)
          HarnessProviderLoginPanel(
            info: info,
            keyTrailing: info.supportsApiKey && info.hasCredential
                ? CcButton(
                    variant: CcButtonVariant.destructive,
                    onPressed: _busy ? null : _remove,
                    child: Text(l10n.remove),
                  )
                : null,
          ),
        if (hasPlan && signedIn) ...[
          if (info.supportsApiKey) const SizedBox(height: 10),
          ProviderPlanPanel(
            providerId: info.id,
            accountLabel: info.accountLabel,
            trailing: info.supportsApiKey
                ? null
                : CcButton(
                    variant: CcButtonVariant.ghost,
                    size: CcButtonSize.sm,
                    onPressed: _busy ? null : _remove,
                    child: Text(l10n.providerSignOut),
                  ),
          ),
        ] else if (!info.supportsApiKey && info.hasCredential)
          _hug(
            CcButton(
              variant: CcButtonVariant.ghost,
              onPressed: _busy ? null : _remove,
              child: Text(l10n.providerSignOut),
            ),
          ),
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

  Future<void> _saveApiKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      await saveHarnessApiKey(ref, providerId: widget.info.id, apiKey: key);
      _keyController.clear();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Per-provider sampling recipe + output ceiling, collapsed by default.
  ///
  /// Collapsed because it is expert configuration: the defaults are correct for
  /// hosted APIs, and it only earns attention when running a local model that
  /// publishes its own recipe.
  Widget _generationControls(
    AppLocalizations l10n,
    DesignSystemTokens? tokens,
  ) {
    final configured = widget.info.generation.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              icon: _generationOpen
                  ? AppIcons.chevronDown
                  : AppIcons.chevronRight,
              onPressed: () =>
                  setState(() => _generationOpen = !_generationOpen),
              child: Text(l10n.providerGenerationLabel),
            ),
            if (configured) ...[
              const SizedBox(width: 6),
              // A dot, not colour alone: the setting is silent otherwise, and an
              // overridden ceiling changes every run on this provider.
              CcChip(
                label: l10n.providerGenerationOverridden,
                leadingIcon: AppIcons.slidersHorizontal,
              ),
            ],
          ],
        ),
        if (_generationOpen) ...[
          const SizedBox(height: 6),
          Text(
            l10n.providerGenerationHint,
            style: TextStyle(fontSize: 11, color: tokens?.textTertiary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _numField(l10n.providerMaxTokensLabel, _maxTokensController),
              _numField(l10n.providerTemperatureLabel, _temperatureController),
              _numField(l10n.providerTopPLabel, _topPController),
              _numField(l10n.providerTopKLabel, _topKController),
            ],
          ),
          if (_generationError != null) ...[
            const SizedBox(height: 6),
            Text(
              _generationError!,
              style: TextStyle(fontSize: 11, color: tokens?.textErrorPrimary),
            ),
          ],
          const SizedBox(height: 8),
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            onPressed: _busy ? null : _saveGeneration,
            child: Text(l10n.save),
          ),
        ],
      ],
    );
  }

  Widget _numField(String label, TextEditingController controller) => SizedBox(
    width: 150,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 4),
        CcTextField(controller: controller, hintText: '—'),
      ],
    ),
  );

  Future<void> _saveGeneration() async {
    final maxTokens = _parseInt(_maxTokensController.text);
    final temperature = _parseDouble(_temperatureController.text);
    final topP = _parseDouble(_topPController.text);
    final topK = _parseInt(_topKController.text);
    final l10n = AppLocalizations.of(context);
    // Validate client-side so a typo does not need a server round trip to be
    // reported. The op validates again — the client is not the boundary.
    final invalid =
        (maxTokens != null && maxTokens <= 0) ||
        (topK != null && topK <= 0) ||
        (temperature != null && (temperature < 0 || temperature > 2)) ||
        (topP != null && (topP <= 0 || topP > 1)) ||
        _isMalformed(_maxTokensController.text, maxTokens) ||
        _isMalformed(_temperatureController.text, temperature) ||
        _isMalformed(_topPController.text, topP) ||
        _isMalformed(_topKController.text, topK);
    if (invalid) {
      setState(() => _generationError = l10n.providerGenerationInvalid);
      return;
    }
    setState(() {
      _generationError = null;
      _busy = true;
    });
    try {
      await saveHarnessGenerationDefaults(
        ref,
        providerId: widget.info.id,
        maxTokens: maxTokens,
        temperature: temperature,
        topP: topP,
        topK: topK,
      );
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.providerGenerationSaved, variant: CcToastVariant.success);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _generationError = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// True when the user typed something that is not a number — otherwise a typo
  /// would silently clear the field instead of reporting the mistake.
  static bool _isMalformed(String raw, num? parsed) =>
      raw.trim().isNotEmpty && parsed == null;

  static int? _parseInt(String raw) =>
      raw.trim().isEmpty ? null : int.tryParse(raw.trim());

  static double? _parseDouble(String raw) =>
      raw.trim().isEmpty ? null : double.tryParse(raw.trim());

  Future<void> _saveBaseUrl() async {
    setState(() => _busy = true);
    try {
      await saveHarnessApiKey(
        ref,
        providerId: widget.info.id,
        apiKey: '',
        baseUrl: _baseUrlController.text.trim().isEmpty
            ? null
            : _baseUrlController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Confirms a destructive credential action, then runs it.
  ///
  /// Disconnecting is not undoable from here — an API key is not shown again
  /// after saving, and an OAuth plan needs the whole browser login repeated —
  /// and it silently strands every agent pinned to one of the provider's
  /// models. Cheap to confirm, expensive to misclick.
  Future<void> _confirmDestructive({
    required String title,
    required String body,
    required String confirmLabel,
    required Future<void> Function() action,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: title,
        content: Text(body),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _remove() {
    final l10n = AppLocalizations.of(context);
    final name = widget.info.displayName;
    // An OAuth plan is "signed out of"; a stored key is "removed". Same
    // consequence, but the word has to match what the user thinks they did.
    final oauth = widget.info.enabled == HarnessProviderEnabled.oauth;
    return _confirmDestructive(
      title: oauth
          ? l10n.providerSignOutConfirmTitle(name)
          : l10n.providerRemoveKeyConfirmTitle(name),
      body: oauth
          ? l10n.providerSignOutConfirmBody(name)
          : l10n.providerRemoveKeyConfirmBody(name),
      confirmLabel: oauth ? l10n.providerSignOut : l10n.remove,
      action: () => removeHarnessCredential(ref, providerId: widget.info.id),
    );
  }

  Future<void> _removeProvider() {
    final l10n = AppLocalizations.of(context);
    final name = widget.info.displayName;
    return _confirmDestructive(
      title: l10n.providerRemoveConfirmTitle(name),
      body: l10n.providerRemoveConfirmBody(name),
      confirmLabel: l10n.remove,
      action: () => removeCustomHarnessProvider(ref, widget.info.id),
    );
  }
}

/// A human-readable badge for a harness provider's connection provenance.
class _ProvenanceBadge extends StatelessWidget {
  const _ProvenanceBadge({required this.info});

  final HarnessProviderInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (info.enabled) {
      case HarnessProviderEnabled.env:
        return CcBadge(
          label: l10n.enabledViaEnv(info.accountLabel ?? 'env'),
          variant: CcBadgeVariant.success,
        );
      case HarnessProviderEnabled.account:
        return CcBadge(
          label: l10n.providerConnectedApiKey,
          variant: CcBadgeVariant.success,
        );
      case HarnessProviderEnabled.oauth:
        return CcBadge(
          label: info.accountLabel == null
              ? l10n.providerConnectedOauth
              : l10n.providerConnectedAccount(info.accountLabel!),
          variant: CcBadgeVariant.success,
        );
      case HarnessProviderEnabled.local:
        return CcBadge(
          label: l10n.providerLocalReady,
          variant: CcBadgeVariant.success,
        );
      case HarnessProviderEnabled.custom:
        return CcBadge(
          label: l10n.enabledLabel,
          variant: CcBadgeVariant.success,
        );
      case HarnessProviderEnabled.disabled:
        return CcBadge(
          label: l10n.providerNotConnected,
          variant: CcBadgeVariant.neutral,
        );
    }
  }
}

class _ModelRow extends StatelessWidget {
  const _ModelRow({required this.model, required this.catalog});

  final HarnessModelInfo model;
  final ModelCatalog? catalog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    // Prefer the live price the provider served; otherwise enrich from the
    // models.dev catalog by resolving the qualified id.
    final catalogModel = catalog?.resolve(model.id);
    final inputCost = model.inputCostPerMTokens ?? catalogModel?.cost?.input;
    final outputCost = model.outputCostPerMTokens ?? catalogModel?.cost?.output;
    final context0 = model.contextWindow ?? catalogModel?.limits.context;
    return Padding(
      padding: const EdgeInsets.only(left: 44, top: 6, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  model.displayName ?? model.id,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (inputCost != null && outputCost != null)
                Text(
                  l10n.costPerMillion(
                    '\$${inputCost.toStringAsFixed(2)}',
                    '\$${outputCost.toStringAsFixed(2)}',
                  ),
                  style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
                ),
            ],
          ),
          if (context0 != null) ...[
            const SizedBox(height: 4),
            CcChip(label: l10n.contextTokens(_compactTokens(context0))),
          ],
        ],
      ),
    );
  }

  static String _compactTokens(int tokens) {
    if (tokens >= 1000000) {
      final m = tokens / 1000000;
      return '${m == m.roundToDouble() ? m.toInt() : m.toStringAsFixed(1)}M';
    }
    if (tokens >= 1000) {
      return '${(tokens / 1000).round()}k';
    }
    return '$tokens';
  }
}

/// The "Custom providers" subsection header: title, explainer, add button.
class _CustomProvidersHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.customProviders,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.customProvidersDescription,
                  style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CcButton(
            variant: CcButtonVariant.secondary,
            icon: AppIcons.plus,
            onPressed: () => showCcDialog<void>(
              context: context,
              builder: (_) => const _AddCustomProviderDialog(),
            ),
            child: Text(l10n.addProvider),
          ),
        ],
      ),
    );
  }
}

/// Dialog for registering a custom provider: name, wire dialect, base URL,
/// and an optional API key for private endpoints.
class _AddCustomProviderDialog extends ConsumerStatefulWidget {
  const _AddCustomProviderDialog();

  @override
  ConsumerState<_AddCustomProviderDialog> createState() =>
      _AddCustomProviderDialogState();
}

class _AddCustomProviderDialogState
    extends ConsumerState<_AddCustomProviderDialog> {
  final _nameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _keyController = TextEditingController();
  CustomProviderDialect _dialect = CustomProviderDialect.openai;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    return CcDialog(
      title: l10n.addProvider,
      maxWidth: 440,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _fieldLabel(l10n.providerNameLabel, tokens),
          CcTextField(controller: _nameController, hintText: 'e.g. Ollama'),
          const SizedBox(height: 12),
          _fieldLabel(l10n.apiTypeLabel, tokens),
          CcSelect<CustomProviderDialect>(
            options: [
              CcSelectOption(
                value: CustomProviderDialect.openai,
                label: l10n.dialectOpenAiCompatible,
              ),
              CcSelectOption(
                value: CustomProviderDialect.anthropic,
                label: l10n.dialectAnthropicCompatible,
              ),
            ],
            value: _dialect,
            onChanged: (d) => setState(() => _dialect = d),
          ),
          const SizedBox(height: 12),
          _fieldLabel(l10n.providerBaseUrlLabel, tokens),
          CcTextField(
            controller: _baseUrlController,
            hintText: 'http://localhost:11434/v1',
          ),
          const SizedBox(height: 12),
          _fieldLabel(l10n.providerApiKeyOptionalHint, tokens),
          CcTextField(
            controller: _keyController,
            hintText: l10n.providerApiKeyHint,
            obscureText: true,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              l10n.failedWithError(_error!),
              style: TextStyle(fontSize: 12, color: tokens?.textErrorPrimary),
            ),
          ],
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: _busy ? null : _submit,
          child: Text(l10n.addProvider),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text, DesignSystemTokens? tokens) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, color: tokens?.textSecondary),
    ),
  );

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    if (name.isEmpty || baseUrl.isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await addCustomHarnessProvider(
        ref,
        displayName: name,
        dialect: _dialect,
        baseUrl: baseUrl,
        apiKey: _keyController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
