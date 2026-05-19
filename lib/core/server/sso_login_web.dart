/// Web half of the SSO login seam — see `sso_login.dart`.
library;

import 'dart:async';
import 'dart:js_interop';

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

Completer<SsoPairPayload?>? _pending;
JSFunction? _handler;

/// Web round-trip: a NEW TAB for the IdP, with the completion page posting
/// the minted credential back to this one (origin-validated — the message
/// carries a credential). A blocked popup falls back to navigating this tab,
/// which lands in the boot gate's fragment handling on the way back; that
/// path never returns here, so the future simply never completes.
Future<SsoPairPayload?> startSsoLoginImpl({
  required AuthProviderInfo provider,
  required String origin,
  String? clientOrigin,
  void Function()? onAwaiting,
}) {
  cancelSsoLoginImpl();
  final loginUrl = provider.loginUrl(
    origin,
    clientOrigin: clientOrigin ?? web.window.location.origin,
  );
  _mark();
  final popup = web.window.open(loginUrl, '_blank');
  if (popup == null || popup.closed) {
    web.window.location.assign(loginUrl);
    return Completer<SsoPairPayload?>().future;
  }
  final completer = _pending = Completer<SsoPairPayload?>();
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
    final deviceId = raw['deviceId'];
    final psk = raw['psk'];
    if (server is! String ||
        deviceId is! String ||
        psk is! String ||
        server.isEmpty ||
        deviceId.isEmpty ||
        psk.isEmpty) {
      return;
    }
    _removeListener();
    _clearMark();
    if (_pending == completer) {
      _pending = null;
    }
    if (!completer.isCompleted) {
      completer.complete(
        SsoPairPayload(server: server, deviceId: deviceId, psk: psk),
      );
    }
  }).toJS;
  web.window.addEventListener('message', _handler!);
  onAwaiting?.call();
  return completer.future;
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
  } on Object {
    // Best effort.
  }
}

void _removeListener() {
  final handler = _handler;
  if (handler != null) {
    web.window.removeEventListener('message', handler);
    _handler = null;
  }
}
