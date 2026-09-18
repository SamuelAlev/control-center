import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_lookup_port.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Whether the VS Code go-to-definition modifier is currently held: ⌘ on
/// macOS, Ctrl on Windows/Linux (the inverse of `editor.multiCursorModifier:
/// alt`).
bool isDiffGotoModifierHeld() {
  final kb = HardwareKeyboard.instance;
  final isMac = defaultTargetPlatform == TargetPlatform.macOS;
  return isMac ? kb.isMetaPressed : kb.isControlPressed;
}

/// Kind of interactive span under a Cmd/Ctrl+hover in the unified diff.
enum DiffGotoKind {
  /// A JS/TS regexp literal (`/pattern/flags`).
  regexp,

  /// A code-graph symbol (class, function, type name).
  identifier,
}

/// A display-column range on one diff line that Cmd/Ctrl+click can open.
@immutable
class DiffInteractiveSpan {
  /// Creates a [DiffInteractiveSpan].
  const DiffInteractiveSpan({
    required this.kind,
    required this.fileIndex,
    required this.displayLine,
    required this.startCol,
    required this.endCol,
    required this.text,
  });

  /// Whether this span is a regexp literal or an identifier.
  final DiffGotoKind kind;

  /// File index in the current diff document.
  final int fileIndex;

  /// Display line (not the raw parser index).
  final int displayLine;

  /// Inclusive display-column start (tabs expanded).
  final int startCol;

  /// Exclusive display-column end.
  final int endCol;

  /// Source text of the span (raw, tabs unexpanded).
  final String text;

  @override
  bool operator ==(Object other) =>
      other is DiffInteractiveSpan &&
      other.kind == kind &&
      other.fileIndex == fileIndex &&
      other.displayLine == displayLine &&
      other.startCol == startCol &&
      other.endCol == endCol &&
      other.text == text;

  @override
  int get hashCode =>
      Object.hash(kind, fileIndex, displayLine, startCol, endCol, text);
}

/// Transient "you landed here" mark after jumping to a go-to candidate.
@immutable
class DiffGotoLanding {
  /// Creates a [DiffGotoLanding].
  const DiffGotoLanding({
    required this.fileIndex,
    required this.displayLine,
    required this.startCol,
    this.endCol,
  });

  /// File index in the current diff document.
  final int fileIndex;

  /// Display line that was scrolled into view.
  final int displayLine;

  /// Inclusive display-column start of the identifier, or 0 for a whole-line
  /// fallback when the name cannot be placed.
  final int startCol;

  /// Exclusive display-column end of the identifier. Null means the rest of
  /// the line (fallback when the name is not on the row).
  final int? endCol;

  @override
  bool operator ==(Object other) =>
      other is DiffGotoLanding &&
      other.fileIndex == fileIndex &&
      other.displayLine == displayLine &&
      other.startCol == startCol &&
      other.endCol == endCol;

  @override
  int get hashCode => Object.hash(fileIndex, displayLine, startCol, endCol);
}

/// How long the landing flash stays after a go-to jump.
const Duration kGotoLandingFade = Duration(seconds: 3);

/// Display-column range of [name] on [lineText], or null if it is not there.
///
/// Prefers a [DiffTokenKind.symbol] token of that exact text (the identifier
/// the grammar already classified). Falls back to a whole-identifier match
/// that will not attach through a preceding `.` (`obj.name` is a use, not a
/// definition).
(int, int)? diffGotoNameDisplayRange(
  String lineText,
  String name, {
  List<DiffToken>? tokens,
}) {
  if (name.isEmpty) {
    return null;
  }
  if (tokens != null && tokens.isNotEmpty) {
    var offset = 0;
    for (final token in tokens) {
      if (token.kind == DiffTokenKind.symbol && token.text == name) {
        return (
          PrDiffDocument.rawColToDisplayCol(lineText, offset),
          PrDiffDocument.rawColToDisplayCol(
            lineText,
            offset + token.text.length,
          ),
        );
      }
      offset += token.text.length;
    }
  }
  final match = RegExp(
    '(^|[^\\w.\$])(${RegExp.escape(name)})\\b',
  ).firstMatch(lineText);
  if (match == null) {
    return null;
  }
  final start = match.start + match[1]!.length;
  return (
    PrDiffDocument.rawColToDisplayCol(lineText, start),
    PrDiffDocument.rawColToDisplayCol(lineText, start + name.length),
  );
}

