import 'package:cc_connect_core/src/github_scope.dart' show isGitHubSegment;
import 'package:cc_connect_core/src/wire.dart';

/// Maximum request size accepted by `POST /v1/github/review_comments`.
const int connectMaxReviewCommentsRequestBytes = 256 * 1024;

/// Maximum number of inline review comments accepted in a single
/// `POST /v1/github/review_comments` batch.
const int connectMaxReviewCommentsPerRequest = 25;

/// Maximum length of a single inline review comment body accepted by
/// `POST /v1/github/review_comments`.
const int connectMaxReviewCommentBodyLength = 32768;

/// Whose token a `/v1/github/scope` mint is.
enum GitHubMintActor {
  /// A one-repository child of the person's own user token
  /// (`/applications/{client_id}/token/scoped`): what GitHub shows as the
  /// person "via" the App. For what a person does, or an agent does in their
  /// name (pull requests it opens for them, pushes to them).
  user('user'),

  /// A one-repository installation token of the App (`ghs_`): GitHub shows
  /// the App's bot. Authorized by the person's sealed grant (they must see
  /// the repository with the asked permission), never broader than them.
  app('app');

  const GitHubMintActor(this.wire);

  /// The wire spelling (`as`).
  final String wire;

  /// Parses a wire value; null when unknown.
  static GitHubMintActor? fromWire(Object? wire) {
    for (final actor in values) {
      if (actor.wire == wire) {
        return actor;
      }
    }
    return null;
  }
}

/// `POST /v1/github/scope`.
final class GitHubScopeRequest {
  /// Creates the request.
  const GitHubScopeRequest({
    required this.seal,
    required this.workspaceId,
    required this.repoId,
    required this.repoOwner,
    required this.repoName,
    required this.scope,
    required this.actor,
  });

  /// Parses the body; throws [FormatException].
  factory GitHubScopeRequest.fromJson(Map<String, Object?> json) {
    final seal = json['seal'];
    final workspace = json['workspace_id'];
    final repoId = json['repo_id'];
    final owner = json['repo_owner'];
    final name = json['repo_name'];
    final scope = json['scope'];
    final actor = GitHubMintActor.fromWire(json['as']);
    if (actor == null ||
        seal is! String ||
        seal.isEmpty ||
        workspace is! String ||
        !isWorkspaceScope(workspace) ||
        repoId is! int ||
        repoId <= 0 ||
        owner is! String ||
        name is! String ||
        scope is! String) {
      throw const FormatException('github scope');
    }
    return GitHubScopeRequest(
      seal: seal,
      workspaceId: workspace,
      repoId: repoId,
      repoOwner: owner,
      repoName: name,
      scope: scope,
      actor: actor,
    );
  }

  /// The accountable human's GitHub seal.
  final String seal;

  /// The workspace the seal belongs to.
  final String workspaceId;

  /// The numeric repository id (from the linked repo record).
  final int repoId;

  /// The repository owner login.
  final String repoOwner;

  /// The repository name.
  final String repoName;

  /// The requested scope wire value.
  final String scope;

  /// Whose token to mint (`as`).
  final GitHubMintActor actor;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'seal': seal,
    'workspace_id': workspaceId,
    'repo_id': repoId,
    'repo_owner': repoOwner,
    'repo_name': repoName,
    'scope': scope,
    'as': actor.wire,
  };
}

/// The answer to [GitHubScopeRequest].
final class GitHubScopedToken {
  /// Creates the token.
  const GitHubScopedToken({
    required this.accessToken,
    required this.grantedScope,
    required this.expiresAt,
    this.updatedSeal = '',
    this.installationId = 0,
    this.repositorySelection = '',
    this.repositoryIds = const [],
    this.permissions = const {},
  });

