import 'package:control_center/core/deep_link/deep_link_handler.dart';
import 'package:control_center/features/auth/presentation/oauth_done_deep_link.dart';
import 'package:control_center/features/pr_review/presentation/pr_deep_links.dart';
import 'package:control_center/features/workspaces/presentation/workspace_deep_link.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dispatches an inbound custom-scheme URL to the feature that owns it.
///
/// `control-center://pair` (the SSO login bounce, which re-homes the whole
/// app) goes to [adoptPairLink]; everything else is a navigation inside the
/// current session. Every in-app destination is workspace-prefixed and the
/// prefix is what re-scopes the app, so a link opened while another workspace
/// is active switches to the right one instead of rendering the right screen
/// with the wrong context.
Future<void> handleDesktopIncomingUrl(
  ProviderContainer container,
  String rawUrl, {
  required Future<void> Function(String rawUrl) adoptPairLink,
}) async {
  if (rawUrl.startsWith('control-center://pair')) {
    await adoptPairLink(rawUrl);
    return;
  }
  switch (DeepLinkHandler.resolve(rawUrl)) {
    case final PrDeepLink pr:
      await openPrDeepLink(container, pr);
    case final PullRequestsDeepLink pulls:
      await openPullRequestsDeepLink(container, pulls);
    case InboxDeepLink():
      openInboxDeepLink(container);
    case final RepoInboxDeepLink inbox:
      await openRepoInboxDeepLink(container, inbox);
    case SpaceDeepLink(:final workspaceId, :final spaceId):
      await openWorkspaceDeepLink(
        container,
        workspaceId,
        spaceRoute(workspaceId, spaceId),
      );
    case TicketDeepLink(:final workspaceId, :final ticketId):
      await openWorkspaceDeepLink(
        container,
        workspaceId,
        ticketDetailRoute(workspaceId, ticketId),
      );
    case OauthDoneDeepLink(:final loginId, :final code):
      await completeSignInFromDeepLink(container, loginId: loginId, code: code);
    case null:
      return;
  }
}
