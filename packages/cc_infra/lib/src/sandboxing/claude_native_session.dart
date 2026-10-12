import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The exact authorization scope a native Claude Code session id belongs to.
///
/// A session id minted by `claude -p` is NOT portable: it names a transcript
/// that lives in one account's config directory, was produced by one model at
/// one effort under one permission/mcp posture, and describes one agent's work
/// inside one conversation's working directory. Resuming it in any other scope
/// would hand an agent another agent's context — which is exactly why Claude
/// Code warns that `--continue` ("the latest session in this directory") is
/// unsafe when several conversations coexist.
///
/// [storageKey] is the ONLY thing a store is ever asked about: two dispatches
/// can share a record iff every part below is identical, so a record can never
/// be read across workspaces, conversations, agents, accounts, working
/// directories or policies. The isolation is structural, not a check someone
/// can forget to write.
class ClaudeNativeSessionScope {
  /// Creates a [ClaudeNativeSessionScope].
  const ClaudeNativeSessionScope({
    required this.workspaceId,
    required this.conversationId,
    required this.agentId,
    required this.accountId,
    required this.workdir,
    required this.policyFingerprint,
  });

  /// Workspace whose database/isolation boundary owns the record.
  final String workspaceId;

  /// Conversation the turn belongs to. Two conversations in one workspace hold
  /// two different histories.
  final String conversationId;

  /// Agent whose run this is; two agents in one conversation saw different
  /// tool results and system prompts.
  final String agentId;

  /// Claude Code account (its config directory). A session transcript is
  /// written into that account's directory, so a different account is a
  /// different store of sessions entirely.
  final String accountId;

  /// Working directory / worktree the CLI was launched in. Claude Code stores
  /// sessions per project path; a resumed id from another tree would carry the
  /// wrong file context.
  final String workdir;

  /// Canonical fingerprint of the launch policy: model, effort, permission
  /// mode, MCP config posture and appended system prompt. A resumed session
  /// silently inherits the old policy's system prompt and permission surface,
  /// so any change to it forks rather than resumes.
  final String policyFingerprint;

  /// The canonical, delimiter-joined scope string the key hashes.
  String get canonical => [
    'ws=$workspaceId',
    'conv=$conversationId',
    'agent=$agentId',
    'acct=$accountId',
    'cwd=$workdir',
    'policy=$policyFingerprint',
  ].join('\u0000');

  /// Stable storage key for this scope: `sha256(canonical)` in hex.
  String get storageKey => sha256.convert(utf8.encode(canonical)).toString();

  @override
  String toString() => 'ClaudeNativeSessionScope($canonical)';
}

/// Per-model, whole-tree token/cost counters as `claude` reports them in
/// `modelUsage`.
///
/// Whole-tree means subagent requests are included, so these counters answer
/// "what did the whole invocation spend on model X" — the honest source for
/// token attribution. They are NOT added to the per-turn main-loop tokens;
/// doing both is the double count this type exists to prevent.
class ClaudeModelUsageSnapshot {
  /// Reads a snapshot back off [toJson]'s shape.
  factory ClaudeModelUsageSnapshot.fromJson(Map<String, dynamic> json) {
    int i(String key) {
      final value = json[key];
      return value is num ? value.toInt() : 0;
    }

    final cost = json['costUsd'];
    return ClaudeModelUsageSnapshot(
      inputTokens: i('inputTokens'),
      outputTokens: i('outputTokens'),
      cacheReadTokens: i('cacheReadTokens'),
      cacheWriteTokens: i('cacheWriteTokens'),
      costUsd: cost is num ? cost.toDouble() : 0,
      costBasis: json['costBasis'] as String?,
    );
  }

  /// Creates a [ClaudeModelUsageSnapshot].
  const ClaudeModelUsageSnapshot({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cacheReadTokens = 0,
    this.cacheWriteTokens = 0,
    this.costUsd = 0,
    this.costBasis,
  });

  /// Uncached input tokens.
  final int inputTokens;

  /// Output tokens.
  final int outputTokens;

  /// Cache-hit read tokens.
  final int cacheReadTokens;

  /// Cache-write tokens.
  final int cacheWriteTokens;

  /// Estimated USD cost for this model's share of the invocation.
  final double costUsd;

  /// Which price table priced the latest request: `list`, `managed` or
  /// `unknown`. Null on older CLIs that do not report it.
  final String? costBasis;

  /// Sum of every token category.
  int get totalTokens =>
      inputTokens + outputTokens + cacheReadTokens + cacheWriteTokens;

