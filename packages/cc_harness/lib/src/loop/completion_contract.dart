import 'package:cc_harness/src/loop/agent_loop.dart';

/// A run's deliverable, declared up front (presence check at the terminal
/// boundary). Without it, "no tool calls" counts as success even with no
/// artifact. Kernel-agnostic: tool names + text; dispatch maps modes. [probe]
/// is the seam for a future quality verifier.
class CompletionContract {
  /// Creates a completion contract.
  const CompletionContract({
    required this.id,
    required this.requiredToolNames,
    required this.nudge,
    required this.unmetSummary,
    this.maxNudges = 1,
    this.probe,
  });

  /// Stable identifier for the contract, e.g. `plan.submitted`. Reported on
  /// [LoopDone.unmetContractId] so the caller can act on *which* contract
  /// failed without string-matching a message.
  final String id;

  /// Tool names that satisfy the contract, ANY-OF. A single successful call to
  /// any of them discharges it.
  ///
  /// Deliberately not a language: no sequencing, no boolean expressions, no
  /// per-turn contracts. A deliverable that needs a sequence is a pipeline.
  final Set<String> requiredToolNames;

  /// Injected as a system message when the model would stop with the contract
  /// unmet. Should name the verb, say plainly that nothing exists yet and
  /// authorize an honest opt-out so a genuine no-deliverable turn can end.
  final String nudge;

  /// Recorded as the run's summary when the contract is never satisfied.
  final String unmetSummary;

  /// How many times the loop may nudge before giving up. One is the default on
  /// purpose: an unbounded nudge is a doom loop with better branding.
  final int maxNudges;

  /// Optional artifact-existence check, consulted only when no required tool
  /// call succeeded. Lets a caller satisfy a contract by evidence rather than
  /// by observing the call (e.g. the artifact was written by an earlier run).
  final ContractProbe? probe;

  /// Whether this contract can ever be unsatisfied.
  bool get isActive => requiredToolNames.isNotEmpty || probe != null;
}

/// Resolves whether the deliverable exists, independent of tool observation.
/// Must not throw; a throwing probe is treated as "not satisfied".
typedef ContractProbe = Future<bool> Function();

/// Tracks contract satisfaction across a single run. Loop-internal.
class ContractLedger {
  /// Creates a ledger for [contract] (null = nothing to track).
  ContractLedger(this.contract);

  /// The contract being tracked, if any.
  final CompletionContract? contract;

  var _satisfied = false;
  var _nudgesIssued = 0;

  /// Whether a required tool has completed successfully.
  bool get satisfied => _satisfied;

  /// How many nudges have been issued so far.
  int get nudgesIssued => _nudgesIssued;

  /// Whether the ledger is tracking an active contract.
  bool get isActive => contract?.isActive ?? false;

  /// Records the outcome of a tool call. Only a non-error call counts: a
  /// `submit_plan` that came back with validation violations has delivered
  /// nothing, so the contract stays open and the nudge still fires.
  void recordToolResult(String toolName, {required bool isError}) {
    final c = contract;
    if (c == null || isError || _satisfied) {
      return;
    }
    if (c.requiredToolNames.contains(toolName)) {
      _satisfied = true;
    }
  }

  /// Whether the loop may nudge once more.
  bool get canNudge => (contract?.maxNudges ?? 0) > _nudgesIssued;

  /// Consumes one nudge allowance and returns its text.
  String takeNudge() {
    _nudgesIssued++;
    return contract!.nudge;
  }

  /// Runs [CompletionContract.probe] when the verbs were never observed.
  /// Swallows failures — a broken probe must not fail the run.
  Future<bool> resolveSatisfied() async {
    if (_satisfied) {
      return true;
    }
    final probe = contract?.probe;
    if (probe == null) {
      return false;
    }
    try {
      _satisfied = await probe();
    } on Object {
      _satisfied = false;
    }
    return _satisfied;
  }
}
