import 'dart:convert';

import 'package:control_center/core/server/server_connection_config.dart';

/// Decodes a base64url-JSON fragment, or null when it is not one.
Map<String, dynamic>? decodePairingJson(String fragment) {
  final text = fragment.trim();
  try {
    final padded = text.padRight((text.length + 3) & ~3, '=');
    final json = jsonDecode(utf8.decode(base64Url.decode(padded)));
    return json is Map ? json.cast<String, dynamic>() : null;
  } on FormatException {
    return null;
  }
}

/// Decodes a pairing fragment into its string fields: base64url JSON, or a
/// `key=value&…` query string. Null when it is neither.
///
/// Nested values such as an invite's `d` descriptor stringify; nothing here
/// reads them.
Map<String, String>? decodePairingFragment(String fragment) {
  final text = fragment.trim();
  if (text.isEmpty) {
    return null;
  }
  final json = decodePairingJson(text);
  if (json != null) {
    return {for (final e in json.entries) e.key: '${e.value}'};
  }
  try {
    final fields = Uri.splitQueryString(text);
    return fields.isEmpty ? null : fields;
  } on Object {
    return null;
  }
}

/// Builds the link a first-party client accepts: [origin] plus the credential
/// in the URL FRAGMENT, which never reaches a server's logs.
String buildPairingLink({
  required String origin,
  required String server,
  required String deviceId,
  required String psk,
}) {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'s': server, 'i': deviceId, 'k': psk})))
      .replaceAll('=', '');
  return '$origin/#$payload';
}

/// What a pasted invite or pairing link asks this client to do.
///
/// Parsing grants nothing: anyone can forge a link, so a caller must show
/// [displayServer] and wait for an explicit Connect. Phone relay links (a v2
/// payload with no `s`) and sealed SSO completions do not parse.
class PairingLink {
  const PairingLink._({
    required this.server,
    required this.displayServer,
    required this.deviceId,
    required this.psk,
    required this.inviteCode,
  });

  /// The server exactly as the link named it.
  final String server;

  /// The normalized `ws(s)://` address this link connects to.
  final String displayServer;

  /// The minted device id; empty for an invite.
  final String deviceId;

  /// The minted device credential; empty for an invite.
  final String psk;

  /// The one-time invite code; empty for a pairing link.
  final String inviteCode;

  /// Reads a whole link, or a bare fragment payload. Null unless it names a
  /// valid server and either an invite code or a device credential.
  static PairingLink? parse(String input) {
    final text = input.trim();
    final hash = text.indexOf('#');
    final fields = decodePairingFragment(
      hash < 0 ? text : text.substring(hash + 1),
    );
    if (fields == null) {
      return null;
    }
    final server = (fields['server'] ?? fields['s'] ?? '').trim();
    final displayServer = normalizeServerUrl(server);
    final deviceId = (fields['device'] ?? fields['i'] ?? '').trim();
    final psk = (fields['psk'] ?? fields['k'] ?? '').trim();
    final inviteCode = (fields['invite'] ?? fields['inv'] ?? '').trim();
    final hasCredential = deviceId.isNotEmpty && psk.isNotEmpty;
    if (displayServer == null || (inviteCode.isEmpty && !hasCredential)) {
      return null;
    }
    return PairingLink._(
      server: server,
      displayServer: displayServer,
      deviceId: deviceId,
      psk: psk,
      inviteCode: inviteCode,
    );
  }
}
