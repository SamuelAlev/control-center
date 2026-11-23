import 'dart:io';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_infra/cc_infra.dart' show PushedCommitInspector;

/// Runs `git` for a stack push, with [stdin] as its input when given. Same
/// shape as `StackGit`.
typedef StackPushGit =
    Future<({int exitCode, String stdout, String stderr})> Function(
      String workingDirectory,
      List<String> args, {
      Map<String, String>? environment,
      String? stdin,
    });

/// What the commits a stack push sends are held to.
sealed class StackPushRule {
  const StackPushRule();
}

/// An agent run publishes: every commit sent must keep one of [identities]'
/// rules, exactly as the push gateway holds the run's own pushes
/// ([PushedCommitInspector.violationOfAny]).
final class AgentRunStackPush extends StackPushRule {
  /// Creates the rule.
  const AgentRunStackPush(this.identities);

  /// The identities of the runs that publish (one requester).
  final List<AgentCommitIdentity> identities;
}

/// A person publishes. Their own commits are theirs, pushed under their own
/// sign-in as from their own clone; a commit authored as one of [agents] is
/// agent work and must be a well-formed agent commit
/// ([PushedCommitInspector.agentObjectViolation]).
final class PersonStackPush extends StackPushRule {
  /// Creates the rule.
  const PersonStackPush(this.agents);

  /// Every identity that is "the agent" in the workspace.
  final List<GitPerson> agents;
}

/// Pushes the layers of one repository's stack from a space checkout, after
/// inspecting every commit each push sends.
///
/// The checkout is the agent's working tree: its config, hooks and refs are
/// the agent's to write. So nothing of it is trusted here. The pushes run
/// from a scratch bare repository that borrows the checkout's objects
/// (`objects/info/alternates`) and nothing else: no `insteadOf`, `pushurl`,
/// `push.followTags` or hook of the checkout applies, and the destination is
/// the linked repository's own URL ([remoteUrl]), never the checkout's
/// `origin`. What the remote already has is read from the remote itself (a
/// fetch of its branches and tags into `refs/cc-remote/*` of the scratch
/// repository), never from the checkout's remote-tracking refs, which the
/// agent could point at a forged commit to hide it. Every commit reachable
/// from a layer's tip that the remote does not have is then inspected before
/// a byte is pushed. Only a commit is pushed (a tip that is a tag object is
/// refused), so no tag object travels with it.
///
/// [open] fetches the remote's state once for every layer of the publish
/// ([StackPushSession]). The fetch tells the remote which commits are already
/// here, so it sends only what the checkout lacks: the checkout's branch and
/// remote-tracking tips are copied into the scratch repository as
/// `refs/cc-have/*`, which only steer that negotiation. Server-run git never
/// lists an alternate's refs itself (`core.alternateRefsCommand` is empty in
/// `IsolatedGit`), and without them a fetch into an empty repository
/// downloads the remote's entire history. A forged tip there can only make
/// the remote leave out objects that are already here; what counts as
/// published is still only what the remote advertised.
final class StackLayerPusher {
  /// Creates the pusher.
  StackLayerPusher({required this.git, String Function(Repo repo)? remoteUrl})
    : remoteUrl = remoteUrl ?? defaultRemoteUrl;

  /// Runs git.
  final StackPushGit git;

  /// Where [Repo]'s layers are pushed and its remote state read.
  final String Function(Repo repo) remoteUrl;

  /// `https://<git host>/<owner>/<name>.git`.
  static String defaultRemoteUrl(Repo repo) =>
      'https://${repo.forge.gitHost}/${repo.remoteOwner}/${repo.remoteName}.git';

  /// A network command that moves less than [stallBytesPerSecond] for
  /// [stallSeconds] is given up on (`GIT_HTTP_LOW_SPEED_*`). A slow transfer
  /// that keeps moving is never cut off; a remote's keep-alives count as
  /// moving.
  static const int stallBytesPerSecond = 1;

