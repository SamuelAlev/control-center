/// VM variant of the identity-probe HTTP client factory.
///
/// `ServerEntryFactory.fromManualUrl` probes `GET <server>/healthz` to read
/// the identity it then TOFU-pins. A non-loopback `cc_server` serves TLS
/// with a SELF-SIGNED certificate by design, so the default `http.Client`
/// (strict X.509) fails the handshake and the whole add-server flow reports
/// a reachable server as unreachable.
///
/// Why relaxing validation here is safe: the probed fingerprint is only a
/// hint — it is verified cryptographically by the Ed25519 handshake on the
/// first connect (`connectToEntry`), so a poisoned probe fails closed there
/// instead of trusting anything. The callback is additionally narrowed to
/// the exact host:port under probe, so a reused client can never silently
/// cover an unrelated request. Do NOT replace this with
/// `HttpOverrides.global` — that would disable validation app-wide.
library;

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Returns a factory for a probe client that accepts the self-signed
/// certificate of [httpBase]'s host:port only.
http.Client Function() identityProbeClientFactory(Uri httpBase) {
  final host = httpBase.host;
  final port = httpBase.hasPort
      ? httpBase.port
      : (httpBase.scheme == 'https' ? 443 : 80);
  return () {
    final inner = HttpClient()
      ..badCertificateCallback = (cert, certHost, certPort) =>
          certHost == host && certPort == port;
    return IOClient(inner);
  };
}