/// Resolves the interactive span at [displayCol] on [lineText].
///
/// Only tokens classified as [DiffTokenKind.regexp] or [DiffTokenKind.symbol]
/// are interactive — there is no word-under-cursor fallback, so JSON keys,
/// comments, keywords, and unscoped locals never underline. Adjacent tokens
/// of the same kind are merged so `/foo/g` or a split identifier is one span.
/// Regexp wins when both kinds sit on the same column.
DiffInteractiveSpan? interactiveSpanAt({
  required String lineText,
  required int displayCol,
  required int fileIndex,
  required int displayLine,
  List<DiffToken>? tokens,
}) {
  if (tokens == null || tokens.isEmpty) {
    return null;
  }
  final rawCol = PrDiffDocument.displayColToRawCol(lineText, displayCol);
  final regexp = _tokenKindRawRange(tokens, rawCol, DiffTokenKind.regexp);
  if (regexp != null) {
    return DiffInteractiveSpan(
      kind: DiffGotoKind.regexp,
      fileIndex: fileIndex,
      displayLine: displayLine,
      startCol: PrDiffDocument.rawColToDisplayCol(lineText, regexp.$1),
      endCol: PrDiffDocument.rawColToDisplayCol(lineText, regexp.$2),
      text: lineText.substring(regexp.$1, regexp.$2),
    );
  }
  final symbol = _tokenKindRawRange(tokens, rawCol, DiffTokenKind.symbol);
  if (symbol == null) {
    return null;
  }
  final text = lineText.substring(symbol.$1, symbol.$2);
  if (isDiffGotoIgnoredName(text)) {
    return null;
  }
  return DiffInteractiveSpan(
    kind: DiffGotoKind.identifier,
    fileIndex: fileIndex,
    displayLine: displayLine,
    startCol: PrDiffDocument.rawColToDisplayCol(lineText, symbol.$1),
    endCol: PrDiffDocument.rawColToDisplayCol(lineText, symbol.$2),
    text: text,
  );
}

/// Names TextMate may mark as symbols that are never in the code graph
/// (keywords-as-identifiers, JS/TS primitives).
bool isDiffGotoIgnoredName(String name) {
  if (name.length < 2) {
    return true;
  }
  return _kDiffGotoIgnoredNames.contains(name);
}

const Set<String> _kDiffGotoIgnoredNames = {
  'null',
  'undefined',
  'true',
  'false',
  'this',
  'super',
  'new',
  'typeof',
  'instanceof',
  'void',
  'any',
  'never',
  'unknown',
  'NaN',
  'Infinity',
};

/// Cap on in-diff definition hits so a huge PR cannot inflate the popover.
const int kMaxDiffDefinitionHits = 20;

/// A likely definition recovered from a loaded pull-request diff.
@immutable
class DiffDefinitionHit {
  /// Creates a [DiffDefinitionHit].
  const DiffDefinitionHit({
    required this.filePath,
    required this.startLine,
    required this.kind,
  });

  /// Repo-relative path of the file that contains the hit.
  final String filePath;

  /// 1-based post-image line number.
  final int startLine;

  /// Best-effort kind inferred from the matching line.
  final CodeSymbolKind kind;
}

