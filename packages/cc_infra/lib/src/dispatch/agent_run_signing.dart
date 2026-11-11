part of 'agent_run_gateway.dart';

/// How a run's commits are signed: the names, the program a sandboxed git
/// signs with, and the git configuration that points at it.
///
/// The signing key never enters a sandbox. Git hands [shim] the commit
/// object; the shim posts it to the gateway ([path]), which signs it only
/// when it is the run's own commit, made now.
// A namespace over constants and one pure function.
// ignore: avoid_classes_with_only_static_members
abstract final class AgentRunSigning {
  /// Path a run posts a commit object to for the server to sign.
  static const String path = '/agent/git-sign';

  /// File name of [shim] in a run's shim directory.
  static const String shimName = 'cc-git-sign';

  /// Cap on a commit object posted for signing.
  static const int maxObjectBytes = 1024 * 1024;

  /// How far a commit's committer date may be from the server's clock, and
  /// its author date ahead of it, for the commit to be signed.
  static const Duration clockSkew = Duration(minutes: 5);

  /// How many commits one run may ask to have signed. Far above what a long
  /// rebase needs; it bounds what a run that was talked into misusing the
  /// route can collect.
  static const int maxSignaturesPerRun = 1000;

  /// How long the route waits for a person to answer an "ask" before it
  /// refuses. Shorter than the signer's own 60-second limit ([shim]), so the
  /// approval comes down before git gives up.
  static const Duration decisionDeadline = Duration(seconds: 50);

  /// The `gpg.ssh.program` of a run whose commits are signed.
  ///
  /// Git calls it with the commit object as its last argument (a file); the
  /// agent run [client] posts the object to the gateway, which checks it
  /// against the run's identity and answers with the signature git expects
  /// beside it (`<file>.sig`). It holds no secret: the run's token comes from
  /// the environment, and the gateway decides. Only `-Y sign` is served; a
  /// verification call fails.
  static String shim(AgentRunClientLauncher client) =>
      '''
#!/bin/sh
# Control Center: git's SSH signer for this agent run. The signing key stays
# on the server: the commit object goes to the agent run gateway, which signs
# it only if it is this run's own commit.
exec ${client.shellCommand} git-sign "\$@"
''';

  /// `git -c` pairs that sign every commit with [signingKey] through
  /// [signProgram], and nothing else: tags and pushes stay unsigned and no
  /// other signer is reachable. With neither, the run signs nothing
  /// ([AgentRunLease.unsignedGitConfig]).
  static List<(String, String)> gitConfig(
    String? signingKey,
    String? signProgram,
  ) {
    if (signingKey == null || signProgram == null) {
      return AgentRunLease.unsignedGitConfig;
    }
    return [
      ('gpg.format', 'ssh'),
      ('gpg.ssh.program', signProgram),
      ('user.signingkey', 'key::$signingKey'),
      ('commit.gpgsign', 'true'),
      ('tag.gpgsign', 'false'),
      ('push.gpgsign', 'false'),
      ('gpg.program', 'false'),
      ('gpg.x509.program', 'false'),
    ];
  }
}

