import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The values that go the other way, into the identity provider's console.
///
/// These used to be reachable only through a "Copy SP metadata" button that put
/// an XML blob on the clipboard — correct for a metadata upload, useless for the
/// providers that ask you to paste an ACS URL into a form. They are derived from
/// the server's own origin, so they are shown, not edited.
///
/// When the server does not know its public URL there is nothing to show and
/// nothing that would work, so the group says that instead of rendering three
/// broken URLs built from a guess.
class SsoHandoffGroup extends StatelessWidget {
  /// Creates an [SsoHandoffGroup].
  const SsoHandoffGroup({
    super.key,
    required this.isSaml,
    required this.origin,
    required this.spEntityId,
  });

  /// Whether the SAML values are wanted (OIDC otherwise).
  final bool isSaml;

  /// The server's canonical origin, or null when it has none.
  final String? origin;

  /// The configured SP entity id; blank means "derive it from the origin".
  final String spEntityId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final base = origin;

    if (base == null) {
      return SettingsGroup(
        title: l10n.ssoGroupHandoff,
        showRule: true,
        children: [
          CcAlert(
            title: l10n.ssoOriginUnknownTitle,
            variant: CcAlertVariant.warning,
            description: Text(
              l10n.ssoOriginUnknownBody,
              style: CcTypography.caption.copyWith(color: tokens.textSecondary),
            ),
          ),
        ],
      );
    }

    return SettingsGroup(
      title: l10n.ssoGroupHandoff,
      description: l10n.ssoGroupHandoffDescription,
      showRule: true,
      children: isSaml
          ? [
              SettingsField(
                label: l10n.ssoAcsUrlLabel,
                description: l10n.ssoAcsUrlDescription,
                layout: SettingsFieldLayout.stacked,
                child: SettingsCopyField(value: '$base/saml/acs'),
              ),
              SettingsField(
                label: l10n.ssoSpEntityIdResolvedLabel,
                layout: SettingsFieldLayout.stacked,
                child: SettingsCopyField(
                  value: spEntityId.trim().isEmpty ? '$base/saml' : spEntityId,
                ),
              ),
              SettingsField(
                label: l10n.ssoMetadataUrlLabel,
                description: l10n.ssoMetadataUrlDescription,
                layout: SettingsFieldLayout.stacked,
                child: SettingsCopyField(value: '$base/saml/metadata'),
              ),
            ]
          : [
              SettingsField(
                label: l10n.ssoRedirectUriLabel,
                description: l10n.ssoRedirectUriDescription,
                layout: SettingsFieldLayout.stacked,
                child: SettingsCopyField(value: '$base/oidc/callback'),
              ),
              SettingsField(
                label: l10n.ssoSignInUrlLabel,
                description: l10n.ssoSignInUrlDescription,
                layout: SettingsFieldLayout.stacked,
                child: SettingsCopyField(value: '$base/oidc/login'),
              ),
            ],
    );
  }
}
