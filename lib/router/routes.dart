/// Application route paths.
library;

import 'package:flutter/material.dart';

/// Root navigator key used by the app router.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// API keys configuration screen.
const String apiKeysRoute = '/api-keys';

/// Loading screen shown while we figure out whether onboarding is complete.
const String splashRoute = '/splash';

/// First-run onboarding (API keys + first workspace).
const String onboardingRoute = '/onboarding';

/// Main dashboard screen.
const String dashboardRoute = '/dashboard';

/// Pull requests list screen.
const String pullRequestsRoute = '/pull-requests';

/// Compose-a-new-pull-request screen. Static segment, matched before the
/// `:prNumber` detail route so "compose" isn't parsed as a PR number.
const String pullRequestsComposeRoute = '/pull-requests/compose';

/// Pull request detail screen.
String pullRequestDetailRoute(int number) => '/pull-requests/$number';

/// Agents registry screen.
const String agentsRoute = '/agents';

/// Workspaces list screen.
const String workspaceListRoute = '/workspaces';

/// Returns the path for a specific workspace detail screen.
String workspaceRoute(String id) => '/workspaces/$id';

/// Messaging screen (Slack-style DMs and group channels).
const String messagingRoute = '/messaging';

/// Ticketing board (work items the agents read from and act on).
const String ticketsRoute = '/tickets';

/// Ticket detail screen for [id].
String ticketDetailRoute(String id) => '/tickets/$id';

/// Project overview screen for [projectId] (grouped tickets + progress).
String projectOverviewRoute(String projectId) => '/projects/$projectId';

/// Newsfeed (RSS reader) home — all articles, with All/Unread/Saved views.
const String newsfeedRoute = '/newsfeed';

/// Newsfeed → Settings (manage feeds + open behavior).
const String newsfeedSettingsRoute = '/newsfeed/settings';

/// Article reader (in-app webview) for a given article id.
String newsfeedArticleRoute(String articleId) => '/newsfeed/article/$articleId';

/// Settings screen (defaults to the appearance subroute — the first item in
/// the "General" sidebar group).
const String settingsRoute = '/settings';

/// Settings → Appearance (theme, language, typography). The settings landing.
const String settingsAppearanceRoute = '/settings/appearance';

/// Settings → Notifications (per-event notification toggles).
const String settingsNotificationsRoute = '/settings/notifications';

/// Settings → Advanced (voice, semantic search, branch template, privacy,
/// logging). The rarely-touched system configuration.
const String settingsAdvancedRoute = '/settings/advanced';

/// Settings → Integrations (GitHub, ticketing, MCP server).
const String settingsIntegrationsRoute = '/settings/integrations';

/// Settings → Adapters (auto-detected agent runners).
const String settingsAdaptersRoute = '/settings/adapters';

/// Settings → Agents (registered agent identities).
const String settingsAgentsRoute = '/settings/agents';

/// Settings → Repositories (manage repos that workspaces can target).
const String settingsReposRoute = '/settings/repositories';

/// Settings → Skills.
const String settingsSkillsRoute = '/settings/skills';

/// Settings → Keybindings.
const String settingsKeybindingsRoute = '/settings/keybindings';

/// Settings → Security → Sandboxing.
const String settingsSandboxingRoute = '/settings/sandboxing';
/// Analytics dashboard screen.
const String analyticsRoute = '/analytics';

/// Agent detail screen within analytics.
String analyticsAgentRoute(String agentId) => '/analytics/agents/$agentId';

/// GitHub user profile screen.
String userProfileRoute(String login) => '/users/$login';

/// Pipeline runs list screen.
const String pipelinesRoute = '/pipelines';

/// Manual run launcher — pick a manually-runnable pipeline, fill its input
/// form, and start a run.
const String runPipelineRoute = '/pipelines/run';

/// Pipeline run detail screen — shows step timeline for a specific run.
String pipelineRunRoute(String runId) => '/pipelines/$runId';

/// Pipeline templates settings screen — list and edit pipeline templates.
const String settingsPipelinesRoute = '/settings/pipelines';

/// Pipeline template editor (drag-and-drop canvas) for a specific template.
String pipelineTemplateEditorRoute(String templateId) =>
    '/settings/pipelines/$templateId';

/// Teams management screen.
const String teamsRoute = '/settings/teams';

/// Memory (knowledge) screen: facts, policies, and the knowledge graph.
const String memoryRoute = '/memory';

/// Meetings list screen (local meeting notes).
const String meetingsRoute = '/meetings';

/// Live meeting recording screen (rec bar + notes + streaming transcript).
/// Static segment, matched before the `:meetingId` detail route so "record"
/// isn't parsed as a meeting id.
const String meetingsRecordRoute = '/meetings/record';

/// Meeting detail screen (notes + transcript) for [id].
String meetingDetailRoute(String id) => '/meetings/$id';

/// Calendar screen (month / week / agenda views of synced events).
const String calendarRoute = '/calendar';

/// Calendar event detail screen for [id].
String calendarDetailRoute(String id) => '/calendar/$id';

