/// The capability tier of a tool invocation — how dangerous it is.
///
/// Replaces the coarse `requiresApproval: bool` with a three-level ladder so
/// the same tool can be safe-or-risky depending on its *arguments* (a `gh`
/// invocation is `read` for `gh pr view` but `write` for `gh pr merge`). The
/// approval gate auto-approves any tier at or below the active [ApprovalMode]'s
/// ceiling and prompts for anything above it.
enum CapabilityTier {
  /// Reads state only (list/get/search/view). Never prompts.
  read,

  /// Mutates workspace or external state (commit, comment, write file).
  write,

  /// Executes arbitrary code or irreversible/destructive actions (shell, merge,
  /// delete, publish). The most dangerous tier.
  exec;

  /// Monotonic rank used for ceiling comparisons (`read` < `write` < `exec`).
  int get rank => switch (this) {
    CapabilityTier.read => 0,
    CapabilityTier.write => 1,
    CapabilityTier.exec => 2,
  };

  /// The canonical wire string.
  String get wire => name;

  /// Parses a wire string, defaulting to [exec] (the safe, most-restrictive
  /// assumption for an unknown/untyped tool).
  static CapabilityTier fromWire(String? raw) => switch (raw) {
    'read' => CapabilityTier.read,
    'write' => CapabilityTier.write,
    'exec' => CapabilityTier.exec,
    _ => CapabilityTier.exec,
  };
}

/// The user's standing approval posture. Auto-approves every tier at or below
/// its ceiling; anything above prompts via the `ConfirmationPort`.
enum ApprovalMode {
  /// Auto-approve `read` only; prompt for `write` and `exec`. The default — it
  /// preserves CC's historical "mutating tools prompt" behaviour.
  alwaysAsk,

  /// Auto-approve `read` + `write`; prompt for `exec` only.
  write,

  /// Auto-approve everything. No prompts (the "trust this session" escape
  /// hatch). A tool that forces approval via [ToolApproval.override] still
  /// prompts.
  yolo;

  /// The highest tier this mode auto-approves.
  CapabilityTier get ceiling => switch (this) {
    ApprovalMode.alwaysAsk => CapabilityTier.read,
    ApprovalMode.write => CapabilityTier.write,
    ApprovalMode.yolo => CapabilityTier.exec,
  };

  /// Whether [tier] is auto-approved under this mode.
  bool approves(CapabilityTier tier) => tier.rank <= ceiling.rank;

  /// The canonical wire string.
  String get wire => switch (this) {
    ApprovalMode.alwaysAsk => 'always-ask',
    ApprovalMode.write => 'write',
    ApprovalMode.yolo => 'yolo',
  };

  /// Parses a wire string, defaulting to [alwaysAsk].
  static ApprovalMode fromWire(String? raw) => switch (raw) {
    'write' => ApprovalMode.write,
    'yolo' => ApprovalMode.yolo,
    _ => ApprovalMode.alwaysAsk,
  };
}

/// A tool's capability decision for a specific set of arguments.
///
/// Either a bare [tier], or a tier with a forced-prompt [override] (e.g. a
/// destructive argument pattern that should always confirm regardless of mode)
/// and an optional [reason] surfaced in the prompt.
class ToolApproval {
  /// Creates a [ToolApproval].
  const ToolApproval(this.tier, {this.override = false, this.reason});

  /// A `read`-tier approval (convenience).
  static const ToolApproval read = ToolApproval(CapabilityTier.read);

  /// A `write`-tier approval (convenience).
  static const ToolApproval write = ToolApproval(CapabilityTier.write);

  /// An `exec`-tier approval (convenience).
  static const ToolApproval exec = ToolApproval(CapabilityTier.exec);

  /// The capability tier.
  final CapabilityTier tier;

  /// When true, the gate prompts even if the mode would auto-approve [tier].
  final bool override;

  /// Optional human-readable reason shown in the confirmation prompt.
  final String? reason;
}

/// The resolved approval decision the gate acts on.
enum ApprovalDecision {
  /// Run without prompting.
  allow,

  /// Surface a confirmation prompt before running.
  prompt,

  /// Refuse outright.
  deny,
}

/// Resolves a [ToolApproval] against the active [ApprovalMode].
///
/// Pure and side-effect-free so it is trivially unit-testable. The gate
/// (`McpToolDispatcher`) calls this, then acts on the [ApprovalDecision].
ApprovalDecision resolveApproval(ToolApproval approval, ApprovalMode mode) {
  // yolo auto-approves everything unless the tool forces a prompt.
  if (mode == ApprovalMode.yolo) {
    return approval.override ? ApprovalDecision.prompt : ApprovalDecision.allow;
  }
  if (approval.override) {
    return ApprovalDecision.prompt;
  }
  return mode.approves(approval.tier)
      ? ApprovalDecision.allow
      : ApprovalDecision.prompt;
}
