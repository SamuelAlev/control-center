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

/// Workspace-settings key holding the account pool for [lane], at the
/// workspace's scope or (with [agentId]) one agent's override of it.
///
/// THE one spelling of pool storage, for every lane. The two lanes that
/// predate this keep the keys they were first written under, so existing pools
/// read back unchanged; any lane added later lands under `account_pools.`.
/// Null when [lane] is not one this install knows — rejecting an unknown lane
/// rather than deriving a key from it is what stops a client writing arbitrary
/// settings keys through the pool ops.
String? accountPoolKey(String lane, String? agentId) {
  if (!AccountPoolLanes.isKnown(lane)) {
    return null;
  }
  final provider = AccountPoolLanes.harnessProviderOf(lane);
  final base = lane == AccountPoolLanes.claudeCode
      ? 'claude_accounts.pool'
      : provider != null
      ? 'harness_accounts.pool.$provider'
      : 'account_pools.$lane';
  return agentId == null || agentId.isEmpty ? base : '$base.agent.$agentId';
}

/// The pool that applies to one dispatch on [lane], read most-specific first:
/// the agent's own, else the workspace's, else unconfigured.
///
/// The returned cursor key is where THAT pool's round-robin position lives — the agent's
/// when the agent's pool answered, so two agents rotating the same accounts
/// keep independent positions.
///
/// An agent pool with no accounts in it is treated as "not set" rather than as
/// "attach nothing" — an empty list is what an editor leaves behind when the
/// operator removes the last row, and reading that as a deliberate opt-out
/// would silently stop every run for that agent. A corrupt pool falls through
/// to the next scope rather than stopping the dispatch.
Future<({AccountPool pool, String? cursorKey, int cursor})> readAccountPool(
  WorkspaceSettingsRepository settings, {
  required String? workspaceId,
  required String? agentId,
  required String lane,
}) async {
  const unset = (pool: AccountPool(), cursorKey: null, cursor: 0);
  if (workspaceId == null || workspaceId.isEmpty) {
    return unset;
  }
  for (final scopeAgent in [
    if (agentId != null && agentId.isNotEmpty) agentId,
    null,
  ]) {
    final key = accountPoolKey(lane, scopeAgent);
    if (key == null) {
      return unset;
    }
    final raw = await settings.get(workspaceId, key);
    if (raw == null || raw.isEmpty) {
      continue;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final pool = AccountPool.fromJson(decoded);
        if (!pool.isEmpty) {
          final cursorKey = '$key.cursor';
          final cursor =
              int.tryParse(await settings.get(workspaceId, cursorKey) ?? '') ??
              0;
          return (pool: pool, cursorKey: cursorKey, cursor: cursor);
        }
      }
    } on Object {
      // Fall through to the next scope.
    }
  }
  return unset;
}

/// The pools in one workspace's [settings] that name accounts of [lane]
/// outside [existing], rewritten without them — the settings to write back
/// after a credential of that lane is removed from the server.
///
/// A pool that would be left empty is not in the result; see
/// [AccountPool.retainOnly] for why it keeps its dangling ids. Cursor keys
/// share the prefix and are skipped: a round-robin cursor is taken modulo the
/// pool's length, so a shorter pool needs no rewrite of it.
Map<String, String> prunedAccountPools(
  Map<String, String> settings, {
  required String lane,
  required Set<String> existing,
}) {
  final workspaceKey = accountPoolKey(lane, null);
  if (workspaceKey == null) {
    return const {};
  }
  final agentPrefix = '$workspaceKey.agent.';
  final out = <String, String>{};
  for (final MapEntry(:key, :value) in settings.entries) {
    final isPool =
        key == workspaceKey ||
        (key.startsWith(agentPrefix) && !key.endsWith('.cursor'));
    if (!isPool) {
      continue;
    }
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        continue;
      }
      final pruned = AccountPool.fromJson(decoded).retainOnly(existing);
      if (pruned != null) {
        out[key] = jsonEncode(pruned.toJson());
      }
    } on FormatException {
      // A corrupt pool is already ignored by dispatch; leave it for the editor.
    }
  }
  return out;
}

/// Orders a harness provider's [credentialIds] for one dispatch, applying the
/// workspace's (or the agent's) pool, its strategy, and any cooling-off keys.
///
/// Pool reading, selection and the removed-accounts refusal are the SAME code
/// the Claude Code lane runs ([readAccountPool], [AccountSelector]); what is
/// harness-specific is only what it does with the answer. A null order means
/// nothing is configured, so the caller keeps the store's own order. The
/// round-robin cursor is advanced and persisted here, BEFORE the run, so two
/// dispatches racing still lead with different credentials.
Future<AccountPoolOrder> resolveHarnessRotationOrder({
  required WorkspaceSettingsRepository settings,
  required CredentialCooldownStore cooldowns,
  required String? workspaceId,
  required String? agentId,
  required String providerId,
  required List<String> credentialIds,
}) async {
  final read = await readAccountPool(
    settings,
    workspaceId: workspaceId,
    agentId: agentId,
    lane: AccountPoolLanes.harness(providerId),
  );
  if (read.pool.isEmpty) {
    return (order: null, refusal: null);
  }

  final cooling = await cooldowns.activeFor(providerId);
  final choice = AccountSelector.select(
    pool: read.pool,
    availability: {
      for (final id in credentialIds)
        id: AccountAvailability(
          id: id,
          signedIn: true,
          spent: cooling.containsKey(id),
          availableAt: cooling[id],
        ),
    },
    cursor: read.cursor,
  );

  switch (choice) {
    case AccountPoolUnset():
      return (order: null, refusal: null);
    case AccountsRemoved(:final accountIds):
      // Refused, exactly as the Claude lane refuses: the pool exists to keep
      // this scope off the keys it does not name.
      return (
        order: null,
        refusal: (
          reason: RunCredentialReason.accountsRemoved,
          accountIds: accountIds,
          earliestReset: null,
        ),
      );
    case AccountsAllSpent(:final accountIds):
      // Unlike the Claude lane there is no refusal here, and that asymmetry is
      // deliberate: `FallbackProvider` retries a capacity error on the SAME
      // target after backoff, so handing it the pool anyway lets a window that
      // reopens mid-turn still serve the run. Refusing would be strictly worse.
      return (order: accountIds, refusal: null);
    case AccountChosen(cursor: final next):
      final cursorKey = read.cursorKey;
      if (next != read.cursor && cursorKey != null && workspaceId != null) {
        await settings.set(workspaceId, cursorKey, '$next');
      }
      // Cooling keys go last rather than nowhere, for the same backoff reason.
      return (order: [...choice.order, ...choice.standby], refusal: null);
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
