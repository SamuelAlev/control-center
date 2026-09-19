part of '../cc_server_runtime.dart';

/// A late-bound holder for services constructed after the RPC catalog (the
/// catalog's deferred closures read [value] per request).
class _Late<T> {
  /// The held value, once constructed.
  T? value;
}

/// Detects the capabilities of the server host for the implicit local worker
/// (PRD 20 §1). Deliberately lightweight (no subprocess probing) so startup
/// stays fast; a Flutter/ML-capable machine that wants those axes joins the
/// fleet as a dedicated `cc_worker` declaring them.
WorkerCapabilities _detectLocalWorkerCapabilities() {
  final String os;
  if (Platform.isMacOS) {
    os = 'macos';
  } else if (Platform.isLinux) {
    os = 'linux';
  } else if (Platform.isWindows) {
    os = 'windows';
  } else {
    os = 'unknown';
  }
  final version = Platform.version.toLowerCase();
  final arch = version.contains('arm64') || version.contains('aarch64')
      ? 'arm64'
      : 'x64';
  final sandboxBackends = <String>{
    if (Platform.isMacOS) 'native-macos',
    if (Platform.isLinux) 'native-linux',
  };
  return WorkerCapabilities(
    os: os,
    arch: arch,
    cores: Platform.numberOfProcessors,
    ramMb: 0,
    sandboxBackends: sandboxBackends,
    alwaysOn: true,
    acceptsParallel: true,
  );
}

/// Splits a stored per-adapter argv string into arguments.
///
/// Whitespace-separated, honouring single and double quotes so a flag carrying
/// a spaced value survives. Deliberately NOT a shell parse: these arguments are
/// appended to an argv list and executed directly, never through a shell, so
/// interpreting metacharacters here would invent an injection surface that the
/// exec path does not otherwise have.
List<String> _splitAdapterArgs(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const [];
  }
  final out = <String>[];
  final buffer = StringBuffer();
  String? quote;
  for (final rune in raw.trim().runes) {
    final ch = String.fromCharCode(rune);
    if (quote != null) {
      if (ch == quote) {
        quote = null;
      } else {
        buffer.write(ch);
      }
      continue;
    }
    if (ch == '"' || ch == "'") {
      quote = ch;
      continue;
    }
    if (ch.trim().isEmpty) {
      if (buffer.isNotEmpty) {
        out.add(buffer.toString());
        buffer.clear();
      }
      continue;
    }
    buffer.write(ch);
  }
  if (buffer.isNotEmpty) {
    out.add(buffer.toString());
  }
  return out;
}

/// Decodes a stored per-adapter env override map.
///
/// A malformed blob yields an EMPTY map rather than throwing: a corrupt
/// settings row must not take agent dispatch down, and launching without an
/// override is the safe direction.
Map<String, String> _decodeAdapterEnv(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const {};
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return {
        for (final entry in decoded.entries)
          if (entry.value is String) '${entry.key}': entry.value as String,
      };
    }
  } on FormatException {
    // Fall through to the empty map.
  }
  return const {};
}

/// Workspace-settings key holding a Claude Code account pool.
///
/// One key per scope: the workspace's own, and one per agent that overrides it.
/// Namespaced so it cannot collide with a real setting, and absent until the
/// operator attaches something — which is what keeps an install that never
/// opens the screen on the pre-pool path.
String claudeAccountPoolKey(String? agentId) =>
    agentId == null || agentId.isEmpty
    ? 'claude_accounts.pool'
    : 'claude_accounts.pool.agent.$agentId';

/// Workspace-settings key holding a pool's round-robin position.
String claudeAccountCursorKey(String? agentId) =>
    '${claudeAccountPoolKey(agentId)}.cursor';

