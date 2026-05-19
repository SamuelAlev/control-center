import 'dart:math' as math;

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/foundation.dart';

@immutable
class _CharRange {
  const _CharRange(this.start, this.end);
  final int start; // inclusive
  final int end; // exclusive

  @override
  bool operator ==(Object other) =>
      other is _CharRange && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
}

@immutable
class _DiffRanges {
  const _DiffRanges({required this.oldRanges, required this.newRanges});
  final Set<_CharRange> oldRanges;
  final Set<_CharRange> newRanges;
}

@immutable
class _Pair {
  const _Pair(this.delIdx, this.addIdx, this.similarity);
  final int delIdx;
  final int addIdx;
  final double similarity;
}

/// Lines must have at least this much content similarity to be paired for
/// word-diffing. Below this, they're treated as independent insert/deletes.
const double _pairThreshold = 0.3;

/// Computes changed character ranges using the diff_match_patch library
/// (Myers' diff algorithm + semantic cleanup).
_DiffRanges _computeDiffRanges(String a, String b) {
  if (a.isEmpty && b.isEmpty) {
    return const _DiffRanges(oldRanges: {}, newRanges: {});
  }
  if (a.isEmpty) {
    return _DiffRanges(oldRanges: {}, newRanges: {_CharRange(0, b.length)});
  }
  if (b.isEmpty) {
    return _DiffRanges(oldRanges: {_CharRange(0, a.length)}, newRanges: {});
  }

  final dmp = DiffMatchPatch();
  final diffs = dmp.diff(a, b);
  dmp.diffCleanupSemantic(diffs);

  final oldRanges = <_CharRange>{};
  final newRanges = <_CharRange>{};
  var oldPos = 0;
  var newPos = 0;

  for (final diff in diffs) {
    switch (diff.operation) {
      case DIFF_EQUAL:
        oldPos += diff.text.length;
        newPos += diff.text.length;
        break;
      case DIFF_DELETE:
        oldRanges.add(_CharRange(oldPos, oldPos + diff.text.length));
        oldPos += diff.text.length;
        break;
      case DIFF_INSERT:
        newRanges.add(_CharRange(newPos, newPos + diff.text.length));
        newPos += diff.text.length;
        break;
    }
  }

  return _DiffRanges(oldRanges: oldRanges, newRanges: newRanges);
}

/// Splits [tokens] at the boundaries of [changedRanges], assigning
/// [changedColor] to tokens (or token segments) that fall inside a changed
/// range. Tokens outside all changed ranges keep their original [DiffToken.colorValue].
List<DiffToken> _applyDiffToTokens(
  List<DiffToken> tokens,
  Set<_CharRange> changedRanges,
  int changedColor,
  int changedBgColor,
) {
  if (changedRanges.isEmpty) {
    return tokens;
  }
  final out = <DiffToken>[];
  var offset = 0;
  for (final token in tokens) {
    final tokenStart = offset;
    final tokenEnd = offset + token.text.length;
    offset = tokenEnd;

    final intersecting =
        changedRanges
            .where((r) => r.start < tokenEnd && r.end > tokenStart)
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    if (intersecting.isEmpty) {
      out.add(token);
      continue;
    }

    final merged = <_CharRange>[];
    for (final r in intersecting) {
      final clipped = _CharRange(
        math.max(r.start, tokenStart),
        math.min(r.end, tokenEnd),
      );
      if (merged.isEmpty) {
        merged.add(clipped);
      } else {
        final last = merged.last;
        if (clipped.start <= last.end) {
          merged[merged.length - 1] = _CharRange(
            last.start,
            math.max(last.end, clipped.end),
          );
        } else {
          merged.add(clipped);
        }
      }
    }

    var cursor = tokenStart;
    for (final range in merged) {
      if (cursor < range.start) {
        out.add(
          DiffToken(
            token.text.substring(cursor - tokenStart, range.start - tokenStart),
            token.colorValue,
          ),
        );
      }
      if (range.start < range.end) {
        out.add(
          DiffToken(
            token.text.substring(
              range.start - tokenStart,
              range.end - tokenStart,
            ),
            changedColor,
            backgroundColorValue: changedBgColor,
          ),
        );
      }
      cursor = range.end;
    }
    if (cursor < tokenEnd) {
      out.add(
        DiffToken(token.text.substring(cursor - tokenStart), token.colorValue),
      );
    }
  }
  return out;
}

String _specText(DiffLineSpec spec) =>
    spec.tokens.fold<String>('', (s, t) => s + t.text);

/// The "body" text with leading whitespace stripped — used for similarity
/// comparisons so that indent differences don't sway the pairing decision.
String _specBodyText(DiffLineSpec spec) => _specText(spec).trimLeft();

/// Content similarity ratio using Levenshtein distance.
/// Returns 0.0 (completely different) to 1.0 (identical).
double _similarity(DiffMatchPatch dmp, String a, String b) {
  if (a == b) {
    return 1.0;
  }

  if (a.isEmpty || b.isEmpty) {
    return 0.0;
  }

  final diffs = dmp.diff(a, b);
  final distance = dmp.diff_levenshtein(diffs);
  final maxLen = math.max(a.length, b.length);
  return 1.0 - (distance / maxLen);
}

