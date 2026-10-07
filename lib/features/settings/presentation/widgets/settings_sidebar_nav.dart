import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The settings destinations as sidebar groups, shown in place of the global
/// navigation while a settings route is open.
///
/// Rendered from `kSettingsNav`, the single source of truth for the settings
/// information architecture. Groups are SCOPES — You / Workspace / Server —
/// because "who does this affect?" is the question the old topic-based
/// grouping could not answer. In the collapsed rail the group labels drop out
/// and each item is its icon with a tooltip.
class SettingsSidebarNav extends ConsumerWidget {
  /// Creates a [SettingsSidebarNav].
  const SettingsSidebarNav({
    super.key,
    required this.location,
    required this.workspaceId,
  });

  /// The current matched router location, used to resolve the selected item.
  final String location;

  /// The active workspace id, used to build each destination's route.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Install-wide destinations are the operator's; the server refuses every
    // other caller, so offering them is a form that ends in an error.
    final isServerOwner = ref.watch(isServerOwnerProvider);
    // "Any forge", not "GitHub": someone who works only on GitLab has a
    // complete setup, and dotting their sidebar forever would train them to
    // ignore the dot.
    final needsIntegrationSetup = !ref.watch(hasAnyForgeConnectedProvider);

    CcSidebarItem? item(SettingsNavItem entry) {
      if (entry.ownerOnly && !isServerOwner) {
        return null;
      }
      final route = entry.route(workspaceId);
      final selected = entry.matchesSubroutes
          ? (location == route || location.startsWith('$route/'))
          : location == route;
      // The only attention affordance: agents cannot reach a code host until a
      // forge connection exists and that is configured here.
      final attention =
          needsIntegrationSetup && entry.id == 'workspace.profile';
      return CcSidebarItem(
        icon: entry.icon,
        label: entry.label(l10n),
        badge: attention
            ? _AttentionDot(
                semanticLabel: l10n.needsSetupLabel,
                selected: selected,
              )
            : null,
        selected: selected,
        onPressed: () => context.go(route),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final group in kSettingsNav)
          if (group.items.map(item).whereType<CcSidebarItem>().toList()
              case final visible when visible.isNotEmpty)
            CcSidebarGroup(label: group.label(l10n), children: visible),
      ],
    );
  }
}

/// A small caution-amber dot that flags a settings category needing setup.
/// Paired with a [Semantics] label so it isn't status-by-color-alone.
class _AttentionDot extends StatelessWidget {
  const _AttentionDot({required this.semanticLabel, required this.selected});

  final String semanticLabel;

  /// On the selected row's solid brand fill the amber dot fails contrast, so
  /// it renders in `accentOn` like the row's other content.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? (context.designSystem?.accentOn ?? const Color(0xFFFFFFFF))
        : (context.designSystem?.fgWarningPrimary ?? const Color(0xFFCA8504));
    return CcTooltip(
      message: semanticLabel,
      child: Semantics(
        label: semanticLabel,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