  /// This snapshot minus [previous], per counter, never below zero.
  ///
  /// A counter that shrank (a reset or a fork restarted the totals) floors at
  /// zero here; the caller treats the whole result as a fresh baseline in that
  /// case, so a shrunken counter must not produce a negative attribution.
  ClaudeModelUsageSnapshot delta(ClaudeModelUsageSnapshot previous) =>
      ClaudeModelUsageSnapshot(
        inputTokens: _sub(inputTokens, previous.inputTokens),
        outputTokens: _sub(outputTokens, previous.outputTokens),
        cacheReadTokens: _sub(cacheReadTokens, previous.cacheReadTokens),
        cacheWriteTokens: _sub(cacheWriteTokens, previous.cacheWriteTokens),
        costUsd: costUsd - previous.costUsd,
        costBasis: costBasis,
      );

  /// Whether every counter is at zero.
  bool get isEmpty =>
      inputTokens == 0 &&
      outputTokens == 0 &&
      cacheReadTokens == 0 &&
      cacheWriteTokens == 0 &&
      costUsd == 0;

  static int _sub(int value, int previous) {
    final d = value - previous;
    return d < 0 ? 0 : d;
  }

  /// JSON form, for the durable store.
  Map<String, dynamic> toJson() => {
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'cacheReadTokens': cacheReadTokens,
    'cacheWriteTokens': cacheWriteTokens,
    'costUsd': costUsd,
    if (costBasis != null) 'costBasis': costBasis,
  };

  @override
  String toString() =>
      'ClaudeModelUsageSnapshot(in=$inputTokens, out=$outputTokens, '
      'read=$cacheReadTokens, write=$cacheWriteTokens, \$costUsd)';
}

/// A durable native-session mapping plus the cumulative accounting baseline
/// that goes with it.
///
/// The accounting baseline travels WITH the session id because they have the
/// same lifetime: a resumed Claude Code call restores the session's prior
/// spend into `total_cost_usd`, so the adapter must remember what it already
/// counted or the restored spend is counted twice. Persisting them apart would
/// let one survive the other.
class ClaudeNativeSessionRecord {
  /// Creates a [ClaudeNativeSessionRecord].
  const ClaudeNativeSessionRecord({
    required this.storageKey,
    required this.sessionId,
    required this.policyFingerprint,
    required this.conversationRevision,
    required this.createdAt,
    required this.lastUsedAt,
    this.deliveredConversationKeys = const [],
    this.deliveredSectionKeys = const [],
    this.producedRunIds = const [],
    this.turns = 0,
    this.cumulativeCostUsd = 0,
    this.modelUsage = const {},
    this.mainUsageSinceModels = const ClaudeModelUsageSnapshot(),
    this.cliRestoresTotals = false,
  });

  /// The scope hash this record is filed under. Present so a record read back
  /// from disk can prove which scope it belongs to.
  final String storageKey;

  /// The native Claude Code session id (`system/init`'s `session_id`, which is
  /// also what `--resume` takes).
  final String sessionId;

  /// Policy fingerprint in force when the session was created.
  final String policyFingerprint;

  /// The conversation block this session has already been given, hashed.
  ///
  /// The per-session delivered-context CURSOR. A resumed turn omits the
  /// conversation window only while its revision still matches, so a shared
  /// conversation that moved on while this session was parked — or a switch
  /// away to another model/account and back — re-delivers the window instead of
  /// silently dropping the entries the session never saw.
  ///
  /// Required: a record without one (an older or foreign shape) cannot
  /// establish continuity, and the caller must start a FRESH session with the
  /// full prompt rather than fabricate a safe delta.
  final String conversationRevision;

  /// The keys of the conversation entries already delivered to this session.
  ///
  /// The bounded cursor: a resumed turn sends only entries whose key is absent
  /// here (plus anything the session produced itself, which is never re-sent).
  final List<String> deliveredConversationKeys;

  /// Keys of the per-turn SECTIONS already delivered (bounded), so an unchanged
  /// retrieved-memory/turn section is not re-sent.
  final List<String> deliveredSectionKeys;

  /// Run ids this exact native session is known to have produced (bounded).
  ///
  /// The lineage that proves a self-authored message is already in this
  /// session's transcript. Populated only by a CLEAN run.
  final List<String> producedRunIds;

  /// How many cursor/lineage entries are retained.
  ///
  /// The lists are a bounded cursor, not a log: a conversation with thousands
  /// of turns keeps the most recent window, which is exactly the window the
  /// deltas are drawn from.
  static const int maxCursorEntries = 256;

