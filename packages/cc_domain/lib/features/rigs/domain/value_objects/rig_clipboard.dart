import 'package:cc_domain/features/rigs/domain/value_objects/rig_action_result.dart';

/// Which of a guest's selections a clipboard operation addresses.
///
/// X11 has three and they are not interchangeable. Collapsing them into one
/// "clipboard" is what makes a remote desktop feel broken in ways nobody can
/// describe: middle-click paste stops working, or a drag hands over the last
/// thing that was copied instead of the thing being dragged.
enum RigClipboardSelection {
  /// `CLIPBOARD` — what Ctrl+C fills and Ctrl+V reads. The only one the
  /// browser and mobile surfaces have, so it is the default everywhere.
  clipboard,

  /// `PRIMARY` — X11's select-to-copy, pasted with the middle button. Read
  /// only: writing it from the host would fight whatever the user just
  /// selected inside the guest.
  primary,

  /// `XdndSelection` — the payload of a drag that is IN FLIGHT right now.
  ///
  /// This is what makes drag-out possible at all: while a guest application
  /// drags something, it owns this selection, so asking for it is how the
  /// host learns what is being dragged. It is a live, transient thing —
  /// outside a drag there is no owner and the read simply comes back empty,
  /// which is the correct answer rather than an error.
  xdnd;

  /// Stable wire string.
  String get wire => name;

  /// Parses [value], defaulting to [clipboard] — the selection every surface
  /// has, and the only sensible reading of an unqualified "the clipboard".
  static RigClipboardSelection fromWire(String? value) {
    for (final s in RigClipboardSelection.values) {
      if (s.wire == value) {
        return s;
      }
    }
    return RigClipboardSelection.clipboard;
  }
}

/// One file that exists inside a guest, named but not carried.
///
/// Deliberately a REFERENCE, never bytes. A clipboard read that inlined file
/// contents would put an arbitrary number of megabytes into a JSON-RPC reply
/// (and into the action log) to answer a question the caller may not even have
/// followed up on. The bytes ride the separate `/rig/files` lane, once the
/// caller decides it wants them.
class RigGuestFile {
  /// Creates a [RigGuestFile].
  const RigGuestFile({
    required this.name,
    required this.guestPath,
    this.sizeBytes,
    this.mediaType,
  });

  /// Reads a [RigGuestFile] from [json], or null when it carries no usable
  /// path — an entry with no path cannot be fetched and is worse than absent,
  /// because it renders as a file the user then cannot open.
  static RigGuestFile? fromJson(Map<String, dynamic> json) {
    final path = json['guest_path'];
    if (path is! String || path.isEmpty) {
      return null;
    }
    final name = json['name'];
    final size = json['size_bytes'];
    final mediaType = json['media_type'];
    return RigGuestFile(
      name: name is String && name.isNotEmpty
          ? name
          : basenameOfGuestPath(path),
      guestPath: path,
      sizeBytes: size is int ? size : null,
      mediaType: mediaType is String && mediaType.isNotEmpty ? mediaType : null,
    );
  }

  /// The file's display name (the last path segment).
  final String name;

  /// Its absolute path INSIDE the guest. Meaningless on the host — it is a
  /// coordinate for the file lane, not something to open locally.
  final String guestPath;

  /// Size in bytes when the guest reported one.
  final int? sizeBytes;

  /// MIME type when known.
  final String? mediaType;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'name': name,
    'guest_path': guestPath,
    if (sizeBytes != null) 'size_bytes': sizeBytes,
    if (mediaType != null) 'media_type': mediaType,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RigGuestFile &&
          other.name == name &&
          other.guestPath == guestPath &&
          other.sizeBytes == sizeBytes &&
          other.mediaType == mediaType;

  @override
  int get hashCode => Object.hash(name, guestPath, sizeBytes, mediaType);

  @override
  String toString() => 'RigGuestFile($guestPath)';
}

/// The last segment of a POSIX guest path, or the path itself when it has no
/// separator. Guests are Linux on every surface, so `/` is the separator
/// whatever the HOST runs — using the host's would mangle every path on
/// Windows.
String basenameOfGuestPath(String path) {
  final trimmed = path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;
  final slash = trimmed.lastIndexOf('/');
  return slash < 0 ? trimmed : trimmed.substring(slash + 1);
}

/// What is on a clipboard — the guest's or the host's — in the flavours that
/// cross the boundary.
///
/// The three fields are not exclusive: a copy out of a browser routinely
/// carries both text and an image, and a file manager carries a uri-list and
/// a plain-text fallback. Keeping all three lets each side choose its best
/// flavour rather than the transfer choosing for it.
///
/// **Images are capped, and the cap is honest.** A clipboard read rides the
/// JSON lane, so the image is base64 in a reply the server has to hold whole.
/// An oversized image comes back with [imageSkippedBytes] set instead of
/// being silently downscaled: a paste that quietly changes the pixels is a
/// worse outcome than one that says it could not carry them.
class RigClipboardData {
  /// Creates a [RigClipboardData].
  const RigClipboardData({
    this.text,
    this.imageBase64,
    this.imageMediaType,
    this.files = const [],
    this.imageSkippedBytes,
  });

