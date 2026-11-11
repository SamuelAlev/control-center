import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart'
    show NeedsSignInException, ValidationException;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/cc_infra.dart'
    show GitHubAppMintRefused, gitHubInstallationSettingsUrl;
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/forge/forge_repo_pins.dart'
    show RepoLinkVerdict;
import 'package:cc_server_core/src/forge/github_client_types.dart';
import 'package:cc_server_core/src/forge/github_lane_resolver.dart';
import 'package:cc_server_core/src/forge/github_minter.dart';
import 'package:cc_server_core/src/forge/repo_access_registry.dart';

/// What automation meets on a GitHub repository linked to a workspace,
/// read without minting a token and recorded in [RepoAccessRegistry]: the
/// check when a repository is linked ([verifyLink]), the daily sweep
/// ([sweepLinks]), the open-PR poller's reading ([classifyRepo]), and what
/// each automation mint learned ([recordMinted], [recordRefusal]).
final class GitHubLinkChecks {
  /// Creates the checks over the GitHub facade's parts.
  GitHubLinkChecks({
    required this._lanes,
    required this._minter,
    required this._repoAccess,
    required this._isSignedIn,
    required this._accountableHuman,
    required this._installationsFor,
    required this._installLink,
    required this._now,
  });

  final GitHubLaneResolver _lanes;
  final GitHubMinter _minter;
  final RepoAccessRegistry _repoAccess;
  final Future<bool> Function(String userId, {String? workspaceId}) _isSignedIn;
  final Future<String?> Function(String workspaceId) _accountableHuman;
  final Future<List<GitHubInstallationView>> Function(
    String workspaceId,
    String userId,
  )
  _installationsFor;
  final Future<Uri> Function(String workspaceId) _installLink;
  final DateTime Function() _now;

  /// Checks linking [owner]/[repo] to [workspaceId] by [userId] and records
  /// what automation will meet there in [RepoAccessRegistry].
  ///
  /// Hard refusals: a name that is not a GitHub repository
  /// ([ValidationException]), [userId] not signed in to GitHub
  /// ([NeedsSignInException]), and [userId]'s own sign-in not seeing a
  /// repository the App does reach ([ValidationException]). A repository the
  /// App does not reach is invisible to an App sign-in too, so that answer
  /// is the App's, not the person's: it comes back as the soft "not
  /// installed" / "not selected" outcome with where to fix it. Without a
  /// GitHub lane nothing can mint for the link, so there is nothing more to
  /// check.
  ///
  /// Soft outcomes come back (most blocking first) and the first is
  /// recorded: the App not installed on the owner, the repository not
  /// selected in its installation, the installation suspended, the
  /// accountable person unable to see it or not signed in. None of them
  /// stops the link: an admin can fix each afterwards.
  ///
  /// The linker's read is what pins the link: its repository id comes back
  /// as the verdict's `forgeRepoId` (empty without a lane, or when only the
  /// App side was read), and no read here is held against an earlier pin.
  Future<RepoLinkVerdict> verifyLink(
    String workspaceId,
    String userId,
    String owner,
    String repo, {
    String? repoId,
  }) async {
    // Checked before anything else, lane or not: a stored `..` or `%2e`
    // segment would otherwise be linked now and resolve to another path
    // the moment a lane is configured.
    if (!isGitHubSegment(owner) || !isGitHubSegment(repo)) {
      throw const ValidationException('That is not a GitHub repository name.');
    }
    final identity = await _lanes.resolve(workspaceId);
    if (identity.lane == GitHubLane.none) {
      return (forgeRepoId: '', warnings: const <RepoAccessIssue>[]);
    }
    if (!await _isSignedIn(userId, workspaceId: workspaceId)) {
      throw NeedsSignInException(
        ForgeHost.github.wire,
        'Sign in to GitHub to link $owner/$repo: automation in this workspace '
        'can reach only repositories the person linking them can see.',
      );
    }
    _minter.forgetRepo(gitHubRepoKey(workspaceId, userId, owner, repo));
    final String forgeRepoId;
    try {
      forgeRepoId =
          '${(await _minter.repoFacts(workspaceId, userId, owner, repo, pinned: false)).id}';
    } on GitHubScopeRefused catch (e) {
      if (e.code == GitHubRefusal.accessDenied) {
        final appSide = await _appSide(
          workspaceId,
          owner,
          repo,
          identity: identity,
          human: userId,
        );
        if (appSide != null && appSide.state.blocksAutomation) {
          final found = [appSide];
          await _recordChecked(workspaceId, owner, repo, found, repoId: repoId);
          _linkChecked(workspaceId, owner, repo, found);
          return (forgeRepoId: '', warnings: found);
        }
      }
      throw switch (e.code) {
        GitHubRefusal.accessDenied => ValidationException(
          'Your GitHub account cannot see $owner/$repo, so it cannot be '
          'linked to this workspace.',
        ),
        GitHubRefusal.needsSignIn => NeedsSignInException(
          ForgeHost.github.wire,
          'Sign in to GitHub again to link $owner/$repo.',
        ),
        GitHubRefusal.ssoRequired => NeedsSignInException(
          ForgeHost.github.wire,
          '$owner enforces SAML single sign-on: sign in to GitHub again '
          "through the organization's SSO to link $owner/$repo.",
        ),
        _ => ValidationException(e.message),
      };
    }
    final found = await _checkAutomation(
      workspaceId,
      owner,
      repo,
      identity: identity,
      fallbackHuman: userId,
      pinned: false,
    );
    await _recordChecked(workspaceId, owner, repo, found, repoId: repoId);
    _linkChecked(workspaceId, owner, repo, found);
    return (forgeRepoId: forgeRepoId, warnings: found);
  }

