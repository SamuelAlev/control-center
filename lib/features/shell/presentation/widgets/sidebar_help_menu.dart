import 'package:cc_domain/cc_domain.dart' show BuildInfo;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/changelog/presentation/widgets/changelog_dialog.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/keyboard_cheatsheet.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const String _newIssueUrl =
    'https://github.com/SamuelAlev/control-center/issues/new';

/// Global-sidebar footer entry opening the help menu above it. Like service
/// status it is a surface, not a destination: it is selected only while open.
class SidebarHelpMenu extends StatefulWidget implements CcFluidHoverTarget {
  /// Creates a [SidebarHelpMenu].
  const SidebarHelpMenu({required this.workspaceId, super.key});

  /// The workspace the menu's Settings destinations open under.
  final String workspaceId;

  @override
  bool get fluidHoverEnabled => true;

  @override
  State<SidebarHelpMenu> createState() => _SidebarHelpMenuState();
}

class _SidebarHelpMenuState extends State<SidebarHelpMenu> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    return CcMenu(
      controller: _controller,
      toggleOnTargetTap: false,
      targetAnchor: AlignmentDirectional.topEnd,
      followerAnchor: AlignmentDirectional.bottomEnd,
      offset: const Offset(0, -AppSpacing.sm),
      minWidth: 260,
      semanticLabel: l10n.helpMenuLabel,
      items: [
        CcMenuItem.section(l10n.helpMenuLabel),
        CcMenuItem(
          icon: AppIcons.keyboard,
          label: l10n.cheatSheetTitle,
          onSelected: () => showKeyboardCheatSheet(context),
        ),
        CcMenuItem(
          icon: AppIcons.rocket,
          label: l10n.helpWhatsNew,
          onSelected: () => showChangelogDialog(context),
        ),
        CcMenuItem(
          icon: AppIcons.activity,
          label: l10n.settingsDiagnostics,
          onSelected: () =>
              router.go(settingsDiagnosticsRoute(widget.workspaceId)),
        ),
        const CcMenuItem.divider(),
        CcMenuItem.section(l10n.helpReportProblem),
        CcMenuItem(
          icon: AppIcons.bug,
          label: l10n.helpCreateGitHubIssue,
          onSelected: () => openExternalUrl(_newIssueUrl),
        ),
        const CcMenuItem.divider(),
        CcMenuItem(
          label: 'Control Center',
          trailing: 'v${BuildInfo.buildVersion}',
          onSelected: () => router.go(settingsAboutRoute(widget.workspaceId)),
        ),
      ],
      target: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => CcSidebarItem(
          icon: AppIcons.circleHelp,
          label: l10n.helpMenuLabel,
          selected: _controller.isOpen,
          onPressed: _controller.toggle,
        ),
      ),
    );
  }
}
