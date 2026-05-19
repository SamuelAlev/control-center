/// Translation between Slack's wire text and the markdown Control Center
/// speaks.
///
/// Two directions and they are not symmetric:
///
///  * **Inbound** Slack escapes `&`, `<`, `>` and wraps every entity in angle
///    brackets (`<@U123>`, `<#C1|general>`, `<https://x|label>`). Handing that
///    to an agent verbatim means the prompt contains ids the model has to guess
///    at, so it is unwrapped into plain markdown first.
///  * **Outbound** the streaming path needs no conversion at all — Slack's
///    `markdown_text` chunks are standard markdown. Only the non-streaming
///    fallback (`chat.postMessage`) speaks *mrkdwn*, Slack's older dialect
///    where bold is `*one asterisk*` and links are `<url|label>`.
///
// Pure text transforms with no state to inject: a namespace, not a service.
// ignore_for_file: avoid_classes_with_only_static_members
library;

/// Slack ⇄ markdown text conversions.
abstract final class SlackText {
  static final _botMention = RegExp(r'<@([A-Z0-9]+)(\|[^>]*)?>');
  static final _spaceRef = RegExp(r'<#([A-Z0-9]+)(?:\|([^>]*))?>');
  static final _linkRef = RegExp(r'<(https?://[^>|]+)(?:\|([^>]*))?>');
  static final _specialRef = RegExp(r'<!([a-z]+)(?:\^[^>|]*)?(?:\|([^>]*))?>');
  static final _codeSpan = RegExp('`{1,3}[^`]*`{1,3}', dotAll: true);
  static final _heading = RegExp(r'^\s{0,3}#{1,6}\s+(.*)$', multiLine: true);
  static final _mdLink = RegExp(r'\[([^\]]+)\]\((\S+?)\)');
  static final _tripleEmphasis = RegExp(r'\*\*\*(.+?)\*\*\*', dotAll: true);
  static final _boldStars = RegExp(r'\*\*(.+?)\*\*', dotAll: true);
  // The emphasis run may not open or close on whitespace, so prose arithmetic
  // (`2 * 3 * 4`) and `* ` bullets are left alone, as in markdown itself.
  static final _italicStar = RegExp(
    r'(?<![\w*])\*(?![\s*])([^*\n]*[^\s*])\*(?![\w*])',
  );
  static final _boldUnderscores = RegExp(r'__(.+?)__', dotAll: true);

  /// Marker standing in for a bold run while single-asterisk italics are
  /// converted, so `**bold**` is not mistaken for two italic markers.
  static const _boldMarker = '\u0000b\u0000';

  /// Marker standing in for an extracted code span.
  static const _codeMarker = '\u0000c';

  /// Turns one inbound Slack message into markdown an agent can read.
  ///
  /// [botUserId], when given, is removed entirely: the `@bot` that addressed
  /// the app is routing, not content and leaving it in would have the agent
  /// answer a question about its own Slack id.
  static String toMarkdown(String slack, {String? botUserId}) {
    var text = slack;
    text = text.replaceAllMapped(_botMention, (m) {
      final id = m.group(1);
      if (botUserId != null && id == botUserId) {
        return '';
      }
      final label = m.group(2)?.substring(1);
      return '@${label != null && label.isNotEmpty ? label : id}';
    });
    text = text.replaceAllMapped(_spaceRef, (m) {
      final name = m.group(2);
      return '#${name != null && name.isNotEmpty ? name : m.group(1)}';
    });
    text = text.replaceAllMapped(_linkRef, (m) {
      final url = m.group(1)!;
      final label = m.group(2);
      return (label == null || label.isEmpty || label == url)
          ? url
          : '[$label]($url)';
    });
    text = text.replaceAllMapped(_specialRef, (m) {
      final label = m.group(2);
      return '@${label != null && label.isNotEmpty ? label : m.group(1)}';
    });
    // Entity decoding comes last: doing it first would create `<`/`>` that the
    // entity patterns above would then mis-read as Slack markup.
    text = text
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');
    return text.trim();
  }

  /// Whether [slack] addresses the bot with an explicit `@mention`.
  static bool mentionsBot(String slack, String botUserId) =>
      botUserId.isNotEmpty && slack.contains('<@$botUserId');

  /// Converts markdown to Slack's mrkdwn, for the non-streaming fallback.
  ///
  /// Deliberately minimal — bold, italic, headings, links. Anything else
  /// (lists, quotes, code fences, tables) is already close enough that
  /// rewriting it would risk mangling agent output for no gain.
  static String toMrkdwn(String markdown) {
    // Code spans are extracted first so their contents survive untouched.
    final codes = <String>[];
    var text = markdown.replaceAllMapped(_codeSpan, (m) {
      codes.add(m.group(0)!);
      return '$_codeMarker${codes.length - 1}\u0000';
    });

    // Bold via the marker, or the italic pass below would read the asterisks
    // this line just gained and turn the heading into italics.
    text = text.replaceAllMapped(
      _heading,
      (m) => '$_boldMarker${m.group(1)!.trim()}$_boldMarker',
    );
    text = text.replaceAllMapped(
      _mdLink,
      (m) => '<${m.group(2)}|${m.group(1)}>',
    );
    text = text.replaceAllMapped(
      _tripleEmphasis,
      (m) => '${_boldMarker}_${m.group(1)}_$_boldMarker',
    );
    text = text.replaceAllMapped(
      _boldStars,
      (m) => '$_boldMarker${m.group(1)}$_boldMarker',
    );
    text = text.replaceAllMapped(
      _boldUnderscores,
      (m) => '$_boldMarker${m.group(1)}$_boldMarker',
    );
    text = text.replaceAllMapped(_italicStar, (m) => '_${m.group(1)}_');
    text = text.replaceAll(_boldMarker, '*');

    for (var i = 0; i < codes.length; i++) {
      text = text.replaceAll('$_codeMarker$i\u0000', codes[i]);
    }
    return text;
  }
}
