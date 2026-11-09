import 'package:control_center/features/chat_bridges/presentation/widgets/sections/chat_my_link_block.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/sections/chat_provider_setup_block.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/scope_badge.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which half of the chat-bridge surface to render.
///
/// A chat bridge spans two scopes, so it is split rather than filed whole under
/// one of them: connecting a Slack app and customizing the bot is workspace
/// setup an admin does once, while linking *your* Slack account to *your* user
/// is personal and lives with the rest of your identity.
enum ChatBridgeSurface {
  /// Connect/disconnect, the shared-app install, guided setup, bot
  /// customization and the roster of who in the workspace has linked.
  /// Workspace-scoped, admin-gated.
  workspaceSetup,

  /// Just "link my account" for each connected provider. User-scoped.
  myAccountLink,
}

/// Settings: the workspace's chat bots, one block per provider, rendered as
/// one of two halves.
///
/// Rendered from `chat.providers`, so this widget names no provider: a server
/// that offers Discord grows a Discord block here with no client change. Per
/// provider, an admin connects the app (or installs the shared one) and every
/// member links their own chat identity so their messages are attributed to
/// them rather than to whoever installed the app.
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
    final providers = ref.watch(chatProvidersProvider).value ?? const [];
    if (providers.isEmpty || workspaceId == null) {
      // No provider offered (or the list has not arrived): a card with nothing
      // actionable in it is worse than no card.
      return const SizedBox.shrink();
    }
    final links = ref.watch(chatUserLinksProvider).value ?? const [];
    final personal = surface == ChatBridgeSurface.myAccountLink;

    // The personal half has nothing to say until an admin has connected
    // something — an unconnected provider offers no account to link.
    final visible = personal
        ? providers.where((v) => v.status.isConnected).toList()
        : providers;
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }
    final isAdmin =
        ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false;

    return SectionCard(
      label: personal ? l10n.chatMyAccountsTitle : l10n.chatBridgesTitle,
      // The workspace half already lives under Settings → Workspace; a
      // WORKSPACE badge there restates the nav. Keep YOU on the personal
      // half so a Profile page of mixed cards (forge, calendar, chat) still
      // names whose credential this is.
      trailing: personal ? const ScopeBadge(SettingScope.user) : null,
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
