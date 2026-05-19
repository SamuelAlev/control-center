/// Kind of attachment.
enum AttachmentKind {
  /// Image file (png, jpg, gif, webp).
  image,
  /// Generic file attachment.
  file,
}

/// An attachment on a message — an image or file reference.
class MessageAttachment {
  const MessageAttachment({
    required this.id,
    required this.path,
    required this.name,
    required this.kind,
    this.size,
    this.order = 0,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) =>
      MessageAttachment(
        id: json['id'] as String,
        path: json['path'] as String,
        name: json['name'] as String,
        kind: json['kind'] == 'image'
            ? AttachmentKind.image
            : AttachmentKind.file,
        size: json['size'] as int?,
        order: json['order'] as int? ?? 0,
      );

  /// Unique identifier.
  final String id;

  /// Absolute or relative path to the file on disk.
  final String path;

  /// Display name of the file.
  final String name;

  /// Whether this is an image or file.
  final AttachmentKind kind;

  /// File size in bytes, if known.
  final int? size;

  /// Ordering within the message's attachments.
  final int order;

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'name': name,
        'kind': kind.name,
        if (size != null) 'size': size,
        'order': order,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAttachment &&
          id == other.id &&
          path == other.path &&
          name == other.name &&
          kind == other.kind &&
          size == other.size &&
          order == other.order;

  @override
  int get hashCode => Object.hash(id, path, name, kind, size, order);
}
