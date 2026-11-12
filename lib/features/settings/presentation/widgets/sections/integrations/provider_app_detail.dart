import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/provider_app_fields.dart';
import 'package:control_center/features/settings/providers/provider_apps_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The fields one provider's own app needs, as `(wire field, label, set)`,
/// in the order the form shows them. The server's `partial` state means some
/// of these are set and some are not; the missing ones are named back.
List<(String, String, bool)> providerAppFields(
  AppLocalizations l10n,
  ProviderAppStatusView app,
) => switch (app.provider) {
  'github' => [
    ('app_id', l10n.providerAppId, app.appId.isNotEmpty),
    ('private_key', l10n.providerPrivateKey, app.hasPrivateKey),
    ('client_id', l10n.providerClientId, app.clientId.isNotEmpty),
    ('client_secret', l10n.providerClientSecret, app.hasClientSecret),
  ],
  'google' => [
    ('client_id', l10n.providerClientId, app.clientId.isNotEmpty),
    ('client_secret', l10n.providerClientSecret, app.hasClientSecret),
  ],
  'linear' => [
    ('client_id', l10n.providerClientId, app.clientId.isNotEmpty),
    ('api_key', l10n.providerServiceApiKey, app.hasApiKey),
  ],
  _ => const [],
};

/// The expanded body of one provider app row: its fields, the callback URLs
/// to register, and for GitHub the one-click App creation.
class ProviderAppDetail extends ConsumerWidget {
  /// Creates the detail for [app].
  const ProviderAppDetail({super.key, required this.app});

  /// The app being edited.
  final ProviderAppStatusView app;

  Future<void> _save(WidgetRef ref, String field, String value) =>
      saveProviderApp(ref, app.provider, {field: value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fields = providerAppFields(l10n, app);
    final missing = [
      for (final (_, label, set) in fields)
        if (!set) label,
    ];
    final isGitHub = app.provider == 'github';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (app.state == ProviderAppState.partial && missing.isNotEmpty) ...[
          // A half-configured app is an error, not a fallback: the server
          // refuses the lane rather than quietly using Connect instead.
          CcAlert(
            title: l10n.providerAppPartial,
            description: Text(
              l10n.providerAppMissingFields(missing.join(', ')),
            ),
            variant: CcAlertVariant.danger,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (app.error.isNotEmpty) ...[
          CcAlert(title: app.error, variant: CcAlertVariant.danger),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (isGitHub) ...[
          if (app.state != ProviderAppState.complete) ...[
            const _CreateGitHubApp(),
            const SizedBox(height: AppSpacing.lg),
          ],
          SettingsGroup(
            title: l10n.providerAppsGroupServer,
            description: l10n.providerAppsGroupServerDescription,
            gap: AppSpacing.md,
            children: [
              ProviderAppSecretField(
                title: l10n.providerAppId,
                value: app.appId,
                onSet: (v) => _save(ref, 'app_id', v),
              ),
              ProviderAppSecretField(
                title: l10n.providerPrivateKey,
                configured: app.hasPrivateKey,
                secret: true,
                multiline: true,
                onSet: (v) => _save(ref, 'private_key', v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _PrConversations(botLogin: app.botLogin),
          const SizedBox(height: AppSpacing.lg),
        ],
        SettingsGroup(
          title: l10n.providerAppsGroupSignIn,
          description: app.provider == 'linear'
              ? l10n.providerAppsGroupSignInLinearDescription
              : l10n.providerAppsGroupSignInDescription,
          showRule: isGitHub,
          gap: AppSpacing.md,
          children: [
            ProviderAppSecretField(
              title: l10n.providerClientId,
              value: app.clientId,
              onSet: (v) => _save(ref, 'client_id', v),
            ),
            if (app.provider != 'linear')
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
            if (app.redirectUris.isNotEmpty)
              // Shown verbatim because the provider compares it byte for
              // byte: a callback URL assembled by hand is the most common
              // reason a sign-in that "should work" is refused.
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
          ],
        ),
      ],
    );
  }
}

/// "Create my GitHub App": GitHub's manifest flow registers an App with the
/// right permissions and callback, and hands its credentials straight back
/// to this server — nothing to copy by hand.
class _CreateGitHubApp extends ConsumerStatefulWidget {
  const _CreateGitHubApp();

  @override
  ConsumerState<_CreateGitHubApp> createState() => _CreateGitHubAppState();
}

class _CreateGitHubAppState extends ConsumerState<_CreateGitHubApp> {
  bool _starting = false;
  final _organization = TextEditingController();

  @override
  void dispose() {
    _organization.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    final open = ref.read(externalUrlOpenerProvider);
    setState(() => _starting = true);
    try {
      final url = await beginGitHubAppManifest(
        ref,
        organization: _organization.text,
      );
      if (!open(url) && mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.couldNotOpenBrowser, variant: CcToastVariant.danger);
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(failureMessage(l10n, e), variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsGroup(
      title: l10n.providerAppCreateGitHubTitle,
      description: l10n.providerAppCreateGitHubHint,
      gap: AppSpacing.sm,
      children: [
        SettingsField(
          label: l10n.providerAppCreateGitHubOrg,
          description: l10n.providerAppCreateGitHubOrgHint,
          layout: SettingsFieldLayout.stacked,
          // RTL carve-out: a GitHub organization login is a Latin token.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CcTextField(
              controller: _organization,
              hintText: 'acme',
              enabled: !_starting,
              onSubmitted: (_) {
                if (!_starting) {
                  unawaited(_start());
                }
              },
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: CcButton(
            size: CcButtonSize.sm,
            icon: AppIcons.externalLink,
            loading: _starting,
            onPressed: _starting ? null : () => unawaited(_start()),
            child: Text(l10n.providerAppCreateGitHub),
          ),
        ),
      ],
    );
  }
}

class _PrConversations extends StatelessWidget {
  const _PrConversations({required this.botLogin});

  final String botLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return SettingsGroup(
      title: l10n.providerAppsGroupPrConversations,
      description: l10n.providerAppsGroupPrConversationsDescription,
      gap: AppSpacing.md,
      children: [
        // The exact spelling a commenter must type — GitHub does not offer
        // app accounts in the @ autocomplete, so it has to be copied from
        // somewhere.
        SettingsField(
          label: l10n.providerAppBotLogin,
          layout: SettingsFieldLayout.stacked,
          child: SettingsCopyField(
            value: botLogin,
            emptyLabel: l10n.providerAppBotLoginEmpty,
          ),
        ),
        SettingsField(
          label: l10n.providerAppAskOnGitHub,
          layout: SettingsFieldLayout.stacked,
          child: Text(
            l10n.providerAppAskOnGitHubHint,
            style: TextStyle(color: tokens.textSecondary),
          ),
        ),
      ],
    );
  }
}
