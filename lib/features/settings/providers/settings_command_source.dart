import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Settings destinations in the same order and with the same visibility as the
/// settings sidebar.
class _SettingsCommandSource implements CommandSource {
  @override
  String get id => 'settings';

  @override
  String get category => 'Settings';

  @override
  bool get isDynamic => false;

  @override
  List<CommandItem> buildItems(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const [];
    }

    final isServerOwner = ref.watch(isServerOwnerProvider);
    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context);
    return [
      for (final group in kSettingsNav)
        for (final item in group.items)
          if (!item.ownerOnly || isServerOwner)
            CommandItem(
              id: 'settings:${item.id}',
              label: item.label(l10n),
              description: group.label(l10n),
              category: l10n.settingsLabel,
              icon: item.icon,
              onExecute: () => router.go(item.route(workspaceId)),
            ),
    ];
  }
}

/// Palette commands for the currently visible settings destinations.
final settingsCommandSourceProvider = Provider<CommandSource>(
  (_) => _SettingsCommandSource(),
);
