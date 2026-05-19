import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_domain/features/dispatch/domain/registry/registry_event.dart';

/// Input for [AgentRegistry.register].
class RegisterAgentInput {
  /// Creates a [RegisterAgentInput].
  ///
  /// [workspaceId] is required and must be non-empty: the registry is
  /// process-global and spans every open workspace, so workspace is the
  /// isolation boundary for every roster / peer query.
  const RegisterAgentInput({
    required this.id,
    required this.displayName,
    required this.workspaceId,
    this.kind = AgentKind.main,
    this.status = AgentStatus.running,
    this.parentId,
    this.conversationId,
    this.dispatchId,
    this.sessionFile,
  });

  /// Stable agent id.
  final String id;

  /// One-line display label. Normalized via `oneLineLabel` by the registry.
  final String displayName;

  /// Owning workspace — the isolation boundary. Must be non-empty.
  final String workspaceId;

  /// Runtime role (defaults to [AgentKind.main]).
  final AgentKind kind;

  /// Initial status (defaults to [AgentStatus.running]).
  final AgentStatus status;

  /// Id of the spawning agent, if any.
  final String? parentId;

  /// Conversation / channel this agent is working in, if any.
  final String? conversationId;

  /// Id of the live dispatch backing this agent, if already known.
  final String? dispatchId;

  /// Persisted session path, retained for later revival.
  final String? sessionFile;
}

/// Process-global registry of agents — the main session plus every subagent —
/// keyed by stable id.
///
/// Tracks each agent's [AgentStatus] and live work so peers can be addressed by
/// id and a work-aware roster can render who is alive and what they are doing.
/// Sessions are registered explicitly at dispatch; finished agents stay
/// registered as [AgentStatus.idle] (or [AgentStatus.parked] once their
/// dispatch is released) and are only dropped on explicit [unregister].
///
/// The registry is a single process-wide instance shared by the dispatch
/// service, MCP tools, and the UI, so a concrete implementation exposes a
/// global accessor rather than being constructed per call site.
///
/// ## Workspace isolation
///
/// The registry spans every open workspace, so it is workspace-scoped data:
/// every roster / peer query MUST be filtered by `workspaceId`. Use
/// [listForWorkspace] / [watchWorkspaceRoster] for rosters and [listVisibleTo]
/// for peer discovery — all three are workspace-scoped. The unscoped [list] is
/// CROSS-WORKSPACE BY DESIGN and reserved for the all-workspaces dashboard /
/// diagnostics; never use it to answer a workspace-scoped question.
abstract interface class AgentRegistry {
  /// Registers a new agent, or refreshes an already-registered one (status,
  /// dispatch, activity) while preserving its original `createdAt`. Returns the
  /// resulting [AgentRef]. Emits [AgentRegistered] (new) or [AgentStatusChanged]
  /// (refresh).
  AgentRef register(RegisterAgentInput input);

  /// Transitions [id]'s status. No-op when unknown or unchanged. Activity is
  /// cleared on any non-running status (stale work must never linger in the
  /// roster). Emits [AgentStatusChanged].
  void setStatus(String id, AgentStatus status);

  /// Records a short activity gist for the work-aware roster. Only a running
  /// agent has current work, so a heartbeat for any other status is dropped.
  /// The gist is normalized to one bounded line, so untrusted intent text can
  /// neither break the roster nor smuggle terminal escapes. Display-only and
  /// read on demand, so it emits no event — keeping the per-tool-call update
  /// rate off the listener path.
  void setActivity(String id, String activity);

  /// Attaches a live dispatch to [id] (revive / new run). Bumps `lastActivity`;
  /// emits no event (the accompanying [setStatus] does).
  void attachDispatch(String id, String dispatchId, {String? sessionFile});

  /// Detaches the live dispatch from [id], leaving the [AgentRef] in place.
  void detachDispatch(String id);

  /// Removes [id] from the registry. No-op when unknown. Emits [AgentRemoved].
  void unregister(String id);

  /// Returns the ref for [id], or null when unknown.
  AgentRef? get(String id);

  /// Every tracked agent across every workspace.
  ///
  /// CROSS-WORKSPACE BY DESIGN: spans all workspaces, for the all-workspaces
  /// dashboard / diagnostics only. For a workspace-scoped roster use
  /// [listForWorkspace]; for peers use [listVisibleTo].
  List<AgentRef> list();

  /// Every tracked agent owned by [workspaceId]. Workspace-scoped.
  List<AgentRef> listForWorkspace(String workspaceId);

  /// Every alive (running | idle) peer the agent [id] can address: same
  /// workspace, excluding [id] itself and excluding read-only advisors. Returns
  /// an empty list when [id] is unknown. Workspace-scoped — an agent never sees
  /// peers from another workspace.
  List<AgentRef> listVisibleTo(String id);

  /// A broadcast stream of every roster change, across all workspaces.
  ///
  /// CROSS-WORKSPACE BY DESIGN: filter by `ref.workspaceId` before acting on an
  /// event in a workspace-scoped consumer. For a ready-made workspace-scoped
  /// view use [watchWorkspaceRoster].
  Stream<RegistryEvent> get changes;

  /// A broadcast stream of [workspaceId]'s roster: the current scoped snapshot
  /// is emitted immediately, then a fresh snapshot on every relevant change.
  /// Workspace-scoped — the primary "onChange drives UI" surface.
  Stream<List<AgentRef>> watchWorkspaceRoster(String workspaceId);
}
