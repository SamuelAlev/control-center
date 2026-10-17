part of 'space_message_tile.dart';

Widget _textBubble(DesignSystemTokens t, String content, bool isMine) {
  final body = TextStyle(fontSize: 14, height: 1.4, color: t.textPrimary);
  final refs = findFileRefs(content);
  return DecoratedBox(
    decoration: BoxDecoration(
      color: isMine ? t.accentSoft : t.bgSecondary,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: refs.isEmpty
          ? PhoneMarkdown(data: content)
          : Text.rich(
              TextSpan(children: _bodySpans(t, content, body, refs)),
              style: body,
            ),
    ),
  );
}

List<InlineSpan> _bodySpans(
  DesignSystemTokens t,
  String content,
  TextStyle body,
  List<FileRefMatch> refs,
) {
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final ref in refs) {
    if (ref.start > cursor) {
      spans.add(TextSpan(text: content.substring(cursor, ref.start)));
    }
    spans.add(
      TextSpan(
        text: ref.name,
        style: body.copyWith(color: t.accent, fontWeight: FontWeight.w500),
      ),
    );
    cursor = ref.end;
  }
  if (cursor < content.length) {
    spans.add(TextSpan(text: content.substring(cursor)));
  }
  return spans;
}

Widget _agentBubble(
  DesignSystemTokens t,
  List<TranscriptSegment> segments,
  bool streamComplete,
) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: AgentTranscript(segments: segments, isLive: !streamComplete),
      ),
    ),
  );
}
