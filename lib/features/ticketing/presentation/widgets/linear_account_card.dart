import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart'
    show ForgeConnectionStatus;
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticketing_connection_card.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in person's own Linear account: every interactive ticket
/// action they take runs as it. Rendered by onboarding and You → Connected
/// accounts.
///
/// The workspace's choice of vendor and its automation actor stay on
/// Workspace → Integrations ([TicketingConnectionCard]); this card is only
/// the person's sign-in. It shows while the workspace keeps its tickets in
/// Linear, and whenever the person holds a Linear grant, so a grant they
/// made can always be seen and disconnected.
///
/// The card's line says where the sign-in applies: every workspace on this
/// server, unless the workspace signs in to Linear through its own app or
/// its own Connect and so keeps its own grant.
class LinearAccountCard extends ConsumerWidget {
  /// Creates a [LinearAccountCard].
  const LinearAccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final connections = ref.watch(oauthConnectionsProvider(workspaceId));
    final lanes = ref.watch(oauthLanesProvider(workspaceId)).value ?? const {};
    final connection = connections.value?[ConnectOAuthLane.linear];
    if (!watchLinearAccountApplies(ref)) {
      return const SizedBox.shrink();
    }
    final reach = connection == null
        ? null
        : !isWorkspaceOnlyGrant(connection)
        ? l10n.accountReachServer
        : switch (ref.watch(activeWorkspaceProvider)?.name) {
            final name? => l10n.accountReachWorkspace(name),
            null => null,
          };

    return SectionCard(
      label: l10n.ticketing,
      subtitle: reach == null ? null : Text(reach),
      child: LinearSignInRow(
        lane: ConnectOAuthLane.linear,
        workspaceId: workspaceId,
        connection: connection,
        loading: connections.isLoading && !connections.hasValue,
        laneInfo: lanes[ConnectOAuthLane.linear],
        canManage: true,
      ),
    );
  }
}

/// Whether [LinearAccountCard] has anything to show: the workspace keeps its
/// tickets in Linear, or the person holds a Linear grant (working or not),
/// which they must always be able to see and disconnect.
bool watchLinearAccountApplies(WidgetRef ref) {
  if (ref.watch(activeTicketProviderProvider) == TicketProvider.linear) {
    return true;
  }
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  final status = ref
      .watch(oauthConnectionsProvider(workspaceId))
      .value?[ConnectOAuthLane.linear]
      ?.status;
  return status != null && status != ForgeConnectionStatus.notConnected;
}
