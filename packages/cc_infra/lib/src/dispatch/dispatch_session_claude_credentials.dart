part of 'dispatch_session.dart';

/// Which Claude Code account a run signs in as, and parking the run on the
/// credential gate until that account has a usable sign-in.
extension _ClaudeAccountCredentials on DispatchSession {
  /// Parks this run until this account's directory holds a credential again,
  /// and reports whether it does.
  ///
  /// False when no gate is wired, when the operator cancels, or when the wait
  /// times out — every one of which falls through to the failure the run had
  /// before the gate existed.
  Future<bool> _gateOnClaudeSignIn({required String detail}) async {
    final gate = deps.credentialGate;
    if (gate == null) {
      return false;
    }
    addEvent(
      DebugEvent(
        content:
            '[claude] waiting for a sign-in on $claudeConfigDir — '
            'the run continues as soon as one lands.',
      ),
    );
    final outcome = await gate.awaitCredentials(
      RunCredentialBlockRequest(
        lane: RunCredentialLane.claudeCode,
        reason: RunCredentialReason.signedOut,
        detail: detail,
        runLogId: runLogId,
        accountIds: [for (final a in claudeAccounts) a.accountId],
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        agentId: agentId,
        agentName: agentName,
      ),
      // The credential lands as a FILE in the account directory — written
      // directly by the CLI off macOS or by an in-sandbox refresh, and mirrored
      // there from the Keychain otherwise. The mirror has to be re-run for the
      // Keychain case; without it the probe would watch a file that a
      // successful `claude auth login` never touches.
      recheck: () async {
        final sync = deps.syncClaudeCredential;
        final accountId = claudeAccounts.firstOrNull?.accountId;
        if (sync != null && accountId != null) {
          await sync(accountId);
        }
        return _claudeAccountHasCredential();
      },
    );
    return outcome == RunCredentialOutcome.resolved;
  }

  /// Parks this run until a Claude Code account that just 401'd has a newer
  /// credential, and reports whether one landed.
  ///
  /// Distinct from [_gateOnClaudeSignIn]: that one fires before spawn, when
  /// the directory is empty. This one fires after `claude -p` has already
  /// proved the credential on disk no longer authenticates — an access token
  /// the CLI could not renew, which still looks signed-in to the pre-spawn
  /// probe. The same prompt is re-run when a human signs in; cancelling or
  /// timing out falls through to the error the turn already has.
  ///
  /// False when no gate is wired, when the operator cancels, when the wait
  /// times out, or when the gate says "resolved" without the credential file
  /// actually changing — that last one is what stops a poll from relaunching
  /// `claude` against the same dead token.
  ///
  /// [midTurn] names the one account a turn that already did work was running
  /// on. Only that account can continue it — its session lives in that
  /// directory — so only its login is asked for and only its credential counts
  /// as renewed.
  Future<bool> _gateOnExpiredClaudeSignIn({
    required String detail,
    ({String accountId, String configDir})? midTurn,
  }) async {
    final gate = deps.credentialGate;
    if (gate == null) {
      return false;
    }
    addEvent(
      DebugEvent(
        content: midTurn != null
            ? '[claude] waiting for a fresh sign-in — '
                  'the turn continues where it stopped as soon as one lands.'
            : '[claude] waiting for a fresh sign-in — '
                  'the same prompt continues as soon as one lands.',
      ),
    );
    final all = _claudeCredentialBlobs();
    final before = midTurn == null
        ? all
        : {
            for (final e in all.entries)
              if (e.key == midTurn.configDir) e.key: e.value,
          };
    final outcome = await gate.awaitCredentials(
      RunCredentialBlockRequest(
        lane: RunCredentialLane.claudeCode,
        reason: RunCredentialReason.credentialExpired,
        detail: detail,
        runLogId: runLogId,
        accountIds: midTurn != null
            ? [if (midTurn.accountId.isNotEmpty) midTurn.accountId]
            : [
                for (final a in claudeAccounts)
                  if (a.accountId.isNotEmpty) a.accountId,
              ],
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        agentId: agentId,
        agentName: agentName,
      ),
      // Re-mirror first. On macOS the login lands in the Keychain and the
      // file the sandbox can read is only a copy; without the sync the probe
      // watches a file `claude auth login` never touches.
      recheck: () => _claudeCredentialsRenewed(before),
    );
    if (outcome != RunCredentialOutcome.resolved) {
      return false;
    }
    return _claudeCredentialsRenewed(before);
  }

  /// `.credentials.json` contents for every account dir this run can see.
  ///
  /// A missing file is stored as null so a login that creates one counts as
  /// a change, and a sign-out that deletes one does not have to.
  Map<String, String?> _claudeCredentialBlobs() {
    final dirs = <String>{
      if (claudeConfigDir != null && claudeConfigDir!.isNotEmpty)
        claudeConfigDir!,
      for (final a in claudeAccounts)
        if (a.configDir.isNotEmpty) a.configDir,
    };
    return {for (final dir in dirs) dir: _readClaudeCredential(dir)};
  }

  /// Whether any account dir in [before] now holds a different credential.
  ///
  /// Content, not mtime: a failed refresh and the Keychain mirror can both
  /// rewrite the file without a human signing in, and a 1-second filesystem
  /// timestamp cannot tell that apart from a real login. A new sign-in
  /// replaces the blob.
  Future<bool> _claudeCredentialsRenewed(Map<String, String?> before) async {
    final sync = deps.syncClaudeCredential;
    if (sync != null) {
      for (final account in claudeAccounts) {
        if (account.accountId.isEmpty) {
          continue;
        }
        await sync(account.accountId);
      }
    }
    final now = _claudeCredentialBlobs();
    for (final dir in before.keys) {
      final current = now[dir];
      if (current != null && current.isNotEmpty && current != before[dir]) {
        return true;
      }
    }
    return false;
  }

  String? _readClaudeCredential(String dir) {
    try {
      final file = File('$dir/.credentials.json');
      if (!file.existsSync()) {
        return null;
      }
      return file.readAsStringSync();
    } on Object {
      return null;
    }
  }

  /// Whether the Claude Code account this run will use has something to
  /// authenticate with.
  ///
  /// Only answerable when Control Center owns the config dir; with none set the
  /// CLI resolves its own credential (a keychain item, `~/.claude`) and this
  /// returns true rather than guessing. A token in the environment counts:
  /// `CLAUDE_CODE_OAUTH_TOKEN` and `ANTHROPIC_API_KEY` both authenticate the
  /// CLI without any file in the config dir, so treating an empty dir as
  /// signed-out would refuse a run that would have worked.
  bool _claudeAccountHasCredential() {
    final dir = claudeConfigDir;
    if (dir == null || dir.isEmpty) {
      return true;
    }
    for (final key in const ['CLAUDE_CODE_OAUTH_TOKEN', 'ANTHROPIC_API_KEY']) {
      final fromCaller = callerEnv[key] ?? adapterEnvOverride[key];
      if (fromCaller != null && fromCaller.isNotEmpty) {
        return true;
      }
      final fromHost = Platform.environment[key];
      if (fromHost != null && fromHost.isNotEmpty) {
        return true;
      }
    }
    return File('$dir/.credentials.json').existsSync();
  }

  /// [base] re-pointed at ONE account of a multi-account run.
  Map<String, String> _envForClaudeAccount(
    Map<String, String> base,
    String configDir,
  ) {
    if (configDir.isEmpty) {
      return base;
    }
    return {...base, 'CLAUDE_CONFIG_DIR': configDir};
  }
}