  /// Parses the body; throws [FormatException].
  factory GitHubScopedToken.fromJson(Map<String, Object?> json) {
    final access = json['access_token'];
    final granted = json['granted_scope'];
    final expires = json['expires_at'];
    final parsedExpiry = expires is String ? DateTime.tryParse(expires) : null;
    final updated = json['updated_seal'];
    final installation = json['installation_id'];
    final selection = json['repository_selection'];
    final repositories = json['repositories'];
    final permissions = json['permissions'];
    if (access is! String ||
        access.isEmpty ||
        granted is! String ||
        parsedExpiry == null ||
        (selection != null && selection is! String) ||
        (repositories != null &&
            (repositories is! List || repositories.any((r) => r is! int))) ||
        (permissions != null &&
            (permissions is! Map ||
                permissions.entries.any(
                  (e) => e.key is! String || e.value is! String,
                )))) {
      throw const FormatException('github scoped token');
    }
    return GitHubScopedToken(
      accessToken: access,
      grantedScope: granted,
      expiresAt: parsedExpiry.toUtc(),
      updatedSeal: updated is String ? updated : '',
      installationId: installation is int ? installation : 0,
      repositorySelection: selection as String? ?? '',
      repositoryIds: [
        if (repositories is List)
          for (final r in repositories) r as int,
      ],
      permissions: {
        if (permissions is Map)
          for (final e in permissions.entries) e.key as String: e.value as String,
      },
    );
  }

  /// The one-repository `ghu_` token.
  final String accessToken;

  /// The scope actually granted (possibly clamped below the request).
  final String grantedScope;

  /// When the token expires.
  final DateTime expiresAt;

  /// A rotated parent seal the server must persist, when the parent was
  /// refreshed on the way.
  final String updatedSeal;

  /// The installation the token was minted through.
  final int installationId;

  /// An installation token's (`as: app`) `repository_selection` as GitHub
  /// answered the mint; empty for a user child.
  final String repositorySelection;

  /// The repository ids an installation token covers, as GitHub answered
  /// the mint; empty for a user child.
  final List<int> repositoryIds;

  /// The permissions an installation token carries, as GitHub answered the
  /// mint; empty for a user child.
  final Map<String, String> permissions;

  /// The GitHub mint answer's coverage, in the shape `scopedTokenMatches`
  /// reads: the server proves an installation token covers exactly one
  /// repository with exactly the granted permissions before using it.
  Map<String, Object?> get coverage => {
    'repository_selection': repositorySelection,
    'repositories': repositoryIds,
    'permissions': permissions,
  };

  /// The wire body.
  Map<String, Object?> toJson() => {
    'access_token': accessToken,
    'granted_scope': grantedScope,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    if (updatedSeal.isNotEmpty) 'updated_seal': updatedSeal,
    if (installationId > 0) 'installation_id': installationId,
    if (repositorySelection.isNotEmpty)
      'repository_selection': repositorySelection,
    if (repositoryIds.isNotEmpty) 'repositories': repositoryIds,
    if (permissions.isNotEmpty) 'permissions': permissions,
  };
}

/// `POST /v1/github/revoke`: a full disconnect (seal) or one scoped token.
final class GitHubRevokeRequest {
  /// Creates the request.
  const GitHubRevokeRequest({
    required this.workspaceId,
    this.seal = '',
    this.scopedToken = '',
  });

  /// Parses the body; throws [FormatException].
  factory GitHubRevokeRequest.fromJson(Map<String, Object?> json) {
    final workspace = json['workspace_id'];
    final seal = json['seal'];
    final token = json['scoped_token'];
    if (workspace is! String ||
        !isWorkspaceScope(workspace) ||
        seal is! String ||
        seal.isEmpty ||
        (token != null && token is! String)) {
      throw const FormatException('github revoke');
    }
    return GitHubRevokeRequest(
      workspaceId: workspace,
      seal: seal,
      scopedToken: token as String? ?? '',
    );
  }

  /// The workspace the seal belongs to.
  final String workspaceId;

  /// The grant's seal (proves the caller owns it).
  final String seal;

  /// When set, only this scoped token is revoked; otherwise the whole grant.
  final String scopedToken;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'workspace_id': workspaceId,
    'seal': seal,
    if (scopedToken.isNotEmpty) 'scoped_token': scopedToken,
  };
}

/// One installation of the shared GitHub App the signed-in person can see
/// (`POST /v1/github/installations`, body: [SealRequest]). Any server a
/// member of the account signs in on may mint against it: the org's install
/// is its consent, and every token is the member's own, clamped to their
/// repository role.
final class GitHubInstallationView {
  /// Creates the view.
  const GitHubInstallationView({
    required this.installationId,
    required this.accountId,
    required this.accountLogin,
    required this.targetType,
    required this.suspended,
  });

