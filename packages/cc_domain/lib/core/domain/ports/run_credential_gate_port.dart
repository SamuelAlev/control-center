/// Parking a run whose credential cannot serve it, instead of failing it.
///
/// A run that cannot authenticate used to die at the launch branch: an
/// `ErrorEvent` naming the problem, exit 126/127, turn over. The operator then
/// walked to Settings, fixed the credential and retyped the message — the work
/// was lost for a reason that heals in seconds.
///
/// This port is the alternative. The dispatch stack hands the gate the SAME
/// verdict it would have failed on, plus a `recheck` closure that answers "can
/// this run go now?", and blocks. A host with a human attached publishes the
/// block, offers the fix, watches for it and lets the run continue in place. A
/// host with nobody attached times out and gets exactly the old failure, which
/// is what keeps an unattended pipeline or cron run from turning into a hang.
///
/// Two lanes are gated today and the reason is what Control Center OWNS: it
/// holds the Claude Code account directories and the harness provider
/// credentials, so it can state, before a spawn, whether either can serve a
/// run. The other CLIs (codex, opencode, gemini, cursor, goose, pi) own their
/// own login and expose no status probe, so a pre-flight for them would be a
/// guess; they are a later, additive lane rather than a wrong one now.
library;

/// Which credential lane a parked run is waiting on.
enum RunCredentialLane {
  /// The `claude-code` adapter's account directories
  /// (`<dataDir>/claude-accounts/<id>`), whose login the CLI performs and
  /// Control Center only reads.
  claudeCode('claude_code'),

  /// A built-in-harness provider credential (an API key, or a stored OAuth
  /// account) resolved through `ProviderCredentialStore`.
  harness('harness');

  const RunCredentialLane(this.wire);

  /// Stable persisted/RPC spelling. Never the enum name — renaming a Dart
  /// symbol must not silently re-point what a client branches on.
  final String wire;

  /// Parses [raw], defaulting to [harness] for anything unrecognized.
  static RunCredentialLane fromWire(String? raw) {
    for (final l in values) {
      if (l.wire == raw) {
        return l;
      }
    }
    return harness;
  }
}

/// Why the run cannot start.
///
/// Four states rather than one "credential problem", because they heal four
/// different ways and telling the operator the wrong one costs them the fix: a
/// spent plan comes back by itself at a known time, a signed-out directory
/// comes back only when a human runs `claude auth login`, an expired credential
/// looks signed in until it 401s, and a missing API key needs a key pasted.
enum RunCredentialReason {
  /// No credential at all for this provider (the harness lane's only state).
  noCredential('no_credential'),

  /// The account directory holds no usable credential — nobody has signed in,
  /// or somebody signed out.
  signedOut('signed_out'),

  /// A credential is present but past its expiry with nothing to renew itself
  /// with, so every request on it can only 401.
  credentialExpired('credential_expired'),

  /// The plan's windows are used up, or the account is cooling off after a real
  /// rate-limit response. The only reason that carries a reset time.
  planSpent('plan_spent');

  const RunCredentialReason(this.wire);

  /// Stable persisted/RPC spelling, for the same reason [RunCredentialLane.wire]
  /// is one.
  final String wire;

  /// Parses [raw], defaulting to [noCredential] for anything unrecognized.
  static RunCredentialReason fromWire(String? raw) {
    for (final r in values) {
      if (r.wire == raw) {
        return r;
      }
    }
    return noCredential;
  }
}

/// Why a dispatch cannot start on any Claude Code account: what is wrong, which
/// accounts it is wrong for, and when (if ever) one frees up by itself.
///
/// A named shape rather than a bare reason because all three facts travel
/// together from the account store through the dispatch port into the gate, and
/// spelling the record out at each hop is how one of them gets dropped.
typedef ClaudeAccountRefusal = ({
  RunCredentialReason reason,
  List<String> accountIds,
  DateTime? earliestReset,
});

/// How a parked run stopped being parked.
enum RunCredentialOutcome {
  /// The credential became usable — the run continues, in the same turn.
  resolved,

  /// A human declined to fix it and cancelled the run.
  cancelled,

  /// Nobody answered before the deadline. The caller falls through to the
  /// failure it would have produced without a gate.
  timedOut,
}

/// What a parked run tells the operator, and what the gate needs to route it.
class RunCredentialBlockRequest {
  /// Creates a [RunCredentialBlockRequest].
  const RunCredentialBlockRequest({
    required this.lane,
    required this.reason,
    required this.detail,
    this.runLogId,
    this.providerId,
    this.accountIds = const [],
    this.availableAt,
    this.workspaceId,
    this.spaceId,
    this.conversationId,
    this.agentId,
    this.agentName,
  });

  /// Which credential lane is blocked.
  final RunCredentialLane lane;

  /// Why.
  final RunCredentialReason reason;

  /// The verbatim sentence the run WOULD have failed with.
  ///
  /// Carried rather than re-derived so the dialog and the fallback error cannot
  /// disagree: if the deadline passes, this exact text is what lands in the
  /// transcript.
  final String detail;

