// VM-only PR-review providers (server-side execution half of
// `pr_review_providers.dart`).
//
// `DispatchReviewersService` fans out specialist reviewers into review
// channels (driven by the `dispatch_reviewers` MCP tool and pipeline review
// steps). It owns the local Drift `dao*` repositories directly and drives the
// dispatch-capable `MessagingService`, so it is server-side only and lives here
// — never reached from the web graph. The web-safe UI providers (PR detail /
// files / diff / reviews / checks streams over RPC) stay in
// `pr_review_providers.dart`.
library;

import 'package:cc_infra/src/pr_review/dispatch_reviewers_service.dart';
import 'package:control_center/di/server_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart'
    show messagingServiceProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [DispatchReviewersService] shared by the MCP tool and any
/// pipeline step that fans out specialist reviewers.
final dispatchReviewersServiceProvider = Provider<DispatchReviewersService>((
  ref,
) {
  return DispatchReviewersService(
    // Server-side EXECUTION (shared by the dispatch_reviewers MCP tool and
    // pipeline review steps) — owns the DB directly via dao*.
    agents: ref.watch(daoAgentRepositoryProvider),
    messaging: ref.watch(daoMessagingRepositoryProvider),
    reviewChannels: ref.watch(daoReviewChannelRepositoryProvider),
    messagingPort: ref.watch(messagingServiceProvider),
    workspaces: ref.watch(daoWorkspaceRepositoryProvider),
    filesystemPort: ref.watch(workspaceFilesystemPortProvider),
  );
});
