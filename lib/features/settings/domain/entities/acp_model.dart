/// A model advertised by an ACP-compatible agent runner.
///
/// In a full ACP integration these come from the `availableModels` field of
/// the adapter's `session/new` response (Agent Client Protocol). Until the
/// ACP transport is wired we ship a curated list keyed by adapter id.
class AcpModel {
  /// Creates a new [AcpModel].
  const AcpModel({required this.id, required this.name, this.description});

  /// Unique model identifier (e.g. 'anthropic/claude-opus-4-7').
  final String id;
  /// Human-readable model name.
  final String name;
  /// Optional model description.
  final String? description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcpModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

