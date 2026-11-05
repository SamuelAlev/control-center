part of 'server_connect_dialog.dart';

/// SSO buttons and the manual pairing fields under the server URL.
class _ServerConnectAuthFields extends StatelessWidget {
  const _ServerConnectAuthFields({
    required this.ssoError,
    required this.providers,
    required this.busy,
    required this.busyProvider,
    required this.awaitingBrowser,
    required this.pairingAllowed,
    required this.manualExpanded,
    required this.showManual,
    required this.pairingKeyExpanded,
    required this.onStartSso,
    required this.onToggleManual,
    required this.onTogglePairingKey,
    required this.onInviteChanged,
    required this.onSubmit,
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
  final bool pairingKeyExpanded;
  final ValueChanged<AuthProviderInfo> onStartSso;
  final VoidCallback onToggleManual;
  final VoidCallback onTogglePairingKey;
  final VoidCallback onInviteChanged;
  final VoidCallback onSubmit;
  final TextEditingController invite;
  final TextEditingController device;
  final TextEditingController psk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // An invite mints this client's own credential, so a pairing key beside
    // one would be ignored.
    final hasInvite = invite.text.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ssoError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            ssoError!,
            style: CcTypography.caption.copyWith(color: t.danger),
          ),
        ],
        if (providers.isNotEmpty) ...[
          for (final provider in providers) ...[
            const SizedBox(height: AppSpacing.sm),
            CcButton(
              onPressed: busy ? null : () => onStartSso(provider),
              variant: CcButtonVariant.accent,
              loading: identical(busyProvider, provider),
              fullWidth: true,
              child: Text(l10n.ssoSignInWith(provider.label)),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            awaitingBrowser ? l10n.ssoWaitingForBrowser : l10n.ssoOpensBrowser,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
          if (pairingAllowed) ...[
            const SizedBox(height: AppSpacing.sm),
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
        CcCollapsible(
          expanded: showManual,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              CcTextField(
                controller: invite,
                label: l10n.serverSetupInviteCode,
                hintText: l10n.serverSetupInviteCodeHint,
                enabled: !busy,
                onChanged: (_) => onInviteChanged(),
                onSubmitted: (_) => onSubmit(),
              ),
              if (!hasInvite) ...[
                const SizedBox(height: AppSpacing.xs),
                CcButton(
                  onPressed: busy ? null : onTogglePairingKey,
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  fullWidth: true,
                  icon: pairingKeyExpanded
                      ? AppIcons.chevronUp
                      : AppIcons.chevronDown,
                  child: Text(l10n.connectUsePairingKey),
                ),
              ],
              CcCollapsible(
                expanded: pairingKeyExpanded && !hasInvite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    CcTextField(
                      controller: device,
                      label: l10n.serverRemoteDeviceId,
                      enabled: !busy,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CcTextField(
                      controller: psk,
                      label: l10n.serverRemotePairingKey,
                      hintText: l10n.serverRemotePairingKeyHint,
                      obscureText: true,
                      enabled: !busy,
                      onSubmitted: (_) => onSubmit(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
