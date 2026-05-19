/// Agent mention parser.
class AgentMentionParser {
  /// Creates a new [AgentMentionParser].
  const AgentMentionParser();

  /// Parse mentions.
  List<String> parseMentions(String text) {
    return RegExp(r'@(\w+)')
        .allMatches(text)
        .map((m) => m.group(1)!.toLowerCase())
        .toList(growable: false);
  }

  /// Strip mentions.
  String stripMentions(String text) {
    return text.replaceAll(RegExp(r'@\w+\s*'), '').trim();
  }
}
