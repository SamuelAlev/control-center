/// The kind of actor behind a [Principal].
enum PrincipalType {
  /// A human user (`users` table).
  user,

  /// An AI agent (`agents` table).
  agent;

  /// The value persisted in the database and sent over the wire.
  String get wireName => name;

  /// Parses a stored/wire value; returns null for unknown values.
  static PrincipalType? fromWire(String? value) {
    for (final type in PrincipalType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return null;
  }
}

/// The actor performing an action: a human user or an agent.
///
/// Humans and agents are co-equal participants; everything that records "who
/// did this" (messages, tickets, reviews, plans, run logs, audit entries)
/// resolves through a [Principal] instead of a bare id, so attribution never
/// collapses N humans into one sentinel.
///
/// Wire format is `user:<id>` / `agent:<id>` (see [wire] and [parse]).
sealed class Principal {
  const Principal();

  /// Builds the principal for [type] + [id].
  factory Principal.of(PrincipalType type, String id) => switch (type) {
    PrincipalType.user => UserPrincipal(id),
    PrincipalType.agent => AgentPrincipal(id),
  };

  /// The bare identifier (user id or agent id).
  String get id;

  /// Which kind of actor this is.
  PrincipalType get type;

  /// Whether this principal is a human user.
  bool get isUser => type == PrincipalType.user;

  /// Whether this principal is an agent.
  bool get isAgent => type == PrincipalType.agent;

  /// Compact wire encoding: `user:<id>` or `agent:<id>`.
  String get wire => '${type.wireName}:$id';

  /// Parses a [wire]-encoded principal; returns null when [value] is null,
  /// malformed, or names an unknown type.
  static Principal? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    final sep = value.indexOf(':');
    if (sep <= 0 || sep == value.length - 1) {
      return null;
    }
    final type = PrincipalType.fromWire(value.substring(0, sep));
    if (type == null) {
      return null;
    }
    return Principal.of(type, value.substring(sep + 1));
  }

  /// Parses a [wire]-encoded principal; throws [FormatException] on malformed
  /// input.
  static Principal parse(String value) {
    final parsed = tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid principal encoding: $value');
    }
    return parsed;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Principal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => Object.hash(runtimeType, id, type);

  @override
  String toString() => wire;
}

/// A human user acting through an authenticated device.
class UserPrincipal extends Principal {
  /// Creates a [UserPrincipal] for [id].
  const UserPrincipal(this.id) : assert(id != '', 'userId must not be empty');

  @override
  final String id;

  @override
  PrincipalType get type => PrincipalType.user;
}

/// An agent acting on its own behalf (or on behalf of a requesting user,
/// which is recorded separately where it matters, e.g. git authorship).
class AgentPrincipal extends Principal {
  /// Creates an [AgentPrincipal] for [id].
  const AgentPrincipal(this.id) : assert(id != '', 'agentId must not be empty');

  @override
  final String id;

  @override
  PrincipalType get type => PrincipalType.agent;
}
