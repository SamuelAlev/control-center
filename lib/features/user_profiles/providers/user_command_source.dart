import 'package:control_center/core/network/models/github_user.dart';
import 'package:control_center/features/user_profiles/providers/org_members_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Dynamic [CommandSource] that contributes organization member items.
class UserCommandSource implements CommandSource {
  @override
  String get id => 'org-members';
  @override
  bool get isDynamic => true;

  @override
  String get category => 'Organization members';

  @override
  List<CommandItem> buildItems(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context);
    final members = ref.watch(orgMembersProvider).value ?? const <GitHubUser>[];

    final items = <CommandItem>[];

    // Static "Browse team" action first.
    items.add(
      CommandItem(
        id: 'browse-team',
        label: l10n.commandPaletteBrowseTeam,
        description: l10n.commandPaletteBrowseTeamDesc,
        icon: LucideIcons.users,
        category: l10n.commandPaletteOrgMembers,
        onExecute: () => router.go(settingsReposRoute),
      ),
    );

    // One item per org member.
    for (final member in members) {
      items.add(
        CommandItem(
          id: 'member-${member.login}',
          label: member.login,
          description: member.name,
          icon: LucideIcons.user,
          avatarUrl: member.avatarUrl,
          category: l10n.commandPaletteOrgMembers,
          onExecute: () => router.go(userProfileRoute(member.login)),
        ),
      );
    }

    return items;
  }
}

/// Provider for the user command source.
final userCommandSourceProvider = Provider<CommandSource>(
  (_) => UserCommandSource(),
);
