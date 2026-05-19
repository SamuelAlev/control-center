import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';

/// An event emitted by the `AgentRegistry` whenever its roster changes.
///
/// Consumers (the work-aware roster UI, the dashboard, future peer-messaging)
/// subscribe to `AgentRegistry.changes` and react to these. Each event carries
/// the [ref] in its post-change state.
sealed class RegistryEvent {
  /// Creates a registry event for [ref].
  const RegistryEvent(this.ref);

  /// The agent this event concerns, in its post-change state.
  final AgentRef ref;
}

/// A new agent was registered.
class AgentRegistered extends RegistryEvent {
  /// Creates an [AgentRegistered] event.
  const AgentRegistered(super.ref);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentRegistered && ref == other.ref;

  @override
  int get hashCode => Object.hash(AgentRegistered, ref);

  @override
  String toString() => 'AgentRegistered(${ref.id})';
}

/// An agent's status changed (e.g. running → idle).
class AgentStatusChanged extends RegistryEvent {
  /// Creates an [AgentStatusChanged] event.
  const AgentStatusChanged(super.ref);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentStatusChanged && ref == other.ref;

  @override
  int get hashCode => Object.hash(AgentStatusChanged, ref);

  @override
  String toString() => 'AgentStatusChanged(${ref.id}, ${ref.status})';
}

/// An agent was removed from the registry (released / torn down).
class AgentRemoved extends RegistryEvent {
  /// Creates an [AgentRemoved] event.
  const AgentRemoved(super.ref);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AgentRemoved && ref == other.ref;

  @override
  int get hashCode => Object.hash(AgentRemoved, ref);

  @override
  String toString() => 'AgentRemoved(${ref.id})';
}
