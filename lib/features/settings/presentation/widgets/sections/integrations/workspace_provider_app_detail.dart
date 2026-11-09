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

/// The expanded body of one workspace provider app row: whose app the
/// workspace uses, and, for its own app, the credential fields (secrets
/// write-only) and the callback URLs to register.
class WorkspaceProviderAppDetail extends ConsumerWidget {
  /// Creates the detail for [app].
  const WorkspaceProviderAppDetail({
    super.key,
    required this.app,
    required this.onModeSelected,
  });

  /// The app being edited.
  final WorkspaceProviderAppView app;

  /// Asks to switch whose app the workspace uses (the row confirms first).
  final ValueChanged<WorkspaceAppMode> onModeSelected;

  Future<void> _save(WidgetRef ref, String field, String value) =>
      saveWorkspaceProviderApp(ref, app.provider, {field: value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final own = app.mode == WorkspaceAppMode.own;
    final missing = [
      for (final (label, set) in workspaceProviderAppRequired(l10n, app))
        if (!set) label,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final mode in WorkspaceAppMode.values)
          _ModeOption(
            mode: mode,
            selected: app.mode,
            title: _modeTitle(l10n, mode),
            hint: mode == WorkspaceAppMode.own
                ? l10n.workspaceProviderAppModeOwnHint
                : l10n.workspaceProviderAppModeInheritHint,
            onSelected: onModeSelected,
          ),
        if (own) ...[
          if (app.state == ProviderAppState.partial && missing.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            // Half-configured is an error, not a fallback: the server turns
            // the provider off here rather than use its own app instead.
            CcAlert(
              title: l10n.providerAppPartial,
              description: Text(
                l10n.workspaceProviderAppMissingFields(missing.join(', ')),
              ),
              variant: CcAlertVariant.danger,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            title: workspaceProviderAppName(app.provider),
            description: app.provider == 'klipy'
                ? l10n.workspaceProviderAppKlipyHint
                : l10n.workspaceProviderAppClientChangeHint,
            gap: AppSpacing.md,
            children: [..._fields(l10n, ref), ..._callbacks(l10n)],
          ),
        ],
      ],
    );
  }

  String _modeTitle(AppLocalizations l10n, WorkspaceAppMode mode) =>
      mode == WorkspaceAppMode.own
      ? l10n.workspaceProviderAppModeOwn
      : l10n.workspaceProviderAppModeInherit;

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

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.selected,
    required this.title,
    required this.hint,
    required this.onSelected,
  });

  final WorkspaceAppMode mode;
  final WorkspaceAppMode selected;
  final String title;
  final String hint;
  final ValueChanged<WorkspaceAppMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      onTap: () => onSelected(mode),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CcRadio<WorkspaceAppMode>(
              value: mode,
              groupValue: selected,
              onChanged: onSelected,
              semanticLabel: title,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CcTypography.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                  Text(
                    hint,
                    style: CcTypography.caption.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
