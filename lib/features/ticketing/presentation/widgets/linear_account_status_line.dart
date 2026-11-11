import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart'
    show ForgeConnectionStatus;
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/your_account_line.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the Tickets group on Workspace → Integrations while the workspace
/// keeps its tickets in Linear: the reader's own Linear account in one line,
/// leading to their profile (You → Profile), where it is managed.
///
/// Local tickets have nothing to sign in to, so the line is absent then
/// ([watchLinearAccountStatusApplies]).
class LinearAccountStatusLine extends ConsumerWidget {
  /// Creates a [LinearAccountStatusLine].
  const LinearAccountStatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final connections = ref.watch(oauthConnectionsProvider(workspaceId)).value;
    if (workspaceId == null || connections == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final connection = connections[ConnectOAuthLane.linear];
    final status = connection?.status ?? ForgeConnectionStatus.notConnected;
    return YourAccountLine(
      workspaceId: workspaceId,
      status: status == ForgeConnectionStatus.notConnected
          ? l10n.yourAccountNotConnected('Linear')
          : yourAccountEntry(
              l10n,
              provider: 'Linear',
              status: status,
              account: connection?.account ?? '',
            ),
      attention: status != ForgeConnectionStatus.connected,
    );
  }
}

/// Whether [LinearAccountStatusLine] has anything to say: inside a workspace
/// that keeps its tickets in Linear, once the reader's sign-ins have arrived
/// (before the first answer "not connected" would be a guess).
bool watchLinearAccountStatusApplies(WidgetRef ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  return workspaceId != null &&
      ref.watch(activeTicketProviderProvider) == TicketProvider.linear &&
      ref.watch(oauthConnectionsProvider(workspaceId)).value != null;
}