  /// See [stallBytesPerSecond].
  static const int stallSeconds = 120;

  /// Prepares the pushes of the checkout at [root] to [repo], authenticated
  /// by [auth], and reads what the remote already has. Returns the session,
  /// or why it could not be prepared. The caller closes the session.
  Future<({StackPushSession? session, String? error})> open({
    required String root,
    required Repo repo,
    required Map<String, String> auth,
  }) async {
    final commonDir = await git(root, [
      'rev-parse',
      '--path-format=absolute',
      '--git-common-dir',
    ]);
    if (commonDir.exitCode != 0 || commonDir.stdout.trim().isEmpty) {
      return (session: null, error: 'could not read the checkout');
    }
    final network = {
      ...auth,
      'GIT_HTTP_LOW_SPEED_LIMIT': '$stallBytesPerSecond',
      'GIT_HTTP_LOW_SPEED_TIME': '$stallSeconds',
    };
    final scratch = await Directory.systemTemp.createTemp('cc-stack-push-');
    final session = StackPushSession._(
      git,
      root,
      scratch,
      remoteUrl(repo),
      network,
    );
    final bare = session._bare;
    final init = await git(scratch.path, ['init', '--bare', '--quiet', bare]);
    if (init.exitCode != 0) {
      await session.close();
      return (session: null, error: _error(init));
    }
    await File(
      '$bare/objects/info/alternates',
    ).writeAsString('${commonDir.stdout.trim()}/objects\n');
    await session._seedHaves();
    final fetched = await git(bare, [
      'fetch',
      '--quiet',
      '--no-tags',
      '--no-write-fetch-head',
      session.url,
      '+refs/heads/*:$_remoteRefs/heads/*',
      '+refs/tags/*:$_remoteRefs/tags/*',
    ], environment: network);
    if (fetched.exitCode != 0) {
      await session.close();
      return (session: null, error: _error(fetched));
    }
    return (session: session, error: null);
  }

  static const String _remoteRefs = 'refs/cc-remote';
  static const String _haveRefs = 'refs/cc-have';

  static String _error(({int exitCode, String stdout, String stderr}) r) {
    // Every fetch into the scratch repository also tries the empty
    // `core.alternateRefsCommand`; that line says nothing about the failure.
    final err = r.stderr
        .split('\n')
        .where((line) => !line.startsWith('error: cannot run : '))
        .join('\n')
        .trim();
    if (err.isNotEmpty) {
      return err;
    }
    final out = r.stdout.trim();
    return out.isNotEmpty ? out : 'git failed';
  }
}

/// One publish's pushes to one repository: a scratch bare repository holding
/// what the remote had when the session opened, plus every layer pushed
/// since ([StackLayerPusher]).
final class StackPushSession {
  StackPushSession._(
    this._git,
    this._root,
    this._scratch,
    this.url,
    this._network,
  );

  final StackPushGit _git;
  final String _root;
  final Directory _scratch;
  final Map<String, String> _network;

  /// Where the layers are pushed.
  final String url;

  String get _bare => '${_scratch.path}/push.git';

