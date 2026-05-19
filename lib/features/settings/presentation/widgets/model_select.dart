import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Why a [FieldPlaceholder] stands in for its dropdown.
enum FieldPlaceholderKind {
  /// Nothing to pick from yet, and only the user can change that (no adapter
  /// selected, or the adapter advertises no models). Wears disabled chrome.
  idle,

  /// The list is on its way. Wears the live field's chrome so resolving into
  /// the real dropdown is not a visual jump.
  loading,

  /// The list could not be fetched.
  error,
}

/// The stand-in for a dropdown that cannot render yet (no adapter selected,
/// models still loading, the fetch failed, or an empty list).
///
/// It must wear the cc_ui field box — a quiet fill closed by a 1px bottom
/// underline, 12/10 padding and `bodySm` text, no radius and no side chrome —
/// because it stands in a row beside real [CcSelect] triggers: anything else
/// reads as a different kind of control, and any hardcoded height drifts from
/// the trigger's as the tokens move.
///
/// [kind] carries the state in the chrome — a spinner while loading, the
/// field's error tint and outline on failure — so the reason is never left to
/// the sentence alone.
class FieldPlaceholder extends StatelessWidget {
  /// Creates a [FieldPlaceholder].
  const FieldPlaceholder({
    super.key,
    required this.text,
    this.kind = FieldPlaceholderKind.idle,
  });

  /// Placeholder text to display.
  final String text;

  /// Why the dropdown is absent.
  final FieldPlaceholderKind kind;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final input = CcInputTokens.resolve(t);
    final isError = kind == FieldPlaceholderKind.error;
    final isIdle = kind == FieldPlaceholderKind.idle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? input.bgError
            : isIdle
            ? t.bgDisabled
            : input.bg,
        border: Border(
          bottom: BorderSide(
            color: isError
                ? input.borderError
                : isIdle
                ? t.borderDisabled
                : input.border,
          ),
        ),
      ),
      // The 2px danger outline the fields draw on error, over the whole box.
      foregroundDecoration: isError
          ? BoxDecoration(
              border: Border.all(color: input.borderError, width: 2),
            )
          : null,
      child: Row(
        children: [
          if (kind == FieldPlaceholderKind.loading) ...[
            CcSpinner(
              size: 13,
              strokeWidth: 1.5,
              color: t.fgTertiary,
              semanticLabel: text,
            ),
            AppSpacing.hGapSm,
          ] else if (isError) ...[
            Icon(CcIcons.circleX, size: 14, color: t.danger),
            AppSpacing.hGapSm,
          ],
          Expanded(
            // An adapter error carries the upstream message, which is long
            // more often than not: truncate and disclose the rest on hover
            // rather than letting it blow the row's height out.
            child: CcTruncatedText(
              text,
              style: CcTypography.bodySm.copyWith(
                // The field's own hint color, not `textDisabled`: this is
                // guidance the reader needs in order to act ("select an
                // adapter first"), so it holds the AA floor rather than taking
                // the contrast exemption an inert control would be allowed.
                color: isError ? t.danger : input.placeholder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Autocomplete-based model selector for an adapter. Supports free-text
/// entry for model IDs not in the advertised list.
class ModelSelect extends ConsumerStatefulWidget {
  /// Creates a [ModelSelect].
  const ModelSelect({
    super.key,
    required this.adapterId,
    required this.selectedModelId,
    required this.onChange,
    this.enabled = true,
  });

  /// The selected adapter id, or `null` if none.
  final String? adapterId;

  /// The currently selected model id, or `null`.
  final String? selectedModelId;

  /// Called when the user selects or enters a model id.
  final ValueChanged<String?> onChange;

  /// Whether the field is interactive. False renders it read-only rather than
  /// accepting edits that go nowhere — the workspace-scoped model is
  /// admin-gated server-side, and a field that silently discards a
  /// non-admin's entry looks saved.
  final bool enabled;

  @override
  ConsumerState<ModelSelect> createState() => _ModelSelectState();
}

class _ModelSelectState extends ConsumerState<ModelSelect> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedModelId ?? '');
  }

  @override
  void didUpdateWidget(covariant ModelSelect old) {
    super.didUpdateWidget(old);
    if (widget.selectedModelId != old.selectedModelId &&
        widget.selectedModelId != _controller.text) {
      // Defer to avoid mutating the controller during build: setting the text
      // synchronously triggers the autocomplete overlay's show() while we are
      // still in the persistent-callbacks phase, which asserts.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.selectedModelId != _controller.text) {
          _controller.text = widget.selectedModelId ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.adapterId == null) {
      return FieldPlaceholder(text: l10n.selectAdapterFirst);
    }
    final modelsAsync = ref.watch(adapterModelsProvider(widget.adapterId));
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
        if (models.isEmpty) {
          return FieldPlaceholder(
            text: widget.adapterId == 'cc-harness'
                ? l10n.harnessConnectProviderForModels
                : l10n.noModelsAdvertised,
          );
        }
        return SizedBox(
          width: double.infinity,
          child: CcAutocomplete<String>(
            controller: _controller,
            enabled: widget.enabled,
            hintText: l10n.searchOrTypeModel,
            options: [
              for (final m in models) CcSelectOption(value: m.id, label: m.id),
            ],
            // Combo box: listed models commit via onSelected; free-text model
            // ids (not advertised by the adapter) commit on Enter, Tab, or
            // clicking outside; the ✕ unsets.
            onSelected: widget.onChange,
            onCustomValue: widget.onChange,
            onCleared: () => widget.onChange(null),
          ),
        );
      },
    );
  }
}
