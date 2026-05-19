import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/features/shell/breadcrumbs/breadcrumb_registry.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('breadcrumbRegistry', () {
    test('includes an entry for every PageWrapper route', () {
      final expected = <String>{
        inboxRoute(workspaceIdParam),
        pullRequestsRoute(workspaceIdParam),
        '${pullRequestsRoute(workspaceIdParam)}/:owner/:repo/:prNumber',
        spacesRoute(workspaceIdParam),
        ticketsRoute(workspaceIdParam),
        '${ticketsRoute(workspaceIdParam)}/:ticketId',
        projectOverviewRoute(workspaceIdParam, ':projectId'),
        pipelinesRoute(workspaceIdParam),
        runPipelineRoute(workspaceIdParam),
        '${pipelinesRoute(workspaceIdParam)}/:runId',
        newsfeedRoute(workspaceIdParam),
        '${newsfeedRoute(workspaceIdParam)}/article/:articleId',
        memoryRoute(workspaceIdParam),
        apiKeysRoute(workspaceIdParam),
        // Every settings destination, derived from the IA rather than listed
        // by hand — the hand-written copy is exactly what used to drift.
        for (final entry in kSettingsNavItems) entry.route(workspaceIdParam),
        '${settingsPipelinesRoute(workspaceIdParam)}/:templateId',
      };
      final missing = expected.difference(breadcrumbRegistry.keys.toSet());
      expect(
        missing,
        isEmpty,
        reason: 'Missing breadcrumb builders for: $missing',
      );
    });

    test('every entry key uses go_router fullPath pattern (leading slash)', () {
      for (final key in breadcrumbRegistry.keys) {
        expect(
          key.startsWith('/'),
          isTrue,
          reason: 'Pattern "$key" must start with "/" to match fullPath',
        );
      }
    });
  });
}
