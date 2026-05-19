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
        'workspace.repositories',
        'you.devices',
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
      expect(registry.sections.map((s) => s.id).toSet(), {
        'forge.connections',
        'ticketing.connection',
        'calendar.accounts',
        'chat_bridges.my-account-link',
        'chat_bridges.workspace-setup',
        'messaging.conversation-titles',
      });
    });
  });

  group('SettingsRegistry lookups', () {
    test('sectionsFor filters by slot and sorts by order', () {
      const registry = SettingsRegistry(
        sections: [
          SettingsSectionContribution(
            id: 'b',
            slot: SettingsSlot.userProfile,
            order: 20,
            builder: _stub,
          ),
          SettingsSectionContribution(
            id: 'elsewhere',
            slot: SettingsSlot.workspaceGeneral,
            builder: _stub,
          ),
          SettingsSectionContribution(
            id: 'a',
            slot: SettingsSlot.userProfile,
            order: 10,
            builder: _stub,
          ),
        ],
      );
      expect(registry.sectionsFor(SettingsSlot.userProfile).map((s) => s.id), [
        'a',
        'b',
      ]);
    });

    test('sectionsFor does not mutate the backing list', () {
      // It sorts a copy; sorting `sections` in place would reorder the other
      // slots' cards as a side effect of reading one page.
      const registry = SettingsRegistry(
        sections: [
          SettingsSectionContribution(
            id: 'late',
            slot: SettingsSlot.userProfile,
            order: 20,
            builder: _stub,
          ),
          SettingsSectionContribution(
            id: 'early',
            slot: SettingsSlot.userProfile,
            order: 10,
            builder: _stub,
          ),
        ],
      );
      registry.sectionsFor(SettingsSlot.userProfile);
      expect(registry.sections.map((s) => s.id), ['late', 'early']);
    });

    test('bodyFor returns null for an unclaimed destination', () {
      expect(const SettingsRegistry().bodyFor('you.profile'), isNull);
    });
  });
}

Widget _stub(BuildContext context) => const SizedBox.shrink();