/// Builds a lookup result from in-diff definition hits.
CodeGraphLookupResult lookupResultFromDiffHits(
  String name,
  List<DiffDefinitionHit> hits,
) {
  return CodeGraphLookupResult(
    fromBasePartition: false,
    fromDiff: true,
    definitions: [
      for (final hit in hits)
        CodeGraphLookupCandidate(
          id: 'diff:${hit.filePath}:${hit.startLine}',
          name: name,
          qualifiedName: name,
          kind: hit.kind,
          filePath: hit.filePath,
          startLine: hit.startLine,
          endLine: hit.startLine,
        ),
    ],
  );
}

/// Scans loaded PR files for likely definitions of [name].
///
/// Used when the code-graph index has nothing (typical for a PR worktree
/// that has not been indexed yet). Deletion lines are skipped so we do not
/// jump to a name the PR is removing.
List<DiffDefinitionHit> diffDefinitionsNamed({
  required String name,
  required PrDiffDocument document,
  required DiffRawLines Function(int fileIndex) ensureStructure,
}) {
  if (isDiffGotoIgnoredName(name)) {
    return const [];
  }
  final pattern = diffDefinitionPattern(name);
  final hits = <DiffDefinitionHit>[];
  for (var f = 0; f < document.fileCount; f++) {
    final path = document.files[f].filename;
    final raw = ensureStructure(f);
    for (var i = 0; i < raw.length; i++) {
      final kind = raw.kindAt(i);
      if (kind == DiffLineKind.hunkHeader ||
          kind == DiffLineKind.expandGap ||
          kind == DiffLineKind.deletion) {
        continue;
      }
      final line = raw.newLines[i];
      if (line == null) {
        continue;
      }
      final content = raw.contents[i];
      if (!pattern.hasMatch(content)) {
        continue;
      }
      hits.add(
        DiffDefinitionHit(
          filePath: path,
          startLine: line,
          kind: diffDefinitionKindForLine(content, name),
        ),
      );
      if (hits.length >= kMaxDiffDefinitionHits) {
        return hits;
      }
    }
  }
  return hits;
}

/// Conservative definition heuristics for [name] on a single source line.
RegExp diffDefinitionPattern(String name) {
  final n = RegExp.escape(name);
  return RegExp(
    '(?:'
    r'(?:^|[^\w.$])(?:export\s+)?(?:default\s+)?(?:async\s+)?'
    r'(?:abstract\s+)?'
    r'(?:function|class|interface|type|enum|struct|extension|mixin|'
    r'typedef|fn|func|def|trait|impl|protocol)\s+'
    '$n'
    r'\b'
    r'|(?:^|[^\w.$])(?:export\s+)?(?:const|let|var|final|val)\s+(?:async\s+)?'
    '$n'
    r'\b'
    r'|(?:^|[^\w.$])'
    '$n'
    r'\s*(?:<[^>\n]{0,80}>)?\s*\([^)]{0,200}\)\s*\{'
    r'|(?:^|[^\w.$])'
    '$n'
    r'\s*=\s*(?:async\s+)?(?:function\b|\([^)]{0,200}\)\s*=>)'
    ')',
  );
}

/// Best-effort [CodeSymbolKind] from a line that already matched
/// [diffDefinitionPattern].
CodeSymbolKind diffDefinitionKindForLine(String line, String name) {
  final n = RegExp.escape(name);
  if (RegExp(r'\bclass\s+' + n + r'\b').hasMatch(line) ||
      RegExp(r'\b(?:interface|protocol|trait)\s+' + n + r'\b').hasMatch(line)) {
    return CodeSymbolKind.classKind;
  }
  if (RegExp(r'\benum\s+' + n + r'\b').hasMatch(line)) {
    return CodeSymbolKind.enumKind;
  }
  if (RegExp(r'\bmixin\s+' + n + r'\b').hasMatch(line)) {
    return CodeSymbolKind.mixin;
  }
  if (RegExp(r'\bextension\s+' + n + r'\b').hasMatch(line)) {
    return CodeSymbolKind.extension;
  }
  if (RegExp(r'\b(?:typedef|type)\s+' + n + r'\b').hasMatch(line)) {
    return CodeSymbolKind.typedefKind;
  }
  if (RegExp(
    r'\b(?:const|let|var|final|val)\s+(?:async\s+)?' + n + r'\b',
  ).hasMatch(line)) {
    return CodeSymbolKind.variable;
  }
  return CodeSymbolKind.function;
}