  /// What automation meets on [owner]/[repo] in [workspaceId] right now
  /// ([_checkAutomation]), without minting anything and without recording
  /// it: the open-PR poller's reading of a repository GitHub hides from it.
  Future<List<RepoAccessIssue>> classifyRepo(
    String workspaceId,
    String owner,
    String repo,
  ) async {
    final identity = await _lanes.resolve(workspaceId);
    if (identity.lane == GitHubLane.none) {
      return const [];
    }
    return _checkAutomation(workspaceId, owner, repo, identity: identity);
  }

  void _linkChecked(
    String workspaceId,
    String owner,
    String repo,
    List<RepoAccessIssue> found,
  ) => forgeAudit(ForgeAuditEvent.forgeLinkChecked, {
    'forge': ForgeHost.github.wire,
    'workspace_id': workspaceId,
    'repo': '$owner/$repo',
    'state': found.isEmpty ? 'reachable' : found.first.state.wire,
  });

  /// Re-checks every repository in [linked] the way automation will meet
  /// it ([_checkAutomation]) and records the outcome in [RepoAccessRegistry]: an
  /// issue, or reachable. Runs three minutes after boot and then daily.
  /// Returns how many links block automation in [workspaceId] afterwards.
  Future<int> sweepLinks(
    String workspaceId,
    List<({String owner, String repo})> linked,
  ) async {
    final identity = await _lanes.resolve(workspaceId);
    if (identity.lane == GitHubLane.none) {
      return 0;
    }
    var blocked = 0;
    for (final link in linked) {
      final found = await _checkAutomation(
        workspaceId,
        link.owner,
        link.repo,
        identity: identity,
      );
      await _recordChecked(workspaceId, link.owner, link.repo, found);
      _linkChecked(workspaceId, link.owner, link.repo, found);
      if (found.any((i) => i.state.blocksAutomation)) {
        blocked++;
      }
    }
    return blocked;
  }

