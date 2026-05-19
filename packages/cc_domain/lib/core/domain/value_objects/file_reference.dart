// The `@[file:<name>]` reference — one vocabulary, shared by both ends.
//
// A reference is what the composer writes into the prompt where a file belongs
// ("compare ⟦before.png⟧ with ⟦after.png⟧"), what the sent message stores, and
// what the SERVER expands into a real path before an agent ever reads it. All
// three have to agree on the same characters, so the grammar lives here rather
// than in the widget layer that happens to have typed it first.
//
// The name is a display name, not a path: it is shortened and de-duplicated by
// the composer so a sentence stays readable, and the message's
// `metadata['attachments']` is what maps it back to bytes. Anything that needs
// the file itself resolves through that map — never by treating the name as a
// filename.
//
// Deliberately free of `package:path`: this is the shared kernel, and splitting
// a basename is the composer's problem, not the grammar's.
library;

/// Matches one `@[file:<name>]` reference.
///
/// The name is bounded and excludes `]` and newlines so a malformed or
/// hand-typed token cannot swallow the rest of the prompt looking for a closing
/// bracket.
final RegExp fileRefPattern = RegExp(r'@\[file:([^\]\n]{1,64})\]');

/// Longest name [fileRefPattern] will match — the pattern's own bound, stated
/// once so a name and the token built from it cannot disagree.
const int kFileRefMaxTokenNameChars = 64;

/// Builds the reference token for an already-shortened [displayName].
String fileRefToken(String displayName) => '@[file:$displayName]';

/// [name] reduced to something a token can actually carry.
///
/// A `]` or a newline in the name would end the token early and spill the rest
/// of the sentence out of it, and anything past
/// [kFileRefMaxTokenNameChars] simply will not match — so a reference built
/// from a raw filename is one the reader silently fails to find. Callers that
/// shorten for READABILITY (the desktop composer's ellipsizer) go further; this
/// is the floor every caller has to clear.
String sanitizeFileRefName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[\r\n\]]'), '').trim();
  if (cleaned.isEmpty) {
    return 'file';
  }
  return cleaned.length <= kFileRefMaxTokenNameChars
      ? cleaned
      // Trimmed from the FRONT: the tail carries the extension, which is the
      // part that says what the file is.
      : cleaned.substring(cleaned.length - kFileRefMaxTokenNameChars);
}

/// One reference found in composer text.
class FileRefMatch {
  /// Creates a [FileRefMatch].
  const FileRefMatch({
    required this.name,
    required this.token,
    required this.start,
    required this.end,
  });

  /// The display name between the braces.
  final String name;

  /// The full matched token, including `@[file:` and `]`.
  final String token;

  /// Index of the token's first character.
  final int start;

  /// Index just past the token's last character.
  final int end;

  /// Whether [offset] falls strictly INSIDE the token.
  ///
  /// Strictly, because the boundaries are legitimate caret positions: a click
  /// just before `@` or just after `]` is someone placing the caret next to the
  /// reference, not opening it.
  bool containsOffset(int offset) => offset > start && offset < end;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileRefMatch &&
          name == other.name &&
          token == other.token &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(name, token, start, end);
}

/// Every reference in [text], in order.
List<FileRefMatch> findFileRefs(String text) => [
  for (final m in fileRefPattern.allMatches(text))
    FileRefMatch(
      name: m.group(1)!,
      token: m.group(0)!,
      start: m.start,
      end: m.end,
    ),
];

/// Whether [token] still appears verbatim in [text].
///
/// A plain substring test is correct here (unlike the `#`-entity check, which
/// needs word boundaries): the token is bracket-delimited, so `@[file:a.dart]`
/// cannot be a prefix of `@[file:ab.dart]`.
bool fileRefSurvives(String text, String token) => text.contains(token);

/// Replaces every reference in [text] with what [expand] returns for its name.
///
/// Returning null leaves the token as the user typed it — a hand-written
/// `@[file:notes.md]` that matches no attachment is just words, and rewriting it
/// into something else would be editing a sentence nobody understands.
String expandFileRefs(String text, String? Function(String name) expand) {
  if (!text.contains('@[file:')) {
    return text;
  }
  return text.replaceAllMapped(fileRefPattern, (m) {
    final replacement = expand(m.group(1)!);
    return replacement ?? m.group(0)!;
  });
}
