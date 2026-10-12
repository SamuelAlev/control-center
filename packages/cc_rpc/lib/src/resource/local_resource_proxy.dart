import 'remote_resource_proxy_stub.dart'
    if (dart.library.js_interop) 'remote_resource_proxy_web.dart'
    as platform;
import '../resources/resource_tunnel.dart';

/// A capability-scoped, local-only URL for resources on an encrypted RPC channel.
abstract class LocalResourceProxy {
  Uri get baseUri;
  Future<void> close();
}

/// Creates the browser facade. Native clients provide their own VM adapter
/// outside this web-safe package. Each new request resolves the live channel.
Future<LocalResourceProxy> createLocalResourceProxy(
  RemoteResources Function() resources,
) => platform.createLocalResourceProxy(resources);