  /// Text-only content.
  factory RigClipboardData.ofText(String text) => RigClipboardData(text: text);

  /// Nothing on the clipboard.
  static const RigClipboardData empty = RigClipboardData();

  /// The largest image the JSON lane carries, measured on the RAW bytes
  /// (base64 inflates by 4/3, so the encoded form tops out near 21 MB).
  ///
  /// Sized for a full-screen PNG off a large display, which is what people
  /// actually copy. Bigger than that is a file, and files have their own lane.
  static const int maxImageBytes = 16 * 1024 * 1024;

  /// Plain text, when the clipboard holds any.
  final String? text;

  /// Base64 image bytes, when the clipboard holds an image within the cap.
  final String? imageBase64;

  /// The image's MIME type (`image/png` in practice — it is the flavour every
  /// surface can both produce and consume).
  final String? imageMediaType;

  /// Files the clipboard NAMES, as guest-side references. Empty on the host
  /// side of a write until the caller has staged them.
  final List<RigGuestFile> files;

  /// Set when an image was present and too large for the lane: its size, so
  /// the caller can say how big rather than "an image".
  final int? imageSkippedBytes;

  /// Whether an image came through.
  bool get hasImage => imageBase64?.isNotEmpty ?? false;

  /// Whether there is anything at all to carry.
  bool get isEmpty =>
      (text == null || text!.isEmpty) && !hasImage && files.isEmpty;

  /// Whether there is something to carry.
  bool get isNotEmpty => !isEmpty;

  /// A one-line summary for the action feed and the tool result.
  ///
  /// Describes the SHAPE, never the content: this string is written into the
  /// audit log and read back by people who did not do the copying, and a
  /// clipboard is exactly where passwords live.
  String get summary {
    final parts = <String>[
      if (text != null && text!.isNotEmpty) '${text!.length} characters',
      if (hasImage) 'an image',
      if (imageSkippedBytes != null)
        'an image too large to carry (${_mb(imageSkippedBytes!)})',
      if (files.length == 1) '1 file',
      if (files.length > 1) '${files.length} files',
    ];
    if (parts.isEmpty) {
      return 'nothing';
    }
    if (parts.length == 1) {
      return parts.single;
    }
    return '${parts.take(parts.length - 1).join(", ")} and ${parts.last}';
  }

  static String _mb(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  /// The model-facing rendering of a clipboard read.
  ///
  /// The text half is FENCED. A clipboard is content the guest chose, so a
  /// page that copies "ignore your previous instructions" to it must read to
  /// the model as a quoted string, exactly like an extracted DOM. The file
  /// names are guest-chosen too, so they go inside the same fence.
  String toUntrustedText() {
    if (isEmpty) {
      return 'The clipboard is empty.';
    }
    final body = StringBuffer();
    if (text != null && text!.isNotEmpty) {
      body.writeln(text);
    }
    if (files.isNotEmpty) {
      if (body.isNotEmpty) {
        body.writeln();
      }
      body.writeln('Files on the clipboard:');
      for (final f in files) {
        body.writeln('- ${f.guestPath}');
      }
    }
    if (body.isEmpty) {
      // An image with no text: the caption belongs OUTSIDE the fence, because
      // it is the harness speaking, and the image itself rides the result's
      // image slot.
      return 'The clipboard holds $summary.';
    }
    return 'The clipboard holds $summary.\n'
        '${wrapUntrustedRigContent(body.toString().trimRight(), source: "guest clipboard")}';
  }

  /// JSON form.
  Map<String, dynamic> toJson() => {
    if (text != null) 'text': text,
    if (imageBase64 != null) 'image_base64': imageBase64,
    if (imageMediaType != null) 'image_media_type': imageMediaType,
    if (files.isNotEmpty) 'files': [for (final f in files) f.toJson()],
    if (imageSkippedBytes != null) 'image_skipped_bytes': imageSkippedBytes,
  };

  /// Reads a [RigClipboardData] from [json]. Total: a malformed field is read
  /// as absent rather than throwing, because this parses both a guest's reply
  /// and a client's request.
  static RigClipboardData fromJson(Map<String, dynamic> json) {
    final text = json['text'];
    final image = json['image_base64'];
    final mediaType = json['image_media_type'];
    final skipped = json['image_skipped_bytes'];
    return RigClipboardData(
      text: text is String && text.isNotEmpty ? text : null,
      imageBase64: image is String && image.isNotEmpty ? image : null,
      imageMediaType: mediaType is String && mediaType.isNotEmpty
          ? mediaType
          : (image is String && image.isNotEmpty ? 'image/png' : null),
      files: [
        for (final f in (json['files'] as List? ?? const []))
          if (f is Map) ?RigGuestFile.fromJson(f.cast<String, dynamic>()),
      ],
      imageSkippedBytes: skipped is int ? skipped : null,
    );
  }

  @override
  String toString() => 'RigClipboardData($summary)';
}
