import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/server/identity_probe_client.dart'
    if (dart.library.js_interop) 'package:control_center/core/server/identity_probe_client_web.dart';
import 'package:control_center/core/server/server_connection_config.dart';

/// Builds [ServerEntry]s from the three ways a client learns about a server:
/// a pairing/invite payload (carries the full descriptor), a discovered LAN
/// service, or a manually typed URL (the server's identity is probed from
/// `/healthz` before anything is trusted).
final class ServerEntryFactory {
  ServerEntryFactory._();

  /// From a descriptor map handed back by `pairing.mint`, an invite
  /// redemption, or a pairing QR. The descriptor's fingerprint becomes the
  /// TOFU pin.
  static ServerEntry fromDescriptorMap(
    Map<String, dynamic> descriptor, {
    required String deviceId,
  }) => ServerEntry(
    descriptor: ConnectionDescriptor.fromJson(descriptor),
    deviceId: deviceId,
  );

  /// From a manually typed URL: normalizes it, probes `/healthz` for the
  /// server's published identity, and builds a single-path descriptor. The
  /// probed fingerprint is pinned — and then *verified cryptographically* on
  /// the first connect (the probe alone is not proof; the Ed25519 handshake
  /// is). Returns null when the URL is invalid or the server unreachable.
  static Future<ServerEntry?> fromManualUrl({
    required String rawUrl,
    required String deviceId,
  }) async {
    final normalized = normalizeServerUrl(rawUrl);
    if (normalized == null) {
      return null;
    }
    final wsUri = Uri.parse(normalized);
    final httpBase = wsUri.replace(
      scheme: wsUri.scheme == 'wss' ? 'https' : 'http',
      path: '',
    );
    final probe = await probeServerIdentity(
      httpBase,
      httpClientFactory: identityProbeClientFactory(httpBase),
    );
    if (probe == null) {
      return null;
    }
    final path = connectionPathFor(wsUri);
    return ServerEntry(
      descriptor: ConnectionDescriptor(
        serverId: probe.serverId,
        serverName: probe.serverName,
        fingerprint: probe.fingerprint,
        paths: [path],
        insecureAllowed: probe.insecure,
      ),
      deviceId: deviceId,
    );
  }
}

/// Classifies a normalized `ws(s)://…` server URI into its single manual-URL
/// [ConnectionPath]: loopback / tailnet / public-wss / plaintext-LAN, in that
/// precedence. Pure (no probing) so the classification is unit-testable.
ConnectionPath connectionPathFor(Uri wsUri) {
  final port = wsUri.hasPort ? wsUri.port : (wsUri.scheme == 'wss' ? 443 : 80);
  if (TransportSecurityPolicy.isLoopbackHost(wsUri.host)) {
    return LoopbackPath(port: port);
  }
  if (TransportSecurityPolicy.isTailnetHost(wsUri.host)) {
    return TailnetPath(
      host: wsUri.host,
      port: port,
      tls: wsUri.scheme == 'wss',
    );
  }
  if (wsUri.scheme == 'wss') {
    return WssPath(uri: wsUri.toString());
  }
  return LanPath(host: wsUri.host, port: port, tls: false);
}
