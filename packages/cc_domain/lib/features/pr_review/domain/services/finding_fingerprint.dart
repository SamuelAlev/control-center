// Finding identity ACROSS review passes — what makes a manual re-review
// delta-aware instead of amnesiac.
//
// The hard part is that nothing about a finding is stable. Message ids change
// (each pass files new ones), line numbers shift on every rebase, and a
// reviewer agent rarely rewords a finding identically twice. So the
// fingerprint deliberately excludes line numbers and normalizes the title down
// to its content words: `lib/auth.dart` + `bug` + {missing, null, check} is the
// same finding whether it was reported at line 42 or line 87.
//
// The tradeoff is chosen on purpose: a heavily reworded finding is reported as
// NEW rather than silently merged into an old one. Over-reporting "new" costs
// a reviewer a second look; under-reporting hides a finding they never saw.
//
// ignore_for_file: sort_constructors_first

import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';

/// Words carried by nearly every finding title, which therefore say nothing
/// about which finding it is.
const _stopWords = {
  'a',
  'an',
  'and',
  'are',
  'as',
  'at',
  'be',
  'but',
  'by',
  'can',
  'could',
  'for',
  'from',
  'has',
  'have',
  'in',
  'is',
  'it',
  'its',
  'may',
  'might',
  'not',
  'of',
  'on',
  'or',
  'should',
  'that',
  'the',
  'this',
  'to',
  'was',
  'will',
  'with',
  'would',
};

/// A finding reduced to what identifies it across passes.
class FindingFingerprint {
  /// Creates a [FindingFingerprint].
  const FindingFingerprint({
    required this.fingerprint,
    required this.messageId,
    required this.title,
    this.filePath,
    this.kind = ReviewNodeKind.bug,
    this.priority = ReviewNodePriority.p2,
    this.status = ReviewNodeStatus.open,
    this.provenance = '',
    this.ruleId = '',
  });

  /// The stable identity string.
  final String fingerprint;

  /// The channel message this fingerprint was taken from, in THIS pass.
  final String messageId;

  /// The finding's title/summary text as reported.
  final String title;

  /// The anchored file, when the finding had one.
  final String? filePath;

  /// The finding's kind.
  final ReviewNodeKind kind;

  /// The finding's priority.
  final ReviewNodePriority priority;

  /// The finding's status at the time of the pass.
  final ReviewNodeStatus status;

  /// `static` for deterministic findings, `agent` (or empty) otherwise.
  final String provenance;

  /// The static rule that produced it, when deterministic.
  final String ruleId;

  /// Whether the finding was still outstanding when the pass finalized.
  bool get isOpen =>
      status == ReviewNodeStatus.open ||
      status == ReviewNodeStatus.consensusReady;

  /// The normalized content words of [title], used for fuzzy matching.
  Set<String> get titleTokens => normalizeTitle(title);

