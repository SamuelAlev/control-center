import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The bare `/channels` landing: no conversation selected. A quiet empty state
/// pointing at the channel list (the global sidebar's inline list when
/// expanded, the directory's own sub-sidebar in rail mode) plus a new-channel
/// action. The conversation surface itself lives at `/channels/:channelId`
/// (MessagingScreen).
class ChannelsHomeScreen extends ConsumerWidget {
  /// Creates a [ChannelsHomeScreen].
  const ChannelsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ScopedShortcuts(
      scope: '/channels',
      bindings: {'msg.new-channel': () => showNewChannelDialog(context, ref)},
      child: Center(
        child: CcEmptyState(
          icon: AppIcons.messagesSquare,
          message: l10n.selectConversation,
          description: l10n.channelsHomeDescription,
          action: CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => showNewChannelDialog(context, ref),
            child: Text(l10n.newChannel),
          ),
        ),
      ),
    );
  }
}
