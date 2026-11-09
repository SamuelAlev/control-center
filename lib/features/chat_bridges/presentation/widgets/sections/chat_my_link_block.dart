import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_link_claim_panel.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_link_dialog.dart';
import 'package:control_center/features/chat_bridges/providers/chat_link_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The personal half of one provider: "link my account", and the claim on
/// the member's code waiting for their answer.
///
/// The claim shows here as well as in the link dialog because the member may
/// close the dialog before sending the code; the link is only made once they
/// confirm, so the question has to wait somewhere they will look.
class ChatMyLinkBlock extends ConsumerWidget {
  /// Creates a [ChatMyLinkBlock].
  const ChatMyLinkBlock({super.key, required this.view, required this.links});

  /// The provider and this workspace's connection to it.
  final ChatProviderView view;

  /// The workspace's links on this provider.
  final List<ChatUserLinkView> links;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final descriptor = view.descriptor;
    final name = descriptor.displayName;
    final myUserId = ref.watch(currentUserIdProvider);
    final mine = links.where((l) => l.userId == myUserId).firstOrNull;
    final claim = ref
        .watch(chatPendingLinkProvider(view.provider))
        .value
        ?.claim;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsRow(
          icon: AppIcons.link,
          title: l10n.chatLinkMyAccount(name),
          subtitle: mine == null
              ? l10n.chatLinkMyAccountDescription(name)
              : l10n.chatLinkedAs(mine.externalUserId),
          trailing: CcButton(
            variant: CcButtonVariant.secondary,
            icon: AppIcons.atSign,
            onPressed: () => showChatLinkDialog(context, ref, descriptor),
            child: Text(l10n.chatLinkMyAccount(name)),
          ),
        ),
        if (claim != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ChatLinkClaimPanel(
            provider: view.provider,
            providerName: name,
            claim: claim,
          ),
        ],
      ],
    );
  }
}