  /// Builds from a stored JSON map, or null when unusable.
  static FindingFingerprint? fromJson(Map<String, dynamic> json) {
    final fingerprint = json['fp'];
    if (fingerprint is! String || fingerprint.isEmpty) {
      return null;
    }
    return FindingFingerprint(
      fingerprint: fingerprint,
      messageId: json['messageId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      filePath: json['filePath'] as String?,
      kind:
          ReviewNodeKind.fromName(json['kind'] as String?) ??
          ReviewNodeKind.bug,
      priority:
          ReviewNodePriority.fromName(json['priority'] as String?) ??
          ReviewNodePriority.p2,
      status:
          ReviewNodeStatus.fromName(json['status'] as String?) ??
          ReviewNodeStatus.open,
      provenance: json['provenance'] as String? ?? '',
      ruleId: json['ruleId'] as String? ?? '',
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'fp': fingerprint,
    'messageId': messageId,
    'title': title,
    if (filePath != null) 'filePath': filePath,
    'kind': kind.wireName,
    'priority': priority.wireName,
    'status': status.wireName,
    if (provenance.isNotEmpty) 'provenance': provenance,
    if (ruleId.isNotEmpty) 'ruleId': ruleId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FindingFingerprint &&
          runtimeType == other.runtimeType &&
          fingerprint == other.fingerprint &&
          messageId == other.messageId &&
          title == other.title &&
          filePath == other.filePath &&
          kind == other.kind &&
          priority == other.priority &&
          status == other.status &&
          provenance == other.provenance &&
          ruleId == other.ruleId;

  @override
  int get hashCode => Object.hash(
    fingerprint,
    messageId,
    title,
    filePath,
    kind,
    priority,
    status,
    provenance,
    ruleId,
  );
}

/// A previously-flagged finding matched to its current restatement.
class MatchedFinding {
  /// Creates a [MatchedFinding].
  const MatchedFinding({required this.previous, required this.current});

  /// The fingerprint as recorded in the earlier pass.
  final FindingFingerprint previous;

  /// The corresponding fingerprint in the current pass.
  final FindingFingerprint current;
}

/// What changed between two review passes.
class FindingDelta {
  /// Creates a [FindingDelta].
  const FindingDelta({
    this.resolvedSinceLast = const [],
    this.stillOpen = const [],
    this.newFindings = const [],
  });

  /// Findings the previous pass reported that this pass no longer reports (or
  /// now reports as resolved).
  final List<FindingFingerprint> resolvedSinceLast;

  /// Findings present in both passes and still outstanding.
  final List<MatchedFinding> stillOpen;

  /// Findings this pass reports that the previous pass did not.
  final List<FindingFingerprint> newFindings;

  /// Whether there was nothing to compare or nothing moved.
  bool get isEmpty =>
      resolvedSinceLast.isEmpty && stillOpen.isEmpty && newFindings.isEmpty;

  /// Message ids of the findings that are new in this pass.
  Set<String> get newMessageIds => {
    for (final f in newFindings)
      if (f.messageId.isNotEmpty) f.messageId,
  };

  /// Message ids of the findings carried over from the previous pass.
  Set<String> get stillOpenMessageIds => {
    for (final m in stillOpen)
      if (m.current.messageId.isNotEmpty) m.current.messageId,
  };
}

/// Reduces a title to its lowercase content words.
///
/// Numbers are dropped along with punctuation: a title that quotes a line
/// number or a count would otherwise never match itself after a rebase.
Set<String> normalizeTitle(String title) {
  final cleaned = title
      .toLowerCase()
      .replaceAll(RegExp(r'`[^`]*`'), ' ')
      .replaceAll(RegExp('[^a-z ]'), ' ');
  return {
    for (final word in cleaned.split(RegExp(r'\s+')))
      if (word.length > 2 && !_stopWords.contains(word)) word,
  };
}

/// Computes fingerprints and classifies one pass against the previous one.
class FindingFingerprinter {
  /// Creates a [FindingFingerprinter].
  const FindingFingerprinter({this.titleSimilarityFloor = 0.5});

  /// Minimum Jaccard similarity of two titles' content words for a fuzzy
  /// match, once file and kind already agree.
  final double titleSimilarityFloor;

  /// The stable identity of a finding.
  ///
  /// A static-rule finding folds its [ruleId] in instead of the title, which
  /// makes it exactly stable across passes: the same rule firing on the same
  /// file is the same finding, whatever the message text says.
  String fingerprintOf({
    String? filePath,
    required ReviewNodeKind kind,
    required String title,
    String ruleId = '',
  }) {
    final file = (filePath == null || filePath.isEmpty) ? '-' : filePath;
    if (ruleId.isNotEmpty) {
      return '$file|${kind.wireName}|rule:$ruleId';
    }
    final tokens = normalizeTitle(title).toList()..sort();
    // Cap the token set so one very long title cannot make its own bucket.
    final head = tokens.take(8).join(',');
    return '$file|${kind.wireName}|$head';
  }

  /// Classifies [current] against [previous].
  ///
  /// Matching is two-pass: exact fingerprint first, then a fuzzy pass over the
  /// leftovers (same file, same kind, title-token Jaccard at or above
  /// [titleSimilarityFloor]). Each previous finding matches at most once.
  FindingDelta classify({
    required List<FindingFingerprint> previous,
    required List<FindingFingerprint> current,
  }) {
    // Only findings the previous pass left outstanding can be "resolved" or
    // "still open" — one it already recorded as dismissed is settled history.
    final outstanding = [
      for (final p in previous)
        if (p.isOpen) p,
    ];

    final unmatchedPrevious = [...outstanding];
    final matched = <MatchedFinding>[];
    final unmatchedCurrent = <FindingFingerprint>[];

    // Pass 1 — exact fingerprint.
    final byFingerprint = <String, List<FindingFingerprint>>{};
    for (final p in unmatchedPrevious) {
      byFingerprint.putIfAbsent(p.fingerprint, () => []).add(p);
    }
    for (final c in current) {
      final bucket = byFingerprint[c.fingerprint];
      if (bucket != null && bucket.isNotEmpty) {
        final p = bucket.removeAt(0);
        unmatchedPrevious.remove(p);
        matched.add(MatchedFinding(previous: p, current: c));
      } else {
        unmatchedCurrent.add(c);
      }
    }

    // Pass 2 — fuzzy, over what is left on both sides.
    final stillUnmatchedCurrent = <FindingFingerprint>[];
    for (final c in unmatchedCurrent) {
      FindingFingerprint? best;
      var bestScore = 0.0;
      for (final p in unmatchedPrevious) {
        if (p.kind != c.kind || p.filePath != c.filePath) {
          continue;
        }
        final score = _jaccard(p.titleTokens, c.titleTokens);
        if (score >= titleSimilarityFloor && score > bestScore) {
          best = p;
          bestScore = score;
        }
      }
      if (best == null) {
        stillUnmatchedCurrent.add(c);
      } else {
        unmatchedPrevious.remove(best);
        matched.add(MatchedFinding(previous: best, current: c));
      }
    }

    return FindingDelta(
      // A carried-over finding the current pass marks resolved/dismissed
      // counts as resolved, not as still-open.
      resolvedSinceLast: [
        ...unmatchedPrevious,
        for (final m in matched)
          if (!m.current.isOpen) m.previous,
      ],
      stillOpen: [
        for (final m in matched)
          if (m.current.isOpen) m,
      ],
      newFindings: stillUnmatchedCurrent,
    );
  }

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) {
      return 1;
    }
    if (a.isEmpty || b.isEmpty) {
      return 0;
    }
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return union == 0 ? 0 : intersection / union;
  }
}
