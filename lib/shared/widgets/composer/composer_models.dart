import 'package:flutter/widgets.dart';

/// Trigger character that opens a mention popup.
enum MentionTrigger {
  /// `@` — tag an agent, space, file, folder, or scratchpad.
  at('@'),

  /// `/` — invoke a slash command.
  slash('/'),

  /// `#` — reference a PR / issue / ticket (reserved for future).
  hash('#');

  const MentionTrigger(this.symbol);

  /// Trigger character symbol.
  final String symbol;

  /// Looks up a trigger from its character symbol.
  static MentionTrigger? fromChar(String c) {
    for (final t in values) {
      if (t.symbol == c) {
        return t;
      }
    }
    return null;
  }
}

/// A single live mention query inferred from the text and caret position.
@immutable
class MentionQuery {
  /// Creates a new [MentionQuery].
  const MentionQuery({
    required this.trigger,
    required this.partial,
    required this.start,
    required this.end,
  });

  /// Which trigger char opened the popup.
  final MentionTrigger trigger;

  /// Text typed after the trigger (without the trigger char itself).
  final String partial;

  /// Index of the trigger character in the text.
  final int start;

  /// Caret position (exclusive end of the query).
  final int end;

  @override
  bool operator ==(Object other) =>
      other is MentionQuery &&
      other.trigger == trigger &&
      other.partial == partial &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(trigger, partial, start, end);
}

/// One suggestion displayed in the mention popup.
@immutable
class MentionSuggestion {
  /// Creates a new [MentionSuggestion].
  const MentionSuggestion({
    required this.id,
    required this.kind,
    required this.label,
    this.description,
    this.icon,
    required this.replacement,
    this.payload,
    this.badge,
  });

  /// Stable id (e.g. `agent:abc123`, `file:/path/to/file.dart`).
  final String id;

  /// Source-defined kind for grouping (e.g. 'agent', 'file', 'scratchpad').
  final String kind;

  /// Primary text shown in the row.
  final String label;

  /// Secondary text (e.g. agent title, file relative path).
  final String? description;

  /// Optional icon for the row.
  final IconData? icon;

  /// Exact text that replaces the trigger+partial when this row is picked.
  /// Should already include the trigger char and trailing space if desired.
  /// Example: `'@samuel '` or `'@"my file.png" '`.
  final String replacement;

  /// Arbitrary payload attached to the resolved mention (e.g. file path,
  /// agent id, scratchpad id). Round-trips into [ResolvedMention.payload].
  final Map<String, dynamic>? payload;

  /// Short provenance label shown as a trailing chip — where this suggestion
  /// came from, when that is not obvious from the name.
  ///
  /// A skill's name says nothing about which of the space's repos ships it,
  /// and two repos may each carry a `testing`. Null for rows whose origin
  /// needs no explaining.
  final String? badge;
}

/// A mention that was inserted into the composer and is being sent.
@immutable
class ResolvedMention {
  /// Creates a new [ResolvedMention].
  const ResolvedMention({
    required this.kind,
    required this.label,
    required this.start,
    required this.end,
    this.payload,
  });

  /// Mention kind (e.g. 'agent', 'file', 'space').
  final String kind;

  /// Mention label text.
  final String label;

  /// Start index of the mention in the text.
  final int start;

  /// End index of the mention in the text.
  final int end;

  /// Optional payload attached to the mention.
  final Map<String, dynamic>? payload;
}

/// An attachment selected by the user (file picker, drop, or scratchpad).
@immutable
class ComposerAttachment {
  /// Creates a new [ComposerAttachment].
  const ComposerAttachment({
    required this.id,
    required this.kind,
    required this.label,
    this.path,
    this.bytes,
    this.mimeType,
    this.payload,
    this.refName,
    this.sizeBytes,
    this.remoteUrl,
  });

  /// `'file'`, `'image'`, `'scratchpad'`, `'note'`, etc.
  final String kind;

  /// Stable id.
  final String id;

  /// Display label (filename, scratchpad title).
  final String label;

  /// Absolute path on disk, when applicable.
  final String? path;

  /// Inline bytes for clipboard/drop content (otherwise read from [path]).
  final List<int>? bytes;

  /// Optional mime type — informs preview rendering.
  final String? mimeType;

  /// Source-specific metadata (e.g. scratchpad workspace id).
  final Map<String, dynamic>? payload;

  /// The display name of the `@[file:<name>]` reference that points at this
  /// attachment from inside the prompt, or null when it is attached
  /// out-of-band only (a scratchpad, or a legacy caller that inserts no token).
  ///
  /// This — not [label] — is the identity the text refers to: it is shortened
  /// and de-duplicated so two `index.ts` from different packages stay
  /// distinguishable in a sentence.
  final String? refName;

  /// Size in bytes when known. Null for a path-only attachment nobody has
  /// read yet: `stat`-ing a dropped file just to label a chip would touch the
  /// filesystem from a thin client for a subtitle.
  final int? sizeBytes;

  /// An already-signed URL the bytes can be fetched from, for an attachment
  /// that has been SENT: the composer's copy is gone, but the message kept a
  /// blob reference and the host serves it.
  ///
  /// Resolved by the caller, never here. A blob reference needs the workspace
  /// id and the media proxy to become a URL, and both live in feature code —
  /// resolving it inside this shared widget layer is exactly the
  /// shared-imports-features dependency the architecture test forbids.
  final String? remoteUrl;

  /// Whether the attachment is an image based on its mime type.
  bool get isImage => (mimeType ?? '').startsWith('image/');

  /// Returns a copy with the fields given replaced.
  ComposerAttachment copyWith({
    String? mimeType,
    String? refName,
    int? sizeBytes,
    List<int>? bytes,
    String? remoteUrl,
  }) => ComposerAttachment(
    id: id,
    kind: kind,
    label: label,
    path: path,
    bytes: bytes ?? this.bytes,
    mimeType: mimeType ?? this.mimeType,
    payload: payload,
    refName: refName ?? this.refName,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    remoteUrl: remoteUrl ?? this.remoteUrl,
  );
}

/// Payload handed to the send callback.
@immutable
class ComposerSubmission {
  /// Creates a new [ComposerSubmission].
  const ComposerSubmission({
    required this.text,
    required this.mentions,
    required this.attachments,
  });

  /// The full message text as the user typed it (with `@name`, etc. inline).
  final String text;

  /// Structured mentions extracted from the text.
  final List<ResolvedMention> mentions;

  /// Files/scratchpads attached out-of-band (not inlined into [text]).
  final List<ComposerAttachment> attachments;

  /// Whether the submission has no text and no attachments.
  bool get isEmpty => text.trim().isEmpty && attachments.isEmpty;
}
