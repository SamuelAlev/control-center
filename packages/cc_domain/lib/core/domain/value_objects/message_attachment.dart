/// What a person attached to a message, as recorded on its metadata.
///
/// Attachments are the one part of a message whose bytes do not live in the
/// row. `metadata['attachments']` carries a list of these; each entry names
/// where the content actually is (`path`) and what the sentence calls it
/// (`name` — the `@[file:<name>]` reference the prompt points at).
///
/// The list is free-form JSON written by a client, so every read of it goes
/// through `MessageAttachment.attachmentsFromMetadata`, which skips a malformed
/// entry rather than throwing: one bad row would otherwise blank a whole
/// transcript.
library;

/// Reference prefix that marks a [MessageAttachment.path] as content-addressed
/// storage on the server rather than a path on somebody's disk.
const String _blobRefScheme = 'blob:sha256:';

final RegExp _sha256Hex = RegExp(r'^[0-9a-f]{64}$');

/// Kind of attachment.
enum AttachmentKind {
  /// Image file (png, jpg, gif, webp).
  image,

  /// Generic file attachment.
  file,
}

/// An attachment on a message — an image or file reference.
class MessageAttachment {
  /// Creates a [MessageAttachment] with required fields.

  const MessageAttachment({
    required this.id,
    required this.path,
    required this.name,
    required this.kind,
    this.size,
    this.order = 0,
    this.mediaType,
    this.localPath,
  });

  /// Deserializes from a JSON map produced by [toJson].
  ///
  /// Strict: throws on a map missing `id`/`path`/`name`. Use [tryFromJson] for
  /// client-written metadata, where a partial entry is a thing that happens.

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
        mediaType: json['mediaType'] as String?,
        localPath: json['localPath'] as String?,
      );

  /// Parses one metadata entry, or null when it carries no usable content
  /// pointer.
  ///
  /// [index] supplies the fallbacks a hand-written or older entry may not
  /// carry: its position becomes its [order], and its identity when no `id` was
  /// written. Nothing here throws — the caller is walking a list from the wire.
  static MessageAttachment? tryFromJson(Object? raw, {int index = 0}) {
    if (raw is! Map) {
      return null;
    }
    final path = raw['path'];
    if (path is! String || path.isEmpty) {
      return null;
    }
    final id = raw['id'];
    final name = raw['name'];
    final size = raw['size'];
    final order = raw['order'];
    final mediaType = raw['mediaType'];
    final localPath = raw['localPath'];
    return MessageAttachment(
      id: id is String && id.isNotEmpty ? id : 'attachment-$index',
      path: path,
      name: name is String && name.isNotEmpty ? name : 'attachment',
      kind: raw['kind'] == 'image' ? AttachmentKind.image : AttachmentKind.file,
      size: size is int ? size : null,
      order: order is int ? order : index,
      mediaType: mediaType is String && mediaType.isNotEmpty ? mediaType : null,
      localPath: localPath is String && localPath.isNotEmpty ? localPath : null,
    );
  }

  /// Every attachment on [metadata], in send order.
  ///
  /// The one reader of `metadata['attachments']`. Both ends use it — the
  /// transcript to draw the strip, the dispatch path to put the bytes in front
  /// of an agent — so there is a single answer to "what did this message carry".
  static List<MessageAttachment> attachmentsFromMetadata(
    Map<String, dynamic>? metadata,
  ) {
    final raw = metadata?['attachments'];
    if (raw is! List) {
      return const [];
    }
    final out = <MessageAttachment>[];
    for (var i = 0; i < raw.length; i++) {
      final parsed = tryFromJson(raw[i], index: i);
      if (parsed != null) {
        out.add(parsed);
      }
    }
    out.sort((a, b) => a.order.compareTo(b.order));
    return out;
  }

  /// Unique identifier.
  final String id;

  /// Where the content lives.
  ///
  /// Normally a `blob:sha256:<hex>` reference to bytes on the server, which is
  /// the only pointer a later reader — tomorrow, on another device, or another
  /// member — can resolve. A path on somebody's disk appears only in the
  /// degraded case (too large to carry, or a failed upload); [isUploaded] is
  /// what tells the two apart.
  final String path;

  /// Display name of the file — the `@[file:<name>]` reference the message
  /// text points at, so a caption and the sentence agree.
  final String name;

  /// Whether this is an image or file.
  final AttachmentKind kind;

  /// File size in bytes, if known.
  final int? size;

  /// Ordering within the message's attachments.
  final int order;

  /// MIME type as the sending composer resolved it, when it recorded one.
  final String? mediaType;

  /// The sender's own path, kept as a hint for an agent that DOES share this
  /// filesystem. Never what a preview resolves from — the sending device is
  /// routinely not the machine anything later runs on.
  final String? localPath;

  /// Whether this is a picture rather than some other file.
  bool get isImage => kind == AttachmentKind.image;

  /// Whether [path] points at the server rather than at the sender's disk.
  bool get isUploaded => blobHash != null;

  /// The sha256 hex behind a `blob:sha256:<hex>` [path], or null when [path] is
  /// not one.
  ///
  /// The hash becomes a filename on the server, so a value that is not 64
  /// lowercase hex characters is refused here rather than at the call site that
  /// forgets.
  String? get blobHash {
    if (!path.startsWith(_blobRefScheme)) {
      return null;
    }
    final hash = path.substring(_blobRefScheme.length);
    return _sha256Hex.hasMatch(hash) ? hash : null;
  }

  /// Serializes to a JSON-compatible map.

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'name': name,
    'kind': kind.name,
    if (size != null) 'size': size,
    'order': order,
    if (mediaType != null) 'mediaType': mediaType,
    if (localPath != null) 'localPath': localPath,
  };

  /// Structural equality based on every field.

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAttachment &&
          id == other.id &&
          path == other.path &&
          name == other.name &&
          kind == other.kind &&
          size == other.size &&
          order == other.order &&
          mediaType == other.mediaType &&
          localPath == other.localPath;

  /// Hash based on all fields.

  @override
  int get hashCode =>
      Object.hash(id, path, name, kind, size, order, mediaType, localPath);
}
