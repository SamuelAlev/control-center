import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The result of the model editor dialog: which model, and the override to
/// store for it. The dialog itself never calls RPC — the caller persists (the
/// provider detail pane saves over RPC; the add-provider pane collects drafts
/// and sends them with the provider).
class ModelOverrideDraft {
  /// Creates a [ModelOverrideDraft].
  const ModelOverrideDraft({
    required this.modelId,
    required this.override,
    this.reset = false,
  });

  /// The bare (provider-native) model id.
  final String modelId;

  /// The override to store. Empty-valued fields mean "inherit".
  final ProviderModelOverride override;

  /// True when the user chose "reset to automatic" — the caller removes the
  /// stored override instead of saving [override].
  final bool reset;
}

/// Opens the model editor over [context] and returns the entered draft, or
/// null when dismissed.
///
/// With [model] null this is the "add model" form: the id is editable and the
/// saved model is [ProviderModelOverride.manual]. With a [model] it edits that
/// model's override; fields prefill with the effective values (override → live
/// report → models.dev catalog) and a reset action appears when an override
/// exists.
Future<ModelOverrideDraft?> showModelEditorDialog(
  BuildContext context, {
  required String providerId,
  HarnessModelInfo? model,
  ModelCatalog? catalog,
}) {
  return showCcDialog<ModelOverrideDraft>(
    context: context,
    builder: (_) => ModelEditorDialog(
      providerId: providerId,
      model: model,
      catalog: catalog,
    ),
  );
}

/// The Z.ai-style "edit model settings" dialog: model id, context window, max
/// output tokens and the input/output modality sets.
class ModelEditorDialog extends StatefulWidget {
  /// Creates a [ModelEditorDialog].
  const ModelEditorDialog({
    super.key,
    required this.providerId,
    this.model,
    this.catalog,
  });

  /// The provider the model belongs to.
  final String providerId;

  /// The model being edited; null when adding a new one by hand.
  final HarnessModelInfo? model;

  /// The models.dev catalog, for metadata enrichment of live-reported models.
  final ModelCatalog? catalog;

  @override
  State<ModelEditorDialog> createState() => _ModelEditorDialogState();
}

class _ModelEditorDialogState extends State<ModelEditorDialog> {
  late final TextEditingController _id;
  late final TextEditingController _context;
  late final TextEditingController _maxOutput;
  late final Set<String> _input;
  late final Set<String> _output;
  String? _error;

  /// The values the model inherits from its live report / the catalog — what
  /// an empty field falls back to.
  int? _inheritedContext;
  int? _inheritedMaxOutput;
  List<String> _inheritedInput = const ['text'];
  List<String> _inheritedOutput = const ['text'];

  bool get _isAdding => widget.model == null;

  @override
  void initState() {
    super.initState();
    final model = widget.model;
    final catalogModel = model == null
        ? null
        : widget.catalog?.resolve(model.id);
    _inheritedContext = catalogModel?.limits.context;
    _inheritedMaxOutput = catalogModel?.limits.maxOutput;
    if (catalogModel != null) {
      _inheritedInput = [for (final m in catalogModel.inputModalities) m.name];
      _inheritedOutput = [
        for (final m in catalogModel.outputModalities) m.name,
      ];
    }
    // The live report / stored override outrank the catalog as "inherited".
    if (model != null) {
      _inheritedContext = model.contextWindow ?? _inheritedContext;
      _inheritedMaxOutput = model.maxOutputTokens ?? _inheritedMaxOutput;
      if (model.inputModalities.isNotEmpty) {
        _inheritedInput = model.inputModalities;
      }
      if (model.outputModalities.isNotEmpty) {
        _inheritedOutput = model.outputModalities;
      }
    }
    _id = TextEditingController(text: model?.bareId ?? '');
    _context = TextEditingController(text: _inheritedContext?.toString() ?? '');
    _maxOutput = TextEditingController(
      text: _inheritedMaxOutput?.toString() ?? '',
    );
    _input = {..._inheritedInput, 'text'};
    _output = {..._inheritedOutput, 'text'};
  }

