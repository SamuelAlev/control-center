import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/space_folders.dart';
import 'package:cc_remote/widgets/messaging/space_folders_list.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Messaging tab: live spaces grouped by the caller's personal folders.
class MessagingScreen extends ConsumerWidget {
  /// Creates a [MessagingScreen].
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
    final spaces = ref.watch(spacesProvider);
    final prefs = ref.watch(ownServerPrefsProvider);

    return ColoredBox(
      color: t.canvas,
      child: workspaceId == null
          ? const Center(child: CcSpinner(size: 24))
          : spaces.when(
              loading: () => const Center(child: CcSpinner(size: 24)),
              error: (e, _) => CcEmptyState(
                icon: AppIcons.triangleAlert,
                message: l10n.spacesLoadFailed,
                description: e.toString(),
              ),
              data: (items) => prefs.when(
                loading: () => const Center(child: CcSpinner(size: 24)),
                error: (e, _) => CcEmptyState(
                  icon: AppIcons.triangleAlert,
                  message: l10n.spacesLoadFailed,
                  description: e.toString(),
                ),
                data: (_) => RemoteSpaceFoldersList(
                  key: ValueKey(workspaceId),
                  workspaceId: workspaceId,
                  spaces: items,
                  folders: ref.watch(spaceFoldersProvider(workspaceId)),
                ),
              ),
            ),
    );
  }
}
