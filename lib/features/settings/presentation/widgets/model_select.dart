import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder shown when a dropdown cannot render (no adapter selected,
/// loading, error, or empty model list).
class FieldPlaceholder extends StatelessWidget {
  /// Creates a [FieldPlaceholder].
  const FieldPlaceholder({super.key, required this.text});

  /// Placeholder text to display.
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border.all(color: tokens?.borderSecondary ?? Colors.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: tokens?.textTertiary, fontSize: 13),
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
  });

  /// The selected adapter id, or `null` if none.
  final String? adapterId;

  /// The currently selected model id, or `null`.
  final String? selectedModelId;

  /// Called when the user selects or enters a model id.
  final ValueChanged<String?> onChange;

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
      loading: () => FieldPlaceholder(text: l10n.loadingModels),
      error: (e, _) => FieldPlaceholder(text: l10n.failedWithError('$e')),
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
