/// Domain port through which an agent run comments on its own pull request.
///
/// An agent run's GitHub token only reads: it cannot post, label, lock or edit
/// anything on the forge. The server posts the comment instead, as the
/// Control Center bot (bounded by the person who requested the run), and
/// only on a pull request whose head branch is the run's own (one it pushed,
/// or its space's branch) in a repository linked to the run's workspace. The
/// MCP tool depends on this port; the server implements it.
library;

import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_port.dart'
    show kAgentOpenPullRequestTool, kAgentUpdatePullRequestTool;

/// The tool agents call to comment on their own pull request.
const String kAgentCommentOnPullRequestTool = 'comment_on_pull_request';

/// What a shell command that writes to GitHub (`gh pr comment`, `gh pr
/// edit`, `gh pr merge`, `gh issue comment`, a writing `gh api` call…)
/// inside an agent's sandbox is told: it cannot work there, and what to do
/// instead.
const String kAgentShellGitHubWriteRefusal =
    'This run\'s GitHub token is read-only, so this cannot run here. To '
    'comment on this run\'s pull request, call the '
    '$kAgentCommentOnPullRequestTool tool (Claude Code: '
    'mcp__control-center__$kAgentCommentOnPullRequestTool); to change its '
    'title or description (instead of gh pr edit), call '
    '$kAgentUpdatePullRequestTool; to open one, push the branch and call '
    '$kAgentOpenPullRequestTool. Reviewing, approving, merging and closing '
    'are left to a person.';

/// A comment an agent run asks the server to post.
class AgentPullRequestComment {
  /// Creates an [AgentPullRequestComment].
  const AgentPullRequestComment({
    required this.workspaceId,
    required this.conversationId,
    required this.number,
    required this.body,
    this.repo,
  });

  /// The run's workspace (from its trusted scope, never the model).
  final String workspaceId;

  /// The run's conversation (from its trusted scope, never the model).
  final String conversationId;

  /// `owner/name` of the repository, or null for the run's own worktree repo.
  final String? repo;

  /// The pull request number. Its head branch must be the run's own.
  final int number;

  /// The comment (markdown).
  final String body;
}

/// The comment the server posted for an agent run.
class AgentPullRequestCommentResult {
  /// Creates an [AgentPullRequestCommentResult].
  const AgentPullRequestCommentResult({
    required this.repoFullName,
    required this.number,
    required this.url,
  });

  /// `owner/name` of the repository.
  final String repoFullName;

  /// The pull request number.
  final int number;

  /// The pull request's web URL.
  final String url;

  /// The wire shape the tool answers with.
  Map<String, Object?> toWire() => {
    'repo': repoFullName,
    'number': number,
    'url': url,
    'author': 'bot',
  };
}

/// Posts comments on agent runs' own pull requests.
abstract interface class AgentPullRequestCommentPort {
  /// Posts [comment] for the agent run it names. Throws a domain exception
  /// (validation, auth, not found) when it is refused.
  Future<AgentPullRequestCommentResult> comment(
    AgentPullRequestComment comment,
  );
}
