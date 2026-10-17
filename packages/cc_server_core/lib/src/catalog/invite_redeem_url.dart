part of '../remote_rpc_catalog.dart';

/// Derives the invite-redemption HTTP endpoint from the advertised RPC
/// WebSocket URL. Returns '' when `rpcUrl` is empty/unparseable.
String _redeemUrlFrom(String rpcUrl) {
  if (rpcUrl.isEmpty) {
    return '';
  }
  final uri = Uri.tryParse(rpcUrl);
  if (uri == null || uri.host.isEmpty) {
    return '';
  }
  final scheme = uri.scheme == 'wss' || uri.scheme == 'https'
      ? 'https'
      : 'http';
  return uri.replace(scheme: scheme, path: '/invites/redeem').toString();
}

/// Derives the best HTTP-reachable redemption URL from a live descriptor.
///
/// Prefers non-loopback direct paths (tunnel > LAN > tailnet > public wss)
/// over the static `config.publicUrl`, so an invite created after starting a
/// tunnel or binding to the LAN points at the reachable address — not
/// localhost. Returns null when only loopback is available (the caller falls
/// back to the static URL; the client warns the operator).
String? _bestRedeemUrlFromDescriptor(ConnectionDescriptor? descriptor) {
  if (descriptor == null) {
    return null;
  }
  final sorted = [...descriptor.paths]
    ..sort((a, b) => a.rank.compareTo(b.rank));
  for (final path in sorted) {
    if (path is LoopbackPath) {
      continue; // unreachable off-host
    }
    final uri = path.rpcUri;
    if (uri == null) {
      continue; // relay — no HTTP endpoint
    }
    return _redeemUrlFrom(uri.toString());
  }
  return null;
}
