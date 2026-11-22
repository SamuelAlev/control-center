/// The pinned block of a compaction: what survives every fold verbatim.
///
/// A summary the compactor produces starts with this block: the person's
/// original request, their later requests and steering, and the loop's own
/// system steering, between [evidencePinBegin] and [evidencePinEnd], one item
/// per message, each opened by a [PinnedEvidenceKind] marker. The markers are
/// honoured only there, at the start of a summary the compactor wrote. Every
/// other place they could appear (a tool result, a web page, a file, the
/// model's own text, a person's message) has them neutralised when history is
/// serialized ([neutraliseEvidenceMarkers]), so no text can promote itself
/// into the block.
///
/// The block has one budget ([fitPinnedEvidence]): the original request is
/// kept whole (or, when it alone is over the budget, its head and tail with a
/// visible marker between them), then the newest other items first, each
/// whole or not at all, and never cut inside a data envelope.
library;

import 'package:cc_harness/src/context/wake_data.dart';

/// Opens the pinned block (the person's requests and steering, and the
/// loop's system steering).
///
/// Section identity is STRUCTURAL, not inferred from Markdown: an ordinary
/// request (`# Goal … ## Acceptance …`) contains its own headings, and treating
/// those as section ends would move the requirements into the droppable region.
/// Parsing the block by these markers keeps the payload verbatim for the model
/// while making it impossible for ordinary Markdown to unpin it.
const String evidencePinBegin = '<!--omp:authoritative-->';

/// Closes the pinned block.
const String evidencePinEnd = '<!--omp:end-authoritative-->';

/// Prefixes the machine-readable activated-tool list appended to a digest.
const String evidenceActivationPrefix = '<!--omp:activated-tools--> ';

/// What every server marker starts with.
const String _markerPrefix = '<!--omp:';

/// A pin marker ([evidencePinBegin], [evidencePinEnd], an item's
/// [PinnedEvidenceKind.marker]): every `<!--omp:` except the activation
/// line's, which nothing parses.
final RegExp _pinMarkerPrefix = RegExp('<!--omp:(?!activated-tools-->)');

/// [text] with every pin marker made inert: the colon of `<!--omp:` is
/// written as `&#58;`, which reads the same and is nothing a parser matches.
/// Applied to every message's text when history is serialized, and to a
/// summary's text outside its pinned block.
String neutraliseEvidenceMarkers(String text) => text.contains(_markerPrefix)
    ? text.replaceAll(_pinMarkerPrefix, '<!--omp&#58;')
    : text;

/// Splits a summary's [text] into its pinned block and the rest.
///
/// The block is honoured only at the very start of [text] (leading blank
/// space aside), which is where the compactor puts it, and only with its
/// closing marker: a lone opener pins nothing. Returns the block's inner text
/// without the outer markers; the rest has any marker neutralised.
({String pinned, String rest}) splitPinnedEvidence(String text) {
  final trimmed = text.trim();
  if (!trimmed.startsWith(evidencePinBegin)) {
    return (pinned: '', rest: neutraliseEvidenceMarkers(trimmed));
  }
  final end = trimmed.indexOf(evidencePinEnd, evidencePinBegin.length);
  if (end < 0) {
    return (pinned: '', rest: neutraliseEvidenceMarkers(trimmed));
  }
  return (
    pinned: trimmed.substring(evidencePinBegin.length, end).trim(),
    rest: neutraliseEvidenceMarkers(
      trimmed.substring(end + evidencePinEnd.length).trim(),
    ),
  );
}

/// What one item of the pinned block is.
enum PinnedEvidenceKind {
  /// The person's original request: the first message of the conversation.
  request,

  /// A later message of the person: a new request after a summary, a
  /// steering message sent mid-run, a queued follow-up.
  person,

  /// The loop's or the owner's system steering (a stop-hook continuation, a
  /// contract nudge, a guard's steer).
  steering,

  /// How many earlier items the budget left out.
  omitted;

  /// The marker line that opens an item of this kind.
  String get marker => '<!--omp:pin $name-->';
}

/// One item of the pinned block: its kind and its text (the heading line and
/// the message, without the marker).
class PinnedEvidenceItem {
  /// Creates an item.
  const PinnedEvidenceItem(this.kind, this.text);

  /// The person's original request, [body] verbatim.
  factory PinnedEvidenceItem.request(String body) =>
      PinnedEvidenceItem(PinnedEvidenceKind.request, '$_requestHeading\n$body');

