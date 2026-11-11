import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The button that takes someone allowed to fix a sign-in setup to where it
/// is fixed: [settingsId] is a `kSettingsNav` id, a `server.` one for what
/// only the server's owner controls and a workspace one for its admins.
///
/// Null for anyone else, without a workspace or a router, or on the page the
/// fix already sits on.
Widget? signInSetupAction(
  BuildContext context,
  WidgetRef ref,
  String? settingsId,
) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (settingsId == null || workspaceId == null) {
    return null;
  }
  final server = settingsId.startsWith('server.');
  final allowed = server
      ? ref.watch(isServerOwnerProvider)
      : ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false;
  final item = kSettingsNavItems.where((i) => i.id == settingsId).firstOrNull;
  final router = GoRouter.maybeOf(context);
  if (!allowed || item == null || router == null) {
    return null;
  }
  final route = item.route(workspaceId);
  if (router.routeInformationProvider.value.uri.path == route) {
    return null;
  }
  final l10n = AppLocalizations.of(context);
  return CcButton(
    size: CcButtonSize.sm,
    variant: CcButtonVariant.secondary,
    onPressed: () => router.go(route),
    child: Text(
      server ? l10n.signInOpenServerSettings : l10n.signInOpenIntegrations,
    ),
  );
}
