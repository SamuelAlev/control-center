import 'package:control_center/features/shell/breadcrumbs/breadcrumb_registry.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('breadcrumbRegistry', () {
    test('includes an entry for every PageWrapper route', () {
      final expected = <String>{
        dashboardRoute(workspaceIdParam),
        pullRequestsRoute(workspaceIdParam),
        '${pullRequestsRoute(workspaceIdParam)}/:owner/:repo/:prNumber',
        analyticsRoute(workspaceIdParam),
        '${analyticsRoute(workspaceIdParam)}/agents/:agentId',
        messagingRoute(workspaceIdParam),
        ticketsRoute(workspaceIdParam),
        '${ticketsRoute(workspaceIdParam)}/:ticketId',
        projectOverviewRoute(workspaceIdParam, ':projectId'),
        pipelinesRoute(workspaceIdParam),
        runPipelineRoute(workspaceIdParam),
        '${pipelinesRoute(workspaceIdParam)}/:runId',
        newsfeedRoute(workspaceIdParam),
        newsfeedSettingsRoute(workspaceIdParam),
        '${newsfeedRoute(workspaceIdParam)}/article/:articleId',
        memoryRoute(workspaceIdParam),
        apiKeysRoute(workspaceIdParam),
        settingsAppearanceRoute(workspaceIdParam),
        settingsNotificationsRoute(workspaceIdParam),
        settingsIntegrationsRoute(workspaceIdParam),
        settingsAdvancedRoute(workspaceIdParam),
        settingsAdaptersRoute(workspaceIdParam),
        settingsAgentsRoute(workspaceIdParam),
        settingsReposRoute(workspaceIdParam),
        settingsSkillsRoute(workspaceIdParam),
        settingsKeybindingsRoute(workspaceIdParam),
        settingsSandboxingRoute(workspaceIdParam),
        settingsPipelinesRoute(workspaceIdParam),
        '${settingsPipelinesRoute(workspaceIdParam)}/:templateId',
        teamsRoute(workspaceIdParam),
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
