import 'package:cc_rpc/src/resource/local_resource_proxy.dart';
import 'package:cc_rpc/src/resources/resource_tunnel.dart';

/// Browser-only facade entry point; non-browser callers must supply a native
/// local resource adapter instead.
Future<LocalResourceProxy> createLocalResourceProxy(
  RemoteResources Function() resources,
) => Future.error(UnsupportedError('The resource facade requires a browser'));