  /// What automation (no acting person) meets on [owner]/[repo] right now,
  /// most blocking first: App-side issues (not installed, not selected,
  /// suspended), then the accountable person's (not signed in, cannot see).
  /// A transient failure is reported as such and blocks nothing.
  ///
  /// Nothing is minted: the App side is read from the App's installations
  /// ([_appSide]), through the accountable person when one is signed in,
  /// else through [fallbackHuman] (the member linking it). A repository whose
  /// path now names another repository than the one linked is reported as
  /// such, unless [pinned] is false (a link being made).
  Future<List<RepoAccessIssue>> _checkAutomation(
    String workspaceId,
    String owner,
    String repo, {
    required GitHubLaneIdentity identity,
    String? fallbackHuman,
    bool pinned = true,
  }) async {
    final ownerSide = <RepoAccessIssue>[];
    final human = await _accountableHuman(workspaceId);
    String? through;
    var personCannotSee = false;
    if (human == null || !await _isSignedIn(human, workspaceId: workspaceId)) {
      ownerSide.add(
        _issue(
          owner,
          repo,
          RepoAccessState.ownerNotSignedIn,
          'Nobody accountable for this workspace is signed in to GitHub, so '
          'automation has no one to act for on $owner/$repo.',
        ),
      );
    } else {
      through = human;
      _minter.forgetRepo(gitHubRepoKey(workspaceId, human, owner, repo));
      try {
        await _minter.repoFacts(
          workspaceId,
          human,
          owner,
          repo,
          pinned: pinned,
        );
      } on GitHubScopeRefused catch (e) {
        switch (e.code) {
          case GitHubRefusal.accessDenied:
            personCannotSee = true;
          case GitHubRefusal.repoReplaced:
            ownerSide.add(
              _issue(owner, repo, RepoAccessState.repoReplaced, e.message),
            );
          case GitHubRefusal.needsSignIn:
            ownerSide.add(
              _issue(
                owner,
                repo,
                RepoAccessState.ownerNotSignedIn,
                'The person accountable for this workspace needs to sign in '
                'to GitHub again.',
              ),
            );
          case GitHubRefusal.ssoRequired:
            ownerSide.add(
              _issue(owner, repo, RepoAccessState.ownerNotSignedIn, e.message),
            );
          default:
            ownerSide.add(
              _issue(owner, repo, RepoAccessState.transient, e.message),
            );
        }
      }
    }
    through ??= fallbackHuman;
    final appSide = await _appSide(
      workspaceId,
      owner,
      repo,
      identity: identity,
      human: through,
    );
    // An App sign-in sees only what the App reaches: when the App does not
    // reach the repository, that is the reason, not the person.
    if (personCannotSee &&
        (appSide == null || !appSide.state.blocksAutomation)) {
      ownerSide.add(
        _issue(
          owner,
          repo,
          RepoAccessState.ownerCannotSee,
          'The person accountable for this workspace cannot see '
          '$owner/$repo on GitHub, so automation cannot act on it.',
        ),
      );
    }
    final found = [?appSide, ...ownerSide];
    // Blocking first; a transient one only when nothing blocks.
    found.sort(
      (a, b) => (a.state.blocksAutomation ? 0 : 1).compareTo(
        b.state.blocksAutomation ? 0 : 1,
      ),
    );
    return found;
  }

  RepoAccessIssue _issue(
    String owner,
    String repo,
    RepoAccessState state,
    String message, {
    String? installUrl,
  }) {
    final now = _now();
    return RepoAccessIssue(
      forge: ForgeHost.github,
      owner: owner,
      name: repo,
      state: state,
      since: now,
      checkedAt: now,
      message: message,
      installUrl: installUrl,
    );
  }

