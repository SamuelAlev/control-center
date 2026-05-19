/// Web stub for combined server discovery: a browser can join neither
/// multicast groups nor the tailscale CLI, so discovery is a desktop-only
/// affordance. Mirrors the API of `server_discovery.dart` and always returns
/// nothing.
library;

import 'package:control_center/core/server/lan_discovery_web.dart';

export 'lan_discovery_web.dart' show DiscoveredServer, DiscoverySource;

/// No-op discovery on web.
class ServerDiscovery {
  /// Creates the stub discoverer.
  const ServerDiscovery();

  /// Always resolves to an empty list on web.
  Future<List<DiscoveredServer>> discover({
    Duration timeout = const Duration(seconds: 3),
  }) async => const [];

  /// Always completes without emitting on web.
  Stream<List<DiscoveredServer>> watch({
    Duration timeout = const Duration(seconds: 3),
  }) => const Stream.empty();
}
