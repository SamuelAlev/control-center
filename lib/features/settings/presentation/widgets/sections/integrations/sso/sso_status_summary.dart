import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The facts an admin arrives at the SSO page with: *can anyone sign in right
/// now, and how?*
///
/// Four states, before a single input. The old page opened with twelve
/// undifferentiated SAML fields and never said whether SSO was on at all.
class SsoStatusSummary extends StatelessWidget {
  /// Creates an [SsoStatusSummary].
  const SsoStatusSummary({super.key, required this.status});

  /// The `sso.status` wire map.
  final Map<String, dynamic>? status;

  Map<String, dynamic> _forKind(String kind) {
    final entry = status?[kind];
    return entry is Map ? entry.cast<String, dynamic>() : const {};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final saml = _forKind('saml');
    final oidc = _forKind('oidc');
    final scim = status?['scim'];
    final scimActive = scim is Map && scim['token_present'] == true;
    final pairingEnabled = status?['pairing_enabled'] != false;
    final anyLive =
        (saml['enabled'] == true && saml['configured'] == true) ||
        (oidc['enabled'] == true && oidc['configured'] == true);

    final samlState = _connectionState(l10n, saml);
    final oidcState = _connectionState(l10n, oidc);

    return SettingsSummary(
      facts: [
        SettingsFact(
          label: l10n.ssoProviderSaml,
          value: samlState.label,
          tone: samlState.tone,
          mono: false,
        ),
        SettingsFact(
          label: l10n.ssoProviderOidc,
          value: oidcState.label,
          tone: oidcState.tone,
          mono: false,
        ),
        SettingsFact(
          label: l10n.ssoSummaryDirectorySync,
          value: scimActive ? l10n.ssoStateActive : l10n.notConfiguredLabel,
          tone: scimActive ? CcStatusTone.positive : CcStatusTone.neutral,
          mono: false,
        ),
        SettingsFact(
          label: l10n.ssoSummaryManualPairing,
          value: pairingEnabled ? l10n.ssoStateAllowed : l10n.disabled,
          tone: pairingEnabled ? CcStatusTone.info : CcStatusTone.neutral,
          mono: false,
        ),
      ],
      note: anyLive ? null : l10n.ssoNoMethodLiveNote,
    );
  }

  /// Enabled and configured are separate facts on the wire, and the four
  /// combinations mean four different things — "on but incomplete" is a broken
  /// sign-in page, not a disabled one, so it reads as an error rather than as
  /// a neutral off.
  ({String label, CcStatusTone tone}) _connectionState(
    AppLocalizations l10n,
    Map<String, dynamic> row,
  ) {
    final configured = row['configured'] == true;
    final enabled = row['enabled'] == true;
    if (enabled && configured) {
      return (label: l10n.ssoStateLive, tone: CcStatusTone.positive);
    }
    if (configured) {
      return (label: l10n.ssoStateConfiguredOff, tone: CcStatusTone.caution);
    }
    if (enabled) {
      return (label: l10n.ssoStateOnIncomplete, tone: CcStatusTone.negative);
    }
    return (label: l10n.notConfiguredLabel, tone: CcStatusTone.neutral);
  }
}
