import 'package:control_center/features/settings/settings_nav.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the settings information architecture against drift.
///
/// The settings nav model used to be copied into five files — the shell
/// layout's sub-sidebar, the J/K shortcut list, the router, the breadcrumb
/// registry and the route-title registry — each maintained by hand. They
/// diverged: Memory was in the sidebar but missing from the J/K list, so the
/// shortcut silently skipped it and a doc comment described groups
/// ("Resources", "Automation") that no longer existed.
///
/// Everything now derives from `kSettingsNav`. These tests assert the
/// properties that made the old duplication dangerous.
void main() {
  const workspaceId = 'ws-1';

  test('every item has a unique id', () {
    final ids = kSettingsNavItems.map((e) => e.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('every item has a unique route', () {
    final routes = [
      for (final entry in kSettingsNavItems) entry.route(workspaceId),
    ];
    expect(routes.toSet(), hasLength(routes.length));
  });

  test('the flattened item list matches the grouped order', () {
    expect(
      kSettingsNavItems.map((e) => e.id).toList(),
      [for (final g in kSettingsNav) ...g.items.map((e) => e.id)],
      reason:
          'The J/K cycle walks the flattened list; if it can diverge from the '
          'rendered order the shortcut skips or reorders pages.',
    );
  });

  test('groups cover the three scopes, in order', () {
    expect(kSettingsNav.map((g) => g.scope).toList(), [
      SettingScope.user,
      SettingScope.workspace,
      SettingScope.server,
    ]);
  });

  group('scope namespacing', () {
    /// Strips the `/workspaces/<id>` prefix, leaving the logical settings path.
    String logical(String route) =>
        route.replaceFirst('/workspaces/$workspaceId', '');

    test('each item sits under its group\'s scope segment', () {
      const expected = {
        SettingScope.user: '/settings/you/',
        SettingScope.workspace: '/settings/workspace/',
        SettingScope.server: '/settings/server/',
      };
      for (final group in kSettingsNav) {
        for (final entry in group.items) {
          final path = logical(entry.route(workspaceId));
          // Memory and pipelines are foreign features that live under
          // `/settings` with their own historic paths; they are grouped by
          // scope in the sidebar but keep their routes.
          if (const {
            'workspace.memory',
            'workspace.pipelines',
          }.contains(entry.id)) {
            continue;
          }
          expect(
            path,
            startsWith(expected[group.scope]!),
            reason: '${entry.id} is in the ${group.scope.name} group',
          );
        }
      }
    });

    test('settingScopeForLocation reads the scope back off a path', () {
      for (final group in kSettingsNav) {
        for (final entry in group.items) {
          final path = logical(entry.route(workspaceId));
          if (!path.startsWith('/settings/')) {
            continue;
          }
          final resolved = settingScopeForLocation(path);
          if (resolved == null) {
            continue; // foreign feature route, covered above
          }
          expect(resolved, group.scope, reason: entry.id);
        }
      }
    });

    test('a non-settings path has no scope', () {
      expect(settingScopeForLocation('/inbox'), isNull);
      expect(settingScopeForLocation('/settings'), isNull);
    });
  });
}
