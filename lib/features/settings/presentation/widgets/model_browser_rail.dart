import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/providers/model_browser_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/ai_brand_logo.dart';
import 'package:flutter/widgets.dart';

/// The model browser's provider rail: "All models", then one row per provider
/// with its logo and how many of its models match the live search.
class ModelBrowserRail extends StatelessWidget {
  /// Creates a [ModelBrowserRail].
  const ModelBrowserRail({
    required this.groups,
    required this.query,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  /// Every provider group, in display order.
  final List<ModelBrowserGroup> groups;

  /// The live search text the counts reflect.
  final String query;

  /// The selected provider id; null for "All models".
  final String? selectedId;

  /// Fired with a provider id, or null for "All models".
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = groups.fold<int>(0, (n, g) => n + g.matchCount(query));
    return CcScrollArea(
      fadeColor: context.ds.panel,
      child: ListView(
        children: [
          _item(context, label: l10n.allModels, count: total, id: null),
          for (final g in groups)
            _item(context, label: g.name, count: g.matchCount(query), id: g.id),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required String label,
    required int count,
    required String? id,
  }) {
    final t = context.ds;
    final selected = selectedId == id;
    return CcTappable(
      onPressed: () => onSelected(id),
      borderRadius: AppRadii.brSm,
      semanticLabel: label,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final ink = selected ? t.textPrimary : t.textSecondary;
        return Container(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 10, 7),
          decoration: BoxDecoration(
            color: selected
                ? t.accentSoft
                : hovered
                ? t.bgSecondaryHover
                : null,
            borderRadius: AppRadii.brSm,
          ),
          child: Row(
            children: [
              if (id == null)
                Icon(CcIcons.layers, size: 14, color: ink)
              else
                AiBrandLogo(brand: AiBrand.forProvider(id), color: ink),
              AppSpacing.hGapSm,
              Expanded(
                child: CcTruncatedText(
                  label,
                  style: CcTypography.bodySm.copyWith(color: ink),
                ),
              ),
              AppSpacing.hGapSm,
              Text(
                '$count',
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ],
          ),
        );
      },
    );
  }
}
