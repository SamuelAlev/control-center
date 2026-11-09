import 'package:control_center/di/providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens [route] inside [workspaceId] for an inbound deep link.
///
/// The route's workspace prefix is what re-scopes the app (the route sync
/// adopts it before the next frame builds), so nothing is pre-set here. A link
/// into a workspace this server does not know falls back to the picker rather
/// than opening an empty screen.
Future<void> openWorkspaceDeepLink(
  ProviderContainer container,
  String workspaceId,
  String route,
) async {
  final known = await container
      .read(workspaceRepositoryProvider)
      .getAll()
      .then((all) => all.any((w) => w.id == workspaceId))
      // A repository that cannot answer must not swallow the link: trust the id
      // and let the target screen report whatever it finds.
      .onError((_, _) => true);
  container.read(routerProvider).go(known ? route : workspaceListRoute);
}
