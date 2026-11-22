/// The "Still in flight" block written after a compaction.
///
/// A summary is the model's account of the past and can drop what is still
/// running. After every compaction on the harness lane the loop appends this
/// block, built from live state rather than from the summary: one line per
/// kind of open work, each ending with the call that refreshes it. Only the
/// newest block is kept: a new compaction removes the previous one.
library;

/// Extra, already-rendered lines for the block, supplied by the host (the
/// goal, wakes, asks, stored keys). One line per kind, without the leading
/// `- `, each ending with the call that refreshes it.
typedef InFlightLines = Future<List<String>> Function();

/// The block's heading up to the time: how a block is recognized in the
/// history, so a new one replaces it and a summarizer skips it.
const String stillInFlightHeadingPrefix =
    '## Still in flight (from the server at ';

/// The longest the whole block may be, in characters.
const int stillInFlightMaxChars = 1500;

/// The order the kinds appear in, by the label each line starts with. Lines
/// with another label follow, in the order given.
const List<String> _kindOrder = [
  'Goal:',
  'Wakes:',
  'Asked:',
  'Background:',
  'Checklist:',
  'Stored:',
];

/// [at] as the block's heading stamps it: `YYYY-MM-DD HH:MM UTC`.
String stillInFlightStamp(DateTime at) {
  final u = at.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${u.year.toString().padLeft(4, '0')}-${two(u.month)}-${two(u.day)} '
      '${two(u.hour)}:${two(u.minute)} UTC';
}

/// Whether [text] is a "Still in flight" block.
bool isStillInFlightBlock(String text) =>
    text.trimLeft().startsWith(stillInFlightHeadingPrefix);

/// Renders the block for [lines] at [at], or null when there are no lines.
///
/// The heading reads `## Still in flight (from the server at YYYY-MM-DD
/// HH:MM UTC; refresh before relying on it)`: the full UTC date, so a block
/// read days later says how old it is. Lines are ordered by kind ([_kindOrder]); blank
/// lines are dropped. The block is at most [stillInFlightMaxChars]: the line
/// that would cross it is cut with `…` and the rest are left out.
String? renderStillInFlightBlock({
  required DateTime at,
  required List<String> lines,
}) {
  final kept = [
    for (final line in lines)
      if (line.trim().isNotEmpty) line.trim().replaceAll('\n', ' '),
  ];
  if (kept.isEmpty) {
    return null;
  }
  int rank(String line) {
    final i = _kindOrder.indexWhere(line.startsWith);
    return i < 0 ? _kindOrder.length : i;
  }

  final ordered = [for (var i = 0; i < kept.length; i++) (i, kept[i])]
    ..sort((a, b) {
      final byKind = rank(a.$2).compareTo(rank(b.$2));
      return byKind != 0 ? byKind : a.$1.compareTo(b.$1);
    });
  final buf = StringBuffer(
    '$stillInFlightHeadingPrefix${stillInFlightStamp(at)}; refresh before '
    'relying on it)',
  );
  for (final (_, line) in ordered) {
    final entry = '\n- $line';
    final room = stillInFlightMaxChars - buf.length;
    if (entry.length <= room) {
      buf.write(entry);
      continue;
    }
    if (room > 4) {
      buf.write('${entry.substring(0, room - 1)}…');
    }
    break;
  }
  return buf.toString();
}
