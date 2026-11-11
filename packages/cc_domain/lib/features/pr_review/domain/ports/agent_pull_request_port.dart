/// Domain port through which an agent run opens a pull request and edits its
/// own pull request's title and description.
///
/// An agent's sandbox holds only a bot token that cannot open pull requests:
/// a pull request the bot opened is one its requester could approve
/// themselves. The server opens it instead, on the requesting person's own
/// one-repository token (the bot only when nobody requested the run), after
/// checking the repository is linked to the run's workspace and the head
/// branch is the run's own. An edit goes out the same way, and only on the
/// run's own open pull request. The MCP tools depend on this port; the
/// server implements it.
library;

import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';

/// The tool agents call to open a pull request.
const String kAgentOpenPullRequestTool = 'open_pull_request';

/// The tool agents call to change their own pull request's title or
/// description.
const String kAgentUpdatePullRequestTool = 'update_pull_request';

/// What a shell `gh pr create` (or an equivalent API call) inside an agent's
/// sandbox is told: it cannot work there, and what to do instead.
const String kAgentShellPrCreateRefusal =
    'Pull requests are not opened from the shell here: this run\'s GitHub '
    'token cannot open them. Push the branch with git push, then call the '
    '$kAgentOpenPullRequestTool tool (Claude Code: '
    'mcp__control-center__$kAgentOpenPullRequestTool). It opens the pull '
    'request as the person who asked for this run.';

/// A pull request an agent run asks the server to open.
class AgentPullRequestDraft {
  /// Creates an [AgentPullRequestDraft].
  const AgentPullRequestDraft({
    required this.workspaceId,
    required this.conversationId,
    required this.head,
    required this.base,
    required this.title,
    this.body = '',
    this.repo,
    this.draft = false,
  });

  /// The run's workspace (from its trusted scope, never the model).
  final String workspaceId;

  /// The run's conversation (from its trusted scope, never the model).
  final String conversationId;

  /// `owner/name` of the repository, or null for the run's own worktree repo.
  final String? repo;

  /// The branch with the changes. It must be the run's own: pushed by it, or
  /// its space's branch for that repository.
  final String head;

  /// The branch to merge into.
  final String base;

  /// Title.
  final String title;

  /// Description (markdown).
  final String body;

  /// Whether to open it as a draft.
  final bool draft;
}

/// Who a pull request an agent opened is authored by on the forge.
enum AgentPullRequestAuthor {
  /// The person who requested the run, on their own one-repository token.
  requester,

  /// The Control Center bot: nobody requested the run (schedule, webhook).
  bot,
}

/// The pull request the server opened for an agent run.
class AgentPullRequestResult {
  /// Creates an [AgentPullRequestResult].
  const AgentPullRequestResult({
    required this.repoFullName,
    required this.number,
    required this.url,
    required this.author,
  });

  /// `owner/name` of the repository it was opened on.
  final String repoFullName;

  /// The forge's pull request number.
  final int number;

  /// Its web URL.
  final String url;

  /// Whose name it carries.
  final AgentPullRequestAuthor author;

  /// The wire shape the tool answers with.
  Map<String, Object?> toWire() => {
    'repo': repoFullName,
    'number': number,
    'url': url,
    'author': author.name,
  };
}

/// A new title and/or description an agent run asks the server to give its
/// own open pull request.
class AgentPullRequestEdit {
  /// Creates an [AgentPullRequestEdit].
  const AgentPullRequestEdit({
    required this.workspaceId,
    required this.conversationId,
    required this.number,
    this.repo,
    this.title,
    this.body,
  });

  /// The longest title accepted: GitHub's own limit.
  static const int maxTitleLength = 256;

  /// The longest description accepted: GitHub's own limit.
  static const int maxBodyLength = 65536;

  /// The run's workspace (from its trusted scope, never the model).
  final String workspaceId;

  /// The run's conversation (from its trusted scope, never the model).
  final String conversationId;

  /// `owner/name` of the repository, or null for the run's own worktree repo.
  final String? repo;

  /// The pull request number. Its head branch must be the run's own.
  final int number;

  /// The new title, or null to keep it.
  final String? title;

  /// The new description (markdown, replacing the whole of it), or null to
  /// keep it.
  final String? body;
}

/// The pull request the server edited for an agent run.
class AgentPullRequestEditResult {
  /// Creates an [AgentPullRequestEditResult].
  const AgentPullRequestEditResult({
    required this.repoFullName,
    required this.number,
    required this.url,
  });

  /// `owner/name` of the repository.
  final String repoFullName;

  /// The pull request number.
  final int number;

  /// Its web URL.
  final String url;

  /// The wire shape the tool answers with.
  Map<String, Object?> toWire() => {
    'repo': repoFullName,
    'number': number,
    'url': url,
  };
}

/// Opens pull requests for agent runs.
abstract interface class AgentPullRequestPort {
  /// Opens [draft] for the agent run it names. Throws a domain exception
  /// (validation, auth, `NeedsSignInException`) when it is refused.
  Future<AgentPullRequestResult> open(AgentPullRequestDraft draft);

  /// Gives the agent run's own open pull request [edit]'s title and/or
  /// description, as whoever [open] would have opened it as. Throws a domain
  /// exception (validation, auth, not found, `NeedsSignInException`) when it
  /// is refused.
  Future<AgentPullRequestEditResult> update(AgentPullRequestEdit edit);

  /// The member the agent run open in [conversationId] of [workspaceId] acts
  /// for, or null when nobody requested it (schedule, webhook): whose name
  /// any other pull request the run publishes (a stack) must carry. Throws
  /// a domain exception when no run is open there, runs for different people
  /// are, or the requester is no longer a member.
  Future<String?> requesterOf({
    required String workspaceId,
    required String conversationId,
  });

  /// Who may not approve a pull request the agent run open in
  /// [conversationId] publishes: its requester, or for a run nobody
  /// requested everyone who armed the trigger that started it (empty when
  /// nobody did). Throws like [requesterOf].
  Future<Set<String>> approvalOwnersOf({
    required String workspaceId,
    required String conversationId,
  });

  /// The commit identities of the agent runs open in [conversationId] (all
  /// for one requester): what every commit the run publishes server-side (a
  /// stack) must keep, exactly as the push gateway holds the run's own
  /// pushes to its identity. Read from the runs' registered grants, never
  /// from a request. Throws like [requesterOf].
  Future<List<AgentCommitIdentity>> commitIdentitiesOf({
    required String workspaceId,
    required String conversationId,
  });
}
