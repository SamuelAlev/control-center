/// The protocol family a runtime profile speaks — the wire/transport an agent
/// CLI is driven over.
enum ProtocolFamily {
  /// Claude's stream-json CLI protocol.
  claude('Claude'),

  /// Agent Client Protocol.
  acp('ACP'),

  /// The Pi agent CLI protocol.
  pi('Pi'),

  /// The Codex agent CLI protocol.
  codex('Codex'),

  /// A generic CLI invoked directly with no managed protocol.
  cli('CLI');

  /// Creates a [ProtocolFamily] with a display [label].
  const ProtocolFamily(this.label);

  /// Human-readable display label.
  final String label;

  /// Parses a stored value (case-insensitive), defaulting to [cli].
  static ProtocolFamily fromStorage(String? value) {
    if (value == null) {
      return ProtocolFamily.cli;
    }
    return ProtocolFamily.values
            .where((p) => p.name.toLowerCase() == value.toLowerCase())
            .firstOrNull ??
        ProtocolFamily.cli;
  }
}
