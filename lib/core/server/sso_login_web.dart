/// Web half of the SSO login seam — see `sso_login.dart`.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/server/auth_providers.dart';
import 'package:control_center/core/server/sso_pair_link.dart';
import 'package:web/web.dart' as web;

/// Web `/auth/providers` probe. `cc_server` answers it with `Access-Control-
/// Allow-Origin: *` precisely so the hosted client can read it cross-origin
/// before any credential exists.
Future<AuthProvidersSnapshot?> probeAuthProvidersImpl(String origin) async {
  try {
    final response = await web.window
        .fetch('$origin/auth/providers'.toJS)
        .toDart;
    if (!response.ok) {
      return null;
    }
    return AuthProvidersSnapshot.tryParse(
      (await response.text().toDart).toDart,
    );
  } on Object {
    // Silent by design — see the VM variant.
    return null;
  }
}

/// The sessionStorage key holding when this tab last started an SSO
/// round-trip. sessionStorage (not memory) because the popup-blocked
/// fallback RELOADS the app when the IdP redirects back: the marker must
/// survive that navigation, and it must NOT survive into a new tab, where a
/// forged `#fragment` link could otherwise ride an unrelated marker.
const _inFlightKey = 'cc-sso-inflight';
const _privateKey = 'cc-sso-recipient-private';
const _serverOrigin = 'cc-sso-server-origin';

Completer<SsoPairPayload?>? _pending;
JSFunction? _handler;
Timer? _popupWatch;

String? _recipientPrivateKey;
String? _recipientServer;

/// Web SSO opens a popup and decrypts its sealed completion postMessage.
/// If blocked, a same-tab redirect returns a sealed fragment. The private
/// recipient key survives in this tab's sessionStorage, not on the network.
Future<SsoPairPayload?> startSsoLoginImpl({
  required AuthProviderInfo provider,
  required String origin,
  String? clientOrigin,
  void Function()? onAwaiting,
}) async {
  cancelSsoLoginImpl();
  final recipient = await CredentialSeal.newRecipient();
  final loginUrl = provider.loginUrl(
    origin,
    handoffPublicKey: recipient.publicKey,
    clientOrigin: clientOrigin ?? web.window.location.origin,
  );
  try {
    web.window.sessionStorage.setItem(_privateKey, recipient.privateKey);
    web.window.sessionStorage.setItem(_serverOrigin, origin);
  } catch (_) {
    // Popup still works with the in-memory key; a same-tab reload cannot
    // recover it and therefore fails closed instead of accepting plaintext.
  }
  _recipientPrivateKey = recipient.privateKey;
  _recipientServer = origin;
  _mark();
  final popup = web.window.open(loginUrl, '_blank');
  if (popup == null || popup.closed) {
    web.window.location.assign(provider.loginUrl(
      origin,
      relay: 'web',
      handoffPublicKey: recipient.publicKey,
      clientOrigin: clientOrigin ?? web.window.location.origin,
    ));
    return Completer<SsoPairPayload?>().future;
  }
  final completer = _pending = Completer<SsoPairPayload?>();
  _watchPopup(popup, completer);
  _handler = ((web.MessageEvent event) {
    // Trust NOTHING but the expected origin and the message shape.
    if (event.origin != origin) {
      return;
    }
    final raw = event.data.dartify();
    if (raw is! Map || raw['type'] != 'cc-sso-pair') {
      return;
    }
    final server = raw['server'];
    final envelope = raw['envelope'];
    if (server != origin ||
        envelope is! Map ||
        _recipientServer != origin ||
        _recipientPrivateKey == null) {
      return;
    }
    unawaited(() async {
      try {
        final payload = await _openHandoff(
          server,
          envelope.cast<String, dynamic>(),
          _recipientPrivateKey!,
        );
        _removeListener();
        _clearMark();
        if (_pending == completer) _pending = null;
        if (!completer.isCompleted) completer.complete(payload);
      } catch (_) {
        // An invalid or wrong-recipient handoff is not a login.
      }
    }());
  }).toJS;
  web.window.addEventListener('message', _handler!);
  onAwaiting?.call();
  return completer.future;
}