  /// Whether the workspace's App reaches [owner]/[repo], read without
  /// minting: null when it does, else the App-side issue (not installed on
  /// the owner, the repository not selected, the installation suspended,
  /// or GitHub unreadable right now: transient).
  ///
  /// An App lane asks GitHub with the App's JWT (`GET
  /// /repos/{owner}/{repo}/installation`, and the cached installation
  /// listing for which of the first two it is). Connect cannot answer for
  /// the shared App, so it reads the installations [human] can see: an
  /// owner without one is "not installed"; past that, Connect decides when
  /// it mints.
  Future<RepoAccessIssue?> _appSide(
    String workspaceId,
    String owner,
    String repo, {
    required GitHubLaneIdentity identity,
    required String? human,
  }) async {
    try {
      switch (identity.lane) {
        case GitHubLane.none:
          return null;
        case GitHubLane.workspaceApp || GitHubLane.ownApp:
          final app = await _lanes.appFor(workspaceId, identity.lane);
          if (app == null) {
            return null;
          }
          final installation = await app.installationForOwner(owner);
          if (installation == null) {
            return _issue(
              owner,
              repo,
              RepoAccessState.appNotInstalled,
              'The GitHub App is not installed on $owner. Install it from '
              'Settings.',
              installUrl: (await _installLinkOrNull(workspaceId))?.toString(),
            );
          }
          if (installation.isSuspended) {
            return _issue(
              owner,
              repo,
              RepoAccessState.installationSuspended,
              'The GitHub App installation on $owner is suspended.',
            );
          }
          if (!await app.coversRepository(owner, repo)) {
            return _issue(
              owner,
              repo,
              RepoAccessState.repoNotSelected,
              'The GitHub App is installed on $owner, but $owner/$repo is not '
              'among the repositories it may reach.',
              installUrl: gitHubInstallationSettingsUrl(
                installation,
              ).toString(),
            );
          }
          return null;
        case GitHubLane.connect:
          if (human == null) {
            return null;
          }
          final visible = await _installationsFor(workspaceId, human);
          final mine = visible
              .where((i) => i.accountLogin.toLowerCase() == owner.toLowerCase())
              .firstOrNull;
          if (mine == null) {
            return _issue(
              owner,
              repo,
              RepoAccessState.appNotInstalled,
              'The GitHub App is not installed on $owner. Install it from '
              'Settings.',
              installUrl: (await _installLinkOrNull(workspaceId))?.toString(),
            );
          }
          if (mine.suspended) {
            return _issue(
              owner,
              repo,
              RepoAccessState.installationSuspended,
              'The GitHub App installation on $owner is suspended.',
            );
          }
          return null;
      }
    } on GitHubAppMintRefused catch (e) {
      return _issue(owner, repo, RepoAccessState.transient, e.message);
    } on GitHubScopeRefused catch (e) {
      return e.code.isTransient
          ? _issue(owner, repo, RepoAccessState.transient, e.message)
          : null;
    } on ConnectException catch (e) {
      return _issue(
        owner,
        repo,
        RepoAccessState.transient,
        'Control Center Connect could not list installations '
        '(${e.code.wire}).',
      );
    }
  }

  Future<Uri?> _installLinkOrNull(String workspaceId) async {
    try {
      return await _installLink(workspaceId);
    } on GitHubScopeRefused {
      return null;
    }
  }

  /// Records the first of [found] (or reachable when there is none).
  Future<void> _recordChecked(
    String workspaceId,
    String owner,
    String repo,
    List<RepoAccessIssue> found, {
    String? repoId,
  }) async {
    if (found.isEmpty) {
      await _repoAccess.recordReachable(
        workspaceId,
        forge: ForgeHost.github,
        owner: owner,
        name: repo,
      );
      return;
    }
    final first = found.first;
    await _repoAccess.record(
      workspaceId,
      forge: ForgeHost.github,
      owner: owner,
      name: repo,
      state: first.state,
      repoId: repoId,
      message: first.message,
      installUrl: first.installUrl,
    );
  }

  /// The registry state an App-side refusal amounts to, or null.
  static RepoAccessState? _appSideState(GitHubRefusal code) => switch (code) {
    GitHubRefusal.notInstalled => RepoAccessState.appNotInstalled,
    GitHubRefusal.repoNotSelected => RepoAccessState.repoNotSelected,
    GitHubRefusal.suspended => RepoAccessState.installationSuspended,
    _ => null,
  };

