import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/providers/provider_confirm.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The connection controls for a user-added provider: an editable base URL and
/// an optional API key for private endpoints, each saved independently.
///
/// Independently because they fail independently — a wrong URL and a wrong key
/// produce different errors, and making them one form would mean re-entering a
/// write-only secret to fix a typo in a hostname.
class CustomProviderConnection extends ConsumerStatefulWidget {
  /// Creates a [CustomProviderConnection].
  const CustomProviderConnection({super.key, required this.info});

  /// The custom provider being edited.
  final HarnessProviderInfo info;

  @override
  ConsumerState<CustomProviderConnection> createState() =>
      _CustomProviderConnectionState();
}

class _CustomProviderConnectionState
    extends ConsumerState<CustomProviderConnection> {
  final _key = TextEditingController();
  late final _baseUrl = TextEditingController(text: widget.info.baseUrl ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _key.dispose();
    _baseUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final info = widget.info;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsField(
          label: l10n.providerBaseUrlLabel,
          layout: SettingsFieldLayout.stacked,
          child: Row(
            children: [
              Expanded(
                child: CcTextField(
                  controller: _baseUrl,
                  hintText: l10n.providerBaseUrlHint,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: _busy ? null : _saveBaseUrl,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsField(
          label: l10n.providerApiKeyLabel,
          optional: true,
          layout: SettingsFieldLayout.stacked,
          hint: info.hasCredential ? l10n.providerApiKeyStoredHint : null,
          child: Row(
            children: [
              Expanded(
                child: CcTextField(
                  controller: _key,
                  hintText: info.hasCredential
                      ? l10n.providerApiKeyStoredHint
                      : l10n.providerApiKeyOptionalHint,
                  obscureText: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: _busy ? null : _saveApiKey,
                child: Text(l10n.save),
              ),
              if (info.hasCredential) ...[
                const SizedBox(width: AppSpacing.sm),
                CcButton(
                  variant: CcButtonVariant.destructive,
                  onPressed: _busy ? null : _removeKey,
                  child: Text(l10n.remove),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _setBusy({required bool busy}) {
    if (mounted) {
      setState(() => _busy = busy);
    }
  }

  Future<void> _saveApiKey() async {
    final key = _key.text.trim();
    if (key.isEmpty) {
      return;
    }
    _setBusy(busy: true);
    try {
      await saveHarnessApiKey(ref, providerId: widget.info.id, apiKey: key);
      _key.clear();
    } finally {
      _setBusy(busy: false);
    }
  }

  Future<void> _saveBaseUrl() async {
    _setBusy(busy: true);
    try {
      await saveHarnessApiKey(
        ref,
        providerId: widget.info.id,
        apiKey: '',
        baseUrl: _baseUrl.text.trim().isEmpty ? null : _baseUrl.text.trim(),
      );
    } finally {
      _setBusy(busy: false);
    }
  }

  Future<void> _removeKey() {
    final l10n = AppLocalizations.of(context);
    final name = widget.info.displayName;
    return confirmProviderAction(
      context,
      title: l10n.providerRemoveKeyConfirmTitle(name),
      body: l10n.providerRemoveKeyConfirmBody(name),
      confirmLabel: l10n.remove,
      setBusy: _setBusy,
      action: () => removeHarnessCredential(ref, providerId: widget.info.id),
    );
  }
}
