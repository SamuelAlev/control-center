import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/features/focus_mode/presentation/widgets/focus_config_dialog.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/messaging/providers/space_command_source.dart';
import 'package:control_center/features/plan_studio/providers/playbook_command_source.dart';
import 'package:control_center/features/pr_review/providers/pr_command_source.dart';
import 'package:control_center/features/settings/providers/settings_command_source.dart';
import 'package:control_center/features/soundscape/presentation/screens/soundscape_panel.dart';
import 'package:control_center/features/ticketing/providers/ticketing_command_source.dart';
import 'package:control_center/features/user_profiles/providers/user_command_source.dart';
import 'package:control_center/features/workspaces/presentation/widgets/show_add_workspace_dialog.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Static source providing global navigation shortcuts.
class _NavigationCommandSource implements CommandSource {
  @override
  String get id => 'navigation';
  @override
  String get category => 'Navigation';
  @override
  bool get isDynamic => false;

  @override
  List<CommandItem> buildItems(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    // No workspace context \u2192 fall back to the picker for workspace-scoped
    // destinations.
    String nav(String Function(String) build) =>
        workspaceId == null ? workspaceListRoute : build(workspaceId);

    return [
      CommandItem(
        id: 'inbox',
        label: l10n.inboxTitle,
        icon: AppIcons.inbox,
        category: l10n.categoryNavigation,
        onExecute: () => router.go(nav(inboxRoute)),
      ),
      // Deep links (PRD 19 §8): every surface is a stable, shareable URL —
      // copy the current one to the clipboard.
      CommandItem(
        id: 'copy-link',
        label: l10n.copyLinkLabel,
        icon: AppIcons.link,
        category: l10n.categoryNavigation,
        onExecute: () {
          final uri = router.routeInformationProvider.value.uri.toString();
          Clipboard.setData(ClipboardData(text: uri));
          final ctx = rootNavigatorKey.currentContext;
          if (ctx != null) {
            CcToastScope.maybeOf(ctx)?.show(l10n.linkCopied);
          }
        },
      ),
      CommandItem(
        id: 'spaces',
        label: l10n.spaces,
        icon: AppIcons.messagesSquare,
        category: l10n.categoryNavigation,
        onExecute: () => router.go(nav(spacesRoute)),
      ),
      CommandItem(
        id: 'calendar',
        label: l10n.navCalendar,
        icon: AppIcons.calendar,
        category: l10n.categoryNavigation,
        onExecute: () => router.go(nav(calendarRoute)),
      ),
      CommandItem(
        id: 'meetings',
        label: l10n.navMeetings,
        icon: AppIcons.audioLines,
        category: l10n.categoryNavigation,
        onExecute: () => router.go(nav(meetingsRoute)),
      ),
      CommandItem(
        id: 'pipelines',
        label: l10n.pipelinesScreenTitle,
        icon: AppIcons.workflow,
        category: l10n.categoryNavigation,
        onExecute: () => router.go(nav(pipelinesRoute)),
      ),
      CommandItem(
        id: 'plans',
        label: l10n.plansTitle,
        icon: AppIcons.fileText,
        category: l10n.categoryNavigation,
        onExecute: () => router.go(nav(plansRoute)),
      ),
      CommandItem(
        id: 'go-newsfeed',
        label: l10n.newsfeed,
        icon: AppIcons.newspaper,
        category: l10n.categoryNavigation,
        onExecute: () => router.go(nav(newsfeedRoute)),
      ),
      CommandItem(
        id: 'observability',
        label: l10n.navObservability,
        icon: AppIcons.gauge,
        category: l10n.categoryNavigation,
        onExecute: () => router.go(nav(observabilityRoute)),
      ),
      CommandItem(
        id: 'workspaces',
        label: l10n.workspaces,
        icon: AppIcons.folder,
        category: l10n.categoryNavigation,
        onExecute: () => router.go(workspaceListRoute),
      ),
      CommandItem(
        id: 'new-workspace',
        label: l10n.keybindingNewWorkspace,
        icon: AppIcons.plus,
        category: l10n.workspaces,
        onExecute: () async {
          final ctx = rootNavigatorKey.currentContext;
          if (ctx == null) {
            return;
          }
          final id = await showAddWorkspaceDialog(ctx);
          if (id != null) {
            router.go(inboxRoute(id));
          }
        },
      ),
    ];
  }
}