/// Consumes an encrypted same-tab SSO fragment after the IdP returns.
/// Expected SP-initiated logins use tab-scoped sessionStorage. IdP-initiated
/// logins carry a browser-generated recipient in the fragment and require
/// explicit approval in the connect form; neither private key is in HTTP.
Future<SsoPairPayload?> openSsoWebFragment(Map<String, dynamic> json) async {
  final server = json['s'];
  final envelope = json['box'];
  if (server is! String || envelope is! Map) return null;
  final unsolicited = json['idpInitiated'] == true;
  if (!unsolicited && !ssoLoginInFlightImpl()) return null;
  try {
    final privateKey = unsolicited
        ? json['recipientPrivateKey']
        : web.window.sessionStorage.getItem(_privateKey);
    final expected = unsolicited
        ? server
        : web.window.sessionStorage.getItem(_serverOrigin);
    if (privateKey is! String || server != expected) return null;
    final result = await _openHandoff(
      server,
      envelope.cast<String, dynamic>(),
      privateKey,
    );
    if (!unsolicited) _clearMark();
    return result;
  } catch (_) {
    return null;
  }
}

Future<SsoPairPayload> _openHandoff(
  String server,
  Map<String, dynamic> envelope,
  String privateKey,
) async {
  final clear = await CredentialSeal.open(
    recipientPrivateKey: privateKey,
    envelope: envelope,
    context: server,
  );
  final deviceId = clear['i'];
  final psk = clear['k'];
  if (clear['s'] != server ||
      deviceId is! String || deviceId.isEmpty ||
      psk is! String || psk.isEmpty) {
    throw const FormatException('Invalid SSO handoff');
  }
  return SsoPairPayload(server: server, deviceId: deviceId, psk: psk);
}

/// Drops the relay listener and resolves any pending round-trip with null.
/// The sessionStorage marker is deliberately left alone: a same-tab fallback
/// still has to be recognized as expected when the reload comes back.
void cancelSsoLoginImpl() {
  _removeListener();
  final pending = _pending;
  _pending = null;
  if (pending != null && !pending.isCompleted) {
    pending.complete(null);
  }
}

/// Whether this tab has a round-trip inside its adoption window. The browser
/// leg takes seconds-to-minutes; ten covers the slowest IdP login without
/// leaving the door propped open.
bool ssoLoginInFlightImpl({Duration window = const Duration(minutes: 10)}) {
  try {
    final raw = web.window.sessionStorage.getItem(_inFlightKey);
    final at = raw == null ? null : int.tryParse(raw);
    return at != null &&
        DateTime.now().millisecondsSinceEpoch - at <= window.inMilliseconds;
  } on Object {
    return false;
  }
}

void _mark() {
  try {
    web.window.sessionStorage.setItem(
      _inFlightKey,
      '${DateTime.now().millisecondsSinceEpoch}',
    );
  } on Object {
    // Storage can be disabled (private modes) — worst case the completion
    // falls back to the pre-filled connect form, never a failure.
  }
}

void _clearMark() {
  try {
    web.window.sessionStorage.removeItem(_inFlightKey);
    web.window.sessionStorage.removeItem(_privateKey);
    web.window.sessionStorage.removeItem(_serverOrigin);
    _recipientPrivateKey = null;
    _recipientServer = null;
  } on Object {
    // Best effort.
  }
}

void _removeListener() {
  _popupWatch?.cancel();
  _popupWatch = null;
  final handler = _handler;
  if (handler != null) {
    web.window.removeEventListener('message', handler);
    _handler = null;
  }
}

/// A closed popup will never post a credential. Completing the attempt is
/// what lets the connect form offer Connect again instead of waiting forever.
void _watchPopup(web.Window popup, Completer<SsoPairPayload?> completer) {
  _popupWatch?.cancel();
  _popupWatch = Timer.periodic(const Duration(milliseconds: 400), (timer) {
    if (!popup.closed) {
      return;
    }
    timer.cancel();
    if (identical(_popupWatch, timer)) {
      _popupWatch = null;
    }
    if (!identical(_pending, completer) || completer.isCompleted) {
      return;
    }
    _removeListener();
    _clearMark();
    _pending = null;
    completer.complete(null);
  });
}
