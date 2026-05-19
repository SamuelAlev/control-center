import 'package:cc_markdown/src/ast/nodes.dart';
import 'package:cc_markdown/src/cache/parse_cache.dart';
import 'package:cc_markdown/src/parser/parse_options.dart';
import 'package:cc_markdown/src/plugins/plugin.dart';
import 'package:cc_markdown/src/stream/boundary_scanner.dart';
import 'package:flutter/foundation.dart';

/// An immutable, sealed segment of a streaming document: the source span it
/// came from and its (already parsed) block nodes. Sealed blocks never change
/// once created — the streaming widget memoizes their rendered subtree by
/// block identity.
final class CcSealedBlock {
  /// Creates a [CcSealedBlock].
  const CcSealedBlock({
    required this.start,
    required this.end,
    required this.source,
    required this.nodes,
  });

  /// Source offsets of the segment (offsets live here, not on nodes).
  final int start, end;

  /// The exact source substring.
  final String source;

  /// The segment's parsed blocks.
  final List<CcBlockNode> nodes;
}

/// The streaming markdown model: append-only text segmented into sealed
/// blocks + one volatile tail.
///
/// Per [append]: the fence/details/list-aware boundary scanner consumes the
/// new complete lines in O(delta); when the safe boundary advances, ONLY the
/// newly sealed segment is parsed (once, ephemerally — never inserted into
/// the global cache) and appended to [sealedBlocks]. The volatile tail
/// ([tailText]) re-parses per frame — it is one block, typically small.
///
/// Compared to whole-prefix re-parsing: per-delta cost drops from
/// O(accumulated text) to O(delta) + O(tail) and the global parse cache
/// sees ZERO traffic during the stream ([complete] seeds exactly one final
/// authoritative parse).
///
/// Known bounded imperfection (by design): a link-reference or footnote
/// definition arriving in a LATER segment cannot retro-resolve a reference
/// inside an already-sealed block mid-stream; [complete]'s authoritative
/// whole-document parse fixes the final state.
final class CcMarkdownStreamController extends ChangeNotifier {
  /// Creates a [CcMarkdownStreamController].
  CcMarkdownStreamController({
    this.plugins = CcPluginSet.empty,
    this.options = const CcParseOptions(),
  });

  /// Parser plugins for both segment and tail parses.
  final CcPluginSet plugins;

  /// Parse feature toggles.
  final CcParseOptions options;

  final CcBlockBoundaryScanner _scanner = CcBlockBoundaryScanner();
  final List<CcSealedBlock> _sealed = [];
  String _text = '';
  int _sealedUpTo = 0;
  bool _complete = false;
  int _revision = 0;

  /// The full accumulated source.
  String get text => _text;

  /// Whether [complete] has been called.
  bool get isComplete => _complete;

  /// The sealed segments, oldest first.
  List<CcSealedBlock> get sealedBlocks => List.unmodifiable(_sealed);

  /// The volatile tail (source after the last sealed boundary).
  String get tailText => _text.substring(_sealedUpTo);

  /// When the tail is EXACTLY one still-open fenced code block — the shape an
  /// LLM answer is dominated by — this describes it so the renderer can build
  /// the code node directly instead of re-parsing the whole (growing) fence on
  /// every delta.
  ///
  /// Null whenever the tail is anything else, including a fence with prose in
  /// front of it: the caller then takes the ordinary parse path, so this can
  /// only ever be a shortcut.
  CcOpenFenceTail? get openFenceTail {
    if (!_scanner.inFence) {
      return null;
    }
    final open = _scanner.fenceOpenOffset;
    final body = _scanner.fenceBodyOffset;
    if (open < _sealedUpTo || body < open) {
      return null;
    }
    // Only when the fence opener is the very first thing in the tail (leading
    // whitespace aside). Anything before it is markdown that has to be parsed.
    if (_text.substring(_sealedUpTo, open).trim().isNotEmpty) {
      return null;
    }
    return CcOpenFenceTail(
      info: _scanner.fenceInfo,
      code: _text.substring(body),
    );
  }

