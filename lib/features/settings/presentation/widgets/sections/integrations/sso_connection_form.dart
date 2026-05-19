import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/sso/sso_access_group.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/sso/sso_handoff_group.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/sso/sso_text_field.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The editable fields of one SSO connection kind (SAML or OIDC), arranged as
/// four named groups plus an advanced disclosure.
///
/// The old form was twelve controls in one column, in wire order, with a 12px
/// tertiary label above each. Every field looked equally important and none of
/// them said which of the four different jobs it belonged to — telling the
/// server where the identity provider is, telling the provider where the server
/// is, naming the claims, and deciding what a new user may do. Those are the
/// groups now, in the order an admin performs them.
///
/// Stateless-by-design: the parent section owns the values (loaded from
/// `sso.getConfig`) and every edit calls back up, so "save" serializes exactly
/// what is on screen and a reload discards edits cleanly.
class SsoConnectionForm extends StatelessWidget {
  /// Creates an [SsoConnectionForm].
  const SsoConnectionForm({
    super.key,
    required this.kind,
    required this.values,
    required this.onChanged,
    required this.origin,
    this.busy = false,
  });

  /// `saml` or `oidc`.
  final String kind;

  /// The current field values (the `sso.*` wire shape).
  final Map<String, dynamic> values;

  /// Fired with the changed key and its new value.
  final void Function(String key, Object? value) onChanged;

  /// The server's canonical origin, when it knows one. Null means the handoff
  /// URLs cannot be built — which is itself the thing the admin needs told,
  /// since without it no provider can reach this server.
  final String? origin;

  /// Disables every control while a save or test is in flight.
  final bool busy;

  bool get _isSaml => kind == 'saml';

  bool _bool(String key, {required bool fallback}) =>
      values[key] as bool? ?? fallback;

  String _string(String key, String fallback) =>
      values[key] as String? ?? fallback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _identityProvider(context, l10n),
        const SizedBox(height: AppSpacing.xl),
        SsoHandoffGroup(
          isSaml: _isSaml,
          origin: origin,
          spEntityId: _string('spEntityId', ''),
        ),
        const SizedBox(height: AppSpacing.xl),
        _attributeMapping(context, l10n),
        const SizedBox(height: AppSpacing.xl),
        SsoAccessGroup(values: values, onChanged: onChanged, busy: busy),
        if (_isSaml) ...[
          const SizedBox(height: AppSpacing.xl),
          SsoAdvancedGroup(values: values, onChanged: onChanged, busy: busy),
        ],
      ],
    );
  }

  /// Step one: where the identity provider is, and how we trust it.
  Widget _identityProvider(BuildContext context, AppLocalizations l10n) {
    return SettingsGroup(
      title: l10n.ssoGroupIdentityProvider,
      description: _isSaml
          ? l10n.ssoGroupIdentityProviderSamlDescription
          : l10n.ssoGroupIdentityProviderOidcDescription,
      showRule: true,
      children: _isSaml ? _samlIdentity(l10n) : _oidcIdentity(l10n),
    );
  }

  List<Widget> _samlIdentity(AppLocalizations l10n) => [
    SettingsField(
      label: l10n.ssoIdpMetadataLabel,
      layout: SettingsFieldLayout.stacked,
      hint: l10n.ssoIdpMetadataHint,
      child: SsoTextField(
        value: _string('idpMetadataXml', ''),
        hint: '<EntityDescriptor …>',
        minLines: 4,
        maxLines: 10,
        enabled: !busy,
        onChanged: (v) => onChanged('idpMetadataXml', v),
      ),
    ),
    SettingsField(
      label: l10n.ssoSpEntityIdShortLabel,
      description: l10n.ssoSpEntityIdDescription,
      optional: true,
      child: SsoTextField(
        value: _string('spEntityId', ''),
        hint: origin == null ? 'https://cc.example.com/saml' : null,
        enabled: !busy,
        onChanged: (v) => onChanged('spEntityId', v),
      ),
    ),
  ];

  List<Widget> _oidcIdentity(AppLocalizations l10n) => [
    SettingsField(
      label: l10n.ssoIssuerLabel,
      description: l10n.ssoIssuerDescription,
      child: SsoTextField(
        value: _string('issuer', ''),
        hint: 'https://idp.example.com',
        enabled: !busy,
        onChanged: (v) => onChanged('issuer', v),
      ),
    ),
    SettingsField(
      label: l10n.ssoClientIdLabel,
      description: l10n.ssoClientIdHint,
      child: SsoTextField(
        value: _string('clientId', ''),
        enabled: !busy,
        onChanged: (v) => onChanged('clientId', v),
      ),
    ),
    // Confidential provider clients only: the secret itself never comes back
    // over RPC, so this field stays write-only — blank on save keeps the
    // stored one.
    SettingsField(
      label: l10n.ssoClientSecretLabel,
      description: l10n.ssoClientSecretHintUnset,
      optional: true,
      badge: _bool('clientSecretPresent', fallback: false)
          ? CcBadge(
              label: l10n.ssoSecretStored,
              variant: CcBadgeVariant.success,
            )
          : null,
      hint: _bool('clientSecretPresent', fallback: false)
          ? l10n.ssoClientSecretHintSet
          : null,
      child: SsoTextField(
        value: _string('clientSecret', ''),
        obscure: true,
        enabled: !busy,
        onChanged: (v) => onChanged('clientSecret', v),
      ),
    ),
  ];

  /// Step three: which claim carries which field. Defaults are right for most
  /// providers, so these are inline and narrow — they read as a lookup table,
  /// which is what they are.
  Widget _attributeMapping(BuildContext context, AppLocalizations l10n) {
    return SettingsGroup(
      title: l10n.ssoGroupAttributeMapping,
      description: l10n.ssoGroupAttributeMappingDescription,
      showRule: true,
      gap: AppSpacing.md,
      children: [
        for (final field
            in _isSaml
                ? const [
                    ('emailAttribute', 'email'),
                    ('displayNameAttribute', 'displayName'),
                    ('groupsAttribute', 'groups'),
                  ]
                : const [('groupsClaim', 'groups')])
          SettingsField(
            label: _attributeLabel(l10n, field.$1),
            controlWidth: 280,
            child: SsoTextField(
              value: _string(field.$1, field.$2),
              enabled: !busy,
              onChanged: (v) => onChanged(field.$1, v),
            ),
          ),
      ],
    );
  }

  String _attributeLabel(AppLocalizations l10n, String key) => switch (key) {
    'emailAttribute' => l10n.ssoEmailAttributeLabel,
    'displayNameAttribute' => l10n.ssoDisplayNameAttributeLabel,
    'groupsAttribute' => l10n.ssoGroupsAttributeLabel,
    _ => l10n.ssoGroupsClaimLabel,
  };
}
