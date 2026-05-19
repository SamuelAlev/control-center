import 'package:flutter/widgets.dart';

/// Trigger character that opens a mention popup.
enum MentionTrigger {
  /// `@` — tag an agent, channel, file, folder, or scratchpad.
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

  /// Mention kind (e.g. 'agent', 'file', 'channel').
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

  /// Whether the attachment is an image based on its mime type.
  bool get isImage => (mimeType ?? '').startsWith('image/');
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

