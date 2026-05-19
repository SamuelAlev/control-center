import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/providers/model_edit_dialog.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "Add model provider" form shown in the detail pane when the rail's
/// add row is selected: name, base URL, API key, wire dialect and an initial
/// model list.
///
/// Models are optional here — the server probes the endpoint's own `/models`
/// once connected and lists what it serves; the hand-registered list is for
/// endpoints that cannot enumerate their own (a bare inference server, a
/// gateway with listing disabled), which is exactly the case the Z.ai-style
/// form is for.
class AddProviderPane extends ConsumerStatefulWidget {
  /// Creates an [AddProviderPane].
  const AddProviderPane({
    super.key,
    required this.onAdded,
    required this.onCancel,
  });

  /// Fired with the new provider's id once the server accepted it.
  final ValueChanged<String> onAdded;

  /// Fired when the reader abandons the form (back to the selected provider).
  final VoidCallback onCancel;

  @override
  ConsumerState<AddProviderPane> createState() => _AddProviderPaneState();
}

class _AddProviderPaneState extends ConsumerState<AddProviderPane> {
  final _name = TextEditingController();
  final _baseUrl = TextEditingController();
  final _key = TextEditingController();
  CustomProviderDialect _dialect = CustomProviderDialect.openai;

  /// Hand-registered models, keyed by bare id — insertion-ordered.
  final Map<String, ProviderModelOverride> _drafts = {};

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.addModelProviderTitle,
            style: CcTypography.title.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.addModelProviderDescription,
            style: CcTypography.caption.copyWith(color: tokens.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xl),
          SettingsField(
            label: l10n.providerNameLabel,
            layout: SettingsFieldLayout.stacked,
            child: CcTextField(
              controller: _name,
              hintText: 'e.g. DeepSeek',
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsField(
            label: l10n.providerBaseUrlLabel,
            layout: SettingsFieldLayout.stacked,
            child: CcTextField(
              controller: _baseUrl,
              hintText: 'https://api.example.com/v1',
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsField(
            label: l10n.providerApiKeyLabel,
            optional: true,
            layout: SettingsFieldLayout.stacked,
            child: CcTextField(
              controller: _key,
              hintText: l10n.providerApiKeyHint,
              obscureText: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsField(
            label: l10n.apiTypeLabel,
            layout: SettingsFieldLayout.stacked,
            child: CcSelect<CustomProviderDialect>(
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
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Text(
                l10n.modelListTitle,
                style: CcTypography.bodySm.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_drafts.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${_drafts.length}',
                  style: CcFonts.code(
                    textStyle: CcTypography.caption.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              CcButton(
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                icon: AppIcons.plus,
                onPressed: _busy ? null : _addDraft,
                child: Text(l10n.addModel),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_drafts.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: tokens.borderSecondary),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.info, size: 15, color: tokens.textTertiary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.modelListEmptyHint,
                      style: CcTypography.caption.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < _drafts.length; i++) ...[
              if (i > 0) const CcDivider(),
              _DraftRow(
                modelId: _drafts.keys.elementAt(i),
                modelOverride: _drafts.values.elementAt(i),
                onEdit: () => _editDraft(_drafts.keys.elementAt(i)),
                onRemove: () =>
                    setState(() => _drafts.remove(_drafts.keys.elementAt(i))),
              ),
            ],
          const SizedBox(height: AppSpacing.xl),
          const CcDivider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _error ?? l10n.addProviderModelsHint,
                  style: CcTypography.caption.copyWith(
                    color: _error != null
                        ? tokens.textErrorPrimary
                        : tokens.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              CcButton(
                onPressed: _busy || !_valid ? null : _submit,
                loading: _busy,
                child: Text(l10n.addProvider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _valid {
    if (_name.text.trim().isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(_baseUrl.text.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> _addDraft() async {
    final draft = await showModelEditorDialog(context, providerId: 'custom');
    if (draft != null) {
      setState(() => _drafts[draft.modelId] = draft.override);
    }
  }

  Future<void> _editDraft(String modelId) async {
    final existing = _drafts[modelId]!;
    // Synthesize the wire shape so the same editor dialog opens pre-filled;
    // the id stays locked, as it does for listed models.
    final draft = await showModelEditorDialog(
      context,
      providerId: 'custom',
      model: HarnessModelInfo(
        id: 'custom/$modelId',
        providerId: 'custom',
        contextWindow: existing.contextWindow,
        maxOutputTokens: existing.maxOutputTokens,
        inputModalities: existing.inputModalities,
        outputModalities: existing.outputModalities,
        manual: true,
      ),
    );
    if (draft != null) {
      setState(() => _drafts[draft.modelId] = draft.override);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await addCustomHarnessProvider(
        ref,
        displayName: _name.text.trim(),
        dialect: _dialect,
        baseUrl: _baseUrl.text.trim(),
        apiKey: _key.text.trim().isEmpty ? null : _key.text.trim(),
        models: _drafts.isEmpty ? null : Map.of(_drafts),
      );
      if (mounted) {
        widget.onAdded(id);
      }
    } on Object catch (e) {
      setState(() => _error = l10n.failedWithError('$e'));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({
    required this.modelId,
    required this.modelOverride,
    required this.onEdit,
    required this.onRemove,
  });

  final String modelId;
  final ProviderModelOverride modelOverride;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              modelId,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.bodySm.copyWith(color: tokens.textPrimary),
            ),
          ),
          if (modelOverride.contextWindow != null)
            Text(
              l10n.contextTokens('${modelOverride.contextWindow}'),
              style: CcFonts.code(
                textStyle: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.xs),
          CcIconButton(
            icon: AppIcons.pencil,
            size: CcButtonSize.sm,
            tooltip: l10n.editModelSettings,
            onPressed: onEdit,
          ),
          CcIconButton(
            icon: AppIcons.trash2,
            size: CcButtonSize.sm,
            tooltip: l10n.removeModelAction,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
