import 'package:cc_rpc/src/resource/remote_resource_proxy_stub.dart'
    if (dart.library.js_interop) 'package:cc_rpc/src/resource/remote_resource_proxy_web.dart'
    as platform;
import 'package:cc_rpc/src/resources/resource_tunnel.dart';

/// A capability-scoped, local-only URL for resources on an encrypted RPC channel.
abstract class LocalResourceProxy {
  /// Capability-scoped local URL; it is not a public HTTP resource endpoint.
  Uri get baseUri;

  /// Revokes the capability and cancels active proxied resource work.
  Future<void> close();
}

/// Creates the browser facade. Native clients provide their own VM adapter
/// outside this web-safe package. Each new request resolves the live channel.
Future<LocalResourceProxy> createLocalResourceProxy(
  RemoteResources Function() resources,
) => platform.createLocalResourceProxy(resources);
