part of 'server_connect_dialog.dart';

/// Learns what the typed server offers and runs its single sign-on.
mixin _ServerAuthFlow on State<ServerConnectDialog> {
  AuthProvidersSnapshot? _auth;
  String? _probedOrigin;
  Timer? _probeDebounce;
  AuthProviderInfo? _ssoBusyProvider;
  bool _awaitingBrowser = false;
  String? _ssoError;

  /// Bumps on every new sign-in so a popup that closes from an older attempt
  /// cannot clear the one the user just started.
  int _ssoGeneration = 0;

  /// The server-URL field.
  TextEditingController get _url;

  /// Hands over the credentials an SSO round-trip minted.
  Future<void> _finish(ServerConnectCredentials credentials);

  bool get _ssoAvailable => _auth?.providers.isNotEmpty ?? false;

  /// An unknown server (not probed, or it did not answer) is treated as
  /// pairing-allowed: that is what every server without the endpoint is.
  bool get _pairingAllowed => _auth?.pairingEnabled ?? true;

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
  /// credential straight back; on the desktop it returns as a
  /// `control-center://pair` deep link that the host adopts on its own,
  /// which replaces the tree under this dialog, so it just waits.
  Future<void> _startSso(AuthProviderInfo provider) async {
    final l10n = AppLocalizations.of(context);
    final origin = httpOriginFor(_url.text);
    if (origin == null) {
      setState(() => _ssoError = l10n.serverSetupInvalidUrl);
      return;
    }
    final generation = ++_ssoGeneration;
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
          if (mounted && generation == _ssoGeneration) {
            setState(() {
              _ssoBusyProvider = null;
              _awaitingBrowser = true;
            });
          }
        },
      );
    } on SsoBrowserOpenException {
      if (mounted && generation == _ssoGeneration) {
        setState(() {
          _ssoBusyProvider = null;
          _awaitingBrowser = false;
          _ssoError = l10n.ssoBrowserOpenFailed;
        });
      }
      return;
    }
    if (!mounted || generation != _ssoGeneration) {
      return;
    }
    if (payload == null) {
      // Desktop resolves null the moment the browser opens; the credential
      // comes back later as a deep link, so the dialog keeps waiting.
      // Web resolves null when the popup closes or the sign-in fails, and
      // that is the moment Connect has to be usable again.
      if (kIsWeb) {
        setState(() {
          _ssoBusyProvider = null;
          _awaitingBrowser = false;
        });
      }
      return;
    }
    await _finish((
      rawUrl: payload.server,
      inviteCode: '',
      deviceId: payload.deviceId,
      psk: payload.psk,
    ));
  }
}