  /// The registry state any automation refusal amounts to, or null when it
  /// says nothing about the repository.
  static RepoAccessState? _stateFor(GitHubRefusal code) =>
      _appSideState(code) ??
      switch (code) {
        // SAML enforcement: the accountable person signs in again through
        // the organization's SSO, as for a lapsed sign-in.
        GitHubRefusal.needsSignIn ||
        GitHubRefusal.ssoRequired => RepoAccessState.ownerNotSignedIn,
        GitHubRefusal.accessDenied => RepoAccessState.ownerCannotSee,
        GitHubRefusal.providerUnavailable ||
        GitHubRefusal.rateLimited => RepoAccessState.transient,
        _ => null,
      };

  /// Where an admin fixes [state]: the installation's repository selection
  /// when the refusal named it, else the lane's install link.
  Future<String?> _installUrlFor(
    String workspaceId,
    RepoAccessState state,
    GitHubScopeRefused refusal,
  ) async {
    if (state != RepoAccessState.appNotInstalled &&
        state != RepoAccessState.repoNotSelected) {
      return null;
    }
    final named = refusal.installUrl;
    if (named != null) {
      return named.toString();
    }
    try {
      return (await _installLink(workspaceId)).toString();
    } on GitHubScopeRefused {
      return null;
    }
  }

  /// Records what an automation mint (no acting person) learned.
  Future<void> recordRefusal(
    String workspaceId,
    String owner,
    String repo,
    GitHubScopeRefused refusal,
  ) async {
    final state = _stateFor(refusal.code);
    if (state == null) {
      return;
    }
    if (state == RepoAccessState.transient) {
      // An outage never overwrites what blocks: it says nothing new.
      final current = await _repoAccess.issueFor(
        workspaceId,
        forge: ForgeHost.github,
        owner: owner,
        name: repo,
      );
      if (current != null && current.state.blocksAutomation) {
        return;
      }
    }
    await _repoAccess.record(
      workspaceId,
      forge: ForgeHost.github,
      owner: owner,
      name: repo,
      state: state,
      message: refusal.message,
      installUrl: await _installUrlFor(workspaceId, state, refusal),
    );
  }

  /// Records a successful one-repository mint. Any mint through the App
  /// proves the App side; only automation's own (bounded by the accountable
  /// person) proves the accountable person's side.
  Future<void> recordMinted(
    String workspaceId,
    String owner,
    String repo, {
    required bool automation,
  }) async {
    final current = await _repoAccess.issueFor(
      workspaceId,
      forge: ForgeHost.github,
      owner: owner,
      name: repo,
    );
    if (current == null) {
      return;
    }
    final personSide =
        current.state == RepoAccessState.ownerCannotSee ||
        current.state == RepoAccessState.ownerNotSignedIn;
    if (automation || !personSide) {
      await _repoAccess.recordReachable(
        workspaceId,
        forge: ForgeHost.github,
        owner: owner,
        name: repo,
      );
    }
  }

  /// The refusal an automation mint meets on a repository recorded as
  /// [state].
  static GitHubRefusal refusalFor(RepoAccessState state) => switch (state) {
    RepoAccessState.appNotInstalled => GitHubRefusal.notInstalled,
    RepoAccessState.repoNotSelected => GitHubRefusal.repoNotSelected,
    RepoAccessState.installationSuspended => GitHubRefusal.suspended,
    RepoAccessState.ownerNotSignedIn => GitHubRefusal.needsSignIn,
    RepoAccessState.ownerCannotSee => GitHubRefusal.accessDenied,
    // GitLab/Bitbucket only; never recorded for a GitHub repository.
    RepoAccessState.automationTokenMissing => GitHubRefusal.accessDenied,
    RepoAccessState.repoReplaced => GitHubRefusal.repoReplaced,
    RepoAccessState.transient => GitHubRefusal.providerUnavailable,
  };
}