/// The gateway's commit signing route.
extension _CommitSigning on AgentRunGateway {
  /// Signs a commit object with the signing key of the person the run acts
  /// for.
  ///
  /// Refused unless every check passes, before the key is touched:
  ///
  /// * the run signs at all (a person asked for it and has a key);
  /// * the body is a well-formed, unsigned commit;
  /// * it is the run's own commit, by the rule a push is held to
  ///   ([PushedCommitInspector.objectViolation]);
  /// * it is being made now: its committer date is the server's time within
  ///   [AgentRunSigning.clockSkew] and its author date is not in the future,
  ///   so nothing is signed into the past or the future;
  /// * the run asked for fewer than [AgentRunSigning.maxSignaturesPerRun];
  /// * the person's key is still the one the run started with;
  /// * the "Create a commit" rule allows it. An "ask" rule is answered by
  ///   the operator's yes to the committing shell command when there was one
  ///   ([AgentRunGateway.shellPushApprovalWindow]); otherwise the operator
  ///   is asked here, because a commit object built with plumbing, or posted
  ///   to this route directly, never passed the shell gate.
  ///
  /// What a signature says is therefore "a run this person started made this
  /// commit, as them, at this time". It does not bind the commit to the
  /// run's repository or history: the tree and parents are whatever the run
  /// wrote. Policy decisions are guard-decision records; identity, date,
  /// count and key refusals are logged.
  Future<void> _sign(
    HttpRequest request,
    AgentRunGrant grant,
    String secret,
  ) async {
    // Read to the end even when it is too large: git's signer is still
    // writing, and a reply sent mid-upload reaches it as a reset connection
    // instead of the reason.
    final payload = await _readDraining(
      request,
      AgentRunSigning.maxObjectBytes,
    );
    if (payload == null) {
      return AgentRunGateway._plain(
        request,
        HttpStatus.requestEntityTooLarge,
        'Control Center: this object is too large to sign.',
      );
    }
    final identity = grant.identity;
    final key = identity?.signingKey;
    final signing = _signing;
    final user = grant.actingUserId;
    if (identity == null ||
        key == null ||
        signing == null ||
        user == null ||
        user.isEmpty) {
      return AgentRunGateway._plain(
        request,
        HttpStatus.forbidden,
        'Control Center: this run does not sign its commits.',
      );
    }
    final PushedGitObject object;
    try {
      if (!_startsWith(payload, 'tree ')) {
        throw const FormatException('not a commit');
      }
      object = PushedCommitInspector.parse(
        'commit',
        '(new)',
        utf8.decode(payload, allowMalformed: true),
      );
    } on FormatException {
      return AgentRunGateway._plain(
        request,
        HttpStatus.badRequest,
        'Control Center signs only well-formed git commits.',
      );
    }
    if (object.signed) {
      return AgentRunGateway._plain(
        request,
        HttpStatus.badRequest,
        'Control Center: this commit is already signed.',
      );
    }
    Future<void> refuse(int status, String problem) {
      CcInfraLog.warning(
        'agent gateway: refused to sign a commit for run ${grant.runId} '
        '(workspace ${grant.workspaceId}, user $user): $problem',
      );
      return AgentRunGateway._plain(
        request,
        status,
        'Control Center: $problem',
      );
    }

    final problem = PushedCommitInspector.objectViolation(
      object,
      identity.unsigned,
    );
    if (problem != null) {
      return refuse(HttpStatus.forbidden, problem);
    }
    final now = _now().millisecondsSinceEpoch ~/ 1000;
    final skew = AgentRunSigning.clockSkew.inSeconds;
    if ((object.committerTime! - now).abs() > skew ||
        object.authorTime! > now + skew) {
      return refuse(
        HttpStatus.forbidden,
        'a commit is signed only as it is made: its committer date must be '
        'the current time and its author date must not be in the future. '
        'Commit without setting GIT_COMMITTER_DATE.',
      );
    }
    final asked = (_signatures[secret] ?? 0) + 1;
    if (asked > AgentRunSigning.maxSignaturesPerRun) {
      return refuse(
        HttpStatus.tooManyRequests,
        'this run already asked for '
        '${AgentRunSigning.maxSignaturesPerRun} signatures, the most one '
        'run may. Start a new run to sign more.',
      );
    }
    _signatures[secret] = asked;
    const keyChanged =
        'the signing key of the person who asked for this run changed since '
        'it started. Start a new run to sign with it.';
    if (await signing.publicKeyOf(user) != key) {
      return refuse(HttpStatus.conflict, keyChanged);
    }
    final verdict = await _commitVerdict(grant, secret);
    if (!verdict.allowed) {
      return AgentRunGateway._plain(
        request,
        HttpStatus.forbidden,
        'Control Center policy: ${verdict.reason ?? 'denied'}',
      );
    }
    try {
      final signature = await signing.sign(user, key, payload);
      return await AgentRunGateway._plain(
        request,
        HttpStatus.ok,
        signature.trimRight(),
      );
    } on CommitSigningUnavailable {
      // The key went between the check above and the signature.
      return refuse(HttpStatus.conflict, keyChanged);
    }
  }

  /// The policy's answer to signing one commit for [grant]'s run.
  Future<GuardVerdict> _commitVerdict(
    AgentRunGrant grant,
    String secret,
  ) async {
    const classes = {ActionClass.gitCommit};
    const summary = 'sign git commit';
    final approvedUntil = _shellCommitApprovals[secret];
    if (approvedUntil != null && _now().isBefore(approvedUntil)) {
      final resolution = await _guard.resolve(
        workspaceId: grant.workspaceId,
        classes: classes,
        spaceId: grant.spaceId,
        agentId: grant.agentId,
        mode: grant.mode,
      );
      // Only an ask is answered by the shell prompt: a deny still denies.
      if (resolution.decision == ActionDecision.prompt) {
        _guard.recordOutcome(
          workspaceId: grant.workspaceId,
          resolution: resolution,
          applied: ActionDecision.allow,
          classes: classes,
          agentId: grant.agentId,
          spaceId: grant.spaceId,
          actionSummary: '$summary (approved at the shell prompt)',
          prompted: true,
          onBehalfOfUserId: grant.actingUserId,
          runId: grant.runId,
        );
        return const GuardVerdict.allow(prompted: true);
      }
    }
    return _askWithDeadline(
      secret,
      (withdrawn) async => _guard.check(
        workspaceId: grant.workspaceId,
        classes: classes,
        spaceId: grant.spaceId,
        conversationId: grant.conversationId,
        agentId: grant.agentId,
        mode: grant.mode,
        actionSummary: summary,
        onBehalfOfUserId: grant.actingUserId,
        runId: grant.runId,
        request: const ActionRequest(classes: classes),
        autonomy: await AgentRunGateway._autonomyOf(grant),
        withdrawn: withdrawn,
      ),
      deadline: AgentRunSigning.decisionDeadline,
    );
  }

  /// The whole request body, or null when it is larger than [max]. The body
  /// is consumed either way; nothing past [max] is kept.
  Future<List<int>?> _readDraining(HttpRequest request, int max) async {
    final out = BytesBuilder(copy: false);
    var tooLarge = false;
    await for (final chunk in request) {
      if (tooLarge) {
        continue;
      }
      if (out.length + chunk.length > max) {
        tooLarge = true;
        out.clear();
        continue;
      }
      out.add(chunk);
    }
    return tooLarge ? null : out.takeBytes();
  }

  bool _startsWith(List<int> bytes, String prefix) {
    final wanted = ascii.encode(prefix);
    if (bytes.length < wanted.length) {
      return false;
    }
    for (var i = 0; i < wanted.length; i++) {
      if (bytes[i] != wanted[i]) {
        return false;
      }
    }
    return true;
  }
}
