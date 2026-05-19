/// The kind of domain entity referenced from a conversation via `#` tagging.
enum EntityRefType {
  /// A ticket / work item.
  ticket,

  /// A GitHub pull request.
  pullRequest,

  /// A recorded meeting.
  meeting;

  /// Parses a serialized [EntityRefType] name, or null if unrecognized.
  static EntityRefType? tryParse(String? raw) {
    for (final t in values) {
      if (t.name == raw) {
        return t;
      }
    }
    return null;
  }
}

/// A reference to a domain entity (ticket, pull request, or meeting) tagged
/// inside a conversation message via the composer's `#` trigger.
///
/// Stored on a message's `metadata['entityRefs']` and rendered as a
/// live-resolving chip beneath the message. Kept deliberately small and
/// extensible — a new [EntityRefType] (e.g. a news article) drops in without a
/// schema change.
class EntityRef {
  /// Creates an [EntityRef].
  const EntityRef({
    required this.type,
    required this.id,
    this.label,
    this.repoFullName,
  }) : assert(id != '', 'EntityRef id must not be empty');

  /// Builds an [EntityRef] from its JSON map, or null when the payload is not a
  /// recognizable reference (unknown type or empty id).
  static EntityRef? tryFromJson(Map<String, dynamic> json) {
    final type = EntityRefType.tryParse(json['type'] as String?);
    final id = json['id'] as String?;
    if (type == null || id == null || id.isEmpty) {
      return null;
    }
    return EntityRef(
      type: type,
      id: id,
      label: json['label'] as String?,
      repoFullName: json['repoFullName'] as String?,
    );
  }

  /// The kind of entity referenced.
  final EntityRefType type;

  /// The entity's identity: ticket id, meeting id, or PR number (as a string).
  final String id;

  /// Human-readable label captured at tag time — a display fallback while the
  /// live entity resolves, or if it can no longer be found.
  final String? label;

  /// `owner/repo` for [EntityRefType.pullRequest]; null otherwise. Needed to
  /// resolve a PR across repositories.
  final String? repoFullName;

  /// Serializes this reference to a JSON map for message metadata.
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'id': id,
        if (label != null) 'label': label,
        if (repoFullName != null) 'repoFullName': repoFullName,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityRef &&
          type == other.type &&
          id == other.id &&
          label == other.label &&
          repoFullName == other.repoFullName;

  @override
  int get hashCode => Object.hash(type, id, label, repoFullName);
}
