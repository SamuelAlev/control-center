/// One GitHub `suggestion` fence inside a review comment.
class SuggestionBlock {
  /// Creates a parsed suggestion block.
  const SuggestionBlock({
    required this.code,
    required this.start,
    required this.end,
  });

  /// Replacement code inside the fence.
  final String code;

  /// Inclusive start offset of the complete fence in the comment body.
  final int start;

  /// Exclusive end offset of the complete fence in the comment body.
  final int end;
}

/// Matches GitHub suggestion fences while preserving surrounding prose.
final RegExp suggestionFencePattern = RegExp(
  r'```suggestion\s*\r?\n([\s\S]*?)\r?\n?```',
  multiLine: true,
);

/// Parses every suggestion fence in source order.
List<SuggestionBlock> parseSuggestionBlocks(String body) => [
  for (final match in suggestionFencePattern.allMatches(body))
    SuggestionBlock(
      code: match.group(1) ?? '',
      start: match.start,
      end: match.end,
    ),
];

/// Builds a review comment containing one or more GitHub suggestion fences.
String buildSuggestionBody(String comment, List<String> suggestions) {
  final parts = <String>[];
  final prose = comment.trim();
  if (prose.isNotEmpty) {
    parts.add(prose);
  }
  for (final suggestion in suggestions) {
    parts.add('```suggestion\n$suggestion\n```');
  }
  return parts.join('\n\n');
}

/// Replaces all existing suggestion fences while preserving surrounding prose.
///
/// Extra replacements are appended as new fences. Removing a replacement
/// removes the corresponding fence without disturbing text around it.
String replaceSuggestionBlocks(String body, List<String> replacements) {
  final blocks = parseSuggestionBlocks(body);
  if (blocks.isEmpty) {
    return buildSuggestionBody(body, replacements);
  }

  final out = StringBuffer();
  var cursor = 0;
  for (var i = 0; i < blocks.length; i++) {
    final block = blocks[i];
    out.write(body.substring(cursor, block.start));
    if (i < replacements.length) {
      out.write('```suggestion\n${replacements[i]}\n```');
    }
    cursor = block.end;
  }
  out.write(body.substring(cursor));

  if (blocks.length < replacements.length) {
    final rendered = out.toString();
    final withExtras = StringBuffer(rendered);
    if (rendered.isNotEmpty && !rendered.endsWith('\n\n')) {
      withExtras.write(rendered.endsWith('\n') ? '\n' : '\n\n');
    }
    for (var i = blocks.length; i < replacements.length; i++) {
      if (i > blocks.length) {
        withExtras.write('\n\n');
      }
      withExtras.write('```suggestion\n${replacements[i]}\n```');
    }
    return withExtras.toString().trim();
  }
  return out.toString().trim();
}