  /// Parses one item; null when malformed.
  static GitHubInstallationView? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final id = json['installation_id'];
    final accountId = json['account_id'];
    final login = json['account_login'];
    final type = json['target_type'];
    if (id is! int ||
        accountId is! int ||
        login is! String ||
        type is! String) {
      return null;
    }
    return GitHubInstallationView(
      installationId: id,
      accountId: accountId,
      accountLogin: login,
      targetType: type,
      suspended: json['suspended'] == true,
    );
  }

  /// GitHub's installation id.
  final int installationId;

  /// The account the app is installed on (numeric).
  final int accountId;

  /// Its login.
  final String accountLogin;

  /// `Organization` or `User`.
  final String targetType;

  /// Whether the installation is suspended.
  final bool suspended;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'installation_id': installationId,
    'account_id': accountId,
    'account_login': accountLogin,
    'target_type': targetType,
    'suspended': suspended,
  };
}

final RegExp _commitShaPattern = RegExp(r'^[0-9a-fA-F]{7,64}$');

bool _isValidReviewCommentPath(String path) {
  if (path.isEmpty ||
      path.length > 1024 ||
      path.startsWith('/') ||
      path.contains('\x00') ||
      path.contains('\r') ||
      path.contains('\n')) {
    return false;
  }
  return path.split('/').every((segment) => segment != '..' && segment != '.');
}

bool _isValidDiffSide(Object? side) => side == 'RIGHT' || side == 'LEFT';

/// One inline pull-request review comment inside [GitHubReviewCommentsRequest].
final class GitHubReviewCommentInput {
  /// Creates the comment input.
  const GitHubReviewCommentInput({
    required this.path,
    required this.line,
    this.side = 'RIGHT',
    this.startLine,
    this.startSide,
    required this.body,
  });

  /// Parses and validates one comment input; throws [FormatException].
  factory GitHubReviewCommentInput.fromJson(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('github review comment input');
    }
    final path = raw['path'];
    final line = raw['line'];
    final side = raw['side'];
    final startLine = raw['start_line'];
    final startSide = raw['start_side'];
    final body = raw['body'];
    if (path is! String ||
        !_isValidReviewCommentPath(path) ||
        line is! int ||
        line <= 0 ||
        !_isValidDiffSide(side) ||
        (startLine != null &&
            (startLine is! int || startLine <= 0 || startLine >= line)) ||
        (startSide != null && !_isValidDiffSide(startSide)) ||
        (startLine != null && startSide != null && startSide != side) ||
        body is! String ||
        body.trim().isEmpty ||
        body.length > connectMaxReviewCommentBodyLength) {
      throw const FormatException('github review comment input');
    }
    return GitHubReviewCommentInput(
      path: path,
      line: line,
      side: side as String,
      startLine: startLine as int?,
      startSide: startSide as String?,
      body: body,
    );
  }

  /// Repository-relative file path.
  final String path;

  /// Ending line of the anchor.
  final int line;

  /// Diff side (`RIGHT` or `LEFT`).
  final String side;

  /// Optional starting line for a multi-line anchor (`1 <= startLine < line`).
  final int? startLine;

  /// Optional starting diff side (matches [side] when set).
  final String? startSide;

  /// Raw comment body (Connect neutralizes mentions and adds attribution).
  final String body;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'path': path,
    'line': line,
    'side': side,
    if (startLine != null) 'start_line': startLine,
    if (startSide != null) 'start_side': startSide,
    'body': body,
  };
}

/// `POST /v1/github/review_comments`: posts inline pull-request review
/// comments through the shared App's bot, bounded by the caller's seal.
final class GitHubReviewCommentsRequest {
  /// Creates the request.
  const GitHubReviewCommentsRequest({
    required this.seal,
    required this.workspaceId,
    required this.repoId,
    required this.repoOwner,
    required this.repoName,
    required this.prNumber,
    required this.commitSha,
    required this.comments,
  });

  /// Parses and validates the batch request; throws [FormatException].
  factory GitHubReviewCommentsRequest.fromJson(Map<String, Object?> json) {
    final seal = json['seal'];
    final workspace = json['workspace_id'];
    final repoId = json['repo_id'];
    final owner = json['repo_owner'];
    final name = json['repo_name'];
    final prNumber = json['pr_number'];
    final commitSha = json['commit_sha'];
    final rawComments = json['comments'];
    if (seal is! String ||
        seal.isEmpty ||
        workspace is! String ||
        !isWorkspaceScope(workspace) ||
        repoId is! int ||
        repoId <= 0 ||
        owner is! String ||
        !isGitHubSegment(owner) ||
        name is! String ||
        !isGitHubSegment(name) ||
        prNumber is! int ||
        prNumber <= 0 ||
        commitSha is! String ||
        !_commitShaPattern.hasMatch(commitSha) ||
        rawComments is! List ||
        rawComments.isEmpty ||
        rawComments.length > connectMaxReviewCommentsPerRequest) {
      throw const FormatException('github review comments');
    }
    return GitHubReviewCommentsRequest(
      seal: seal,
      workspaceId: workspace,
      repoId: repoId,
      repoOwner: owner,
      repoName: name,
      prNumber: prNumber,
      commitSha: commitSha,
      comments: [
        for (final item in rawComments) GitHubReviewCommentInput.fromJson(item),
      ],
    );
  }

