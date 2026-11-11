import 'package:control_center/di/settings_registry.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The registry trades a compile-time reference for a string id, so the things
/// the compiler used to catch have to be caught here instead.
///
/// A `SettingsBody` whose `navItemId` matches nothing renders an empty page —
/// no crash, no log, just a destination that silently stopped working. That is
/// exactly the failure a typo produces, and it is the reason this file exists.
void main() {
  late SettingsRegistry registry;

  setUp(() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    registry = container.read(settingsRegistryProvider);
  });

  group('SettingsRegistry wiring', () {
    test('every contributed body targets a real nav destination', () {
      final navIds = {for (final item in kSettingsNavItems) item.id};
      final unknown = [
        for (final body in registry.bodies)
          if (!navIds.contains(body.navItemId)) body.navItemId,
      ];
      expect(
        unknown,
        isEmpty,
        reason:
            'these bodies name a nav item that does not exist, so their page '
            'would render blank: ${unknown.join(', ')}',
      );
    });

    test('no two features claim the same destination', () {
      final seen = <String>{};
      final duplicates = [
        for (final body in registry.bodies)
          if (!seen.add(body.navItemId)) body.navItemId,
      ];
      expect(
        duplicates,
        isEmpty,
        reason:
            'bodyFor() returns the FIRST match, so a duplicate silently wins '
            'and the loser never renders: ${duplicates.join(', ')}',
      );
    });

    test('contribution ids are unique across features', () {
      final ids = [
        ...registry.sections.map((s) => s.id),
        ...registry.agentTabs.map((t) => t.id),
        ...registry.agentRegistryViews.map((v) => v.id),
      ];
      expect(ids.toSet(), hasLength(ids.length), reason: 'duplicate ids: $ids');
    });

    test('contribution ids are namespaced by their feature', () {
      final unnamespaced = [
        for (final id in [
          ...registry.sections.map((s) => s.id),
          ...registry.agentTabs.map((t) => t.id),
          ...registry.agentRegistryViews.map((v) => v.id),
        ])
          if (!id.contains('.')) id,
      ];
      expect(
        unnamespaced,
        isEmpty,
        reason:
            'ids collide across features without a `<feature>.` prefix: '
            '${unnamespaced.join(', ')}',
      );
    });

    test('the shipped contributions are all registered', () {
      // A contributions file that nobody adds to the composition root compiles
      // fine and does nothing — the one failure mode of an aggregate-by-hand
      // root. Pinning the expected set makes a forgotten `...xSettingsBodies`
      // a failing test rather than a missing page.
      expect(registry.bodies.map((b) => b.navItemId).toSet(), {
        'workspace.agents',
        'workspace.environments',
        'workspace.meetings',
        'workspace.repositories',
        'you.desktop',
        'you.devices',
        'you.links',
        'you.newsfeed',
        'server.rigs',
        'server.sandbox',
      });
      expect(registry.agentTabs.map((t) => t.id).toSet(), {
        'memory.working-memory',
        'settings.account-pools',
      });
      expect(registry.agentRegistryViews.map((v) => v.id).toSet(), {
        'agents.org-chart',
        'teams.management',
      });
      expect(
        {for (final s in registry.sections) s.id: s.slot},
        {
          'connect.connect': SettingsSlot.serverSignIn,
          'settings.provider-apps': SettingsSlot.serverSignIn,
          'forge.connections': SettingsSlot.userAccounts,
          'ticketing.account': SettingsSlot.userAccounts,
          'calendar.accounts': SettingsSlot.userAccounts,
          'chat_bridges.my-account-link': SettingsSlot.userAccounts,
          'chat_bridges.ticket-drafts': SettingsSlot.userAccounts,
          'connect.workspace': SettingsSlot.workspaceIntegrations,
          'forge.account-status': SettingsSlot.workspaceIntegrations,
          'forge.github-app': SettingsSlot.workspaceIntegrations,
          'forge.automation-tokens': SettingsSlot.workspaceIntegrations,
          'ticketing.account-status': SettingsSlot.workspaceIntegrations,
          'ticketing.connection': SettingsSlot.workspaceIntegrations,
          'settings.workspace-app.linear': SettingsSlot.workspaceIntegrations,
          'settings.sync-health': SettingsSlot.workspaceIntegrations,
          'settings.workspace-app.google': SettingsSlot.workspaceIntegrations,
          'chat_bridges.account-status': SettingsSlot.workspaceIntegrations,
          'chat_bridges.workspace-setup': SettingsSlot.workspaceIntegrations,
          'settings.gifs': SettingsSlot.workspaceIntegrations,
        },
      );
    });

    test('Integrations groups by provider, in the documented order', () {
      // Sign-in apps decide whose app every card below uses, so they lead;
      // then each provider's cards stay adjacent whichever feature owns them,
      // each group opening with the reader's own account there.
      expect(
        registry
            .sectionsFor(SettingsSlot.workspaceIntegrations)
            .map((s) => s.id)
            .toList(),
        [
          'connect.workspace',
          'forge.account-status',
          'forge.github-app',
          'forge.automation-tokens',
          'ticketing.account-status',
          'ticketing.connection',
          'settings.workspace-app.linear',
          'settings.sync-health',
          'settings.workspace-app.google',
          'chat_bridges.account-status',
          'chat_bridges.workspace-setup',
          'settings.gifs',
        ],
      );
    });

    test('connected accounts group by provider, in the documented order', () {
      // The same bands as Integrations, so a provider sits at the same height
      // on the person's profile and the workspace's page.
      expect(
        registry
            .sectionsFor(SettingsSlot.userAccounts)
            .map((s) => s.id)
            .toList(),
        [
          'forge.connections',
          'ticketing.account',
          'calendar.accounts',
          'chat_bridges.my-account-link',
          'chat_bridges.ticket-drafts',
        ],
      );
    });

    test('no personal sign-in is left on the workspace page', () {
      // Every sign-in is stored against the person: connecting one belongs on
      // their own page, whatever feature owns it.
      final integrations = registry
          .sectionsFor(SettingsSlot.workspaceIntegrations)
          .map((s) => s.id);
      for (final id in const [
        'forge.connections',
        'ticketing.account',
        'calendar.accounts',
        'chat_bridges.my-account-link',
        'chat_bridges.ticket-drafts',
      ]) {
        expect(integrations, isNot(contains(id)));
      }
    });
  });

  group('SettingsRegistry lookups', () {
    test('sectionsFor filters by slot and sorts by order', () {
      const registry = SettingsRegistry(
        sections: [
          SettingsSectionContribution(
            id: 'b',
            slot: SettingsSlot.workspaceIntegrations,
            order: 20,
            builder: _stub,
          ),
          SettingsSectionContribution(
            id: 'elsewhere',
            slot: SettingsSlot.serverSignIn,
            builder: _stub,
          ),
          SettingsSectionContribution(
            id: 'a',
            slot: SettingsSlot.workspaceIntegrations,
            order: 10,
            builder: _stub,
          ),
        ],
      );
      expect(
        registry
            .sectionsFor(SettingsSlot.workspaceIntegrations)
            .map((s) => s.id),
        ['a', 'b'],
      );
    });

    test('sectionsFor does not mutate the backing list', () {
      // It sorts a copy; sorting `sections` in place would reorder the other
      // slots' cards as a side effect of reading one page.
      const registry = SettingsRegistry(
        sections: [
          SettingsSectionContribution(
            id: 'late',
            slot: SettingsSlot.workspaceIntegrations,
            order: 20,
            builder: _stub,
          ),
          SettingsSectionContribution(
            id: 'early',
            slot: SettingsSlot.workspaceIntegrations,
            order: 10,
            builder: _stub,
          ),
        ],
      );
      registry.sectionsFor(SettingsSlot.workspaceIntegrations);
      expect(registry.sections.map((s) => s.id), ['late', 'early']);
    });

    test('bodyFor returns null for an unclaimed destination', () {
      expect(const SettingsRegistry().bodyFor('you.profile'), isNull);
    });
  });
}

Widget _stub(BuildContext context) => const SizedBox.shrink();