  /// A later message of the person, [body] verbatim.
  factory PinnedEvidenceItem.person(String body) =>
      PinnedEvidenceItem(PinnedEvidenceKind.person, '# User\n$body');

  /// System steering, [body] verbatim.
  factory PinnedEvidenceItem.steering(String body) => PinnedEvidenceItem(
    PinnedEvidenceKind.steering,
    '# System steering\n$body',
  );

  /// The kind.
  final PinnedEvidenceKind kind;

  /// The heading line and the message.
  final String text;

  /// The item as it is written in the block.
  String get rendered => '${kind.marker}\n$text';

  @override
  bool operator ==(Object other) =>
      other is PinnedEvidenceItem && other.kind == kind && other.text == text;

  @override
  int get hashCode => Object.hash(kind, text);

  @override
  String toString() => 'PinnedEvidenceItem(${kind.name}, $text)';
}

const String _requestHeading = '# User (original request)';

const String _shortenedRequestHeading =
    '# User (original request, shortened: its middle is not shown)';

final RegExp _itemMarker = RegExp(
  r'^<!--omp:pin ([a-z]+)-->$',
  multiLine: true,
);

final RegExp _omittedCount = RegExp(r'^\[(\d+) earlier pinned message');

/// The items of a pinned block's inner text ([splitPinnedEvidence]'s
/// `pinned`), in order. A block written before items had markers is one
/// item: the original request when it starts with the request heading,
/// steering otherwise.
List<PinnedEvidenceItem> parsePinnedEvidence(String inner) {
  final text = inner.trim();
  if (text.isEmpty) {
    return const [];
  }
  final matches = _itemMarker.allMatches(text).toList();
  if (matches.isEmpty) {
    return [
      PinnedEvidenceItem(
        text.startsWith(_requestHeading)
            ? PinnedEvidenceKind.request
            : PinnedEvidenceKind.steering,
        text,
      ),
    ];
  }
  final items = <PinnedEvidenceItem>[];
  final lead = text.substring(0, matches.first.start).trim();
  if (lead.isNotEmpty) {
    items.add(PinnedEvidenceItem(PinnedEvidenceKind.steering, lead));
  }
  for (var i = 0; i < matches.length; i++) {
    final m = matches[i];
    final kind = PinnedEvidenceKind.values.where((k) => k.name == m[1]);
    final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
    final body = text.substring(m.end, end).trim();
    if (body.isEmpty) {
      continue;
    }
    items.add(
      PinnedEvidenceItem(
        kind.isEmpty ? PinnedEvidenceKind.steering : kind.first,
        body,
      ),
    );
  }
  return items;
}

/// [items] fitted to [budget] characters and rendered as a block's inner
/// text (no outer markers); empty when there is nothing to pin.
///
/// The first [PinnedEvidenceKind.request] item comes first and is kept whole;
/// when it alone is over [budget], its head and tail are kept with a marker
/// between them that says how much of its middle is not shown, and its
/// heading says it was shortened. Any later request item counts as a later
/// message. The other items are kept newest first, each whole or not at
/// all, and shown in their original order; how many were left out (now and
/// by earlier folds) is said in one line after the request.
String fitPinnedEvidence(
  List<PinnedEvidenceItem> items, {
  required int budget,
}) {
  PinnedEvidenceItem? request;
  final others = <PinnedEvidenceItem>[];
  var omitted = 0;
  for (final item in items) {
    switch (item.kind) {
      case PinnedEvidenceKind.omitted:
        omitted +=
            int.tryParse(_omittedCount.firstMatch(item.text)?[1] ?? '') ?? 0;
      case PinnedEvidenceKind.request when request == null:
        request = item;
      case PinnedEvidenceKind.request:
        others.add(PinnedEvidenceItem(PinnedEvidenceKind.person, item.text));
      case PinnedEvidenceKind.person || PinnedEvidenceKind.steering:
        others.add(item);
    }
  }
  if (request == null && others.isEmpty) {
    return '';
  }
  var used = 0;
  if (request != null) {
    request = _fitRequest(request, budget);
    used += request.rendered.length + 2;
  }
  final kept = List<bool>.filled(others.length, false);
  for (var i = others.length - 1; i >= 0; i--) {
    final cost = others[i].rendered.length + 2;
    if (used + cost > budget) {
      omitted++;
      continue;
    }
    kept[i] = true;
    used += cost;
  }
  return [
    if (request != null) request.rendered,
    if (omitted > 0)
      PinnedEvidenceItem(
        PinnedEvidenceKind.omitted,
        '[$omitted earlier pinned message${omitted == 1 ? '' : 's'} left out: '
        'the pinned block holds at most $budget characters, so it keeps the '
        'original request and then the newest messages]',
      ).rendered,
    for (var i = 0; i < others.length; i++)
      if (kept[i]) others[i].rendered,
  ].join('\n\n');
}

