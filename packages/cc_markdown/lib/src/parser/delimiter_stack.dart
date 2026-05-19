/// The CommonMark delimiter-run algorithm for `*` / `_` emphasis and GFM
/// `~~` strikethrough.
///
/// Ported in structure from the spec's reference algorithm (and package
/// markdown 7.3.1's `_processDelimiterRun`): the scanner pushes delimiter
/// runs as [CcDelimiterRun] entries interleaved with finished nodes in one
/// work list; [processEmphasis] then pairs closers with openers bottom-up,
/// honoring flanking, the multiple-of-3 rule, and strong-first pairing.
library;

import 'package:cc_markdown/src/ast/nodes.dart';

/// A delimiter run in the inline work list (an entry that is either this or a
/// finished [CcInlineNode]).
final class CcDelimiterRun {
  /// Creates a delimiter run.
  CcDelimiterRun({
    required this.char,
    required this.count,
    required this.canOpen,
    required this.canClose,
  }) : originalCount = count;

  /// The delimiter code unit (`*`, `_`, or `~`).
  final int char;

  /// Remaining (unconsumed) delimiter characters in the run.
  int count;

  /// Length of the run as scanned (for the multiple-of-3 rule).
  final int originalCount;

  /// Whether the run can open emphasis (left-flanking rules applied).
  final bool canOpen;

  /// Whether the run can close emphasis (right-flanking rules applied).
  final bool canClose;

  /// Cleared when a link is resolved across this run (links deactivate
  /// enclosed openers) — an inactive run can still render as literal text.
  bool active = true;

  /// The literal text for the remaining run.
  String get literal => String.fromCharCode(char) * count;
}

const int _star = 0x2A; // *
const int _underscore = 0x5F; // _
const int _tilde = 0x7E; // ~

/// Whether [unit] is (simplified) Unicode whitespace for flanking purposes.
bool ccIsWhitespace(int unit) =>
    unit == 0x20 ||
    unit == 0x09 ||
    unit == 0x0A ||
    unit == 0x0D ||
    unit == 0x0C ||
    unit == 0xA0;

/// Whether [unit] is ASCII punctuation (the class the flanking rules use;
/// simplified to ASCII, which covers the app's corpus).
bool ccIsPunctuation(int unit) =>
    (unit >= 0x21 && unit <= 0x2F) ||
    (unit >= 0x3A && unit <= 0x40) ||
    (unit >= 0x5B && unit <= 0x60) ||
    (unit >= 0x7B && unit <= 0x7E);

/// Computes a [CcDelimiterRun] for a run of [count] × [char] with the given
/// neighbors ([before]/[after] are code units; -1 at text boundaries).
CcDelimiterRun classifyDelimiterRun({
  required int char,
  required int count,
  required int before,
  required int after,
}) {
  final beforeWs = before == -1 || ccIsWhitespace(before);
  final afterWs = after == -1 || ccIsWhitespace(after);
  final beforePunct = before != -1 && ccIsPunctuation(before);
  final afterPunct = after != -1 && ccIsPunctuation(after);

  final leftFlanking = !afterWs && (!afterPunct || beforeWs || beforePunct);
  final rightFlanking = !beforeWs && (!beforePunct || afterWs || afterPunct);

  bool canOpen;
  bool canClose;
  if (char == _underscore) {
    canOpen = leftFlanking && (!rightFlanking || beforePunct);
    canClose = rightFlanking && (!leftFlanking || afterPunct);
  } else {
    canOpen = leftFlanking;
    canClose = rightFlanking;
  }
  return CcDelimiterRun(
    char: char,
    count: count,
    canOpen: canOpen,
    canClose: canClose,
  );
}

