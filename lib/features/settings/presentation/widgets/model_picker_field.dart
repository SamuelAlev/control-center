import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/field_placeholder.dart';
import 'package:control_center/features/settings/presentation/widgets/model_browser_dialog.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The model field of a form: shows the chosen model and opens the
/// [ModelBrowserDialog] to change it.
///
/// Wears the same field chrome as a [CcSelect] trigger so it sits in a
/// settings row without reading as a different kind of control. The ✕ unsets;
/// a custom (unlisted) id is displayed verbatim.
class ModelPickerField extends ConsumerWidget {
  /// Creates a [ModelPickerField].
  const ModelPickerField({
    super.key,
    required this.adapterId,
    required this.selectedModelId,
    required this.onChange,
    this.enabled = true,
  });

  /// The selected adapter id, or null if none.
  final String? adapterId;

  /// The currently selected model id, or null.
  final String? selectedModelId;

  /// Called with the chosen model id, or null when cleared.
  final ValueChanged<String?> onChange;

  /// Whether the field is interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (adapterId == null) {
      return FieldPlaceholder(text: l10n.selectAdapterFirst);
    }
    final modelsAsync = ref.watch(adapterModelsProvider(adapterId));
    return modelsAsync.when(
      loading: () => FieldPlaceholder(
        text: l10n.loadingModels,
        kind: FieldPlaceholderKind.loading,
      ),
      error: (e, _) => FieldPlaceholder(
        text: l10n.failedWithError('$e'),
        kind: FieldPlaceholderKind.error,
      ),
      data: (models) {
        if (models.isEmpty && selectedModelId == null) {
          return FieldPlaceholder(
            text: adapterId == 'cc-harness'
                ? l10n.harnessConnectProviderForModels
                : l10n.noModelsAdvertised,
          );
        }
        final selected = models
            .where((m) => m.id == selectedModelId)
            .firstOrNull;
        // A custom id (not advertised by the adapter) still names the saved
        // model; showing it verbatim beats showing an empty field.
        final label = selected?.name ?? selectedModelId;
        return _Trigger(
          label: label,
          hintText: l10n.selectModel,
          enabled: enabled,
          onClear: label == null ? null : () => onChange(null),
          clearLabel: l10n.clear,
          onPressed: () async {
            final picked = await showModelBrowserDialog(
              context: context,
              adapterId: adapterId,
              selectedModelId: selectedModelId,
            );
            if (picked != null) {
              onChange(picked);
            }
          },
        );
      },
    );
  }
}

/// The closed field: CcSelect trigger chrome with a search glyph, since it
/// opens a browsing dialog rather than dropping a panel in place.
class _Trigger extends StatelessWidget {
  const _Trigger({
    required this.label,
    required this.hintText,
    required this.enabled,
    required this.onPressed,
    required this.clearLabel,
    this.onClear,
  });

  final String? label;
  final String hintText;
  final bool enabled;
  final VoidCallback onPressed;
  final String clearLabel;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final input = CcInputTokens.resolve(t);
    return CcTappable(
      onPressed: enabled ? onPressed : null,
      borderRadius: AppRadii.brSm,
      semanticLabel: label ?? hintText,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: !enabled
                ? t.bgDisabled
                : hovered
                ? t.bgSecondaryHover
                : input.bg,
            border: Border(
              bottom: BorderSide(
                color: enabled ? input.border : t.borderDisabled,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: CcTruncatedText(
                  label ?? hintText,
                  style: CcTypography.bodySm.copyWith(
                    color: !enabled
                        ? t.textDisabled
                        : label != null
                        ? input.text
                        : input.placeholder,
                  ),
                ),
              ),
              AppSpacing.hGapSm,
              if (enabled && onClear != null) ...[
                CcTappable(
                  onPressed: onClear,
                  borderRadius: AppRadii.brSm,
                  semanticLabel: clearLabel,
                  builder: (context, states) => Icon(
                    CcIcons.x,
                    size: 14,
                    color: states.contains(WidgetState.hovered)
                        ? t.textSecondary
                        : t.fgTertiary,
                  ),
                ),
                AppSpacing.hGapSm,
              ],
              Icon(
                CcIcons.search,
                size: 14,
                color: enabled ? t.fgTertiary : t.fgDisabled,
              ),
            ],
          ),
        );
      },
    );
  }
}
