import 'dart:io';

import 'package:cc_harness_runtime/cc_harness_runtime.dart'
    show isNonPublicAddress;

/// Whether [uri] names a host the media proxy must refuse: an empty host,
/// `localhost` and its subdomains, `metadata.google.internal`, or an IP
/// literal that is not public ([isNonPublicAddress]). Re-run on every
/// redirect hop so a signed URL cannot 3xx to an internal address.
///
/// A bare hostname returns `false`: [permittedAddressFor] resolves it and
/// applies the same rule to every answer.
bool isBlockedProxyTarget(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host.isEmpty) {
    return true;
  }
  if (host == 'localhost' ||
      host.endsWith('.localhost') ||
      host == 'metadata.google.internal') {
    return true;
  }
  final addr = InternetAddress.tryParse(host);
  if (addr == null) {
    return false; // A hostname; resolved and judged before any connect.
  }
  return isNonPublicAddress(addr);
}

/// Whether [uri]'s host resolves to a media-proxy-blocked address: an early
/// refusal with a clear status. Resolution failure is BLOCKED. It is not
/// the gate: a resolver may answer differently later, so every fetch also
/// connects through [pinnedPermittedConnection], which dials only the
/// address it judged.
Future<bool> resolvesToBlockedAddress(Uri uri) async {
  final host = uri.host;
  if (host.isEmpty || InternetAddress.tryParse(host) != null) {
    return false; // Literals were already judged synchronously.
  }
  try {
    final addresses = await InternetAddress.lookup(
      host,
    ).timeout(const Duration(seconds: 5));
    if (addresses.isEmpty) {
      return true;
    }
    return addresses.any(isNonPublicAddress);
  } on Object {
    return true;
  }
}

/// The address to connect to for [uri], resolved once with [lookup] and
/// judged by the media-proxy rules ([isBlockedProxyTarget]); null when the
/// host is blocked, resolves to any blocked address, or does not resolve.
/// Every answer must pass, so a name with one private record is refused
/// outright.
Future<InternetAddress?> permittedAddressFor(
  Uri uri, {
  Future<List<InternetAddress>> Function(String host) lookup =
      InternetAddress.lookup,
}) async {
  if (isBlockedProxyTarget(uri)) {
    return null;
  }
  final literal = InternetAddress.tryParse(uri.host);
  if (literal != null) {
    return literal;
  }
  final List<InternetAddress> addresses;
  try {
    addresses = await lookup(uri.host).timeout(const Duration(seconds: 5));
  } on Object {
    return null;
  }
  if (addresses.isEmpty || addresses.any(isNonPublicAddress)) {
    return null;
  }
  return addresses.first;
}

/// An [HttpClient.connectionFactory].
typedef ConnectionFactory =
    Future<ConnectionTask<Socket>> Function(
      Uri uri,
      String? proxyHost,
      int? proxyPort,
    );

/// An [HttpClient.connectionFactory] that closes the check-then-connect gap
/// a separate lookup leaves: it resolves the host once, refuses a blocked
/// answer ([permittedAddressFor]), and connects to exactly that address,
/// with TLS still verified for the URL's host name. A resolver that answers
/// differently later (DNS rebinding) never gets a second say. Every redirect
/// hop opens its own connection through it, so each hop is pinned too.
///
/// Pair with `findProxy = (_) => 'DIRECT'`: a proxy would connect by name.
Future<ConnectionTask<Socket>> pinnedPermittedConnection(
  Uri uri,
  String? proxyHost,
  int? proxyPort,
) => pinnedConnectionVia()(uri, proxyHost, proxyPort);

/// [pinnedPermittedConnection] with its resolver ([lookup]) and dialer
/// ([dial]) supplied, for tests.
ConnectionFactory pinnedConnectionVia({
  Future<List<InternetAddress>> Function(String host) lookup =
      InternetAddress.lookup,
  Future<ConnectionTask<Socket>> Function(InternetAddress address, int port)
      dial = Socket.startConnect,
}) => (uri, proxyHost, proxyPort) async {
  if (proxyHost != null || proxyPort != null) {
    throw const SocketException('a pinned connection never uses a proxy');
  }
  final address = await permittedAddressFor(uri, lookup: lookup);
  if (address == null) {
    throw SocketException('refused to connect to ${uri.host}');
  }
  final task = await dial(address, uri.port);
  final socket = uri.scheme == 'https'
      ? task.socket.then<Socket>(
          (raw) => SecureSocket.secure(raw, host: uri.host),
        )
      : task.socket;
  return ConnectionTask.fromSocket(socket, task.cancel);
};
