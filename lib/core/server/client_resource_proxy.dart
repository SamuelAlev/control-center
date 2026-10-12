import 'package:cc_rpc/cc_rpc.dart'
    if (dart.library.io) 'local_resource_proxy_io.dart'
    as platform;
import 'package:cc_rpc/cc_rpc.dart' show LocalResourceProxy, RemoteResources;

/// Keeps native loopback hosting in client platform infrastructure, while the
/// shared RPC package and browser path remain free of VM-only imports.
Future<LocalResourceProxy> createClientResourceProxy(
  RemoteResources Function() resources,
) => platform.createLocalResourceProxy(resources);
