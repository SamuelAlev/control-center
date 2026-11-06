import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// How much of a record an excerpt reads. A row shows two lines at most, and
/// the list parses every visible row on each keystroke of a search.
const int _kExcerptSourceLimit = 800;

/// One run of an excerpt: plain words, or a machine value.
typedef MemoryExcerptPart = ({String text, bool code});

/// What [markdown] says on one line, as runs of words and machine values.
///
/// Facts and policies are written in markdown. A list row can't render blocks,
/// and printing the source puts `**` and backticks in front of the reader, so
/// this reads the shared parser's tree rather than pattern-matching the syntax.
List<MemoryExcerptPart> memoryExcerptParts(String markdown) {
  final source = markdown.length > _kExcerptSourceLimit
      ? markdown.substring(0, _kExcerptSourceLimit)
      : markdown;
  final parts = <MemoryExcerptPart>[];

  void add(String text, {bool code = false}) {
    if (text.isEmpty) {
      return;
    }
    if (parts.isNotEmpty && parts.last.code == code) {
      parts.last = (text: '${parts.last.text}$text', code: code);
    } else {
      parts.add((text: text, code: code));
    }
  }

  void inline(List<CcInlineNode> nodes) {
    for (final node in nodes) {
      switch (node) {
        case CcText(:final text):
          add(text);
        case CcInlineCode(:final code):
          add(code, code: true);
        case CcSoftBreak() || CcHardBreak():
          add(' ');
        case CcEmphasis(:final children) ||
            CcStrong(:final children) ||
            CcStrikethrough(:final children) ||
            CcLink(:final children):
          inline(children);
        case CcImage(:final alt):
          add(alt);
        default:
          break;
      }
    }
  }

  void blocks(List<CcBlockNode> nodes) {
    for (final node in nodes) {
      if (parts.isNotEmpty) {
        add(' ');
      }
      switch (node) {
        case CcParagraph(:final children) || CcHeading(:final children):
          inline(children);
        case CcBlockquote(:final children):
          blocks(children);
        case CcList(:final items):
          for (final item in items) {
            blocks(item.children);
          }
        case CcCodeBlock(:final code):
          add(code.split('\n').first, code: true);
        default:
          break;
      }
    }
  }

  blocks(const CcParser().parseDocument(source).blocks);
  return _collapseSpaces(parts);
}

/// Runs of whitespace become one space, across part boundaries too.
List<MemoryExcerptPart> _collapseSpaces(List<MemoryExcerptPart> parts) {
  final collapsed = <MemoryExcerptPart>[];
  var afterSpace = true;
  for (final part in parts) {
    var text = part.text.replaceAll(RegExp(r'\s+'), ' ');
    if (afterSpace && text.startsWith(' ')) {
      text = text.substring(1);
    }
    if (text.isNotEmpty) {
      afterSpace = text.endsWith(' ');
      collapsed.add((text: text, code: part.code));
    }
  }
  if (collapsed.isNotEmpty && collapsed.last.text.endsWith(' ')) {
    final last = collapsed.removeLast();
    final text = last.text.trimRight();
    if (text.isNotEmpty) {
      collapsed.add((text: text, code: last.code));
    }
  }
  return collapsed;
}

/// [markdown] as one line of plain words.
String memoryPlainExcerpt(String markdown) =>
    memoryExcerptParts(markdown).map((part) => part.text).join();

/// Splits one line of [plain] words into its first sentence and the rest, so a
/// policy, which has no name of its own, can lead with what it says.
({String lead, String rest}) memoryLeadSentence(String plain) {
  final end = RegExp(r'[.!?:]\s').firstMatch(plain);
  if (end == null) {
    return (lead: plain, rest: '');
  }
  return (
    lead: plain.substring(0, end.start + 1),
    rest: plain.substring(end.end),
  );
}

/// A record's words on a row: plain text beside machine values in the code
/// face, with no markdown syntax showing.
class MemoryExcerpt extends StatelessWidget {
  /// Creates a [MemoryExcerpt].
  const MemoryExcerpt({
    super.key,
    required this.markdown,
    this.maxLines = 2,
    this.skip = 0,
  });

  /// The record's source.
  final String markdown;

  /// How many lines it may take.
  final int maxLines;

  /// How many leading characters of the excerpt another line already shows.
  final int skip;

  List<MemoryExcerptPart> get _parts {
    final shown = <MemoryExcerptPart>[];
    var remaining = skip;
    for (final part in memoryExcerptParts(markdown)) {
      if (part.text.length <= remaining) {
        remaining -= part.text.length;
      } else {
        shown.add((text: part.text.substring(remaining), code: part.code));
        remaining = 0;
      }
    }
    return shown;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final plain = CcTypography.bodySm.copyWith(color: t.textTertiary);
    final code = CcFonts.code(textStyle: plain.copyWith(fontSize: 12));
    return Text.rich(
      TextSpan(
        style: plain,
        children: [
          for (final part in _parts)
            TextSpan(text: part.text, style: part.code ? code : null),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
