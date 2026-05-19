/// Severity of a confirmation request, used by the UI to colour the modal.
enum ConfirmationSeverity {
  /// Read-only operation that's still worth flagging (e.g. network egress
  /// to a non-allowlisted host).
  info,

  /// Mutates the workspace or sends a message externally.
  warning,

  /// Destructive (force-push, delete branch, `rm -rf`, package install).
  destructive,
}

/// What kind of privileged operation is being confirmed.
enum ConfirmationKind {
  /// A shell command (e.g. `git push`, `npm install`).
  command,

  /// A file write outside the allowed roots.
  fileWrite,

  /// Network egress to a non-allowlisted host.
  networkEgress,

  /// An agent requesting a capability escalation.
  capabilityEscalation,
}

/// How long a remembered decision should persist.
enum RememberScope {
  /// Single use — always re-prompt.
  once,

  /// Current session only (in-memory, never persisted).
  session,

  /// All future invocations in this workspace.
  workspace,

  /// All future invocations for this specific agent.
  agent,
}

/// Request payload surfaced to the user for inline approval of a privileged
/// agent action.
class ConfirmationRequest {
  /// Creates a new [ConfirmationRequest].
  const ConfirmationRequest({
    required this.spaceId,
    required this.title,
    required this.detail,
    this.severity = ConfirmationSeverity.warning,
    this.command,
    this.kind = ConfirmationKind.command,
    this.rememberChoice,
    this.fingerprint,
    this.workspaceId,
    this.actionClasses = const [],
    this.agentId,
    this.constraintJson,
  });

  /// The SPACE the request originated from — the container, not one of its
  /// conversations. Every producer supplies a space id and the phone narrows
  /// on one, so naming it after a conversation only invited the two ids to be
  /// mixed up now that they are different values.
  final String spaceId;

  /// The workspace the action belongs to. Authorizes the remote-approval
  /// surface: `confirmation.respond` requires the responding user to be a
  /// member of this workspace and `confirmation.watchPending` filters each
  /// snapshot to the subscriber's own workspaces. Null only on hosts without
  /// identity wiring (single-user); production always sets it.
  final String? workspaceId;

  /// Short headline ("Push to main", "Install package").
  final String title;

  /// Long-form description of what the agent is about to do.
  final String detail;

  /// Severity tier.
  final ConfirmationSeverity severity;

  /// Verbatim command the agent is about to run, if applicable.
  final String? command;

  /// What kind of operation is being confirmed.
  final ConfirmationKind kind;

  /// When non-null, the UI offers a "remember this decision" dropdown
  /// scoped to this value. Destructive-severity requests never set this
  /// (the UI hides the dropdown).
  final RememberScope? rememberChoice;

  /// Canonical fingerprint of the matched command (exact token sequence).
  /// Used to look up / persist remembered decisions.
  final String? fingerprint;

  /// The effect classes that PROMPTED, as wire names.
  ///
  /// Carried so answering with "remember this" can materialize a real policy
  /// rule for exactly those effects. Without them the remember affordance had
  /// nothing to write, which is why `rememberChoice` was set on every request
  /// and read by nobody.
  final List<String> actionClasses;

  /// The agent whose action this is (scopes an `agent`-scoped remember).
  final String? agentId;

  /// The argument constraint the approved action matched, as stored JSON.
  ///
  /// This is what makes a standing approval NARROW: remembering "yes" to a
  /// push to `feature/x` grants pushes to `feature/*`, not to `main`.
  final String? constraintJson;
}

/// Wire DTO for a pending agent-action confirmation — the
/// `confirmation.watchPending` snapshot entry + the payload the phone renders.
/// Mirrors the host's `pendingConfirmationToWire` shape.
class ConfirmationRequestDto {
  /// Creates a [ConfirmationRequestDto].
  const ConfirmationRequestDto({
    required this.id,
    required this.spaceId,
    required this.title,
    required this.detail,
    required this.severity,
    this.command,
    required this.createdAt,
    this.workspaceId,
    this.rememberScope,
    this.actionClasses = const [],
  });

  /// Factory from the wire map.
  factory ConfirmationRequestDto.fromJson(Map<String, dynamic> json) =>
      ConfirmationRequestDto(
        id: json['id'] as String,
        spaceId: json['space_id'] as String? ?? '',
        workspaceId: json['workspace_id'] as String?,
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        severity: json['severity'] as String? ?? 'warning',
        command: json['command'] as String?,
        createdAt: json['created_at'] as String? ?? '',
        rememberScope: json['remember_scope'] as String?,
        actionClasses: [
          for (final c in (json['action_classes'] as List? ?? const []))
            c.toString(),
        ],
      );

  /// Stable id echoed back in `confirmation.respond`.
  final String id;

  /// The space the request originated from.
  final String spaceId;

  /// The workspace the request belongs to, when the host knew one.
  ///
  /// `confirmation.watchPending` is host-global (the server filters it to
  /// workspaces the subscriber belongs to, but does not narrow further), so a
  /// workspace-scoped surface needs this to tell "an agent in THIS project is
  /// stuck" from "some agent somewhere is". Null on a request the dispatch
  /// stack raised without one — treated as belonging to whatever workspace is
  /// being viewed rather than hidden, because an unattributable blocked agent
  /// still blocks.
  final String? workspaceId;

  /// Short headline ("Push to main").
  final String title;

  /// Long-form description of what the agent is about to do.
  final String detail;

  /// Severity tier name (`info` / `warning` / `destructive`).
  final String severity;

  /// Verbatim command, when applicable.
  final String? command;

  /// ISO-8601 creation timestamp.
  final String createdAt;

  /// The scope a "remember this decision" answer would apply at, or null when
  /// this request is not rememberable (the server decides).
  final String? rememberScope;

  /// The effect classes that prompted, for the remember affordance's label.
  final List<String> actionClasses;

  /// Whether the responder may turn this into a standing approval.
  ///
  /// A destructive request never offers it: "don't ask me again" is the wrong
  /// affordance in front of an irreversible action.
  bool get isRememberable =>
      rememberScope != null && actionClasses.isNotEmpty && severity != 'destructive';
}

/// Port used by sandbox hooks to interrupt an in-flight agent and ask the
/// user to approve a destructive operation.
abstract interface class ConfirmationPort {
  /// Surfaces [request] in the UI. Resolves once the user accepts or denies.
  /// Returns true on accept, false on deny / timeout.
  Future<bool> requestApproval(ConfirmationRequest request);
}
