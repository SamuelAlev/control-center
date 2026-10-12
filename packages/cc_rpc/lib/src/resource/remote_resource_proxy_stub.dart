import '../resources/resource_tunnel.dart';
import 'local_resource_proxy.dart';

Future<LocalResourceProxy> createLocalResourceProxy(
  RemoteResources Function() resources,
) => Future.error(UnsupportedError('The resource facade requires a browser'));