  /// Copies the checkout's branch and remote-tracking tips into
  /// `refs/cc-have/*` so the fetch can name them as already here. Best
  /// effort: without them the fetch is only slower. A tip whose object is
  /// missing is left out (`update-ref` would refuse the whole batch).
  Future<void> _seedHaves() async {
    final listed = await _git(_root, [
      'for-each-ref',
      '--format=%(objectname)',
      'refs/heads',
      'refs/remotes',
    ]);
    if (listed.exitCode != 0) {
      return;
    }
    final tips = {
      for (final line in listed.stdout.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    };
    if (tips.isEmpty) {
      return;
    }
    final checked = await _git(_bare, [
      'cat-file',
      '--batch-check=%(objectname) %(objecttype)',
    ], stdin: '${tips.join('\n')}\n');
    if (checked.exitCode != 0) {
      return;
    }
    final present = [
      for (final line in checked.stdout.split('\n'))
        if (line.split(' ') case [
          final oid,
          final type,
        ] when type == 'commit' || type == 'tag')
          oid,
    ];
    if (present.isEmpty) {
      return;
    }
    final commands = StringBuffer();
    for (var i = 0; i < present.length; i++) {
      commands.writeln('create ${StackLayerPusher._haveRefs}/$i ${present[i]}');
    }
    await _git(_bare, ['update-ref', '--stdin'], stdin: '$commands');
  }

  /// Pushes [branch] of the checkout to the remote as `refs/heads/<branch>`.
  /// With [force] the push replaces the remote branch only while it still is
  /// what the checkout last saw of it. Returns why it was refused or failed,
  /// or null.
  Future<String?> push({
    required String branch,
    required bool force,
    required StackPushRule rule,
  }) async {
    final tip = await _git(_root, [
      'rev-parse',
      '--verify',
      '--quiet',
      '--end-of-options',
      'refs/heads/$branch',
    ]);
    final sha = tip.stdout.trim();
    if (tip.exitCode != 0 || sha.isEmpty) {
      return 'could not read $branch in the checkout';
    }
    final type = await _git(_bare, ['cat-file', '-t', sha]);
    if (type.exitCode != 0 || type.stdout.trim() != 'commit') {
      return '$branch does not point at a commit';
    }
    final listed = await _git(_bare, [
      'rev-list',
      sha,
      '--not',
      '--glob=${StackLayerPusher._remoteRefs}/*',
    ]);
    if (listed.exitCode != 0) {
      return StackLayerPusher._error(listed);
    }
    final oids = [
      for (final line in listed.stdout.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
    final problem = await _inspect(oids, rule);
    if (problem != null) {
      return 'Control Center did not push $branch: $problem';
    }
    String? lease;
    if (force) {
      final seen = await _git(_root, [
        'rev-parse',
        '--verify',
        '--quiet',
        '--end-of-options',
        'refs/remotes/origin/$branch',
      ]);
      lease = seen.exitCode == 0 ? seen.stdout.trim() : '';
    }
    final pushed = await _git(_bare, [
      'push',
      '--quiet',
      '--no-verify',
      if (lease != null) '--force-with-lease=refs/heads/$branch:$lease',
      url,
      '$sha:refs/heads/$branch',
    ], environment: _network);
    if (pushed.exitCode != 0) {
      return StackLayerPusher._error(pushed);
    }
    // The remote has it now: a later layer of this publish does not inspect
    // these commits again.
    await _git(_bare, [
      'update-ref',
      '${StackLayerPusher._remoteRefs}/heads/$branch',
      sha,
    ]);
    // What `push -u origin` would have recorded in the checkout. Best
    // effort: a checkout without an `origin` remote simply has no upstream.
    await _git(_root, ['update-ref', 'refs/remotes/origin/$branch', sha]);
    await _git(_root, [
      'branch',
      '--set-upstream-to=origin/$branch',
      '--end-of-options',
      branch,
    ]);
    return null;
  }

  /// Deletes the scratch repository.
  Future<void> close() async {
    try {
      await _scratch.delete(recursive: true);
    } on FileSystemException {
      // Best effort.
    }
  }

  Future<String?> _inspect(List<String> oids, StackPushRule rule) async {
    if (oids.isEmpty) {
      return null;
    }
    try {
      final objects = await PushedCommitInspector.inspectCommits(_bare, oids);
      return switch (rule) {
        AgentRunStackPush(:final identities) =>
          PushedCommitInspector.violationOfAny(objects, identities),
        PersonStackPush(:final agents) =>
          PushedCommitInspector.agentObjectViolation(objects, agents),
      };
    } on FormatException catch (e) {
      return 'its commits could not be inspected (${e.message}).';
    }
  }
}
