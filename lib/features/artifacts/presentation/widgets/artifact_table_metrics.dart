part of 'artifact_table.dart';

/// Plain-text length of an inline run, and whether it contains media (an image
/// or a custom inline that may size itself with a `LayoutBuilder`).
({int length, bool media}) _inlineMetrics(List<CcInlineNode> nodes) {
  var length = 0;
  var media = false;

  void walk(List<CcInlineNode> ns) {
    for (final node in ns) {
      switch (node) {
        case CcText(:final text):
          length += text.length;
        case CcInlineCode(:final code):
          length += code.length;
        case CcInlineHtml(:final raw):
          length += raw.length;
        case CcEmphasis(:final children):
          walk(children);
        case CcStrong(:final children):
          walk(children);
        case CcStrikethrough(:final children):
          walk(children);
        case CcLink(:final children):
          walk(children);
        case CcSoftBreak():
        case CcHardBreak():
          length += 1;
        case CcImage():
        case CcCustomInline():
          media = true;
        default:
          break;
      }
    }
  }

  walk(nodes);
  return (length: length, media: media);
}