/// Runs the pairing phase over [items] (a mix of [CcInlineNode] and
/// [CcDelimiterRun]) from [stackBottom] onward, replacing paired runs with
/// [CcEmphasis]/[CcStrong]/[CcStrikethrough] nodes in place.
///
/// Leftover runs are NOT converted to text here — the caller flattens them
/// via [flattenInlineItems] so partially-consumed runs keep their remaining
/// literal characters.
void processEmphasis(List<Object> items, int stackBottom) {
  var closerIndex = stackBottom;
  while (closerIndex < items.length) {
    final closerItem = items[closerIndex];
    if (closerItem is! CcDelimiterRun || !closerItem.canClose) {
      closerIndex++;
      continue;
    }
    final closer = closerItem;

    // Find the nearest matching opener below the closer.
    var openerIndex = closerIndex - 1;
    CcDelimiterRun? opener;
    while (openerIndex >= stackBottom) {
      final candidate = items[openerIndex];
      if (candidate is CcDelimiterRun &&
          candidate.char == closer.char &&
          candidate.canOpen &&
          candidate.active &&
          candidate.count > 0 &&
          !_violatesRuleOfThree(candidate, closer) &&
          (closer.char != _tilde ||
              (candidate.originalCount == 2 && closer.originalCount == 2))) {
        opener = candidate;
        break;
      }
      openerIndex--;
    }

    if (opener == null) {
      // No opener: if this run can't open either, it will never pair — leave
      // it to flatten as text. Either way move on.
      closerIndex++;
      continue;
    }

    final use = closer.char == _tilde
        ? 2
        : (opener.count >= 2 && closer.count >= 2)
        ? 2
        : 1;

    // Children: everything strictly between opener and closer; leftover inner
    // delimiter runs become literal text (they can no longer pair).
    final children = flattenInlineItems(
      items.sublist(openerIndex + 1, closerIndex),
    );

    final CcInlineNode node = switch (closer.char) {
      _tilde => CcStrikethrough(children),
      _ => use == 2 ? CcStrong(children) : CcEmphasis(children),
    };

    opener.count -= use;
    closer.count -= use;

    // Replace the inner span with the single wrapped node.
    items.removeRange(openerIndex + 1, closerIndex);
    items.insert(openerIndex + 1, node);
    closerIndex = openerIndex + 2; // position of the closer now

    if (opener.count <= 0) {
      items.removeAt(openerIndex);
      closerIndex--;
    }
    if (closer.count <= 0) {
      items.removeAt(closerIndex);
    }
    // Re-scan from the closer position: the same closer may pair again with
    // an earlier opener (e.g. ***a*** consuming 2 then 1).
  }
}

/// Rule of three (CommonMark 6.2, rules 9–10): when one of the two runs can
/// both open and close, the pair is forbidden if the combined length is a
/// multiple of 3 — unless both lengths are themselves multiples of 3.
bool _violatesRuleOfThree(CcDelimiterRun opener, CcDelimiterRun closer) {
  if (closer.char == _tilde) {
    return false;
  }
  final oneIsBoth =
      (opener.canOpen && opener.canClose) ||
      (closer.canOpen && closer.canClose);
  if (!oneIsBoth) {
    return false;
  }
  final sum = opener.originalCount + closer.originalCount;
  if (sum % 3 != 0) {
    return false;
  }
  return opener.originalCount % 3 != 0 || closer.originalCount % 3 != 0;
}

/// Collapses a work list into finished inline nodes: leftover delimiter runs
/// become literal text and adjacent [CcText] nodes merge.
List<CcInlineNode> flattenInlineItems(List<Object> items) {
  final out = <CcInlineNode>[];
  final buffer = StringBuffer();

  void flushBuffer() {
    if (buffer.isNotEmpty) {
      out.add(CcText(buffer.toString()));
      buffer.clear();
    }
  }

  for (final item in items) {
    switch (item) {
      case final CcDelimiterRun run:
        if (run.count > 0) {
          buffer.write(run.literal);
        }
      case final CcText text:
        buffer.write(text.text);
      case final CcInlineNode node:
        flushBuffer();
        out.add(node);
      default:
        assert(false, 'Unexpected inline work item: $item');
    }
  }
  flushBuffer();
  return out;
}

/// Marker export so `_star`/`_underscore` stay private; the parser passes raw
/// code units.
const List<int> ccEmphasisDelimiters = [_star, _underscore, _tilde];
