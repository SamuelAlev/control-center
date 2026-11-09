import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_connect_dialog.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_create_app_dialog.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_customize_bot_dialog.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_shared_app_row.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_status_line.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The workspace half of one provider: connect or disconnect, the shared-app
/// install, guided setup, bot customization and the link roster.
///
/// Two ways in, never mixed in one workspace. An admin either pastes the
/// tokens of the workspace's own app (which Control Center can also create
/// and later reshape) or installs the shared Control Center app through the
/// browser. A shared-app connection has no tokens or bot settings here, so
/// those rows are not offered for it.
class ChatProviderSetupBlock extends ConsumerWidget {
  /// Creates a [ChatProviderSetupBlock].
  const ChatProviderSetupBlock({
    super.key,
    required this.view,
    required this.workspaceId,
    required this.links,
    required this.isAdmin,
  });

  /// The provider and this workspace's connection to it.
  final ChatProviderView view;

  /// The workspace being set up.
  final String workspaceId;

  /// The workspace's links on this provider.
  final List<ChatUserLinkView> links;

  /// Whether the reader administers the workspace.
  final bool isAdmin;

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
    final ownApp = status.mode != ChatConnectionMode.connect;
    final sharedLane = chatSharedAppLane(view.provider);

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
              ? ChatStatusLine(status: status, providerName: name)
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
        if (!connected && sharedLane != null)
          ChatSharedAppRow(
            lane: sharedLane,
            workspaceId: workspaceId,
            providerName: name,
            canManage: isAdmin && !busy,
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
          if (ownApp && isAdmin && descriptor.supportsBotCustomization)
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
