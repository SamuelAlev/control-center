import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter/foundation.dart';

/// Decrypted credential payload of an SSO login bounce-back. The HTTP
/// completion page and deep link contain only an X25519 sealed envelope.
class SsoPairPayload {
  /// Creates an [SsoPairPayload].
  const SsoPairPayload({
    required this.server,
    required this.deviceId,
    required this.psk,
    this.unsolicited = false,
  });

  /// The server origin the credential was minted for.
  final String server;

  /// The minted device id.
  final String deviceId;

  /// The minted device credential (one-time-use-shaped).
  final String psk;

  /// True only for an IdP-initiated assertion; an app must ask before pairing.
  final bool unsolicited;
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

String? _handoffPrivateKey;
String? _handoffServerOrigin;

/// Arms one client-held recipient for a single expected SSO round-trip.
void beginSealedSsoLogin({
  required String origin,
  required String privateKey,
}) {
  _handoffServerOrigin = origin;
  _handoffPrivateKey = privateKey;
  markSsoLoginStarted();
}

/// Invalidates the ephemeral recipient and its login window.
void clearSealedSsoLogin() {
  _handoffPrivateKey = null;
  _handoffServerOrigin = null;
  ssoLoginStartedAt.value = null;
}

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

/// Opens only a client-held encrypted handoff. IdP-initiated browser handoffs
/// carry a browser-generated private key in the URL fragment (never HTTP);
/// those are unbidden and must require explicit user approval before pairing.
Future<SsoPairPayload?> decodeSsoPairLink(String rawUrl) async {
  if (!isSsoPairLink(rawUrl)) return null;
  final fragment = Uri.tryParse(rawUrl)?.fragment ?? '';
  if (fragment.isEmpty) return null;
  try {
    final decoded = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(fragment))),
    );
    if (decoded is! Map || decoded['s'] is! String ||
        decoded['box'] is! Map) return null;
    final unsolicited = decoded['idpInitiated'] == true;
    final privateKey = unsolicited
        ? decoded['recipientPrivateKey']
        : _handoffPrivateKey;
    final expectedOrigin = unsolicited
        ? decoded['s'] as String
        : _handoffServerOrigin;
    if ((!unsolicited && !isSsoLoginInFlight()) ||
        privateKey is! String ||
        expectedOrigin == null ||
        decoded['s'] != expectedOrigin) return null;
    final clear = await CredentialSeal.open(
      recipientPrivateKey: privateKey,
      envelope: (decoded['box'] as Map).cast<String, dynamic>(),
      context: expectedOrigin,
    );
    final deviceId = clear['i'];
    final psk = clear['k'];
    if (clear['s'] != expectedOrigin ||
        deviceId is! String || deviceId.isEmpty ||
        psk is! String || psk.isEmpty) return null;
    if (!unsolicited) clearSealedSsoLogin();
    return SsoPairPayload(
      server: expectedOrigin,
      deviceId: deviceId,
      psk: psk,
      unsolicited: unsolicited,
    );
  } catch (_) {
    return null;
  }
}

/// The marker is only for routing into the setup confirmation UI. It proves
/// nothing: the sealed credential is validated by [decodeSsoPairLink].
bool isIdpInitiatedSsoPairLink(String rawUrl) {
  if (!isSsoPairLink(rawUrl)) return false;
  try {
    final fragment = Uri.parse(rawUrl).fragment;
    final decoded = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(fragment))),
    );
    return decoded is Map && decoded['idpInitiated'] == true;
  } catch (_) {
    return false;
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
