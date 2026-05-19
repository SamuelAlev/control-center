import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/invite_member_dialog.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/members_roster_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/workspace_activity_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Members: the workspace roster (roles + removal) with minted
/// invites merged under it, invite minting from the header action and the
/// per-workspace audit trail.
class MembersSettingsScreen extends ConsumerWidget {
  /// Creates a [MembersSettingsScreen].
  const MembersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = context.currentWorkspaceId;
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final isAdmin =
        ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false;
    return SettingsPage(
      title: l10n.membersNav,
      subtitle: l10n.membersSettingsDescription,
      actions: [
        // Invites are an admin surface; the server rejects the mint anyway.
        if (isAdmin)
          CcButton(
            onPressed: () => showInviteMemberDialog(context, workspaceId),
            icon: AppIcons.userPlus,
            size: CcButtonSize.sm,
            variant: CcButtonVariant.primary,
            child: Text(l10n.inviteMember),
          ),
      ],
      sections: [
        MembersRosterSection(workspaceId: workspaceId),
        WorkspaceActivitySection(workspaceId: workspaceId),
      ],
    );
  }
}