/// Reads the most specific pool that applies: the agent's, else the
/// workspace's, else unconfigured.
///
/// An agent pool with no accounts in it is treated as "not set" rather than as
/// "attach nothing" — an empty list is what an editor leaves behind when the
/// operator removes the last row, and reading that as a deliberate opt-out
/// would silently stop every run for that agent.
Future<AccountPool> _readClaudeAccountPool(
  WorkspaceSettingsRepository settings,
  String workspaceId,
  String? agentId,
) async {
  for (final key in [
    if (agentId != null && agentId.isNotEmpty) claudeAccountPoolKey(agentId),
    claudeAccountPoolKey(null),
  ]) {
    final raw = await settings.get(workspaceId, key);
    if (raw == null || raw.isEmpty) {
      continue;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final pool = AccountPool.fromJson(decoded);
        if (!pool.isEmpty) {
          return pool;
        }
      }
    } on Object {
      // A corrupt pool falls through to the next scope rather than stopping
      // the dispatch.
    }
  }
  return const AccountPool();
}

/// The lane an account pool belongs to.
///
/// One string so a single pair of RPC ops serves both, because the editing
/// surface is identical: an ordered list plus a strategy. `claude-code` names
/// the CLI adapter's account directories; `harness:<providerId>` names one
/// harness provider's stored credentials.
const String claudeAccountLane = 'claude-code';

/// The workspace-settings key a [lane] + [agentId] pool is stored under, or
/// null when the lane is not one we recognize.
///
/// Rejecting an unknown lane rather than deriving a key from it is what stops a
/// client writing arbitrary settings keys through this op.
String? accountPoolKeyForLane(String lane, String? agentId) {
  if (lane == claudeAccountLane) {
    return claudeAccountPoolKey(agentId);
  }
  const prefix = 'harness:';
  if (lane.startsWith(prefix) && lane.length > prefix.length) {
    return harnessPoolKey(lane.substring(prefix.length), agentId);
  }
  return null;
}

/// Workspace-settings key holding a harness provider's account pool.
///
/// Per provider, because "which keys may this workspace spend" is a different
/// question for OpenAI than for Kimi — and per agent on top of that, so a
/// research agent can be pinned to the cheap key while the rest of the
/// workspace rotates.
String harnessPoolKey(String providerId, String? agentId) =>
    agentId == null || agentId.isEmpty
    ? 'harness_accounts.pool.$providerId'
    : 'harness_accounts.pool.$providerId.agent.$agentId';

/// Workspace-settings key holding a harness pool's round-robin position.
String harnessCursorKey(String providerId, String? agentId) =>
    '${harnessPoolKey(providerId, agentId)}.cursor';

