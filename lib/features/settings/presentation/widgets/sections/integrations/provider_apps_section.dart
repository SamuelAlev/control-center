import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/provider_app_fields.dart';
import 'package:control_center/features/settings/providers/provider_apps_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How this SERVER authenticates as itself: the GitHub App and the Linear app.
///
/// Server scope, operator only — the `providerApps.*` ops are gated to the
/// server admin, and a member who cannot change these never sees the card
/// (the list resolves empty for them).
///
/// Two different jobs come out of one registration and the card says so: the
/// app id + private key are what lets the server read repositories with no
/// human behind the request (webhooks, polling, sync), while the client id +
/// secret are what lets a PERSON sign in and get a credential of their own.
/// Configuring only the second is a valid, common setup — so each app's row
/// reports the two capabilities separately rather than collapsing them into one
/// "configured" verdict that would be true and useless.
class ProviderAppsSection extends ConsumerStatefulWidget {
  /// Creates a [ProviderAppsSection].
  const ProviderAppsSection({super.key});

  @override
  ConsumerState<ProviderAppsSection> createState() =>
      _ProviderAppsSectionState();
}

class _ProviderAppsSectionState extends ConsumerState<ProviderAppsSection> {
  final _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final apps = ref.watch(providerAppsProvider).value ?? const [];
    if (apps.isEmpty) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      label: l10n.providerApps,
      subtitle: Text(l10n.providerAppsDescription),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      headerPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final app in apps) ...[
            const CcDivider(),
            _ProviderAppRow(
              app: app,
              expanded: _expanded.contains(app.provider),
              onExpandedChanged: (open) => setState(() {
                if (open) {
                  _expanded.add(app.provider);
                } else {
                  _expanded.remove(app.provider);
                }
              }),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _ProviderAppRow extends ConsumerStatefulWidget {
  const _ProviderAppRow({
    required this.app,
    required this.expanded,
    required this.onExpandedChanged,
  });

  final ProviderAppStatusView app;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  @override
  ConsumerState<_ProviderAppRow> createState() => _ProviderAppRowState();
}

class _ProviderAppRowState extends ConsumerState<_ProviderAppRow> {
  bool _testing = false;

  Future<void> _save(String field, String value) =>
      saveProviderApp(ref, widget.app.provider, {field: value});

  Future<void> _test() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _testing = true);
    try {
      final result = await testProviderApp(ref, widget.app.provider);
      if (!mounted) {
        return;
      }
      CcToastScope.of(context).show(
        result.error.isNotEmpty
            ? result.error
            : l10n.providerAppInstalledOn(result.installations.join(', ')),
        variant: result.error.isEmpty
            ? CcToastVariant.success
            : CcToastVariant.danger,
      );
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = widget.app;
    final isGitHub = app.provider == 'github';
    final name = isGitHub ? 'GitHub' : 'Linear';
    final broken = app.error.isNotEmpty;
    final anyCapability = app.canActAsServer || app.canSignIn;

    return SettingsEntityRow(
      title: name,
      icon: isGitHub ? AppIcons.gitBranch : AppIcons.circleCheck,
      tone: broken
          ? CcStatusTone.negative
          : anyCapability
          ? CcStatusTone.positive
          : CcStatusTone.neutral,
      statusLabel: broken
          ? l10n.settingsStateFailed
          : anyCapability
          ? l10n.configuredLabel
          : l10n.notConfiguredLabel,
      subtitle: _summary(l10n),
      // The two capabilities, always both stated. "Configured" alone hid which
      // half worked, and the halves fail in completely different ways: one
      // breaks background sync silently, the other breaks the sign-in button.
      meta: [
        ProviderAppCapability(
          label: l10n.providerAppCapActsAsServer,
          enabled: app.canActAsServer,
        ),
        ProviderAppCapability(
          label: l10n.providerAppCapSignsIn,
          enabled: app.canSignIn,
        ),
      ],
      trailing: CcButton(
        onPressed: _testing ? null : _test,
        variant: CcButtonVariant.secondary,
        size: CcButtonSize.sm,
        loading: _testing,
        child: Text(l10n.testLabel),
      ),
      expanded: widget.expanded,
      onExpandedChanged: widget.onExpandedChanged,
      detail: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (broken) ...[
            CcAlert(title: app.error, variant: CcAlertVariant.danger),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (isGitHub)
            SettingsGroup(
              title: l10n.providerAppsGroupServer,
              description: l10n.providerAppsGroupServerDescription,
              gap: AppSpacing.md,
              children: [
                ProviderAppSecretField(
                  title: l10n.providerAppId,
                  value: app.appId,
                  onSet: (v) => _save('app_id', v),
                ),
                ProviderAppSecretField(
                  title: l10n.providerPrivateKey,
                  configured: app.hasPrivateKey,
                  secret: true,
                  multiline: true,
                  onSet: (v) => _save('private_key', v),
                ),
              ],
            ),
          if (isGitHub) ...[
            const SizedBox(height: AppSpacing.lg),
            SettingsGroup(
              title: l10n.providerAppsGroupPrConversations,
              description: l10n.providerAppsGroupPrConversationsDescription,
              gap: AppSpacing.md,
              children: [
                // The exact spelling a commenter must type — GitHub does not
                // offer app accounts in the @ autocomplete, so it has to be
                // copied from somewhere.
                SettingsField(
                  label: l10n.providerAppBotLogin,
                  layout: SettingsFieldLayout.stacked,
                  child: SettingsCopyField(
                    value: app.botLogin,
                    emptyLabel: l10n.providerAppBotLoginEmpty,
                  ),
                ),
                SettingsField(
                  label: l10n.providerAppAskOnGitHub,
                  layout: SettingsFieldLayout.stacked,
                  child: Builder(
                    builder: (context) {
                      final tokens =
                          context.designSystem ?? DesignSystemTokens.light();
                      return Text(
                        l10n.providerAppAskOnGitHubHint,
                        style: TextStyle(color: tokens.textSecondary),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
          if (isGitHub) const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            title: l10n.providerAppsGroupSignIn,
            description: l10n.providerAppsGroupSignInDescription,
            showRule: isGitHub,
            gap: AppSpacing.md,
            children: [
              ProviderAppSecretField(
                title: l10n.providerClientId,
                value: app.clientId,
                onSet: (v) => _save('client_id', v),
              ),
              ProviderAppSecretField(
                title: l10n.providerClientSecret,
                configured: app.hasClientSecret,
                secret: true,
                onSet: (v) => _save('client_secret', v),
              ),
              if (!isGitHub)
                ProviderAppSecretField(
                  title: l10n.providerApiKey,
                  configured: app.hasApiKey,
                  secret: true,
                  onSet: (v) => _save('api_key', v),
                ),
              if (app.redirectUri.isNotEmpty)
                // Shown verbatim because the provider compares it byte for
                // byte: a callback URL assembled by hand is the most common
                // reason a sign-in that "should work" is refused.
                SettingsField(
                  label: l10n.providerCallbackUrl,
                  layout: SettingsFieldLayout.stacked,
                  child: SettingsCopyField(value: app.redirectUri),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _summary(AppLocalizations l10n) {
    final app = widget.app;
    if (app.error.isNotEmpty) {
      return app.error;
    }
    return switch ((app.canActAsServer, app.canSignIn)) {
      (true, true) => l10n.providerAppFullyConfigured,
      (true, false) => l10n.providerAppServerOnly,
      (false, true) => l10n.providerAppSignInOnly,
      (false, false) => l10n.notConfiguredLabel,
    };
  }
}
