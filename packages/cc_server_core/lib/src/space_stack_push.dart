import 'dart:io';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_infra/cc_infra.dart' show PushedCommitInspector;

/// Runs `git` for a stack push. Same shape as `StackGit`.
typedef StackPushGit =
    Future<({int exitCode, String stdout, String stderr})> Function(
      String workingDirectory,
      List<String> args, {
      Map<String, String>? environment,
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

/// Pushes one stack layer from a space checkout, after inspecting every
/// commit the push sends.
///
/// The checkout is the agent's working tree: its config, hooks and refs are
/// the agent's to write. So nothing of it is trusted here. The push runs
/// from a scratch bare repository that borrows the checkout's objects
/// (`objects/info/alternates`) and nothing else: no `insteadOf`, `pushurl`,
/// `push.followTags` or hook of the checkout applies, and the destination is
/// the linked repository's own URL ([remoteUrl]), never the checkout's
/// `origin`. What the remote already has is read from the remote itself (a
/// fetch of its branches and tags into the scratch repository), never from
/// the checkout's remote-tracking refs, which the agent could point at a
/// forged commit to hide it. Every commit reachable from the layer's tip that
/// the remote does not have is then inspected before a byte is pushed. Only
/// a commit is pushed (a tip that is a tag object is refused), so no tag
/// object travels with it.
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

  static const String _remoteRefs = 'refs/cc-remote';

  /// Pushes [branch] of the checkout at [root] to [repo] as
  /// `refs/heads/<branch>`, authenticated by [auth]. With [force] the push
  /// replaces the remote branch only while it still is what the checkout
  /// last saw of it. Returns why it was refused or failed, or null.
  Future<String?> push({
    required String root,
    required Repo repo,
    required String branch,
    required bool force,
    required Map<String, String> auth,
    required StackPushRule rule,
  }) async {
    final commonDir = await git(root, [
      'rev-parse',
      '--path-format=absolute',
      '--git-common-dir',
    ]);
    final tip = await git(root, [
      'rev-parse',
      '--verify',
      '--quiet',
      '--end-of-options',
      'refs/heads/$branch',
    ]);
    final sha = tip.stdout.trim();
    if (commonDir.exitCode != 0 || tip.exitCode != 0 || sha.isEmpty) {
      return 'could not read $branch in the checkout';
    }
    final scratch = await Directory.systemTemp.createTemp('cc-stack-push-');
    try {
      final bare = '${scratch.path}/push.git';
      final init = await git(scratch.path, ['init', '--bare', '--quiet', bare]);
      if (init.exitCode != 0) {
        return _error(init);
      }
      await File(
        '$bare/objects/info/alternates',
      ).writeAsString('${commonDir.stdout.trim()}/objects\n');
      final type = await git(bare, ['cat-file', '-t', sha]);
      if (type.exitCode != 0 || type.stdout.trim() != 'commit') {
        return '$branch does not point at a commit';
      }
      final url = remoteUrl(repo);
      final fetched = await git(bare, [
        'fetch',
        '--quiet',
        '--no-tags',
        '--no-write-fetch-head',
        url,
        '+refs/heads/*:$_remoteRefs/heads/*',
        '+refs/tags/*:$_remoteRefs/tags/*',
      ], environment: auth);
      if (fetched.exitCode != 0) {
        return _error(fetched);
      }
      final listed = await git(bare, [
        'rev-list',
        sha,
        '--not',
        '--glob=$_remoteRefs/*',
      ]);
      if (listed.exitCode != 0) {
        return _error(listed);
      }
      final oids = [
        for (final line in listed.stdout.split('\n'))
          if (line.trim().isNotEmpty) line.trim(),
      ];
      final problem = await _inspect(bare, oids, rule);
      if (problem != null) {
        return 'Control Center did not push $branch: $problem';
      }
      String? lease;
      if (force) {
        final seen = await git(root, [
          'rev-parse',
          '--verify',
          '--quiet',
          '--end-of-options',
          'refs/remotes/origin/$branch',
        ]);
        lease = seen.exitCode == 0 ? seen.stdout.trim() : '';
      }
      final pushed = await git(bare, [
        'push',
        '--quiet',
        '--no-verify',
        if (lease != null) '--force-with-lease=refs/heads/$branch:$lease',
        url,
        '$sha:refs/heads/$branch',
      ], environment: auth);
      if (pushed.exitCode != 0) {
        return _error(pushed);
      }
    } finally {
      try {
        await scratch.delete(recursive: true);
      } on FileSystemException {
        // Best effort.
      }
    }
    // What `push -u origin` would have recorded in the checkout. Best
    // effort: a checkout without an `origin` remote simply has no upstream.
    await git(root, ['update-ref', 'refs/remotes/origin/$branch', sha]);
    await git(root, [
      'branch',
      '--set-upstream-to=origin/$branch',
      '--end-of-options',
      branch,
    ]);
    return null;
  }

  static Future<String?> _inspect(
    String bare,
    List<String> oids,
    StackPushRule rule,
  ) async {
    if (oids.isEmpty) {
      return null;
    }
    try {
      final objects = await PushedCommitInspector.inspectCommits(bare, oids);
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

  static String _error(({int exitCode, String stdout, String stderr}) r) {
    final err = r.stderr.trim();
    if (err.isNotEmpty) {
      return err;
    }
    final out = r.stdout.trim();
    return out.isNotEmpty ? out : 'git failed';
  }
}
