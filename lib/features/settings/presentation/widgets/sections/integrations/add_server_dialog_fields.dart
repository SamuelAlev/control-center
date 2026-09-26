part of 'add_server_dialog.dart';

/// SSO buttons and the manual pairing fields under the server URL.
class _AddServerAuthFields extends StatelessWidget {
  const _AddServerAuthFields({
    required this.ssoError,
    required this.providers,
    required this.busy,
    required this.busyProvider,
    required this.awaitingBrowser,
    required this.pairingAllowed,
    required this.manualExpanded,
    required this.showManual,
    required this.onStartSso,
    required this.onToggleManual,
    required this.invite,
    required this.device,
    required this.psk,
  });

  final String? ssoError;
  final List<AuthProviderInfo> providers;
  final bool busy;
  final AuthProviderInfo? busyProvider;
  final bool awaitingBrowser;
  final bool pairingAllowed;
  final bool manualExpanded;
  final bool showManual;
  final ValueChanged<AuthProviderInfo> onStartSso;
  final VoidCallback onToggleManual;
  final TextEditingController invite;
  final TextEditingController device;
  final TextEditingController psk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ssoError != null) ...[
          const SizedBox(height: 8),
          Text(
            ssoError!,
            style: CcTypography.caption.copyWith(color: t.danger),
          ),
        ],
        if (providers.isNotEmpty) ...[
          for (final provider in providers) ...[
            const SizedBox(height: 8),
            CcButton(
              onPressed: busy ? null : () => onStartSso(provider),
              variant: CcButtonVariant.accent,
              loading: identical(busyProvider, provider),
              fullWidth: true,
              child: Text(l10n.ssoSignInWith(provider.label)),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            awaitingBrowser ? l10n.ssoWaitingForBrowser : l10n.ssoOpensBrowser,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          if (pairingAllowed) ...[
            const SizedBox(height: 8),
            CcButton(
              onPressed: busy ? null : onToggleManual,
              variant: CcButtonVariant.ghost,
              fullWidth: true,
              child: Text(
                manualExpanded
                    ? l10n.ssoHideManualPairing
                    : l10n.ssoUseManualPairing,
              ),
            ),
          ],
        ],
        if (showManual) ...[
          const SizedBox(height: 8),
          CcTextField(
            controller: invite,
            hintText: l10n.serverSetupInviteCodeHint,
            enabled: !busy,
          ),
          const SizedBox(height: 8),
          CcTextField(
            controller: device,
            hintText: l10n.serverRemoteDeviceId,
            enabled: !busy,
          ),
          const SizedBox(height: 8),
          CcTextField(
            controller: psk,
            hintText: l10n.serverRemotePairingKey,
            obscureText: true,
            enabled: !busy,
          ),
        ],
      ],
    );
  }
}
