/// Normalized swarm definition types.
///
/// A *swarm* is a named set of agents that cooperate on a workspace under one
/// of three coordination modes. These are the camelCase, defaults-applied
/// shapes produced after parsing a swarm config; the parsing/YAML layer is
/// intentionally out of scope here.
///
/// Ported from oh-my-pi `swarm-extension/src/swarm/schema.ts` (normalized
/// `SwarmAgent` / `SwarmDefinition` / `SwarmMode`).
library;

/// How a swarm's agents are coordinated.
enum SwarmMode {
  /// Agents form a chain: each stage hands off to the next. The only mode
  /// where `targetCount` may differ from `1` (fan-out copies of the pipeline).
  pipeline,

  /// Agents run concurrently with no implicit ordering.
  parallel,

  /// Agents run one after another in declaration order.
  sequential,
}

/// A single agent within a [SwarmDefinition].
///
/// Dependencies are expressed two ways:
///
/// * [waitsFor] — names of agents this agent must wait on before it runs.
/// * [reportsTo] — names of agents this agent reports its results to; this
///   *inverts* into a dependency, the target depends on this reporter (see
///   `buildDependencyGraph`).
class SwarmAgent {
  /// Creates a [SwarmAgent].
  ///
  /// [name], [role], and [task] must all be non-empty. [reportsTo] and
  /// [waitsFor] default to empty lists.
  SwarmAgent({
    required this.name,
    required this.role,
    required this.task,
    this.extraContext,
    this.reportsTo = const <String>[],
    this.waitsFor = const <String>[],
    this.model,
  })  : assert(name.isNotEmpty, 'SwarmAgent.name must not be empty'),
        assert(role.isNotEmpty, 'SwarmAgent.role must not be empty'),
        assert(task.isNotEmpty, 'SwarmAgent.task must not be empty');

  /// Stable identifier of this agent within its swarm.
  final String name;

  /// The agent's persona / role label.
  final String role;

  /// The work this agent is assigned.
  final String task;

  /// Optional extra context appended to the agent's brief.
  final String? extraContext;

  /// Names of agents this agent reports its results to. Each such relationship
  /// inverts into a dependency: the target depends on this agent.
  final List<String> reportsTo;

  /// Names of agents this agent must wait on before running.
  final List<String> waitsFor;

  /// Optional per-agent model override. Must be non-empty when provided
  /// (enforced by `validateSwarmDefinition`, not by the constructor).
  final String? model;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwarmAgent &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          role == other.role &&
          task == other.task &&
          extraContext == other.extraContext &&
          model == other.model &&
          _listEquals(reportsTo, other.reportsTo) &&
          _listEquals(waitsFor, other.waitsFor);

  @override
  int get hashCode => Object.hash(
        name,
        role,
        task,
        extraContext,
        model,
        Object.hashAll(reportsTo),
        Object.hashAll(waitsFor),
      );

  @override
  String toString() => 'SwarmAgent($name, role=$role)';
}

/// A normalized, validated-shape swarm: a named group of [SwarmAgent]s on a
/// single workspace, coordinated under one [SwarmMode].
///
/// [agentOrder] preserves declaration order so that pipeline / sequential
/// modes with no explicit dependencies can be chained deterministically (see
/// `buildDependencyGraph`).
class SwarmDefinition {
  /// Creates a [SwarmDefinition].
  ///
  /// [name] and [workspace] must be non-empty, and [agentOrder] must list
  /// exactly the keys of [agents] (so the two stay in sync).
  ///
  /// [targetCount] bounds and mode constraints are *not* asserted here: they
  /// are user-facing semantic errors surfaced by `validateSwarmDefinition`, so
  /// an out-of-range value must remain constructible rather than crash.
  SwarmDefinition({
    required this.name,
    required this.workspace,
    required this.mode,
    required this.agents,
    required this.agentOrder,
    this.targetCount = 1,
    this.model,
  })  : assert(name.isNotEmpty, 'SwarmDefinition.name must not be empty'),
        assert(
          workspace.isNotEmpty,
          'SwarmDefinition.workspace must not be empty',
        ),
        assert(
          agentOrder.length == agents.length,
          'agentOrder must list every agent exactly once',
        );

  /// Human-readable swarm name.
  final String name;

  /// The workspace this swarm operates in.
  final String workspace;

  /// Coordination mode.
  final SwarmMode mode;

  /// Number of copies of the swarm to spawn. Only meaningfully `!= 1` in
  /// [SwarmMode.pipeline] (enforced by `validateSwarmDefinition`).
  final int targetCount;

  /// Optional swarm-level default model. Must be non-empty when provided
  /// (enforced by `validateSwarmDefinition`, not by the constructor).
  final String? model;

  /// The agents keyed by name.
  final Map<String, SwarmAgent> agents;

  /// Declaration order of agent names, preserved for implicit sequencing.
  final List<String> agentOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwarmDefinition &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          workspace == other.workspace &&
          mode == other.mode &&
          targetCount == other.targetCount &&
          model == other.model &&
          _listEquals(agentOrder, other.agentOrder) &&
          _shallowAgentsEqual(agents, other.agents);

  @override
  int get hashCode => Object.hash(
        name,
        workspace,
        mode,
        targetCount,
        model,
        Object.hashAll(agentOrder),
        agents.length,
      );

  @override
  String toString() =>
      'SwarmDefinition($name, $mode, agents=${agentOrder.length})';
}

/// Whether two ordered string lists are element-wise equal.
bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// A shallow equality over the agents map: same keys mapping to equal agents.
bool _shallowAgentsEqual(
  Map<String, SwarmAgent> a,
  Map<String, SwarmAgent> b,
) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
