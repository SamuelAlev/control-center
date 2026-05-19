import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';

/// Assembles this server's live [ConnectionDescriptor] — every way a client
/// can currently reach it (PRD 15 §1) — and keeps it current as tunnels come
/// and go.
///
/// Path sources:
///  * **loopback** — always (the thick desktop / same-machine case).
///  * **LAN** — every non-loopback IPv4 interface address, when the server
///    is bound beyond loopback.
///  * **wss** — the configured `--public-url` when it names a non-loopback
///    host (VPS or reverse proxy).
///  * **tunnel** — registered dynamically by the tunnel manager
///    ([setTunnelPath]); tailscale registers a [TailnetPath], cloudflared /
///    ngrok register a [WssPath].
///  * **relay** — the signaling broker + this server's relay room, always
///    (the guaranteed NAT-traversal fallback).
///
/// The descriptor also names the **bulk HTTPS base** (media proxy, model
/// downloads) so relayed clients can route bulk transfers around the control
/// plane when any HTTP path is reachable (PRD 15 §11).
class ServerDescriptorService {
  /// Creates a descriptor service for [identity] under [config].
  ServerDescriptorService({
    required this.config,
    required this.identity,
    int? boundPort,
  }) : _boundPort = boundPort ?? config.port;

  /// The resolved server config.
  final CcServerConfig config;

  /// The server identity (id, name, fingerprint, relay room).
  final ServerIdentity identity;

  int _boundPort;
  ConnectionPath? _tunnelPath;
  String? _tunnelHttpBase;

  /// Records the actually-bound RPC port (differs from config when `--port 0`).
  set boundPort(int port) => _boundPort = port;

  /// Registers (or clears, with nulls) the managed tunnel's path once the
  /// supervised binary reports its address. [httpBase] is the tunnel's HTTPS
  /// origin for bulk transfers.
  void setTunnelPath(ConnectionPath? path, {String? httpBase}) {
    _tunnelPath = path;
    _tunnelHttpBase = httpBase;
  }

  /// Builds the current descriptor.
  Future<ConnectionDescriptor> describe() async {
    final paths = <ConnectionPath>[LoopbackPath(port: _boundPort)];

    if (config.bindAny) {
      for (final host in await _lanAddresses()) {
        paths.add(
          LanPath(host: host, port: _boundPort, tls: config.tlsConfigured),
        );
      }
    }

    final public = Uri.tryParse(config.publicUrl);
    if (public != null &&
        public.host.isNotEmpty &&
        !_isLoopbackHost(public.host)) {
      paths.add(WssPath(uri: config.publicUrl));
    }

    final tunnel = _tunnelPath;
    if (tunnel != null) {
      paths.add(tunnel);
    }

    if (config.signalingUrl.isNotEmpty) {
      paths.add(
        RelayPath(signalingUrl: config.signalingUrl, room: identity.relayRoom),
      );
    }

    return ConnectionDescriptor(
      serverId: identity.serverId,
      serverName: identity.serverName,
      fingerprint: identity.fingerprint,
      paths: paths,
      bulkHttpBase: _bulkHttpBase(public),
      insecureAllowed: config.allowInsecure && !config.tlsConfigured,
    );
  }

  String? _bulkHttpBase(Uri? public) {
    if (_tunnelHttpBase != null && _tunnelHttpBase!.isNotEmpty) {
      return _tunnelHttpBase;
    }
    if (public != null && public.host.isNotEmpty) {
      final scheme = switch (public.scheme) {
        'wss' || 'https' => 'https',
        _ => 'http',
      };
      if (!_isLoopbackHost(public.host) || scheme == 'https') {
        return Uri(
          scheme: scheme,
          host: public.host,
          port: public.hasPort ? public.port : null,
        ).toString();
      }
    }
    return 'http://127.0.0.1:$_boundPort';
  }

  Future<List<String>> _lanAddresses() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      return [
        for (final i in interfaces)
          for (final a in i.addresses)
            if (!a.isLoopback) a.address,
      ];
    } catch (_) {
      return const [];
    }
  }

  static bool _isLoopbackHost(String host) {
    final lower = host.toLowerCase();
    return lower == 'localhost' ||
        lower == '127.0.0.1' ||
        lower == '::1' ||
        lower == '[::1]' ||
        lower.startsWith('127.');
  }
}