  @override
  void dispose() {
    _id.dispose();
    _context.dispose();
    _maxOutput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return CcDialog(
      title: _isAdding ? l10n.addModel : l10n.editModelSettings,
      maxWidth: 460,
      onClose: () => Navigator.of(context).pop(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsField(
            label: l10n.modelIdLabel,
            layout: SettingsFieldLayout.stacked,
            hint: _isAdding ? null : l10n.modelIdImmutableHint,
            child: CcTextField(
              controller: _id,
              hintText: 'e.g. glm-5-turbo',
              enabled: _isAdding,
              autofocus: _isAdding,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsField(
            label: l10n.contextWindowLabel,
            layout: SettingsFieldLayout.stacked,
            child: CcTextField(
              controller: _context,
              hintText: 'e.g. 200000',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsField(
            label: l10n.providerMaxTokensLabel,
            layout: SettingsFieldLayout.stacked,
            child: CcTextField(
              controller: _maxOutput,
              hintText: 'e.g. 128000',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsField(
            label: l10n.inputTypesLabel,
            layout: SettingsFieldLayout.stacked,
            child: Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _lockedModality(l10n.modalityText),
                _modality('image', l10n.modalityImage, _input),
                _modality('audio', l10n.modalityAudio, _input),
                _modality('video', l10n.modalityVideo, _input),
                _modality('pdf', l10n.modalityPdf, _input),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsField(
            label: l10n.outputTypesLabel,
            layout: SettingsFieldLayout.stacked,
            child: Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _lockedModality(l10n.modalityText),
                _modality('image', l10n.modalityImage, _output),
                _modality('audio', l10n.modalityAudio, _output),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: CcTypography.caption.copyWith(
                color: tokens.textErrorPrimary,
              ),
            ),
          ],
        ],
      ),
      actions: [
        // Reset is meaningless on a hand-registered model: there is no
        // endpoint/catalog metadata to return to — removing it IS the undo,
        // and that affordance lives on the row.
        if ((widget.model?.hasOverride ?? false) && !widget.model!.manual)
          CcButton(
            variant: CcButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(
              ModelOverrideDraft(
                modelId: widget.model!.bareId,
                override: const ProviderModelOverride(),
                reset: true,
              ),
            ),
            child: Text(l10n.modelOverrideReset),
          ),
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }

  /// Text is always present on an LLM endpoint's model; the lock says so
  /// rather than letting the box uncheck.
  Widget _lockedModality(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CcCheckbox(value: true, onChanged: null, label: Text(label)),
        const SizedBox(width: AppSpacing.xs),
        const Icon(AppIcons.lock, size: 12),
      ],
    );
  }

  Widget _modality(String token, String label, Set<String> set) {
    return CcCheckbox(
      value: set.contains(token),
      semanticLabel: label,
      label: Text(label),
      onChanged: (checked) => setState(() {
        if (checked) {
          set.add(token);
        } else {
          set.remove(token);
        }
      }),
    );
  }

  static int? _parseCount(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final value = int.tryParse(trimmed);
    return value != null && value > 0 ? value : null;
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final modelId = _id.text.trim();
    if (_isAdding && modelId.isEmpty) {
      setState(() => _error = l10n.modelIdRequired);
      return;
    }
    // A field that fails to parse is a mistake to report, not a silent
    // "inherit" — only an EMPTY field means that.
    final contextRaw = _context.text.trim();
    final maxOutputRaw = _maxOutput.text.trim();
    final contextWindow = _parseCount(contextRaw);
    final maxOutput = _parseCount(maxOutputRaw);
    if (contextRaw.isNotEmpty && contextWindow == null) {
      setState(() => _error = l10n.modelTokensInvalid);
      return;
    }
    if (maxOutputRaw.isNotEmpty && maxOutput == null) {
      setState(() => _error = l10n.modelTokensInvalid);
      return;
    }
    final input = _ordered(_input);
    final output = _ordered(_output);
    // Fields left at the inherited value are not stored: an override says
    // only what it changes, so a models.dev refresh still flows through for
    // everything the user did not consciously pin.
    final isManual = widget.model?.manual ?? _isAdding;
    final override = ProviderModelOverride(
      contextWindow: isManual
          ? contextWindow
          : (contextWindow == _inheritedContext ? null : contextWindow),
      maxOutputTokens: isManual
          ? maxOutput
          : (maxOutput == _inheritedMaxOutput ? null : maxOutput),
      inputModalities: isManual || !_sameSet(input, _inheritedInput)
          ? input
          : const [],
      outputModalities: isManual || !_sameSet(output, _inheritedOutput)
          ? output
          : const [],
      manual: isManual,
    );
    Navigator.of(
      context,
    ).pop(ModelOverrideDraft(modelId: modelId, override: override));
  }

  static List<String> _ordered(Set<String> selected) => [
    for (final token in ProviderModelOverride.knownModalities)
      if (selected.contains(token)) token,
  ];

  static bool _sameSet(List<String> a, List<String> b) =>
      a.length == b.length && a.toSet().containsAll(b);
}
