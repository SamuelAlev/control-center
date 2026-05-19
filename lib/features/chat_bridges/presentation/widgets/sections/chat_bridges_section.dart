import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_connect_dialog.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_create_app_dialog.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_customize_bot_dialog.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_link_dialog.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/scope_badge.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Accounts: the workspace's chat bots, one block per provider.
///
/// Rendered from `chat.providers`, so this widget names no provider: a server
/// that offers Discord grows a Discord block here with no client change. Per
/// provider, an admin connects the app (credentials go straight to the server and
/// never come back) and every member links their own chat identity so their
/// messages are attributed to them rather than to whoever installed the app.
/// Which half of the chat-bridge surface to render.
///
/// A chat bridge spans two scopes, so it is split rather than filed whole under
/// one of them: connecting a Slack app and customizing the bot is workspace
/// setup an admin does once, while linking *your* Slack account to *your* user
/// is personal and lives with the rest of your identity.
enum ChatBridgeSurface {
  /// Connect/disconnect, guided setup, bot customization, and the roster of
  /// who in the workspace has linked. Workspace-scoped, admin-gated.
  workspaceSetup,

  /// Just "link my account" for each connected provider. User-scoped.
  myAccountLink,
}

/// The chat-bridge settings surface, rendered as one of two halves.
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
    final workspaceId = context.currentWorkspaceId;
    final providers = ref.watch(chatProvidersProvider).value ?? const [];
    if (providers.isEmpty) {
      // No provider offered (or the list has not arrived): a card with nothing
      // actionable in it is worse than no card.
      return const SizedBox.shrink();
    }
    final links = ref.watch(chatUserLinksProvider).value ?? const [];
    final isAdmin =
        workspaceId != null &&
        (ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false);

    // The personal half has nothing to say until an admin has connected
    // something — an unconnected provider offers no account to link.
    final visible = surface == ChatBridgeSurface.myAccountLink
        ? providers.where((v) => v.status.isConnected).toList()
        : providers;
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      label: surface == ChatBridgeSurface.myAccountLink
          ? l10n.chatMyAccountsTitle
          : l10n.chatBridgesTitle,
      trailing: ScopeBadge(
        surface == ChatBridgeSurface.myAccountLink
            ? SettingScope.user
            : SettingScope.workspace,
      ),
      child: Column(
        children: [
          for (final view in visible)
            _ProviderBlock(
              view: view,
              links: links.where((l) => l.provider == view.provider).toList(),
              isAdmin: isAdmin,
              surface: surface,
            ),
        ],
      ),
    );
  }
}

/// One provider's rows: connect/disconnect, guided setup, customization, and the
/// link roster.
class _ProviderBlock extends ConsumerWidget {
  const _ProviderBlock({
    required this.view,
    required this.links,
    required this.isAdmin,
    required this.surface,
  });

  final ChatProviderView view;
  final List<ChatUserLinkView> links;
  final bool isAdmin;
  final ChatBridgeSurface surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final descriptor = view.descriptor;
    final status = view.status;
    final name = descriptor.displayName;
    final myUserId = ref.watch(currentUserIdProvider);
    final controller = ref.read(chatConnectionControllerProvider.notifier);
    final busy = ref.watch(chatConnectionControllerProvider).isLoading;
    final connected = status.isConnected;

    // Personal surface: one row, "link my <provider> account". Everything else
    // here — connect, guided setup, bot customization, the roster of who else
    // linked — is workspace administration and belongs on the workspace page.
    if (surface == ChatBridgeSurface.myAccountLink) {
      return SettingsRow(
        icon: AppIcons.link,
        title: l10n.chatLinkMyAccount(name),
        subtitle: _myLinkSubtitle(l10n, name, links, myUserId),
        trailing: CcButton(
          variant: CcButtonVariant.secondary,
          icon: AppIcons.atSign,
          onPressed: () => showChatLinkDialog(context, descriptor),
          child: Text(l10n.chatLinkMyAccount(name)),
        ),
      );
    }