/// Matches deletion lines to addition lines by content similarity within a
/// single hunk block, then applies word-diff to each matched pair.
/// Unmatched lines keep their full-line highlighting.
void _pairAndDiff(
  List<DiffLineSpec> specs,
  List<int> delIndices,
  List<int> addIndices,
  int delColor,
  int addColor,
  int delBgColor,
  int addBgColor,
) {
  if (delIndices.isEmpty || addIndices.isEmpty) {
    return;
  }

  void applyPair(int delIdx, int addIdx) {
    final delText = _specText(specs[delIndices[delIdx]]);
    final addText = _specText(specs[addIndices[addIdx]]);
    if (delText == addText || delText.isEmpty || addText.isEmpty) {
      return;
    }

    final diff = _computeDiffRanges(delText, addText);

    final delSpecIdx = delIndices[delIdx];
    final addSpecIdx = addIndices[addIdx];

    specs[delSpecIdx] = DiffLineSpec(
      kind: specs[delSpecIdx].kind,
      tokens: _applyDiffToTokens(
        specs[delSpecIdx].tokens,
        diff.oldRanges,
        delColor,
        delBgColor,
      ),
      oldLine: specs[delSpecIdx].oldLine,
      newLine: specs[delSpecIdx].newLine,
    );

    specs[addSpecIdx] = DiffLineSpec(
      kind: specs[addSpecIdx].kind,
      tokens: _applyDiffToTokens(
        specs[addSpecIdx].tokens,
        diff.newRanges,
        addColor,
        addBgColor,
      ),
      oldLine: specs[addSpecIdx].oldLine,
      newLine: specs[addSpecIdx].newLine,
    );
  }

  // Special case: exactly one deletion and one addition — always pair them
  // regardless of similarity. Handles single-line rewrites gracefully.
  if (delIndices.length == 1 && addIndices.length == 1) {
    applyPair(0, 0);
    return;
  }

  final dmp = DiffMatchPatch();

  // Use body text (leading whitespace stripped) for similarity so that indent
  // differences don't distract from content-level matching. The full text
  // (including whitespace) is used for the actual word-diff inside applyPair.
  final delBodyTexts = delIndices.map((i) => _specBodyText(specs[i])).toList();
  final addBodyTexts = addIndices.map((i) => _specBodyText(specs[i])).toList();

  final pairs = <_Pair>[];
  for (var di = 0; di < delBodyTexts.length; di++) {
    for (var ai = 0; ai < addBodyTexts.length; ai++) {
      final s = _similarity(dmp, delBodyTexts[di], addBodyTexts[ai]);
      if (s >= _pairThreshold) {
        pairs.add(_Pair(di, ai, s));
      }
    }
  }

  // Match greedily: highest similarity first, each line used at most once.
  pairs.sort((a, b) => b.similarity.compareTo(a.similarity));

  final matchedDel = <int>{};
  final matchedAdd = <int>{};

  for (final pair in pairs) {
    if (matchedDel.contains(pair.delIdx) || matchedAdd.contains(pair.addIdx)) {
      continue;
    }
    matchedDel.add(pair.delIdx);
    matchedAdd.add(pair.addIdx);
    applyPair(pair.delIdx, pair.addIdx);
  }
}

/// Walks [specs] (a flat list of diff lines with precomputed tokens) and
/// applies inline diff highlighting.
///
/// Lines are grouped by hunk: within each hunk, deletion and addition lines
/// are paired by **content similarity** (not adjacency), so reorganizations
/// like wrapping existing code in a new `<div>` produce the correct word-diff
/// pairings. Unmatched lines keep full-line highlighting.
void applyInlineWordDiff(List<DiffLineSpec> specs, Map<String, int> palette) {
  final delColor = palette['deletion'];
  final addColor = palette['addition'];
  if (delColor == null || addColor == null) {
    return;
  }
  final delBgColor = (delColor & 0x00FFFFFF) | 0x66000000;
  final addBgColor = (addColor & 0x00FFFFFF) | 0x66000000;

  var i = 0;
  while (i < specs.length) {
    if (specs[i].kind != DiffLineKind.hunkHeader) {
      i++;
      continue;
    }
    // Advance past the hunk header, collect deletion / addition indices
    // within this hunk block (stops at next header or end-of-list).
    i++;
    final delIndices = <int>[];
    final addIndices = <int>[];
    while (i < specs.length && specs[i].kind != DiffLineKind.hunkHeader) {
      final spec = specs[i];
      if (spec.kind == DiffLineKind.deletion) {
        delIndices.add(i);
      } else if (spec.kind == DiffLineKind.addition) {
        addIndices.add(i);
      }
      i++;
    }
    _pairAndDiff(
      specs,
      delIndices,
      addIndices,
      delColor,
      addColor,
      delBgColor,
      addBgColor,
    );
  }
}
