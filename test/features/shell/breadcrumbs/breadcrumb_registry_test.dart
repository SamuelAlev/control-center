import 'package:control_center/features/shell/breadcrumbs/breadcrumb_registry.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('breadcrumbRegistry', () {
    test('includes an entry for every PageWrapper route', () {
      const expected = <String>{
        dashboardRoute,
        pullRequestsRoute,
        '$pullRequestsRoute/:prNumber',
        agentsRoute,
        analyticsRoute,
        '$analyticsRoute/agents/:agentId',
        messagingRoute,
        ticketsRoute,
        '$ticketsRoute/:ticketId',
        '/projects/:projectId',
        pipelinesRoute,
        runPipelineRoute,
        '$pipelinesRoute/:runId',
        newsfeedRoute,
        newsfeedSettingsRoute,
        '$newsfeedRoute/article/:articleId',
        memoryRoute,
        apiKeysRoute,
        workspaceListRoute,
        '$workspaceListRoute/:workspaceId',
        settingsAppearanceRoute,
        settingsNotificationsRoute,
        settingsIntegrationsRoute,
        settingsAdvancedRoute,
        settingsAdaptersRoute,
        settingsAgentsRoute,
        settingsReposRoute,
        settingsSkillsRoute,
        settingsKeybindingsRoute,
        settingsSandboxingRoute,
        settingsPipelinesRoute,
        '$settingsPipelinesRoute/:templateId',
        teamsRoute,
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
