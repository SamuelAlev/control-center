import 'package:control_center/features/chat_bridges/presentation/widgets/sections/chat_my_link_block.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/sections/chat_provider_setup_block.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which half of the chat-bridge surface to render.
///
/// A chat bridge spans two scopes, so it is split rather than filed whole under
/// one of them: connecting a Slack app and customizing the bot is workspace
/// setup an admin does once (Workspace → Integrations), while linking *your*
/// Slack account to *your* user is personal and lives with the rest of your
/// accounts (You → Profile).
enum ChatBridgeSurface {
  /// Connect/disconnect, the shared-app install, guided setup, bot
  /// customization and the roster of who in the workspace has linked.
  /// Workspace-scoped, admin-gated.
  workspaceSetup,

  /// Just "link my account" for each connected provider. User-scoped, and
  /// kept for this workspace only.
  myAccountLink,
}

/// Settings: the workspace's chat bots, one block per provider, rendered as
/// one of two halves.
///
/// Rendered from `chat.providers`, so this widget names no provider: a server
/// that offers Discord grows a Discord block here with no client change. Per
/// provider, an admin connects the app (or installs the shared one) and every
/// member links their own chat identity so their messages are attributed to
/// them rather than to whoever installed the app. Shown while
/// [watchChatBridgesApplies] holds for its [surface].
class ChatBridgesSection extends ConsumerWidget {
  /// Creates a [ChatBridgesSection].
  const ChatBridgesSection({
    super.key,
    this.surface = ChatBridgeSurface.workspaceSetup,
  });

  /// Which half to render. See [ChatBridgeSurface].
  final ChatBridgeSurface surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // The same workspace the chat reads are scoped to, so the rows and the
    // shared-app install can never disagree about which one this is.
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final links = ref.watch(chatUserLinksProvider).value ?? const [];
    final personal = surface == ChatBridgeSurface.myAccountLink;
    // The personal half lists only connected providers: an unconnected one
    // offers no account to link.
    final visible = personal
        ? ref.watch(connectedChatProvidersProvider)
        : ref.watch(chatProvidersProvider).value ?? const [];
    final isAdmin =
        ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false;
    final workspaceName = personal
        ? ref.watch(activeWorkspaceProvider)?.name
        : null;

    return SectionCard(
      label: personal ? l10n.chatMyAccountsTitle : l10n.chatBridgesTitle,
      // A link is made in one workspace and acts as the person only there.
      subtitle: workspaceName == null
          ? null
          : Text(l10n.accountReachWorkspace(workspaceName)),
      child: Column(
        children: [
          for (final view in visible)
            if (personal)
              ChatMyLinkBlock(
                view: view,
                links: links.where((l) => l.provider == view.provider).toList(),
              )
            else
              ChatProviderSetupBlock(
                view: view,
                workspaceId: workspaceId,
                links: links.where((l) => l.provider == view.provider).toList(),
                isAdmin: isAdmin,
              ),
        ],
      ),
    );
  }
}

/// Whether [ChatBridgesSection] has anything to show on [surface]: inside a
/// workspace, while the server offers a chat provider (a card with nothing
/// actionable in it is worse than no card). The personal half also waits
/// until an admin has connected one: an unconnected provider offers no
/// account to link.
bool watchChatBridgesApplies(WidgetRef ref, ChatBridgeSurface surface) =>
    ref.watch(activeWorkspaceIdProvider) != null &&
    (surface == ChatBridgeSurface.myAccountLink
        ? ref.watch(connectedChatProvidersProvider).isNotEmpty
        : ref.watch(chatProvidersProvider).value?.isNotEmpty ?? false);
