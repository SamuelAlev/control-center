/// The seam that lets a FEATURE own its own settings surface.
///
/// Settings used to be the de-facto integration point of the whole app: a
/// screen under `settings/presentation/` named another feature's widgets
/// directly, so `agents_settings.dart` alone imported presentation code from
/// `agents`, `memory`, `pr_review`, `teams` and `workspaces`. The direction was
/// backwards — the hub knew every spoke — and the `agents` feature had been
/// hollowed out to a bag of widgets with no screen of its own.
///
/// So the dependency is inverted here. A feature declares WHAT it contributes
/// and WHERE it goes; settings renders whatever it is handed and names nobody.
/// The one place that still knows every feature is `lib/di/settings_registry.dart`,
/// which is a composition root — knowing every module is its job, the same way
/// `di/providers.dart` binds every repository port.
///
/// Deliberately contract-only: this file imports `flutter/widgets.dart`, the
/// shared kernel and the l10n table, and nothing from `settings/presentation/`.
/// A feature importing it therefore pulls in no settings UI, so there is no
/// cycle to reason about. `architecture_constraints_test.dart` pins that.
library;

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// A named place in the settings UI that features can contribute sections to.
///
/// A slot is a PROMISE about page identity, not about layout: adding one means
/// committing that a page exists and that contributions belong on it. Keep the
/// set small — a slot per page is a registry, a slot per gap is a plugin
/// framework nobody asked for.
enum SettingsSlot {
  /// Settings → You → Profile & identity, after the built-in identity cards.
  userProfile,

  /// Settings → Workspace → General, after the built-in workspace cards.
  workspaceGeneral,
}

/// One feature's section card on a [SettingsSlot] page.
@immutable
class SettingsSectionContribution {
  /// Creates a [SettingsSectionContribution].
  const SettingsSectionContribution({
    required this.id,
    required this.slot,
    required this.builder,
    this.order = 0,
  });

  /// Stable `<feature>.<section>` identifier. Tests address contributions by
  /// it, so it must not change when the widget behind it is renamed.
  final String id;

  /// Which page this card appears on.
  final SettingsSlot slot;

  /// Sort key within the slot, ascending. Ties keep registration order, so a
  /// feature that does not care can leave this at 0.
  final int order;

  /// Builds the card.
  final WidgetBuilder builder;
}

/// A whole settings destination's body, owned by the feature behind it.
///
/// Some settings destinations are not a stack of generic cards — the agent
/// registry is a master/detail surface with its own toolbar. Those belong to
/// their feature outright; settings keeps only the route and the nav entry.
@immutable
class SettingsBody {
  /// Creates a [SettingsBody].
  const SettingsBody({required this.navItemId, required this.builder});

  /// The `SettingsNavItem.id` this body fills (e.g. `workspace.agents`).
  ///
  /// `settings_registry_test.dart` asserts every contributed id exists in
  /// `kSettingsNav`, so a typo is a failing test rather than a blank page.
  final String navItemId;

  /// Builds the destination's content, below the sub-sidebar.
  final WidgetBuilder builder;
}

/// One feature's tab in the agent registry's detail pane.
///
/// The pane is per-agent, so the builder receives the [Agent] rather than an
/// id: everything a tab needs (its workspace included) is on the entity, and
/// sourcing the workspace from it is what keeps a tab from reading the route.
@immutable
class AgentSettingsTab {
  /// Creates an [AgentSettingsTab].
  const AgentSettingsTab({
    required this.id,
    required this.label,
    required this.builder,
    this.order = 0,
  });

  /// Stable `<feature>.<tab>` identifier.
  final String id;

  /// Localized tab label.
  final String Function(AppLocalizations) label;

  /// Sort key among the tabs, ascending.
  final int order;

  /// Builds the tab body for [Agent].
  final Widget Function(BuildContext context, Agent agent) builder;
}

/// One feature's alternate whole-pane view in the agent registry.
///
/// Rendered instead of the roster + detail split while its toolbar toggle is
/// active — the org chart and the teams manager are both workspace-wide views
/// of the same fleet, so they replace the pane rather than hiding inside one
/// agent's tabs.
@immutable
class AgentRegistryView {
  /// Creates an [AgentRegistryView].
  const AgentRegistryView({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
    this.order = 0,
    this.replacesRoster = false,
  });

  /// Stable `<feature>.<view>` identifier, also the toolbar toggle's state key.
  final String id;

  /// When true the view takes the whole registry body, roster included.
  ///
  /// The two shipped views want different things and the difference is real:
  /// the org chart is a second reading of the SAME roster, so keeping the list
  /// beside it lets you click through to an agent; the teams manager is its own
  /// surface with its own list and would be cramped next to a second one. A
  /// single behaviour would have had to be wrong for one of them.
  final bool replacesRoster;

  /// Localized toolbar-button label.
  final String Function(AppLocalizations) label;

  /// Toolbar-button glyph.
  final IconData icon;

  /// Sort key among the toolbar toggles, ascending.
  final int order;

  /// Builds the pane's content for the given workspace.
  final Widget Function(BuildContext context, String workspaceId) builder;
}

/// Everything the features have contributed to settings.
///
/// Immutable and built once in the composition root. The lookups sort on
/// access rather than at construction because the lists are a handful of
/// entries and a settings page is not a hot path — a sorted-at-build variant
/// would only add a second representation to keep honest.
@immutable
class SettingsRegistry {
  /// Creates a [SettingsRegistry].
  const SettingsRegistry({
    this.sections = const [],
    this.bodies = const [],
    this.agentTabs = const [],
    this.agentRegistryViews = const [],
  });

  /// Section cards, across every slot.
  final List<SettingsSectionContribution> sections;

  /// Whole-destination bodies, keyed by nav item id.
  final List<SettingsBody> bodies;

  /// Tabs on the agent registry's detail pane.
  final List<AgentSettingsTab> agentTabs;

  /// Alternate whole-pane views in the agent registry.
  final List<AgentRegistryView> agentRegistryViews;

  /// The sections contributed to [slot], in display order.
  List<SettingsSectionContribution> sectionsFor(SettingsSlot slot) => [
    for (final s in sections)
      if (s.slot == slot) s,
  ]..sort((a, b) => a.order.compareTo(b.order));

  /// The body contributed for [navItemId], or null when none is.
  SettingsBody? bodyFor(String navItemId) {
    for (final body in bodies) {
      if (body.navItemId == navItemId) {
        return body;
      }
    }
    return null;
  }

  /// The agent-detail tabs, in display order.
  List<AgentSettingsTab> get sortedAgentTabs =>
      [...agentTabs]..sort((a, b) => a.order.compareTo(b.order));

  /// The alternate registry views, in toolbar order.
  List<AgentRegistryView> get sortedAgentRegistryViews =>
      [...agentRegistryViews]..sort((a, b) => a.order.compareTo(b.order));
}