/// Orders [credentialIds] for one dispatch, applying the workspace's (or the
/// agent's) pool, its strategy, and any cooling-off keys.
///
/// Returns null when nothing is configured, so the caller keeps the store's own
/// order — the behaviour every install had before pools existed. The
/// round-robin cursor is advanced and persisted here, BEFORE the run, so two
/// dispatches racing still lead with different credentials.
Future<List<String>?> resolveHarnessRotationOrder({
  required WorkspaceSettingsRepository settings,
  required CredentialCooldownStore cooldowns,
  required String? workspaceId,
  required String? agentId,
  required String providerId,
  required List<String> credentialIds,
}) async {
  if (workspaceId == null || credentialIds.length < 2) {
    return null;
  }
  AccountPool pool = const AccountPool();
  String? usedKey;
  for (final key in [
    if (agentId != null && agentId.isNotEmpty)
      harnessPoolKey(providerId, agentId),
    harnessPoolKey(providerId, null),
  ]) {
    final raw = await settings.get(workspaceId, key);
    if (raw == null || raw.isEmpty) {
      continue;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final candidate = AccountPool.fromJson(decoded);
        if (!candidate.isEmpty) {
          pool = candidate;
          usedKey = key;
          break;
        }
      }
    } on Object {
      // A corrupt pool falls through to the next scope rather than stopping
      // the dispatch.
    }
  }
  if (pool.isEmpty || usedKey == null) {
    return null;
  }

  final cooling = await cooldowns.activeFor(providerId);
  final availability = {
    for (final id in credentialIds)
      id: AccountAvailability(
        id: id,
        signedIn: true,
        spent: cooling.containsKey(id),
        availableAt: cooling[id],
      ),
  };
  final cursorKey = harnessCursorKey(
    providerId,
    usedKey.contains('.agent.') ? agentId : null,
  );
  final cursor =
      int.tryParse(await settings.get(workspaceId, cursorKey) ?? '') ?? 0;
  final choice = AccountSelector.select(
    pool: pool,
    availability: availability,
    cursor: cursor,
  );

  switch (choice) {
    case AccountPoolUnset():
      // Every id in the pool names a credential that no longer exists.
      return null;
    case AccountsAllSpent():
      // Unlike the Claude lane there is no refusal here, and that asymmetry is
      // deliberate: `FallbackProvider` retries a capacity error on the SAME
      // target after backoff, so handing it the pool anyway lets a window that
      // reopens mid-turn still serve the run. Refusing would be strictly worse.
      return [
        for (final id in pool.accountIds)
          if (availability.containsKey(id)) id,
      ];
    case AccountChosen(:final accountId, cursor: final next):
      if (next != cursor) {
        await settings.set(workspaceId, cursorKey, '$next');
      }
      return [
        accountId,
        for (final id in pool.accountIds)
          if (id != accountId && availability.containsKey(id)) id,
      ];
  }
}

/// Claude Code accounts as the shared [SubscriptionUsageAccount] list.
///
/// Zero or one managed login keeps the default `~/.claude` / keychain probe
/// (the service emits that itself when no Claude accounts are supplied). Two
/// or more expand into one account each, with signed-out / expired logins
/// carrying [SubscriptionUsageAccount.knownStatus] so the ten-minute poll
/// does not spend a 401 re-learning what the credential already says.
Future<List<SubscriptionUsageAccount>> _claudeUsageAccounts({
  required ClaudeAccountStore store,
}) async {
  final accounts = await store.listWithStatus();
  if (accounts.length < 2) {
    return const [];
  }
  return [
    for (final a in accounts)
      if (!a.loggedIn)
        SubscriptionUsageAccount(
          providerId: 'claude',
          accountId: a.id,
          accountLabel: _claudeAccountLabel(a),
          knownStatus: SubscriptionStatus.signInRequired,
          knownReason:
              a.statusError ??
              'This account cannot authenticate. Sign in again.',
        )
      else if (a.isCredentialExpired())
        SubscriptionUsageAccount(
          providerId: 'claude',
          accountId: a.id,
          accountLabel: _claudeAccountLabel(a),
          knownStatus: SubscriptionStatus.signInExpired,
          knownReason:
              'The sign-in expired. Usage is readable again after the '
              'next run renews it, or after signing in.',
        )
      else
        SubscriptionUsageAccount(
          providerId: 'claude',
          accountId: a.id,
          accountLabel: _claudeAccountLabel(a),
          configDir: store.configDirFor(a.id),
        ),
  ];
}

/// `me@example.com · max · Acme` — one line naming a Claude Code account.
///
/// Not localized on purpose: every part is a value the CLI handed back
/// verbatim, and translating around an unknown-shaped string reads worse than
/// showing it plainly. Falls back to the operator's own label when the CLI has
/// reported no identity yet.
String _claudeAccountLabel(ClaudeAccount account) {
  final parts = [
    if (account.email != null && account.email!.isNotEmpty) account.email!,
    if (account.subscriptionType != null &&
        account.subscriptionType!.isNotEmpty)
      account.subscriptionType!,
    if (account.orgName != null && account.orgName!.isNotEmpty)
      account.orgName!,
  ];
  return parts.isEmpty ? account.label : parts.join(' · ');
}