  /// The accountable human's GitHub seal.
  final String seal;

  /// The workspace the seal belongs to.
  final String workspaceId;

  /// The numeric repository id (from the linked repo record).
  final int repoId;

  /// The repository owner login.
  final String repoOwner;

  /// The repository name.
  final String repoName;

  /// Pull request number.
  final int prNumber;

  /// Head commit SHA the comments anchor to.
  final String commitSha;

  /// Batch of inline comments to post.
  final List<GitHubReviewCommentInput> comments;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'seal': seal,
    'workspace_id': workspaceId,
    'repo_id': repoId,
    'repo_owner': repoOwner,
    'repo_name': repoName,
    'pr_number': prNumber,
    'commit_sha': commitSha,
    'comments': [for (final c in comments) c.toJson()],
  };
}

/// Outcome of posting a single inline review comment via Connect.
enum GitHubReviewCommentStatus {
  /// Posted to GitHub as the App bot.
  posted('posted'),

  /// GitHub rejected the anchor as outside the PR diff (422).
  outOfDiff('out_of_diff'),

  /// GitHub rejected or failed to post the comment for another reason.
  failed('failed');

  const GitHubReviewCommentStatus(this.wire);

  /// The wire spelling.
  final String wire;

  /// Parses a wire value; null when unknown.
  static GitHubReviewCommentStatus? fromWire(Object? wire) {
    for (final status in values) {
      if (status.wire == wire) {
        return status;
      }
    }
    return null;
  }
}

/// Per-comment result inside [GitHubReviewCommentsResponse].
final class GitHubReviewCommentOutcome {
  /// Creates the outcome.
  const GitHubReviewCommentOutcome({
    required this.index,
    required this.status,
    this.commentId,
  });

  /// Parses one outcome; throws [FormatException].
  factory GitHubReviewCommentOutcome.fromJson(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('github review comment outcome');
    }
    final index = raw['index'];
    final status = GitHubReviewCommentStatus.fromWire(raw['status']);
    final commentId = raw['comment_id'];
    if (index is! int ||
        index < 0 ||
        status == null ||
        (commentId != null && commentId is! int)) {
      throw const FormatException('github review comment outcome');
    }
    return GitHubReviewCommentOutcome(
      index: index,
      status: status,
      commentId: commentId as int?,
    );
  }

  /// Zero-based index into the request's comment list.
  final int index;

  /// Posting status.
  final GitHubReviewCommentStatus status;

  /// GitHub's review comment id when [status] is [GitHubReviewCommentStatus.posted].
  final int? commentId;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'index': index,
    'status': status.wire,
    if (commentId != null) 'comment_id': commentId,
  };
}

/// The answer to [GitHubReviewCommentsRequest].
final class GitHubReviewCommentsResponse {
  /// Creates the response.
  const GitHubReviewCommentsResponse({
    required this.results,
    this.updatedSeal = '',
  });

  /// Parses the response; throws [FormatException].
  factory GitHubReviewCommentsResponse.fromJson(Map<String, Object?> json) {
    final rawResults = json['results'];
    final updated = json['updated_seal'];
    if (rawResults is! List || (updated != null && updated is! String)) {
      throw const FormatException('github review comments response');
    }
    return GitHubReviewCommentsResponse(
      results: [
        for (final item in rawResults)
          GitHubReviewCommentOutcome.fromJson(item),
      ],
      updatedSeal: updated as String? ?? '',
    );
  }

  /// Per-comment outcomes.
  final List<GitHubReviewCommentOutcome> results;

  /// A rotated parent seal the server must persist, when refreshed on the way.
  final String updatedSeal;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'results': [for (final r in results) r.toJson()],
    if (updatedSeal.isNotEmpty) 'updated_seal': updatedSeal,
  };
}