    return Column(
      children: [
        SettingsRow(
          icon: connected ? AppIcons.messagesSquare : AppIcons.plug,
          title: connected
              ? l10n.chatConnectedTo(
                  status.botName ?? name,
                  status.teamName ?? '',
                )
              : name,
          subtitle: connected
              ? ''
              : l10n.chatProviderDescription(
                  name,
                  '/${descriptor.commandName} ticket',
                ),
          subtitleWidget: connected
              ? _StatusLine(status: status, providerName: name)
              : (isAdmin ? null : Text(l10n.chatAdminOnly(name))),
          trailing: connected
              ? CcButton(
                  variant: CcButtonVariant.secondary,
                  icon: AppIcons.unplug,
                  onPressed: !isAdmin || busy
                      ? null
                      : () => controller.disconnect(view.provider),
                  child: Text(l10n.chatDisconnectProvider),
                )
              : CcButton(
                  icon: AppIcons.plug,
                  onPressed: !isAdmin || busy
                      ? null
                      : () => showChatConnectDialog(context, ref, descriptor),
                  child: Text(l10n.chatConnectProvider(name)),
                ),
        ),
        // The guided create is offered *before* connecting, because it is how you
        // get the credentials the connect dialog asks for.
        if (!connected && isAdmin && descriptor.supportsGuidedSetup)
          SettingsRow(
            icon: AppIcons.sparkles,
            title: l10n.chatCreateAppTitle(name),
            subtitle: l10n.chatCreateAppHint(name),
            trailing: CcButton(
              variant: CcButtonVariant.secondary,
              icon: AppIcons.sparkles,
              onPressed: busy
                  ? null
                  : () => showChatCreateAppDialog(context, ref, descriptor),
              child: Text(l10n.chatCreateAppCta),
            ),
          ),
        if (connected) ...[
          if (isAdmin && descriptor.supportsBotCustomization)
            SettingsRow(
              icon: AppIcons.slidersHorizontal,
              title: l10n.chatCustomizeBot,
              // Reshaping the app needs the management credential; without one
              // the row says why rather than failing on press.
              subtitle: status.canManageApp
                  ? l10n.chatCustomizeBotDescription
                  : l10n.chatCustomizeBotUnavailable,
              trailing: CcButton(
                variant: CcButtonVariant.secondary,
                icon: AppIcons.pencil,
                onPressed: !status.canManageApp || busy
                    ? null
                    : () =>
                          showChatCustomizeBotDialog(context, ref, descriptor),
                child: Text(l10n.chatCustomizeBot),
              ),
            ),
          SettingsRow(
            icon: AppIcons.users,
            title: l10n.chatLinkedAccounts,
            subtitle: links.isEmpty
                ? l10n.chatNoLinkedAccounts(name)
                : l10n.chatLinkedMemberCount(links.length),
            trailing: const SizedBox.shrink(),
          ),
          for (final link in links)
            _LinkRow(
              link: link,
              canUnlink: isAdmin || link.userId == myUserId,
              onUnlink: () => controller.unlink(view.provider, link.userId),
            ),
        ],
      ],
    );
  }

  /// Whether *this* user is linked — the only part of the roster that changes
  /// what they should do next.
  static String _myLinkSubtitle(
    AppLocalizations l10n,
    String providerName,
    List<ChatUserLinkView> links,
    String? myUserId,
  ) {
    final mine = links.where((l) => l.userId == myUserId).firstOrNull;
    if (mine == null) {
      return l10n.chatLinkMyAccountDescription(providerName);
    }
    return l10n.chatLinkedAs(mine.externalUserId);
  }
}

/// The live state of one connection: a tag plus, when the provider refused
/// streaming, the one caveat that changes how replies look.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status, required this.providerName});

  final ChatConnectionStatus status;
  final String providerName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem;
    final (label, tone) = switch (status.state) {
      ChatConnectionState.connected => (
        l10n.chatStateLive,
        CcStatusTone.positive,
      ),
      ChatConnectionState.connecting => (
        l10n.chatStateConnecting,
        CcStatusTone.caution,
      ),
      ChatConnectionState.error => (l10n.chatStateError, CcStatusTone.negative),
      ChatConnectionState.disconnected => (
        l10n.chatNotConnected,
        CcStatusTone.neutral,
      ),
    };
    final caption = CcTypography.caption.copyWith(
      color: t?.textTertiary,
      height: 1.45,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CcStatusTag(label: label, tone: tone),
            if (status.lastError != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.lastError!,
                  style: caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        if (status.streamingAvailable == false) ...[
          const SizedBox(height: 4),
          Text(l10n.chatStreamingUnavailable(providerName), style: caption),
        ],
      ],
    );
  }
}

/// One linked chat identity.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.link,
    required this.canUnlink,
    required this.onUnlink,
  });

  final ChatUserLinkView link;
  final bool canUnlink;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsRow(
      icon: AppIcons.userCheck,
      title: link.userLabel,
      subtitle: link.method == 'email'
          ? l10n.chatLinkMethodEmail(link.externalUserId)
          : l10n.chatLinkMethodCode(link.externalUserId),
      trailing: CcButton(
        variant: CcButtonVariant.ghost,
        icon: AppIcons.unlink,
        onPressed: canUnlink ? onUnlink : null,
        child: Text(l10n.chatUnlink),
      ),
    );
  }
}