/// Provider for the static navigation command source.
final navigationCommandSourceProvider = Provider<CommandSource>(
  (_) => _NavigationCommandSource(),
);

/// Static source providing view-related actions (theme toggle, settings).
class _ViewCommandSource implements CommandSource {
  @override
  String get id => 'view';
  @override
  String get category => 'View';
  @override
  bool get isDynamic => false;

  @override
  List<CommandItem> buildItems(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context);
    final focusActive = ref.read(focusModeProvider).active;
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    String nav(String Function(String) build) =>
        workspaceId == null ? workspaceListRoute : build(workspaceId);

    return [
      CommandItem(
        id: 'toggle-theme',
        label: 'Toggle theme',
        shortcut: '\u2318\u21E7T',
        icon: AppIcons.sun,
        category: 'View',
        onExecute: () {
          final current = ref.read(themeModeProvider);
          ref
              .read(themeModeProvider.notifier)
              .setThemeMode(
                current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
              );
        },
      ),
      CommandItem(
        id: 'focus-mode',
        label: focusActive ? 'Exit focus mode' : 'Start focus session',
        icon: AppIcons.focus,
        category: 'Focus',
        onExecute: () {
          if (focusActive) {
            ref.read(focusModeProvider.notifier).deactivate();
          } else {
            final ctx = rootNavigatorKey.currentContext;
            if (ctx != null) {
              showCcDialog<void>(
                context: ctx,
                builder: (_) => const FocusConfigDialog(),
              );
            }
          }
        },
      ),
      // No libmpv (a stock Linux desktop): nothing could play.
      if (ref.read(mediaPlaybackAvailableProvider))
        CommandItem(
          id: 'soundscape',
          label: 'Soundscape',
          icon: AppIcons.audioLines,
          category: 'Focus',
          onExecute: () {
            final ctx = rootNavigatorKey.currentContext;
            if (ctx != null) {
              showSoundscapePanel(ctx);
            }
          },
        ),
      CommandItem(
        id: 'settings',
        label: 'Settings',
        icon: AppIcons.settings,
        category: l10n.settingsLabel,
        onExecute: () => router.go(nav(settingsRoute)),
      ),
    ];
  }
}

/// Provider for the static view command source.
final viewCommandSourceProvider = Provider<CommandSource>(
  (_) => _ViewCommandSource(),
);

/// Collects all registered [CommandSource] providers.
///
/// Features register their sources by overriding this provider (or by adding
/// their source providers to the DI composition). The palette collects items
/// from every source when opened.
final commandSourcesProvider = Provider<List<CommandSource>>((ref) {
  return [
    ref.watch(navigationCommandSourceProvider),
    ref.watch(viewCommandSourceProvider),
    ref.watch(spaceCommandSourceProvider),
    ref.watch(settingsCommandSourceProvider),
    ref.watch(userCommandSourceProvider),
    ref.watch(prCommandSourceProvider),
    ref.watch(ticketingCommandSourceProvider),
    ref.watch(playbookCommandSourceProvider),
  ];
});

// NOTE: there is intentionally no "keep palette data warm" helper. Pinning the
// full PR list + workspace tickets for the app's lifetime just so the palette
// opens pre-populated cost far more memory than the one-frame loading state it
// saved; palette sources load on open.

/// Build global commands by collecting items from all registered [CommandSource]s.
List<CommandItem> buildGlobalCommands(BuildContext context, WidgetRef ref) {
  final sources = ref.watch(commandSourcesProvider);
  final items = <CommandItem>[];
  for (final source in sources) {
    items.addAll(source.buildItems(context, ref));
  }
  return items;
}
