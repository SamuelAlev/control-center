import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/server/auth_providers.dart';
import 'package:control_center/core/server/sso_login.dart';
import 'package:control_center/core/server/sso_pair_link.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/server_discovery_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// What [AddServerDialog] resolves to: one set of credentials to pair with,
/// however obtained — typed by hand, or minted by an SSO round-trip this
/// dialog captured inline.
typedef AddServerCredentials = ({
  String rawUrl,
  String inviteCode,
  String deviceId,
  String psk,
});

/// Settings' "add server" dialog. It probes the typed server's
/// unauthenticated `/auth/providers` and ADAPTS: a "Sign in with <label>"
/// button per SSO connection that server offers, and no invite/pairing-key
/// form at all when the server has turned manual pairing off. Without it a
/// desktop user who had already chosen a server could not reach single
/// sign-on short of resetting their connection.
class AddServerDialog extends StatefulWidget {
  /// Creates an [AddServerDialog].
  const AddServerDialog({
    super.key,
    required this.prefillUrl,
    required this.excludeServerIds,
  });

  /// Initial value of the server-URL field.
  final String prefillUrl;

  /// Already-paired servers, hidden from the discovery picker.
  final Set<String> excludeServerIds;

  @override
  State<AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<AddServerDialog> {
  late final TextEditingController _url = TextEditingController(
    text: widget.prefillUrl,
  );
  final TextEditingController _invite = TextEditingController();
  final TextEditingController _device = TextEditingController();
  final TextEditingController _psk = TextEditingController();

  AuthProvidersSnapshot? _auth;
  String? _probedOrigin;
  Timer? _probeDebounce;
  AuthProviderInfo? _ssoBusyProvider;
  bool _awaitingBrowser = false;
  bool _showManual = false;
  String? _ssoError;

  bool get _ssoAvailable => _auth?.providers.isNotEmpty ?? false;

  /// An unknown server (not probed, or it did not answer) is treated as
  /// pairing-allowed: that is what every server without the endpoint is.
  bool get _pairingAllowed => _auth?.pairingEnabled ?? true;

  @override
  void initState() {
    super.initState();
    _url.addListener(_scheduleProbe);
    _scheduleProbe();
  }

  @override
  void dispose() {
    _probeDebounce?.cancel();
    cancelSsoLogin();
    _url.removeListener(_scheduleProbe);
    _url.dispose();
    _invite.dispose();
    _device.dispose();
    _psk.dispose();
    super.dispose();
  }

  void _scheduleProbe() {
    _probeDebounce?.cancel();
    final origin = httpOriginFor(_url.text);
    if (origin == null) {
      if (_auth != null) {
        setState(() {
          _auth = null;
          _probedOrigin = null;
        });
      }
      return;
    }
    if (_auth != null && _probedOrigin == origin) {
      return; // Already probed this exact origin.
    }
    _probeDebounce = Timer(const Duration(milliseconds: 400), () async {
      final snapshot = await probeAuthProviders(origin);
      if (!mounted) {
        return;
      }
      setState(() {
        _auth = snapshot;
        _probedOrigin = snapshot == null ? null : origin;
      });
    });
  }

  /// Starts one provider's round-trip. On web the popup relays the minted
  /// credential straight back and the dialog closes with it; on the desktop
  /// it returns as a `control-center://pair` deep link that the running app
  /// adopts and switches to on its own — which remounts the app over this
  /// dialog, so it just waits.
  Future<void> _startSso(AuthProviderInfo provider) async {
    final l10n = AppLocalizations.of(context);
    final origin = httpOriginFor(_url.text);
    if (origin == null) {
      setState(() => _ssoError = l10n.serverSetupInvalidUrl);
      return;
    }
    setState(() {
      _ssoBusyProvider = provider;
      _ssoError = null;
    });
    final SsoPairPayload? payload;
    try {
      payload = await startSsoLogin(
        provider: provider,
        origin: origin,
        onAwaiting: () {
          if (mounted) {
            setState(() {
              _ssoBusyProvider = null;
              _awaitingBrowser = true;
            });
          }
        },
      );
    } on SsoBrowserOpenException {
      if (mounted) {
        setState(() {
          _ssoBusyProvider = null;
          _awaitingBrowser = false;
          _ssoError = l10n.ssoBrowserOpenFailed;
        });
      }
      return;
    }
    if (!mounted || payload == null) {
      // Null is the DESKTOP shape and not a failure — the browser is still
      // mid-login. Staying open on "waiting for your browser…" says so;
      // popping here would look like the click did nothing.
      return;
    }
    Navigator.of(context).pop((
      rawUrl: payload.server,
      inviteCode: '',
      deviceId: payload.deviceId,
      psk: payload.psk,
    ));
  }

  void _submit() {
    Navigator.of(context).pop((
      rawUrl: _url.text,
      inviteCode: _invite.text,
      deviceId: _device.text.trim(),
      psk: _psk.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final busy = _ssoBusyProvider != null || _awaitingBrowser;
    // Manual credentials show when the server offers nothing better or the
    // user unfolded them — never once it has turned pairing off.
    final showManual = (!_ssoAvailable || _showManual) && _pairingAllowed;
    return CcDialog(
      title: l10n.serverListAddTitle,
      // `CcDialog` centres its panel and never scrolls it, and the body now
      // grows with what the server offers — so bound it here rather than
      // overflow on a short window.
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CcTextField(
                controller: _url,
                hintText: 'wss://host:9030/rpc',
                autofocus: true,
                enabled: !busy,
                // LAN + tailnet discovery (desktop only — a browser can
                // neither browse mDNS nor probe the tailnet).
                suffix: kIsWeb
                    ? null
                    : ServerDiscoveryButton(
                        excludeServerIds: widget.excludeServerIds,
                        onSelected: (server) => _url.text = server.rpcUrl,
                      ),
              ),
              if (_ssoError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _ssoError!,
                  style: CcTypography.caption.copyWith(color: t.danger),
                ),
              ],
              if (_ssoAvailable) ...[
                for (final provider
                    in _auth?.providers ?? const <AuthProviderInfo>[]) ...[
                  const SizedBox(height: 8),
                  CcButton(
                    onPressed: busy
                        ? null
                        : () => unawaited(_startSso(provider)),
                    variant: CcButtonVariant.accent,
                    loading: identical(_ssoBusyProvider, provider),
                    fullWidth: true,
                    child: Text(l10n.ssoSignInWith(provider.label)),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _awaitingBrowser
                      ? l10n.ssoWaitingForBrowser
                      : l10n.ssoOpensBrowser,
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
                if (_pairingAllowed) ...[
                  const SizedBox(height: 8),
                  CcButton(
                    onPressed: busy
                        ? null
                        : () => setState(() => _showManual = !_showManual),
                    variant: CcButtonVariant.ghost,
                    fullWidth: true,
                    child: Text(
                      _showManual
                          ? l10n.ssoHideManualPairing
                          : l10n.ssoUseManualPairing,
                    ),
                  ),
                ],
              ],
              if (showManual) ...[
                const SizedBox(height: 8),
                CcTextField(
                  controller: _invite,
                  hintText: l10n.serverSetupInviteCodeHint,
                  enabled: !busy,
                ),
                const SizedBox(height: 8),
                CcTextField(
                  controller: _device,
                  hintText: l10n.serverRemoteDeviceId,
                  enabled: !busy,
                ),
                const SizedBox(height: 8),
                CcTextField(
                  controller: _psk,
                  hintText: l10n.serverRemotePairingKey,
                  obscureText: true,
                  enabled: !busy,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.of(context).pop(),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        // SSO-only server: the Connect button would submit credentials the
        // server refuses to honour, so it goes with the fields.
        if (showManual)
          CcButton(
            onPressed: busy ? null : _submit,
            variant: CcButtonVariant.accent,
            child: Text(l10n.serverSetupConnect),
          ),
      ],
    );
  }
}
