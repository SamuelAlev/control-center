import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/provider_app_fields.dart';
import 'package:control_center/features/settings/providers/provider_apps_providers.dart';
import 'package:control_center/features/settings/providers/workspace_provider_apps_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The provider's name as people know it; brand names stay untranslated.
String workspaceProviderAppName(String provider) => switch (provider) {
  'google' => 'Google Calendar',
  'linear' => 'Linear',
  'klipy' => 'Klipy',
  _ => provider,
};

/// The fields [app]'s own app needs, as `(label, set)`, for naming what a
/// half-configured app is still missing.
List<(String, bool)> workspaceProviderAppRequired(
  AppLocalizations l10n,
  WorkspaceProviderAppView app,
) => switch (app.provider) {
  'google' => [
    (l10n.providerClientId, app.clientId.isNotEmpty),
    (l10n.providerClientSecret, app.hasClientSecret),
  ],
  'linear' => [(l10n.providerClientId, app.clientId.isNotEmpty)],
  'klipy' => [(l10n.workspaceProviderAppKlipyKey, app.hasAppKey)],
  _ => const [],
};

/// One provider's own app in a workspace on its own apps: what a
/// half-configured app still lacks, the credential fields (secrets
/// write-only) and the callback URLs to register.
class WorkspaceProviderAppDetail extends ConsumerWidget {
  /// Creates the detail for [app].
  const WorkspaceProviderAppDetail({super.key, required this.app});

  /// The app being edited.
  final WorkspaceProviderAppView app;

  Future<void> _save(WidgetRef ref, String field, String value) =>
      saveWorkspaceProviderApp(ref, app.provider, {field: value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final missing = [
      for (final (label, set) in workspaceProviderAppRequired(l10n, app))
        if (!set) label,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (app.state == ProviderAppState.partial && missing.isNotEmpty) ...[
          // Half-configured is an error, not a fallback: the server turns
          // the provider off here rather than use another app instead.
          CcAlert(
            title: l10n.providerAppPartial,
            description: Text(
              l10n.workspaceProviderAppMissingFields(missing.join(', ')),
            ),
            variant: CcAlertVariant.danger,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        // Untitled: the card around it already names the provider.
        SettingsGroup(
          description: app.provider == 'klipy'
              ? l10n.workspaceProviderAppKlipyHint
              : l10n.workspaceProviderAppClientChangeHint,
          gap: AppSpacing.md,
          children: [..._fields(l10n, ref), ..._callbacks(l10n)],
        ),
      ],
    );
  }

  List<Widget> _fields(AppLocalizations l10n, WidgetRef ref) => [
    if (app.provider != 'klipy')
      ProviderAppSecretField(
        title: l10n.providerClientId,
        value: app.clientId,
        onSet: (v) => _save(ref, 'client_id', v),
      ),
    if (app.provider == 'google')
      ProviderAppSecretField(
        title: l10n.providerClientSecret,
        configured: app.hasClientSecret,
        secret: true,
        onSet: (v) => _save(ref, 'client_secret', v),
      ),
    if (app.provider == 'linear')
      ProviderAppSecretField(
        title: l10n.providerServiceApiKey,
        configured: app.hasApiKey,
        secret: true,
        onSet: (v) => _save(ref, 'api_key', v),
      ),
    if (app.provider == 'klipy')
      ProviderAppSecretField(
        title: l10n.workspaceProviderAppKlipyKey,
        configured: app.hasAppKey,
        secret: true,
        onSet: (v) => _save(ref, 'app_key', v),
      ),
  ];

  List<Widget> _callbacks(AppLocalizations l10n) => [
    if (app.redirectUris.isNotEmpty)
      // Shown verbatim: the provider compares the callback byte for byte.
      SettingsField(
        label: app.redirectUris.length == 1
            ? l10n.providerCallbackUrl
            : l10n.providerCallbackUrls,
        description: l10n.providerCallbackUrlHint,
        layout: SettingsFieldLayout.stacked,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < app.redirectUris.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.xs),
              SettingsCopyField(value: app.redirectUris[i]),
            ],
          ],
        ),
      ),
  ];
}