  /// The most recent [maxCursorEntries] of [values], oldest dropped first.
  static List<String> bound(List<String> values) =>
      values.length <= maxCursorEntries
      ? values
      : values.sublist(values.length - maxCursorEntries);

  /// When the session was first opened.
  final DateTime createdAt;

  /// When it was last used, for TTL/eviction by a host that cares.
  final DateTime lastUsedAt;

  /// How many turns this record has accounted for.
  final int turns;

  /// The CLI's cumulative estimated cost (USD) at the last accounted result.
  ///
  /// Only a RESUME BASELINE: the run-level total is the dispatch's own sum, and
  /// this figure is used only when [cliRestoresTotals] says the CLI will
  /// restore it.
  final double cumulativeCostUsd;

  /// The CLI's cumulative whole-tree per-model usage at the last result.
  final Map<String, ClaudeModelUsageSnapshot> modelUsage;

  /// Known main-loop tokens not yet included in the last model counter map.
  final ClaudeModelUsageSnapshot mainUsageSinceModels;

  /// Whether Claude makes these totals durable: true only after a NORMAL
  /// process exit on a CLI new enough to restore session totals (2.1.277+).
  /// False after an interrupted run, or on an older CLI, whose resumed calls
  /// start their figures at zero.
  final bool cliRestoresTotals;

  /// Copy with selected fields replaced.
  ClaudeNativeSessionRecord copyWith({
    String? sessionId,
    String? policyFingerprint,
    String? conversationRevision,
    List<String>? deliveredConversationKeys,
    List<String>? deliveredSectionKeys,
    List<String>? producedRunIds,
    DateTime? lastUsedAt,
    int? turns,
    double? cumulativeCostUsd,
    Map<String, ClaudeModelUsageSnapshot>? modelUsage,
    ClaudeModelUsageSnapshot? mainUsageSinceModels,
    bool? cliRestoresTotals,
  }) => ClaudeNativeSessionRecord(
    storageKey: storageKey,
    sessionId: sessionId ?? this.sessionId,
    policyFingerprint: policyFingerprint ?? this.policyFingerprint,
    conversationRevision: conversationRevision ?? this.conversationRevision,
    deliveredConversationKeys:
        deliveredConversationKeys ?? this.deliveredConversationKeys,
    deliveredSectionKeys: deliveredSectionKeys ?? this.deliveredSectionKeys,
    producedRunIds: producedRunIds ?? this.producedRunIds,
    createdAt: createdAt,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    turns: turns ?? this.turns,
    cumulativeCostUsd: cumulativeCostUsd ?? this.cumulativeCostUsd,
    modelUsage: modelUsage ?? this.modelUsage,
    mainUsageSinceModels: mainUsageSinceModels ?? this.mainUsageSinceModels,
    cliRestoresTotals: cliRestoresTotals ?? this.cliRestoresTotals,
  );

  /// JSON form, for the durable store.
  Map<String, dynamic> toJson() => {
    'storageKey': storageKey,
    'sessionId': sessionId,
    'policyFingerprint': policyFingerprint,
    'conversationRevision': conversationRevision,
    'deliveredConversationKeys': deliveredConversationKeys,
    'deliveredSectionKeys': deliveredSectionKeys,
    'producedRunIds': producedRunIds,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'lastUsedAt': lastUsedAt.toUtc().toIso8601String(),
    'turns': turns,
    'cumulativeCostUsd': cumulativeCostUsd,
    'cliRestoresTotals': cliRestoresTotals,
    'mainUsageSinceModels': mainUsageSinceModels.toJson(),
    'modelUsage': {for (final e in modelUsage.entries) e.key: e.value.toJson()},
  };

  static List<String> _stringList(Object? raw) => raw is List
      ? [
          for (final k in raw)
            if (k is String && k.isNotEmpty) k,
        ]
      : const [];

