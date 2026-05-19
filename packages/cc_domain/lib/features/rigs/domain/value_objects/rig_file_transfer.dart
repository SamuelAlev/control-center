import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';

/// One file on its way INTO a guest: a name and its bytes.
///
/// The name is the only thing the caller supplies about where it lands. There
/// is deliberately no destination path: a host that could name the target
/// could write `/home/cc/.ssh/authorized_keys` or `/usr/local/bin/cc-guest-agent`
/// into a machine an agent then drives. The transfer picks the directory (one
/// per rig, per surface) and [sanitizedName] decides the leaf.
class RigFilePayload {
  /// Creates a [RigFilePayload].
  const RigFilePayload({
    required this.name,
    required this.bytes,
    this.mediaType,
  });

  /// The file's name as the host knew it. Untrusted: it comes from a drop,
  /// which is to say from whatever the user dragged, which is to say from
  /// anywhere.
  final String name;

  /// The contents.
  final Uint8List bytes;

  /// MIME type when the host knew one.
  final String? mediaType;

  /// How big it is.
  int get sizeBytes => bytes.length;

  /// The largest single file the transfer carries.
  ///
  /// A drop is an interactive gesture whose bytes are held whole in memory on
  /// both sides and base64'd in between. Past this size the honest answer is
  /// "use the worktree sync", not a request that quietly consumes a gigabyte
  /// of the server's heap.
  static const int maxFileBytes = 256 * 1024 * 1024;

  /// The largest a single drop may be in total.
  static const int maxTotalBytes = 512 * 1024 * 1024;

  /// The most files one drop may carry. A dragged FOLDER can expand to
  /// thousands of entries, and a per-file round trip through the guest makes
  /// that a several-minute hang with no way to stop it.
  static const int maxFiles = 64;

  /// [name] reduced to something safe to use as a leaf inside the guest's
  /// drop directory.
  ///
  /// Path separators, `..` and control characters are the whole point: the
  /// name reaches a shell command line inside the guest, and `../../.ssh/`
  /// prefixed to it would escape the directory the transfer chose. What is
  /// left is a plain leaf name, or `dropped-file` when nothing usable
  /// survives (an empty name would produce a path ending in `/`).
  String get sanitizedName {
    final leaf = basenameOfGuestPath(name.replaceAll(r'\', '/'));
    final cleaned = leaf.runes
        // C0 controls and DEL. A newline in a filename ends a shell line.
        .where((r) => r > 0x1F && r != 0x7F)
        .map(String.fromCharCode)
        .join()
        .replaceAll('/', '_')
        .trim();
    if (cleaned.isEmpty ||
        cleaned == '.' ||
        cleaned == '..' ||
        cleaned.startsWith('..')) {
      return 'dropped-file';
    }
    // Long names are a filesystem error (255 bytes on ext4), not a security
    // issue — truncate the STEM so the extension, which decides how the guest
    // opens it, survives.
    if (cleaned.length <= 200) {
      return cleaned;
    }
    final dot = cleaned.lastIndexOf('.');
    if (dot <= 0 || cleaned.length - dot > 16) {
      return cleaned.substring(0, 200);
    }
    final ext = cleaned.substring(dot);
    return '${cleaned.substring(0, 200 - ext.length)}$ext';
  }
}

/// What a drop asked for, beyond the bytes themselves.
///
/// [x] and [y] are guest pixels and are what separates a real DROP from a
/// copy: a browser page with a dropzone needs the event delivered at a point,
/// and delivering it at (0, 0) hits the wrong element every time. They are
/// null for a terminal, which has no coordinate space, and may be null for a
/// desktop, where landing the files in a folder is the honest behaviour.
class RigDropRequest {
  /// Creates a [RigDropRequest].
  const RigDropRequest({required this.files, this.x, this.y});

  /// The files being dropped.
  final List<RigFilePayload> files;

  /// Guest-pixel x of the drop point, when there is one.
  final int? x;

  /// Guest-pixel y of the drop point.
  final int? y;

  /// Whether the drop names a point in the guest's coordinate space.
  bool get hasPoint => x != null && y != null;

  /// The total size of the drop.
  int get totalBytes => files.fold(0, (sum, f) => sum + f.sizeBytes);

  /// Why this drop cannot be performed, or null when it can.
  ///
  /// Validated as a WHOLE before a single byte is written: transferring the
  /// first three files of a five-file drop and then failing leaves a guest
  /// directory that looks like a successful drop and is not one.
  String? get rejection {
    if (files.isEmpty) {
      return 'Nothing to drop: the payload carries no files.';
    }
    if (files.length > RigFilePayload.maxFiles) {
      return 'Too many files: ${files.length} (the limit is '
          '${RigFilePayload.maxFiles} per drop). Drop a folder as an archive '
          'instead.';
    }
    for (final f in files) {
      if (f.sizeBytes > RigFilePayload.maxFileBytes) {
        return '"${f.sanitizedName}" is ${_mb(f.sizeBytes)}, over the '
            '${_mb(RigFilePayload.maxFileBytes)} per-file limit for a drop.';
      }
    }
    if (totalBytes > RigFilePayload.maxTotalBytes) {
      return 'The drop is ${_mb(totalBytes)}, over the '
          '${_mb(RigFilePayload.maxTotalBytes)} limit.';
    }
    return null;
  }

  static String _mb(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(bytes < 10 * 1024 * 1024 ? 1 : 0)} MB';
}

/// Where a drop's files landed, and whether the guest was told about them.
class RigDropResult {
  /// Creates a [RigDropResult].
  const RigDropResult({
    required this.files,
    required this.summary,
    this.deliveredAsDrop = false,
    this.isError = false,
  });

  /// A failed drop, with the reason written for whoever asked.
  factory RigDropResult.error(String message) =>
      RigDropResult(files: const [], summary: message, isError: true);

  /// The files as they now exist inside the guest.
  final List<RigGuestFile> files;

  /// One line describing what happened, shown in a toast and recorded in the
  /// action log.
  final String summary;

  /// Whether the guest received a real drop EVENT at the requested point (a
  /// page's dropzone fired), as opposed to the files merely being placed in a
  /// folder and offered on the clipboard.
  ///
  /// Stated rather than assumed because the two feel identical in the UI and
  /// are not the same thing: a user who dropped a CSV onto an upload zone and
  /// got a file in `~/Drops` needs to know the upload did not happen.
  final bool deliveredAsDrop;

  /// Whether the drop failed.
  final bool isError;

  /// JSON form for the file lane's reply.
  Map<String, dynamic> toJson() => {
    'files': [for (final f in files) f.toJson()],
    'summary': summary,
    'delivered_as_drop': deliveredAsDrop,
    'is_error': isError,
  };

  /// Reads a [RigDropResult] from [json].
  static RigDropResult fromJson(Map<String, dynamic> json) => RigDropResult(
    files: [
      for (final f in (json['files'] as List? ?? const []))
        if (f is Map) ?RigGuestFile.fromJson(f.cast<String, dynamic>()),
    ],
    summary: json['summary'] is String ? json['summary'] as String : '',
    deliveredAsDrop: json['delivered_as_drop'] as bool? ?? false,
    isError: json['is_error'] as bool? ?? false,
  );
}

/// One file read back OUT of a guest.
class RigFileBytes {
  /// Creates a [RigFileBytes].
  const RigFileBytes({required this.name, required this.bytes, this.mediaType});

  /// The file's name, from its guest path.
  final String name;

  /// Its contents.
  final Uint8List bytes;

  /// MIME type when it could be inferred.
  final String? mediaType;
}
