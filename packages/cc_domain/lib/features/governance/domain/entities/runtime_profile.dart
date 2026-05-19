import 'package:cc_domain/features/governance/domain/value_objects/protocol_family.dart';

/// A reusable runtime definition wrapping a protocol family, a CLI command and
/// fixed launch arguments. Agents register against a profile so the runtimes
/// that back them are configurable instead of hardcoded.
class RuntimeProfile {
  /// Creates a [RuntimeProfile].
  RuntimeProfile({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.protocolFamily = ProtocolFamily.cli,
    required this.command,
    this.fixedArgs = const [],
    this.description,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (name.isEmpty) {
      throw ArgumentError('Runtime profile name must not be empty');
    }
    if (command.isEmpty) {
      throw ArgumentError('Runtime profile command must not be empty');
    }
  }

  /// Unique profile identifier.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Display name.
  final String name;

  /// Protocol family the runtime speaks.
  final ProtocolFamily protocolFamily;

  /// The CLI command (executable) launched.
  final String command;

  /// Fixed launch arguments always passed to the command.
  final List<String> fixedArgs;

  /// Optional description.
  final String? description;

  /// When created.
  final DateTime createdAt;

  /// When last updated.
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  RuntimeProfile copyWith({
    String? id,
    String? workspaceId,
    String? name,
    ProtocolFamily? protocolFamily,
    String? command,
    List<String>? fixedArgs,
    String? description,
    bool removeDescription = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RuntimeProfile(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      protocolFamily: protocolFamily ?? this.protocolFamily,
      command: command ?? this.command,
      fixedArgs: fixedArgs ?? this.fixedArgs,
      description: removeDescription ? null : (description ?? this.description),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimeProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          name == other.name &&
          protocolFamily == other.protocolFamily &&
          command == other.command &&
          _listEquals(fixedArgs, other.fixedArgs) &&
          description == other.description &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    name,
    protocolFamily,
    command,
    Object.hashAll(fixedArgs),
    description,
    createdAt,
    updatedAt,
  );

  static bool _listEquals(List<String> a, List<String> b) {
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
}