  /// Reads a record back off [toJson]'s shape. Returns null on a shape it
  /// cannot use (missing ids, or no conversation cursor) so a corrupt or
  /// older file degrades to "no resume" — a fresh session with the full
  /// prompt — instead of failing the run or fabricating a delta.
  static ClaudeNativeSessionRecord? fromJson(Map<String, dynamic> json) {
    final storageKey = json['storageKey'];
    final sessionId = json['sessionId'];
    final policy = json['policyFingerprint'];
    final revision = json['conversationRevision'];
    if (storageKey is! String ||
        storageKey.isEmpty ||
        sessionId is! String ||
        sessionId.isEmpty ||
        policy is! String ||
        revision is! String) {
      return null;
    }
    DateTime parseTime(Object? raw, DateTime fallback) {
      if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) {
          return parsed;
        }
      }
      return fallback;
    }

    final now = DateTime.now().toUtc();
    final rawUsage = json['modelUsage'];
    final usage = <String, ClaudeModelUsageSnapshot>{};
    if (rawUsage is Map) {
      for (final entry in rawUsage.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is Map<String, dynamic>) {
          usage[key] = ClaudeModelUsageSnapshot.fromJson(value);
        }
      }
    }
    final cost = json['cumulativeCostUsd'];
    final turns = json['turns'];
    return ClaudeNativeSessionRecord(
      storageKey: storageKey,
      sessionId: sessionId,
      policyFingerprint: policy,
      conversationRevision: revision,
      deliveredConversationKeys: _stringList(json['deliveredConversationKeys']),
      deliveredSectionKeys: _stringList(json['deliveredSectionKeys']),
      producedRunIds: _stringList(json['producedRunIds']),
      createdAt: parseTime(json['createdAt'], now),
      lastUsedAt: parseTime(json['lastUsedAt'], now),
      turns: turns is num ? turns.toInt() : 0,
      cumulativeCostUsd: cost is num ? cost.toDouble() : 0,
      modelUsage: usage,
      mainUsageSinceModels: json['mainUsageSinceModels'] is Map<String, dynamic>
          ? ClaudeModelUsageSnapshot.fromJson(
              json['mainUsageSinceModels'] as Map<String, dynamic>,
            )
          : const ClaudeModelUsageSnapshot(),
      cliRestoresTotals: json['cliRestoresTotals'] == true,
    );
  }
}

/// Where native Claude Code session ids (and their accounting baselines) are
/// persisted between dispatches.
///
/// Keyed by the workspace id (the isolation boundary a host partitions data
/// by) plus the opaque [ClaudeNativeSessionScope.storageKey]: a store cannot
/// accidentally merge two scopes, and cannot be asked to leak one workspace's
/// record into another.
abstract class ClaudeNativeSessionStore {
  /// Loads the record filed under [storageKey] in [workspaceId], or null when
  /// there is none.
  Future<ClaudeNativeSessionRecord?> load({
    required String workspaceId,
    required String storageKey,
  });

  /// Persists [record] under its own `storageKey` in [workspaceId].
  Future<void> save({
    required String workspaceId,
    required ClaudeNativeSessionRecord record,
  });

  /// Removes the record under [storageKey] (an explicit reset/fork).
  Future<void> clear({required String workspaceId, required String storageKey});
}

/// A store that remembers nothing, so every run starts a fresh native session.
///
/// This is the safe default when a host wires no store: it is exactly the
/// pre-resume behaviour, and it can never leak a session across scopes.
class NoopClaudeNativeSessionStore implements ClaudeNativeSessionStore {
  /// Creates a [NoopClaudeNativeSessionStore].
  const NoopClaudeNativeSessionStore();

  @override
  Future<ClaudeNativeSessionRecord?> load({
    required String workspaceId,
    required String storageKey,
  }) async => null;

  @override
  Future<void> save({
    required String workspaceId,
    required ClaudeNativeSessionRecord record,
  }) async {}

  @override
  Future<void> clear({
    required String workspaceId,
    required String storageKey,
  }) async {}
}

/// In-memory store, for tests and single-process sessions.
class InMemoryClaudeNativeSessionStore implements ClaudeNativeSessionStore {
  /// Creates an [InMemoryClaudeNativeSessionStore].
  InMemoryClaudeNativeSessionStore([
    Map<String, ClaudeNativeSessionRecord>? seed,
  ]) : _byKey = {...?seed};

  final Map<String, ClaudeNativeSessionRecord> _byKey;

  /// Every record currently held, for assertions.
  Map<String, ClaudeNativeSessionRecord> get records =>
      Map.unmodifiable(_byKey);

  /// The map key: the workspace is part of it so a shared store behaves like
  /// the file adapter, which partitions its directory by workspace.
  static String _mapKey(String workspaceId, String storageKey) =>
      '$workspaceId\u0000$storageKey';

  @override
  Future<ClaudeNativeSessionRecord?> load({
    required String workspaceId,
    required String storageKey,
  }) async => _byKey[_mapKey(workspaceId, storageKey)];

  @override
  Future<void> save({
    required String workspaceId,
    required ClaudeNativeSessionRecord record,
  }) async {
    _byKey[_mapKey(workspaceId, record.storageKey)] = record;
  }

  @override
  Future<void> clear({
    required String workspaceId,
    required String storageKey,
  }) async {
    _byKey.remove(_mapKey(workspaceId, storageKey));
  }
}
