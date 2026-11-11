import 'package:cc_domain/core/domain/value_objects/forge_connection.dart'
    show ForgeConnectionStatus;
import 'package:control_center/features/chat_bridges/providers/chat_bridge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/your_account_line.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the Chat group on Workspace → Integrations: which chat account the
/// reader linked in this workspace, in one line leading to You → Connected
/// accounts where links are made.
///
/// Only providers the workspace has connected count: an unconnected one
/// offers no account to link, so with none the line is absent
/// ([watchChatAccountStatusApplies]).
class ChatAccountStatusLine extends ConsumerWidget {
  /// Creates a [ChatAccountStatusLine].
  const ChatAccountStatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final connected = ref.watch(connectedChatProvidersProvider);
    final links = ref.watch(chatUserLinksProvider).value;
    if (workspaceId == null || links == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final myUserId = ref.watch(currentUserIdProvider);
    final entries = [
      for (final view in connected)
        (
          name: view.descriptor.displayName,
          account: links
              .where((l) => l.provider == view.provider && l.userId == myUserId)
              .firstOrNull
              ?.externalUserId,
        ),
    ];
    final linked = entries.where((e) => e.account != null).length;
    return YourAccountLine(
      workspaceId: workspaceId,
      status: linked == 0 && entries.length == 1
          ? l10n.yourChatAccountNotLinked(entries.single.name)
          : [
              for (final e in entries)
                yourAccountEntry(
                  l10n,
                  provider: e.name,
                  status: e.account == null
                      ? ForgeConnectionStatus.notConnected
                      : ForgeConnectionStatus.connected,
                  account: e.account ?? '',
                ),
            ].join(' · '),
      attention: linked < entries.length,
    );
  }
}

/// Whether [ChatAccountStatusLine] has anything to say: inside a workspace
/// that has connected a chat provider, once the reader's links have arrived
/// (before that "not linked" would be a guess).
bool watchChatAccountStatusApplies(WidgetRef ref) =>
    ref.watch(activeWorkspaceIdProvider) != null &&
    ref.watch(connectedChatProvidersProvider).isNotEmpty &&
    ref.watch(chatUserLinksProvider).value != null;