(int, int)? _tokenKindRawRange(List<DiffToken> tokens, int rawCol, int kind) {
  var offset = 0;
  var runStart = -1;
  var runEnd = -1;
  var hit = false;
  void flush() {
    runStart = -1;
    runEnd = -1;
    hit = false;
  }

  for (final token in tokens) {
    final start = offset;
    final end = offset + token.text.length;
    if (token.kind == kind) {
      if (runStart < 0) {
        runStart = start;
      }
      runEnd = end;
      if (rawCol >= start && rawCol < end) {
        hit = true;
      } else if (rawCol == end) {
        hit = true;
      }
    } else {
      if (hit && runStart >= 0) {
        return (runStart, runEnd);
      }
      flush();
    }
    offset = end;
  }
  if (hit && runStart >= 0) {
    return (runStart, runEnd);
  }
  return null;
}

/// Slash-normalized equality for a PR filename vs a code-graph `filePath`.
bool diffFilePathsMatch(String a, String b) {
  String norm(String path) {
    var p = path.replaceAll(r'\', '/');
    if (p.startsWith('./')) {
      p = p.substring(2);
    }
    return p;
  }

  final left = norm(a);
  final right = norm(b);
  if (left == right) {
    return true;
  }
  return left.endsWith('/$right') || right.endsWith('/$left');
}

/// A parsed JS/TS `/pattern/flags` literal, mapped onto Dart [RegExp] options.
@immutable
class ParsedJsRegex {
  /// Creates a [ParsedJsRegex].
  const ParsedJsRegex({
    required this.pattern,
    required this.flags,
    required this.caseSensitive,
    required this.multiLine,
    required this.dotAll,
    required this.unicode,
    required this.global,
  });

  /// Pattern body (delimiters stripped).
  final String pattern;

  /// Raw trailing flags (`imsu` plus JS-only `gyd`).
  final String flags;

  /// `i` → Dart `caseSensitive: false`.
  final bool caseSensitive;

  /// `m`.
  final bool multiLine;

  /// `s` (`dotAll`).
  final bool dotAll;

  /// `u`.
  final bool unicode;

  /// `g` — Dart has no constructor flag; the tester uses [RegExp.allMatches].
  final bool global;

  /// Builds a Dart [RegExp], throwing [FormatException] on a bad pattern.
  RegExp toRegExp() => RegExp(
    pattern,
    caseSensitive: caseSensitive,
    multiLine: multiLine,
    dotAll: dotAll,
    unicode: unicode,
  );
}

/// Parses a JS/TS `/pattern/flags` literal. Returns null when [literal] is
/// not slash-delimited.
ParsedJsRegex? parseJsRegexLiteral(String literal) {
  final s = literal.trim();
  if (s.length < 2 || !s.startsWith('/')) {
    return null;
  }
  var i = 1;
  var closed = -1;
  while (i < s.length) {
    final c = s[i];
    if (c == r'\') {
      i += 2;
      continue;
    }
    if (c == '/') {
      closed = i;
      break;
    }
    i++;
  }
  if (closed < 0) {
    return null;
  }
  final pattern = s.substring(1, closed);
  final flags = s.substring(closed + 1);
  var caseSensitive = true;
  var multiLine = false;
  var dotAll = false;
  var unicode = false;
  var global = false;
  for (var f = 0; f < flags.length; f++) {
    switch (flags[f]) {
      case 'i':
        caseSensitive = false;
      case 'm':
        multiLine = true;
      case 's':
        dotAll = true;
      case 'u':
        unicode = true;
      case 'g':
        global = true;
      case 'y':
      case 'd':
      case 'v':
        break;
      default:
        // Unknown flag — still try to compile the pattern.
        break;
    }
  }
  return ParsedJsRegex(
    pattern: pattern,
    flags: flags,
    caseSensitive: caseSensitive,
    multiLine: multiLine,
    dotAll: dotAll,
    unicode: unicode,
    global: global,
  );
}

/// Opaque Cmd/Ctrl+click target used by the overlay (and by widget tests).
class DiffGotoHitTarget extends StatelessWidget {
  /// Creates a [DiffGotoHitTarget].
  const DiffGotoHitTarget({
    super.key,
    required this.onActivate,
    required this.child,
  });

  /// Fired on tap only while the go-to modifier is held.
  final VoidCallback onActivate;

  /// Visual child (typically empty — the overlay paints a click cursor).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isDiffGotoModifierHeld()) {
          onActivate();
        }
      },
      child: MouseRegion(cursor: SystemMouseCursors.click, child: child),
    );
  }
}

