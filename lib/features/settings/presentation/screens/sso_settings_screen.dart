import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/provider_apps_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/sso_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Server → Single sign-on (SAML + OIDC + SCIM provisioning).
///
/// Server-scope by design: authentication decides who may reach ANY
/// workspace on this server. The `sso.*` ops are gated server-side to the
/// server-admin role (owner of ≥1 workspace).
///
/// The provider-app card sits here for the same reason and reads as the other
/// half of one question: SSO is how a human authenticates TO this server,
/// provider apps are how this server authenticates OUT to GitHub and Linear —
/// and what a human signs in through when they connect their own account.
class SsoSettingsScreen extends StatelessWidget {
  /// Creates an [SsoSettingsScreen].
  const SsoSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsServerSso,
      subtitle: l10n.settingsServerSsoDescription,
      sections: const [SsoSection(), ProviderAppsSection()],
    );
  }
}
