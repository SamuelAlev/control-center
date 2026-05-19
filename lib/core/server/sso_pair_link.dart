import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The decoded credential payload of an SSO login bounce-back
/// (`control-center://pair#<base64url {s: origin, i: deviceId, k: psk}>`) —
/// the same `{s, i, k}` shape the web client's URL fragment carries.
class SsoPairPayload {
  /// Creates an [SsoPairPayload].
  const SsoPairPayload({
    required this.server,
    required this.deviceId,
    required this.psk,
  });

  /// The server origin the credential was minted for.
  final String server;

  /// The minted device id.
  final String deviceId;

  /// The minted device credential (one-time-use-shaped).
  final String psk;
}

/// A pair link that arrived while no session could adopt it — the SSO
/// browser round-trip started from the PRE-APP server-setup window, whose
/// completer is still pending. The setup screen listens here and resolves
/// with the credential; the running app never sees a value (it adopts pair
/// links directly).
final ValueNotifier<String?> pendingSsoPairLink = ValueNotifier<String?>(null);

/// When this client last opened a browser SSO round-trip (the connect screen
/// pressing "Sign in with …"), if any. A `control-center://pair` bounce is
/// only auto-adopted inside this window — then it is EXPECTED. Outside it, a
/// pair link is unbidden: anyone can forge one and silently adopting it
/// would re-home the app to an impostor server (the one-click MITM), so the
/// running app refuses it and the setup screen asks the user first.
final ValueNotifier<DateTime?> ssoLoginStartedAt = ValueNotifier<DateTime?>(
  null,
);

/// Marks an SSO browser round-trip as in flight (called just before the
/// browser opens). [at] is injectable for tests.
void markSsoLoginStarted([DateTime? at]) =>
    ssoLoginStartedAt.value = at ?? DateTime.now();

/// Whether a marked round-trip is still inside its adoption window. The
/// browser round-trip takes seconds-to-minutes; ten covers the slowest IdP
/// login without leaving the door propped open for long.
bool isSsoLoginInFlight({Duration window = const Duration(minutes: 10)}) {
  final started = ssoLoginStartedAt.value;
  return started != null && DateTime.now().difference(started) <= window;
}

/// Thrown when the platform refused to hand an SSO login URL to a browser
/// (no registered handler, a sandbox refusal). Connect surfaces map it to
/// the `ssoBrowserOpenFailed` copy — the round-trip never started, so
/// nothing is left in flight.
class SsoBrowserOpenException implements Exception {
  /// Creates an [SsoBrowserOpenException].
  const SsoBrowserOpenException();

  @override
  String toString() => 'Could not open a browser for single sign-on';
}

/// Whether [rawUrl] is an SSO pair bounce-back link.
bool isSsoPairLink(String rawUrl) => rawUrl.startsWith('control-center://pair');

/// Decodes an SSO pair link's credential payload, or null when malformed.
SsoPairPayload? decodeSsoPairLink(String rawUrl) {
  final fragment = Uri.tryParse(rawUrl)?.fragment ?? '';
  if (fragment.isEmpty) {
    return null;
  }
  try {
    final padded = fragment.padRight((fragment.length + 3) & ~3, '=');
    final decoded = jsonDecode(utf8.decode(base64Url.decode(padded)));
    if (decoded is! Map) {
      return null;
    }
    final server = decoded['s'];
    final deviceId = decoded['i'];
    final psk = decoded['k'];
    if (server is! String ||
        server.isEmpty ||
        deviceId is! String ||
        deviceId.isEmpty ||
        psk is! String ||
        psk.isEmpty) {
      return null;
    }
    return SsoPairPayload(server: server, deviceId: deviceId, psk: psk);
  } on Object {
    return null;
  }
}

/// Derives the HTTP origin a browser would use for [rawServerUrl] (a
/// `ws://`/`wss://`/`https://` server URL): scheme-swapped and path-stripped.
String? httpOriginFor(String rawServerUrl) {
  final uri = Uri.tryParse(rawServerUrl.trim());
  if (uri == null || uri.host.isEmpty) {
    return null;
  }
  final scheme = uri.isScheme('wss')
      ? 'https'
      : uri.isScheme('ws')
      ? 'http'
      : uri.scheme;
  if (scheme != 'http' && scheme != 'https') {
    return null;
  }
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '$scheme://${uri.host}$port';
}