  /// The run being held, so a surface can attribute the block to a turn. Null
  /// when the block was raised before a run log id existed.
  final String? runLogId;

  /// The harness provider id, on [RunCredentialLane.harness].
  final String? providerId;

  /// The Claude Code accounts that were considered, on
  /// [RunCredentialLane.claudeCode]. The dialog joins these against the account
  /// roster it already reads rather than being sent labels that could go stale
  /// between the block and the render.
  final List<String> accountIds;

  /// When the block is expected to clear by itself — a plan window's reset or
  /// the end of a cooldown. Null for everything that only a human can fix.
  final DateTime? availableAt;

  /// The workspace the run belongs to. Authorizes the remote surface exactly as
  /// `ConfirmationRequest.workspaceId` does: the watch is filtered to the
  /// subscriber's own workspaces and the resolve op requires membership. Null
  /// only on a host with no identity wiring.
  final String? workspaceId;

  /// The space the run belongs to, so a surface can say which thread stalled.
  final String? spaceId;

  /// The conversation the run belongs to.
  final String? conversationId;

  /// The agent whose turn is parked.
  final String? agentId;

  /// That agent's display name, so the dialog can say who is waiting.
  final String? agentName;
}

/// The `credential_gate.watchBlocked` wire shape — one parked run.
class RunCredentialBlockDto {
  /// Creates a [RunCredentialBlockDto].
  const RunCredentialBlockDto({
    required this.id,
    required this.lane,
    required this.reason,
    required this.detail,
    required this.createdAt,
    this.runLogId,
    this.providerId,
    this.accountIds = const [],
    this.availableAt,
    this.expiresAt,
    this.workspaceId,
    this.spaceId,
    this.conversationId,
    this.agentId,
    this.agentName,
  });

  /// Reads the wire map.
  factory RunCredentialBlockDto.fromJson(Map<String, dynamic> json) =>
      RunCredentialBlockDto(
        id: json['id'] as String? ?? '',
        lane: RunCredentialLane.fromWire(json['lane'] as String?),
        reason: RunCredentialReason.fromWire(json['reason'] as String?),
        detail: json['detail'] as String? ?? '',
        runLogId: json['run_log_id'] as String?,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        providerId: json['provider_id'] as String?,
        accountIds: [
          for (final id in (json['account_ids'] as List?) ?? const [])
            if (id is String && id.isNotEmpty) id,
        ],
        availableAt: DateTime.tryParse(json['available_at'] as String? ?? ''),
        expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
        workspaceId: json['workspace_id'] as String?,
        spaceId: json['space_id'] as String?,
        conversationId: json['conversation_id'] as String?,
        agentId: json['agent_id'] as String?,
        agentName: json['agent_name'] as String?,
      );

  /// Stable id echoed back in `credential_gate.resolve`.
  final String id;

  /// Which credential lane is blocked.
  final RunCredentialLane lane;

  /// Why.
  final RunCredentialReason reason;

  /// The sentence the run would have failed with.
  final String detail;

  /// The run being held, when the host knew one.
  final String? runLogId;

  /// When the block was raised (UTC).
  final DateTime createdAt;

  /// The harness provider id, on the harness lane.
  final String? providerId;

  /// The Claude Code accounts considered, on the claude lane.
  final List<String> accountIds;

  /// When the block is expected to clear by itself, when known.
  final DateTime? availableAt;

  /// When the gate gives up and the run fails with [detail]. Null when the host
  /// waits indefinitely.
  final DateTime? expiresAt;

  /// The workspace the run belongs to, when the host knew one.
  final String? workspaceId;

  /// The space the run belongs to.
  final String? spaceId;

  /// The conversation the run belongs to.
  final String? conversationId;

  /// The agent whose turn is parked.
  final String? agentId;

  /// That agent's display name.
  final String? agentName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunCredentialBlockDto &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Parks a run until the credential it needs can serve it.
///
/// Implemented host-side (see `PendingCredentialBlockRegistry` in `cc_host`).
/// A dispatch with no gate wired behaves exactly as it did before this existed:
/// the caller keeps its old failure path for a null port.
abstract interface class RunCredentialGatePort {
  /// Publishes [request] and blocks until [recheck] answers true, a client
  /// resolves it, or the host's deadline passes.
  ///
  /// [recheck] is polled by the gate — it is the ONLY thing that can say the
  /// credential works now, because the fix usually happens outside the server
  /// (a `claude auth login` in a terminal, a plan window reopening). It must be
  /// cheap and side-effect-free apart from re-reading state, and it may throw:
  /// a throwing probe leaves the run parked rather than being read as either
  /// verdict.
  ///
  /// Never throws — a gate that failed would have to fail the run, and the
  /// caller already has a better answer for that.
  Future<RunCredentialOutcome> awaitCredentials(
    RunCredentialBlockRequest request, {
    required Future<bool> Function() recheck,
  });
}
