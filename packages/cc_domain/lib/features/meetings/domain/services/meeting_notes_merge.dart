/// Heading under which the user's own written notes are preserved verbatim
/// when the AI summary did not absorb them. Stable so re-runs are idempotent.
const String writtenNotesHeading = '### Written notes';

/// Ensures the user's manually-typed notes survive an AI (re-)summarization.
///
/// The summarizer is told to weave the user's rough notes into [enhanced], but
/// a model can silently drop a line — and on a re-run the user expects their
/// own words to never disappear. This deterministic backstop compares each
/// non-empty [userNotes] line against [enhanced]; any line the AI did not carry
/// through (no ~40-char fuzzy substring match) is appended verbatim under a
/// "### Written notes" section.
///
/// Idempotent: a prior "### Written notes" section in [enhanced] is stripped
/// and recomputed each run, so repeated summaries never stack duplicate
/// sections. Returns null when [enhanced] is null (nothing to merge into).
/// Pure — no I/O — so the `meeting.saveNotes` step can call it directly.
String? mergeManualNotes({
  required String userNotes,
  required String? enhanced,
}) {
  if (enhanced == null) {
    return null;
  }
  final base = _stripWrittenNotes(enhanced).trimRight();
  final userLines = userNotes
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList(growable: false);
  if (userLines.isEmpty) {
    return base.isEmpty ? enhanced : base;
  }
  final haystack = _normalize(base);
  final dropped = <String>[];
  for (final line in userLines) {
    final probeSource = _stripBullet(line);
    if (probeSource.isEmpty) {
      continue;
    }
    final probe = _normalize(
      probeSource.length > 40 ? probeSource.substring(0, 40) : probeSource,
    );
    if (probe.isNotEmpty && !haystack.contains(probe)) {
      dropped.add(line);
    }
  }
  if (dropped.isEmpty) {
    return base.isEmpty ? null : base;
  }
  final buffer = StringBuffer(base);
  if (base.isNotEmpty) {
    buffer.write('\n\n');
  }
  buffer
    ..write(writtenNotesHeading)
    ..write('\n')
    ..write(dropped.join('\n'));
  return buffer.toString();
}

/// Removes a trailing "### Written notes" section (and everything after it) so
/// the merge can be recomputed cleanly on a re-run.
String _stripWrittenNotes(String s) {
  final idx = s.lastIndexOf(writtenNotesHeading);
  return idx < 0 ? s : s.substring(0, idx);
}

/// Lowercases + collapses whitespace so matching ignores formatting noise.
String _normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// Strips a leading markdown list / heading marker ("- ", "* ", "1. ", "# ")
/// so a bulleted user note still matches its prose form in the AI notes.
String _stripBullet(String s) =>
    s.replaceFirst(RegExp(r'^\s*([-*•]|\d+[.)]|#{1,6})\s+'), '');
