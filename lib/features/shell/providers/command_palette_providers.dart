import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/features/focus_mode/presentation/widgets/focus_config_dialog.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_command_source.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart'
    show prsByRepoProvider;
import 'package:control_center/features/ticketing/providers/ticketing_command_source.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart'
    show workspaceTicketsProvider;
import 'package:control_center/features/user_profiles/providers/org_members_provider.dart';
import 'package:control_center/features/user_profiles/providers/user_command_source.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── Navigation command source ────────────────────────────────────────────────

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
        id: 'dashboard',
        label: 'Go to Dashboard',
        description: 'Navigate to the global dashboard',
        shortcut: '\u23181',
        icon: AppIcons.layoutDashboard,
        category: l10n.categoryNavigation,
        onExecute: () => router.go(nav(dashboardRoute)),
      ),
      CommandItem(
        id: 'pull-requests',
        label: 'Go to Pull Requests',
        description: 'Navigate to pull requests',
        shortcut: '\u23182',
        icon: AppIcons.gitPullRequest,
        category: l10n.categoryNavigation,
        onExecute: () => router.go(nav(pullRequestsRoute)),
      ),
      CommandItem(
        id: 'agents',
        label: 'Go to Agents',
        description: 'Navigate to agents registry',
        shortcut: '\u23183',
        icon: AppIcons.bot,
        category: l10n.categoryNavigation,
        onExecute: () => router.go(nav(settingsAgentsRoute)),
      ),
      CommandItem(
        id: 'workspaces',
        label: 'Go to Workspaces',
        description: 'Navigate to workspaces list',
        shortcut: '\u23184',
        icon: AppIcons.folder,
        category: l10n.categoryNavigation,
        onExecute: () => router.go(workspaceListRoute),
      ),
      CommandItem(
        id: 'new-workspace',
        label: 'New workspace',
        description: 'Create a new isolated workspace',
        shortcut: '\u2318N',
        icon: AppIcons.plus,
        category: 'Workspace',
        onExecute: () => router.go(workspaceListRoute),
      ),
    ];
  }
}

/// Provider for the static navigation command source.
final navigationCommandSourceProvider = Provider<CommandSource>(
  (_) => _NavigationCommandSource(),
);

// ── View command source ───────────────────────────────────────────────────────

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
        description: 'Switch between light and dark mode',
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
        description: focusActive
            ? 'End the current session and resume normal notifications'
            : 'Configure and start a focused work session',
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
      CommandItem(
        id: 'settings',
        label: 'Settings',
        description: l10n.openApplicationSettings,
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

// ── Aggregated sources ────────────────────────────────────────────────────────

/// Collects all registered [CommandSource] providers.
///
/// Features register their sources by overriding this provider (or by adding
/// their source providers to the DI composition). The palette collects items
/// from every source when opened.
final commandSourcesProvider = Provider<List<CommandSource>>((ref) {
  return [
    ref.watch(navigationCommandSourceProvider),
    ref.watch(viewCommandSourceProvider),
    ref.watch(userCommandSourceProvider),
    ref.watch(prCommandSourceProvider),
    ref.watch(ticketingCommandSourceProvider),
    ref.watch(agentActionCommandSourceProvider),
  ];
});

// ── Agent / quick-action command source ──────────────────────────────────────

class _AgentActionCommandSource implements CommandSource {
  @override
  String get id => 'agent-actions';
  @override
  String get category => 'Quick actions';
  @override
  bool get isDynamic => false;

  @override
  List<CommandItem> buildItems(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    String nav(String Function(String) build) =>
        workspaceId == null ? workspaceListRoute : build(workspaceId);

    return [
      CommandItem(
        id: 'go-newsfeed',
        label: 'Go to Feed',
        description: 'Navigate to the newsfeed',
        icon: AppIcons.rss,
        category: 'Quick actions',
        onExecute: () => router.go(nav(newsfeedRoute)),
      ),
      CommandItem(
        id: 'go-analytics',
        label: 'Go to Analytics',
        description: 'Open the analytics dashboard',
        icon: AppIcons.barChart2,
        category: 'Quick actions',
        onExecute: () => router.go(nav(analyticsRoute)),
      ),
      CommandItem(
        id: 'go-agents',
        label: 'Go to Agents',
        description: 'Navigate to the agent registry',
        icon: AppIcons.users,
        category: 'Agents',
        onExecute: () => router.go(nav(settingsAgentsRoute)),
      ),
    ];
  }
}

/// Provider for the agent-action command source.
final agentActionCommandSourceProvider = Provider<CommandSource>(
  (_) => _AgentActionCommandSource(),
);

/// Keeps dynamic data providers warm so the command palette has
/// PRs and tickets loaded when it opens.
///
/// Call this from the app shell's build method (inside MaterialApp.router)
/// so subscriptions are created before the user opens the palette.
void keepPaletteDataWarm(WidgetRef ref) {
  ref.watch(prsByRepoProvider);
  ref.watch(orgMembersProvider);
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  if (workspaceId != null) {
    ref.watch(workspaceTicketsProvider(workspaceId));
  }
}

// ── Global command builder ────────────────────────────────────────────────────

/// Build global commands by collecting items from all registered [CommandSource]s.
List<CommandItem> buildGlobalCommands(BuildContext context, WidgetRef ref) {
  final sources = ref.watch(commandSourcesProvider);
  final items = <CommandItem>[];
  for (final source in sources) {
    items.addAll(source.buildItems(context, ref));
  }
  return items;
}
