import 'dart:convert';

/// What a provisioning step is doing, so clients can render a specific,
/// localized label instead of a generic "preparing" spinner.
enum ChannelProvisioningStepKind {
  /// Materializing a repo worktree on its conversation branch.
  repo,

  /// Fetching + checking out a pull request's head in a repo worktree.
  prCheckout,

  /// Building an agent's overlay cwd (AGENTS.md + skills + `.mcp.json`).
  agent;

  /// Parses the serialized kind. Unknown / null → null (callers drop the step
  /// rather than mislabeling it).
  static ChannelProvisioningStepKind? fromName(String? raw) {
    for (final k in values) {
      if (k.name == raw) {
        return k;
      }
    }
    return null;
  }
}

/// The granular, transient step channel-workspace provisioning is currently
/// on ("cloning repo X", "setting up agent Y"), surfaced live to clients
/// while the channel's `provisioningStatus` is `provisioning`.
///
/// Stored as a JSON string in the `channels.provisioning_step` column and
/// carried on the channel wire DTO as `provisioning_step`. The column is
/// cleared whenever the status leaves `provisioning`, so a non-null step
/// only ever accompanies an in-flight provision. The [subject] is a display
/// name (repo or agent), never an id — clients interpolate it verbatim.
class ChannelProvisioningStep {
  /// Creates a [ChannelProvisioningStep].
  const ChannelProvisioningStep({required this.kind, this.subject = ''});

  /// What this step is doing.
  final ChannelProvisioningStepKind kind;

  /// The repo or agent display name the step acts on ('' when not applicable).
  final String subject;

  /// Parses the database/wire serialization. Null, empty, or malformed input
  /// (including an unknown kind) → null; provisioning progress is decorative,
  /// so it degrades to the generic label rather than throwing.
  static ChannelProvisioningStep? fromDbValue(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final kind = ChannelProvisioningStepKind.fromName(
        decoded['kind'] as String?,
      );
      if (kind == null) {
        return null;
      }
      return ChannelProvisioningStep(
        kind: kind,
        subject: decoded['subject'] as String? ?? '',
      );
    } on FormatException {
      return null;
    }
  }

  /// Serializes for the `channels.provisioning_step` column and the wire.
  String toDbValue() => jsonEncode({
    'kind': kind.name,
    if (subject.isNotEmpty) 'subject': subject,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelProvisioningStep &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          subject == other.subject;

  @override
  int get hashCode => Object.hash(kind, subject);

  @override
  String toString() => 'ChannelProvisioningStep(${kind.name}, $subject)';
}
