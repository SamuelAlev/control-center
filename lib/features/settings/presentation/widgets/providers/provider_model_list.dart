import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/providers/model_edit_dialog.dart';
import 'package:control_center/features/settings/presentation/widgets/providers/provider_confirm.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The model list of one provider: a heading with the count and the
/// "Add model" action, its own filter once it gets long, then one row per
/// model — name, context window, price, and the edit/remove affordances.
///
/// A provider like OpenRouter serves several hundred ids. Past a dozen the list
/// stops being something you read and becomes something you look something up
/// in, and those need different controls.
class ProviderModelList extends ConsumerStatefulWidget {
  /// Creates a [ProviderModelList].
  const ProviderModelList({
    super.key,
    required this.provider,
    required this.models,
    required this.catalog,
  });

  /// The provider these models belong to.
  final HarnessProviderInfo provider;

  /// The models it reported (override-merged server-side).
  final List<HarnessModelInfo> models;

  /// The models.dev catalog, used only to enrich price and context.
  final ModelCatalog? catalog;

  @override
  ConsumerState<ProviderModelList> createState() => _ProviderModelListState();
}

class _ProviderModelListState extends ConsumerState<ProviderModelList> {
  static const _filterThreshold = 12;
  String _query = '';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final query = _query.trim().toLowerCase();
    final matches = query.isEmpty
        ? widget.models
        : [
            for (final m in widget.models)
              if (m.id.toLowerCase().contains(query) ||
                  (m.displayName ?? '').toLowerCase().contains(query))
                m,
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              l10n.modelListTitle,
              style: CcTypography.bodySm.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${widget.models.length}',
              style: CcFonts.code(
                textStyle: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
            const Spacer(),
            CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              icon: AppIcons.plus,
              onPressed: _busy ? null : _addModel,
              child: Text(l10n.addModel),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (widget.models.length > _filterThreshold) ...[
          CcTextField(
            hintText: l10n.providerModelsFilterHint,
            size: CcTextFieldSize.sm,
            prefix: Icon(AppIcons.search, size: 15, color: tokens.fgQuaternary),
            onChanged: (q) => setState(() => _query = q),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (matches.isEmpty && query.isNotEmpty)
          Text(
            l10n.providersNoneMatch,
            style: CcTypography.caption.copyWith(color: tokens.textTertiary),
          )
        else if (widget.models.isEmpty)
          Text(
            widget.provider.isCustom
                ? l10n.modelListEmptyHint
                : l10n.providerNoModelsYet,
            style: CcTypography.caption.copyWith(color: tokens.textTertiary),
          )
        else
          for (var i = 0; i < matches.length; i++) ...[
            if (i > 0) const CcDivider(),
            _ModelRow(
              provider: widget.provider,
              model: matches[i],
              catalog: widget.catalog,
              busy: _busy,
              onBusy: (busy) => setState(() => _busy = busy),
            ),
          ],
      ],
    );
  }

  Future<void> _addModel() async {
    final l10n = AppLocalizations.of(context);
    final draft = await showModelEditorDialog(
      context,
      providerId: widget.provider.id,
      catalog: widget.catalog,
    );
    if (draft == null || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await saveHarnessModelOverride(
        ref,
        providerId: widget.provider.id,
        modelId: draft.modelId,
        override: draft.override,
      );
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

class _ModelRow extends ConsumerWidget {
  const _ModelRow({
    required this.provider,
    required this.model,
    required this.catalog,
    required this.busy,
    required this.onBusy,
  });

  final HarnessProviderInfo provider;
  final HarnessModelInfo model;
  final ModelCatalog? catalog;
  final bool busy;
  final ValueChanged<bool> onBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    // Prefer the live price the provider served; otherwise enrich from the
    // models.dev catalog by resolving the qualified id.
    final catalogModel = catalog?.resolve(model.id);
    final inputCost = model.inputCostPerMTokens ?? catalogModel?.cost?.input;
    final outputCost = model.outputCostPerMTokens ?? catalogModel?.cost?.output;
    final contextWindow = model.contextWindow ?? catalogModel?.limits.context;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            // A Wrap, not a Row: under narrow widths (or wide translations)
            // the badges flow under the name instead of overflowing the row.
            child: Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  model.displayName ?? model.bareId,
                  style: CcTypography.bodySm.copyWith(
                    color: tokens.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (model.manual)
                  CcChip(label: l10n.manualModelBadge)
                else if (model.hasOverride)
                  SettingsModifiedBadge(label: l10n.modelOverrideEdited),
              ],
            ),
          ),
          // Context and price are right-aligned in fixed columns: a model list
          // is a price table, and a table you cannot scan down is just prose.
          SizedBox(
            width: 64,
            child: contextWindow == null
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.centerRight,
                    child: _ContextPill(label: _compactTokens(contextWindow)),
                  ),
          ),
          SizedBox(
            width: 118,
            child: inputCost == null || outputCost == null
                ? const SizedBox.shrink()
                : Text(
                    l10n.costPerMillion(
                      '\$${inputCost.toStringAsFixed(2)}',
                      '\$${outputCost.toStringAsFixed(2)}',
                    ),
                    textAlign: TextAlign.end,
                    style: CcFonts.code(
                      textStyle: CcTypography.caption.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.xs),
          CcIconButton(
            icon: AppIcons.pencil,
            size: CcButtonSize.sm,
            tooltip: l10n.editModelSettings,
            onPressed: busy ? null : () => _edit(context, ref),
          ),
          if (model.manual)
            CcIconButton(
              icon: AppIcons.trash2,
              size: CcButtonSize.sm,
              tooltip: l10n.removeModelAction,
              onPressed: busy ? null : () => _remove(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final draft = await showModelEditorDialog(
      context,
      providerId: provider.id,
      model: model,
      catalog: catalog,
    );
    if (draft == null || !context.mounted) {
      return;
    }
    onBusy(true);
    try {
      if (draft.reset) {
        await removeHarnessModelOverride(
          ref,
          providerId: provider.id,
          modelId: draft.modelId,
        );
      } else {
        await saveHarnessModelOverride(
          ref,
          providerId: provider.id,
          modelId: draft.modelId,
          override: draft.override,
        );
      }
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    } finally {
      onBusy(false);
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return confirmProviderAction(
      context,
      title: l10n.removeModelConfirmTitle(model.bareId),
      body: l10n.removeModelConfirmBody,
      confirmLabel: l10n.remove,
      setBusy: ({required bool busy}) => onBusy(busy),
      action: () => removeHarnessModelOverride(
        ref,
        providerId: provider.id,
        modelId: model.bareId,
      ),
    );
  }

  static String _compactTokens(int tokens) {
    if (tokens >= 1000000) {
      final m = tokens / 1000000;
      return m == m.roundToDouble()
          ? '${m.toStringAsFixed(0)}M'
          : '${m.toStringAsFixed(1)}M';
    }
    if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(0)}K';
    }
    return '$tokens';
  }
}

/// The context-window badge on a model row — a small mono capsule, the one
/// number that decides whether a model fits the job.
class _ContextPill extends StatelessWidget {
  const _ContextPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: CcFonts.code(
            textStyle: CcTypography.caption.copyWith(
              color: tokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