  /// Bumped on every mutation.
  int get revision => _revision;

  /// Appends [delta] and seals any newly safe segments.
  void append(String delta) {
    if (delta.isEmpty) {
      return;
    }
    _text = _text + delta;
    _complete = false;
    _advance();
    _revision++;
    notifyListeners();
  }

  /// Replaces the text: appends when [next] extends the current text,
  /// otherwise keeps the sealed blocks that survive the common prefix and
  /// rescans from the last surviving boundary (a revert costs a partial
  /// rescan, not a restart).
  void setText(String next) {
    if (next == _text) {
      return;
    }
    if (next.startsWith(_text)) {
      final delta = next.substring(_text.length);
      _text = next;
      _complete = false;
      if (delta.isNotEmpty) {
        _advance();
      }
      _revision++;
      notifyListeners();
      return;
    }

    // Rewrite: keep sealed blocks fully inside the common prefix.
    var common = 0;
    final max = next.length < _text.length ? next.length : _text.length;
    while (common < max &&
        next.codeUnitAt(common) == _text.codeUnitAt(common)) {
      common++;
    }
    _text = next;
    _complete = false;
    _sealed.removeWhere((b) => b.end > common);
    _sealedUpTo = _sealed.isEmpty ? 0 : _sealed.last.end;
    _scanner.reset();
    // Re-feed the scanner the retained prefix so its fence/details state is
    // consistent, then continue over the new text.
    _scanner.scan(_text);
    _advance(rescan: false);
    _revision++;
    notifyListeners();
  }

  /// Ends the stream: one authoritative whole-document parse replaces the
  /// incremental segmentation (fixing any residual seal artifacts and
  /// resolving late link-reference/footnote definitions). When
  /// [seedGlobalCache] is true the result also seeds [CcMarkdownCache], so
  /// the persisted re-render of the final text is a cache hit.
  void complete({bool seedGlobalCache = true}) {
    _complete = true;
    final nodes = seedGlobalCache
        ? CcMarkdownCache.parseCached(_text, plugins, options: options)
        : CcMarkdownCache.parseEphemeral(_text, plugins, options: options);
    _sealed
      ..clear()
      ..add(
        CcSealedBlock(start: 0, end: _text.length, source: _text, nodes: nodes),
      );
    _sealedUpTo = _text.length;
    _revision++;
    notifyListeners();
  }

  /// Clears all state (optionally seeding [initial] text).
  void reset([String initial = '']) {
    _text = '';
    _sealed.clear();
    _sealedUpTo = 0;
    _scanner.reset();
    _complete = false;
    if (initial.isNotEmpty) {
      _text = initial;
      _advance();
    }
    _revision++;
    notifyListeners();
  }

  void _advance({bool rescan = true}) {
    if (rescan) {
      _scanner.scan(_text);
    }
    final boundary = _scanner.boundary;
    if (boundary > _sealedUpTo) {
      final source = _text.substring(_sealedUpTo, boundary);
      if (source.trim().isNotEmpty) {
        _sealed.add(
          CcSealedBlock(
            start: _sealedUpTo,
            end: boundary,
            source: source,
            // Ephemeral: sealed-segment substrings are never-again-seen
            // strings; inserting them would churn the global cache.
            nodes: CcMarkdownCache.parseEphemeral(
              source,
              plugins,
              options: options,
            ),
          ),
        );
      }
      _sealedUpTo = boundary;
    }
  }
}

/// The tail of a stream that is exactly one unclosed fenced code block.
final class CcOpenFenceTail {
  /// Creates a [CcOpenFenceTail].
  const CcOpenFenceTail({required this.info, required this.code});

  /// The opening fence's info string (`dart`, `mermaid`, …); empty when none.
  final String info;

  /// Everything after the opening fence line — the code so far.
  final String code;
}
