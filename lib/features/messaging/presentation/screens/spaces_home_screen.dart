import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The bare `/spaces` landing: no conversation selected. A quiet empty state
/// pointing at the space list (the global sidebar's inline list when
/// expanded, the directory's own sub-sidebar in rail mode) plus a new-space
/// action. The conversation surface itself lives at `/spaces/:spaceId`
/// (MessagingScreen).
class SpacesHomeScreen extends ConsumerWidget {
  /// Creates a [SpacesHomeScreen].
  const SpacesHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ScopedShortcuts(
      scope: '/spaces',
      bindings: {'msg.new-space': () => showNewSpaceDialog(context, ref)},
      child: Center(
        child: CcEmptyState(
          icon: AppIcons.messagesSquare,
          message: l10n.selectConversation,
          description: l10n.spacesHomeDescription,
          action: CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => showNewSpaceDialog(context, ref),
            child: Text(l10n.newSpace),
          ),
        ),
      ),
    );
  }
}