/// Gap between the trigger span and the flyout.
const double kGotoPopoverGap = 6;

/// Breathing room between the flyout and the overlay edge.
const double kGotoPopoverMargin = 8;

/// Top-left of a popover of [childSize] relative to [anchor] inside [viewport].
///
/// Prefers just below the trigger; flips just above when the preferred side
/// cannot fit the *actual* child (not a guessed height).
Offset gotoPopoverOrigin({
  required Rect anchor,
  required Size childSize,
  required Size viewport,
  double gap = kGotoPopoverGap,
  double margin = kGotoPopoverMargin,
}) {
  var x = anchor.left;
  final maxX = viewport.width - childSize.width - margin;
  x = x.clamp(margin, maxX < margin ? margin : maxX);

  final below = anchor.bottom + gap;
  final above = anchor.top - childSize.height - gap;
  bool fits(double y) =>
      y >= margin && y + childSize.height <= viewport.height - margin;

  double y;
  if (fits(below)) {
    y = below;
  } else if (fits(above)) {
    y = above;
  } else {
    final spaceBelow = viewport.height - margin - anchor.bottom - gap;
    final spaceAbove = anchor.top - margin - gap;
    y = spaceBelow >= spaceAbove ? below : above;
  }
  final maxY = viewport.height - childSize.height - margin;
  return Offset(x, y.clamp(margin, maxY < margin ? margin : maxY));
}

/// Positions a goto flyout against a live trigger rect, using the child's
/// laid-out size so a short regex tester sits next to the underline.
class GotoPopoverLayout extends SingleChildLayoutDelegate {
  /// Creates a [GotoPopoverLayout].
  const GotoPopoverLayout({required this.anchor});

  /// Trigger span in the overlay's coordinates.
  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxW = (constraints.maxWidth - kGotoPopoverMargin * 2).clamp(
      0.0,
      double.infinity,
    );
    final spaceBelow =
        (constraints.maxHeight -
                kGotoPopoverMargin -
                anchor.bottom -
                kGotoPopoverGap)
            .clamp(0.0, double.infinity);
    final spaceAbove = (anchor.top - kGotoPopoverMargin - kGotoPopoverGap)
        .clamp(0.0, double.infinity);
    final sideCap = spaceBelow > spaceAbove ? spaceBelow : spaceAbove;
    final viewportCap = (constraints.maxHeight - kGotoPopoverMargin * 2).clamp(
      0.0,
      double.infinity,
    );
    final maxH = sideCap < viewportCap ? sideCap : viewportCap;
    return BoxConstraints.loose(Size(maxW, maxH));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      gotoPopoverOrigin(anchor: anchor, childSize: childSize, viewport: size);

  @override
  bool shouldRelayout(GotoPopoverLayout oldDelegate) =>
      anchor != oldDelegate.anchor;
}