/// The pinned inner texts of several blocks (the carried one first, then the
/// fold's own) merged into one, fitted to [budget] ([fitPinnedEvidence]).
String mergePinnedEvidence(List<String> inners, {required int budget}) =>
    fitPinnedEvidence([
      for (final inner in inners) ...parsePinnedEvidence(inner),
    ], budget: budget);

/// [request] whole when it fits [budget], else its head and tail around a
/// marker, never cutting inside a data envelope.
PinnedEvidenceItem _fitRequest(PinnedEvidenceItem request, int budget) {
  if (request.rendered.length <= budget) {
    return request;
  }
  final newline = request.text.indexOf('\n');
  final body = newline < 0 ? '' : request.text.substring(newline + 1);
  final overhead =
      PinnedEvidenceKind.request.marker.length +
      _shortenedRequestHeading.length +
      200;
  final keep = budget - overhead < 200 ? 200 : budget - overhead;
  final cut = clipKeepingEnvelopes(
    body,
    keep,
    marker: (omitted) =>
        '\n…[$omitted characters of the original request are not shown '
        'here: it is longer than the $budget characters the pinned block '
        'holds]…\n',
  );
  return PinnedEvidenceItem(
    PinnedEvidenceKind.request,
    '$_shortenedRequestHeading\n$cut',
  );
}

final RegExp _envelopeOpener = RegExp(
  '<$wakeDataTag id="([0-9a-z]{$wakeDataNonceMinChars,})">',
);

/// The spans of [text]'s data envelopes, each from its opener to the end of
/// the closer that repeats its id (or to the end of [text] when none does).
List<(int, int)> _envelopeSpans(String text) {
  final spans = <(int, int)>[];
  var from = 0;
  while (true) {
    final open = _envelopeOpener.firstMatch(text.substring(from));
    if (open == null) {
      return spans;
    }
    final start = from + open.start;
    final closer = '</$wakeDataTag id="${open[1]}">';
    final close = text.indexOf(closer, from + open.end);
    final end = close < 0 ? text.length : close + closer.length;
    spans.add((start, end));
    from = end;
  }
}

/// [text] cut to about [max] characters, keeping both ends (three quarters
/// head, one quarter tail) with [marker] (given how many characters were
/// left out) between them. A cut never falls inside a data envelope
/// (`<wake-data id="…">…</wake-data id="…">`): an envelope the head would cut
/// is left out from its opener, one the tail would cut is left out up to
/// its closer, so untrusted text never appears without its frame.
String clipKeepingEnvelopes(
  String text,
  int max, {
  String Function(int omitted)? marker,
}) {
  final trimmed = text.trim();
  if (max <= 0 || trimmed.length <= max) {
    return trimmed;
  }
  var headEnd = max * 3 ~/ 4;
  var tailStart = trimmed.length - (max - headEnd);
  for (final (start, end) in _envelopeSpans(trimmed)) {
    if (headEnd > start && headEnd < end) {
      headEnd = start;
    }
    if (tailStart > start && tailStart < end) {
      tailStart = end;
    }
  }
  if (tailStart < headEnd) {
    tailStart = headEnd;
  }
  final omitted = tailStart - headEnd;
  final between = marker?.call(omitted) ?? '…[truncated $omitted chars]…';
  return '${trimmed.substring(0, headEnd)}$between'
      '${trimmed.substring(tailStart)}';
}

/// [text] (the newest part of a longer text, as a tail bound keeps it)
/// without anything before the closer of an envelope whose opener was cut
/// away: the payload of an envelope never appears without its frame.
String dropOrphanedEnvelopeTail(String text) {
  final closer = RegExp(
    '</$wakeDataTag id="([0-9a-z]{$wakeDataNonceMinChars,})">',
  );
  for (final m in closer.allMatches(text)) {
    final opener = '<$wakeDataTag id="${m[1]}">';
    final before = text.substring(0, m.start);
    if (!before.contains(opener)) {
      return text.substring(m.end).trimLeft();
    }
  }
  return text;
}
