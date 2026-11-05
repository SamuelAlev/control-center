import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/server/auth_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_discovery.dart'
    if (dart.library.js_interop) 'package:control_center/core/server/server_discovery_web.dart';
import 'package:control_center/core/server/sso_login.dart';
import 'package:control_center/core/server/sso_pair_link.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/connection_error_alert.dart';
import 'package:control_center/shared/widgets/server_discovery_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

part 'server_connect_dialog_auth.dart';
part 'server_connect_dialog_fields.dart';

/// What a connect dialog resolves to: one set of credentials to pair with,
/// however obtained: typed by hand, pasted as a link, or minted by an SSO
/// round-trip captured inline.
typedef ServerConnectCredentials = ({
  String rawUrl,
  String inviteCode,
  String deviceId,
  String psk,
});

/// Connects to a server from desktop setup, the web gate or Settings.
///
/// It probes the typed server's unauthenticated `/auth/providers` and ADAPTS:
/// a "Sign in with <label>" button per SSO connection that server offers, and
/// no invite/pairing-key form at all when the server has turned manual pairing
/// off.
class ServerConnectDialog extends StatefulWidget {
  /// Creates a [ServerConnectDialog].
  const ServerConnectDialog({
    super.key,
    required this.title,
    this.intro,
    this.prefillUrl = '',
    this.prefillInvite = '',
    this.prefillDeviceId = '',
    this.prefillPsk = '',
    this.excludeServerIds = const {},
    this.discovery = const ServerDiscovery(),
    this.onConnect,
    this.footer,
  });

  /// The dialog's heading.
  final String title;

  /// One line under the heading.
  final String? intro;

  /// Initial value of the server-URL field.
  final String prefillUrl;

  /// Initial value of the invite-code field.
  final String prefillInvite;

  /// Initial value of the device-id field.
  final String prefillDeviceId;

  /// Initial value of the pairing-key field; unfolds the pairing key fields.
  final String prefillPsk;

  /// Already-paired servers, hidden from the discovery picker.
  final Set<String> excludeServerIds;

  /// Server discovery behind the URL field's suffix button.
  final ServerDiscovery discovery;

  /// Connects with the entered credentials, keeping the dialog open until it
  /// settles so a failure is shown beside the fields that caused it. When
  /// null the dialog pops with the credentials instead.
  final Future<void> Function(ServerConnectCredentials)? onConnect;

  /// Extra content under the form, such as a remember-this-device choice.
  final Widget? footer;

  @override
  State<ServerConnectDialog> createState() => _ServerConnectDialogState();
}

class _ServerConnectDialogState extends State<ServerConnectDialog>
    with _ServerAuthFlow {
  @override
  late final TextEditingController _url = TextEditingController(
    text: widget.prefillUrl,
  );
  late final TextEditingController _invite = TextEditingController(
    text: widget.prefillInvite,
  );
  late final TextEditingController _device = TextEditingController(
    text: widget.prefillDeviceId,
  );
  late final TextEditingController _psk = TextEditingController(
    text: widget.prefillPsk,
  );

  bool _showManual = false;
  late bool _showPairingKey = widget.prefillPsk.isNotEmpty;
  bool _connecting = false;
  Object? _connectError;

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

  Future<void> _submit() async {
    if (normalizeServerUrl(_url.text) == null) {
      final l10n = AppLocalizations.of(context);
      setState(
        () => _connectError = UserFacingMessage(l10n.serverSetupInvalidUrl),
      );
      return;
    }
    await _finish((
      rawUrl: _url.text.trim(),
      inviteCode: _invite.text.trim(),
      deviceId: _device.text.trim(),
      psk: _psk.text.trim(),
    ));
  }

  @override
  Future<void> _finish(ServerConnectCredentials credentials) async {
    final onConnect = widget.onConnect;
    if (onConnect == null) {
      Navigator.of(context).pop(credentials);
      return;
    }
    setState(() {
      _connecting = true;
      _connectError = null;
      _ssoBusyProvider = null;
    });
    try {
      await onConnect(credentials);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _connecting = false;
          _awaitingBrowser = false;
          _connectError = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Waiting on the browser must not lock Connect or Sign in. A failed
    // login never calls back, and the only recovery is clicking again.
    final busy = _ssoBusyProvider != null || _connecting;
    // Manual credentials show when the server offers nothing better or the
    // user unfolded them, never once it has turned pairing off.
    final showManual = (!_ssoAvailable || _showManual) && _pairingAllowed;
    final intro = widget.intro;
    final error = _connectError;
    return CcDialog(
      title: widget.title,
      onClose: _connecting ? null : () => Navigator.of(context).pop(),
      // `CcDialog` centres its panel and never scrolls it, and the body grows
      // with what the server offers, so bound it here rather than overflow on
      // a short window.
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (intro != null) ...[
                Text(
                  intro,
                  style: CcTypography.bodySm.copyWith(color: t.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              CcTextField(
                controller: _url,
                label: l10n.serverRemoteUrl,
                hintText: 'wss://host:9030/rpc',
                autofocus: true,
                enabled: !busy,
                onSubmitted: showManual ? (_) => unawaited(_submit()) : null,
                // LAN + tailnet discovery (desktop only: a browser can
                // neither browse mDNS nor probe the tailnet).
                suffix: kIsWeb
                    ? null
                    : ServerDiscoveryButton(
                        discovery: widget.discovery,
                        excludeServerIds: widget.excludeServerIds,
                        onSelected: (server) => _url.text = server.rpcUrl,
                      ),
              ),
              _ServerConnectAuthFields(
                ssoError: _ssoError,
                providers: _auth?.providers ?? const <AuthProviderInfo>[],
                busy: busy,
                busyProvider: _ssoBusyProvider,
                awaitingBrowser: _awaitingBrowser,
                pairingAllowed: _pairingAllowed,
                manualExpanded: _showManual,
                showManual: showManual,
                pairingKeyExpanded: _showPairingKey,
                onStartSso: (provider) => unawaited(_startSso(provider)),
                onToggleManual: () =>
                    setState(() => _showManual = !_showManual),
                onTogglePairingKey: () =>
                    setState(() => _showPairingKey = !_showPairingKey),
                onInviteChanged: () => setState(() {}),
                onSubmit: () => unawaited(_submit()),
                invite: _invite,
                device: _device,
                psk: _psk,
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.md),
                ConnectionErrorAlert(error: error),
              ],
              if (widget.footer case final footer?) ...[
                const SizedBox(height: AppSpacing.md),
                footer,
              ],
            ],
          ),
        ),
      ),
      actions: [
        CcButton(
          onPressed: _connecting ? null : () => Navigator.of(context).pop(),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        // SSO-only server: the Connect button would submit credentials the
        // server refuses to honour, so it goes with the fields.
        if (showManual)
          CcButton(
            onPressed: busy ? null : () => unawaited(_submit()),
            variant: CcButtonVariant.accent,
            icon: AppIcons.link,
            loading: _connecting,
            child: Text(l10n.serverSetupConnect),
          ),
      ],
    );
  }
}
