/// Flutter-free compute core for the PR diff worker.
///
/// This file is deliberately free of any Flutter / `dart:ui` import: the
/// [diffWorker] entrypoint below is compiled to a standalone JavaScript Web
/// Worker by `dart compile js` (via `tool/gen_workers.sh` →
/// `dart run isolate_manager:generate`) and that toolchain cannot compile
/// Flutter. The main-isolate side (`DiffWorkerPool` in `diff_isolate_worker.dart`)
/// imports this file for the worker entrypoint, the pure compute pipeline
/// ([runDiffJob], exercised directly by tests) and the wire-protocol keys.
///
/// Everything crossing the isolate / Web Worker boundary is a plain
/// `Map<String, dynamic>` of primitives and primitive lists — the only shape
/// `isolate_manager` can transfer on the web. The syntax palette (which is
/// derived from the Flutter theme) is computed on the main isolate and passed
/// **into** the job as a `Map<String, int>`, so this core never touches the
/// design system.
library;

import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:control_center/features/pr_review/presentation/utils/word_diff.dart';
import 'package:control_center/shared/syntax/cc_shiki_theme.dart';
import 'package:control_center/shared/syntax/token_lines.dart';
import 'package:control_center/shared/syntax/worker_grammars.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:shiki_flutter/engine.dart';

/// Lines per pass-2 token chunk. Trade-off: smaller = smoother fade-in but more
/// worker→main traffic; larger = fewer messages but visible "stutter" steps.
/// 200 lines is about one screenful, so the user sees a chunk land just as the
/// previous one finishes.
const int diffTokenChunkLines = 200;

/// Keys for the primitive-map wire protocol shared between [runDiffJob] (worker)
/// and the decoders on the main isolate. Kept in one place so the two sides
/// cannot drift.
abstract final class DiffWire {
  /// Event discriminator key.
  static const String type = 't';

  /// `type` value: pass-2 token chunk.
  static const String tok = 'tok';

  /// `type` value: terminal success.
  static const String done = 'done';

  /// `type` value: terminal failure.
  static const String err = 'err';

  // ── Job (main → worker) ──────────────────────────────────────────────────
  /// Job key: unified-diff patch text.
  static const String patch = 'patch';

  /// Job key: shiki language id (nullable — null tokenizes plain and the
  /// word-diff backgrounds still apply, so language-less files keep their
  /// intraline emphasis).
  static const String language = 'lang';

  /// Job key: whether to tokenize with the dark CC theme (`cc-dark`) instead
  /// of the light one. The theme itself is compiled into the worker
  /// (cc_shiki_theme.dart) — only this flag crosses the wire.
  static const String dark = 'dk';

  /// Job key: syntax palette class names (`List<String>`), parallel to
  /// [paletteValues]. The palette is sent as two flat primitive lists rather
  /// than a nested `Map` because only primitives and FLAT maps/lists of
  /// primitives transfer reliably to a Web Worker — a nested map can arrive
  /// empty, which silently drops all syntax colors. Includes the
  /// `deletion`/`addition` keys used by the inline word-diff.
  static const String paletteKeys = 'pk';

  /// Job key: syntax palette ARGB colors (`List<int>`), parallel to
  /// [paletteKeys].
  static const String paletteValues = 'pv';

  // ── tok event ────────────────────────────────────────────────────────────
  /// tok: index of the first line in this chunk.
  static const String startIndex = 's';

  /// tok: number of tokens per line (parallel-array grouping).
  static const String lineLens = 'll';

  /// tok: flattened token texts (parallel to [colors]/[bgs]).
  static const String texts = 'tx';

  /// tok: flattened token ARGB colors (nullable).
  static const String colors = 'co';

  /// tok: flattened token ARGB background colors (nullable).
  static const String bgs = 'bg';

  // ── err event ────────────────────────────────────────────────────────────
  /// err: human-readable message.
  static const String message = 'm';
}

/// Builds a job map for the worker. Called on the main isolate. Syntax colors
/// come from the CC theme compiled into the worker ([dark] picks the variant);
/// the palette lists only feed the inline word-diff (its background washes and
/// `addition`/`deletion` fallback tints), flattened into two parallel
/// primitive lists so they survive the Web Worker boundary (see
/// [DiffWire.paletteKeys]).
Map<String, dynamic> buildDiffJob({
  required String patch,
  required String? language,
  required bool dark,
  required Map<String, int> palette,
}) => <String, dynamic>{
  DiffWire.patch: patch,
  DiffWire.language: language,
  DiffWire.dark: dark,
  DiffWire.paletteKeys: palette.keys.toList(growable: false),
  DiffWire.paletteValues: palette.values.toList(growable: false),
};

/// Runs the two-pass diff pipeline for one file, emitting each event as a
/// primitive map via [emit]. Emits exactly one terminal event (`done` or
/// `err`). Pure and Flutter-free so it runs identically on a native isolate,
/// a Web Worker and directly in tests.
void runDiffJob(
  Map<String, dynamic> job,
  void Function(Map<String, dynamic>) emit,
) {
  try {
    final patch = job[DiffWire.patch] as String;
    final language = job[DiffWire.language] as String?;
    final dark = job[DiffWire.dark] as bool? ?? false;
    // Rebuild the word-diff palette from the two parallel primitive lists (see
    // DiffWire.paletteKeys — a nested map does not survive the web boundary).
    final paletteKeys = job[DiffWire.paletteKeys] as List;
    final paletteValues = job[DiffWire.paletteValues] as List;
    final palette = <String, int>{
      for (var i = 0; i < paletteKeys.length; i++)
        paletteKeys[i] as String: paletteValues[i] as int,
    };

    // ── Pass 1: parse structure ────────────────────────────────────────────
    // Structure is NOT emitted: DiffStructureStore parses it synchronously on
    // the main isolate and always ignored the worker's copy. The parse here
    // only feeds pass 2.
    final parsed = parseUnifiedDiff(patch);

    if (parsed.isEmpty) {
      emit(const <String, dynamic>{DiffWire.type: DiffWire.done});
      return;
    }

    // ── Pass 2: tokenize per hunk in chunks, then apply word-diff ───────────
    // A hunk is tokenized as ONE shiki call over its rows joined by newlines,
    // so grammar state carries across lines — multi-line strings, block
    // comments and JSX color correctly, which the old per-line hljs parse
    // never could.
    final allTokens = <List<DiffToken>>[];
    const chunkSize = diffTokenChunkLines;
    var chunkStart = 0;
    var chunkBuffer = <List<DiffToken>>[];

    void flushChunk() {
      if (chunkBuffer.isEmpty) {
        return;
      }
      emit(_encodeTok(chunkStart, chunkBuffer));
      chunkStart += chunkBuffer.length;
      chunkBuffer = <List<DiffToken>>[];
    }

    void addLine(List<DiffToken> tokens) {
      allTokens.add(tokens);
      chunkBuffer.add(tokens);
      if (chunkBuffer.length >= chunkSize) {
        flushChunk();
      }
    }

    final highlighter = language == null
        ? null
        : _workerHighlighterFor(language);
    var i = 0;
    while (i < parsed.length) {
      final line = parsed[i];
      if (line.kind == DiffLineKind.hunkHeader) {
        addLine([DiffToken(line.hunkHeader ?? '', null)]);
        i++;
        continue;
      }
      final start = i;
      while (i < parsed.length && parsed[i].kind != DiffLineKind.hunkHeader) {
        i++;
      }
      final rows = parsed.sublist(start, i);
      for (final tokens in _tokenizeHunk(highlighter, rows, language, dark)) {
        addLine(tokens);
      }
    }
    flushChunk();

    // Apply inline word-diff over the accumulated tokens, then emit one
    // patch chunk per contiguous run of lines whose tokens actually changed.
    // (In practice each run = one hunk's addition+deletion block.)
    final specs = <DiffLineSpec>[
      for (var i = 0; i < parsed.length; i++)
        DiffLineSpec(
          kind: parsed[i].kind,
          tokens: allTokens[i],
          oldLine: parsed[i].oldLine,
          newLine: parsed[i].newLine,
          hunkHeader: parsed[i].hunkHeader,
        ),
    ];
    applyInlineWordDiff(specs, palette);

    var runStart = -1;
    final runTokens = <List<DiffToken>>[];
    void flushRun() {
      if (runStart < 0 || runTokens.isEmpty) {
        return;
      }
      emit(_encodeTok(runStart, runTokens));
      runTokens.clear();
      runStart = -1;
    }

    for (var i = 0; i < specs.length; i++) {
      final updated = specs[i].tokens;
      if (!_tokensEqual(allTokens[i], updated)) {
        runStart = runStart < 0 ? i : runStart;
        runTokens.add(updated);
      } else {
        flushRun();
      }
    }
    flushRun();

    emit(const <String, dynamic>{DiffWire.type: DiffWire.done});
  } catch (e) {
    emit(<String, dynamic>{
      DiffWire.type: DiffWire.err,
      DiffWire.message: e.toString(),
    });
  }
}

/// The `isolate_manager` custom Web Worker / isolate entrypoint. Generated to
/// `web/diffWorker.js` for the web build; used directly as the isolate function
/// on native. `workerName: 'diffWorker'` in `DiffWorkerPool` must match this
/// function name.
@pragma('vm:entry-point')
@isolateManagerCustomWorker
void diffWorker(dynamic params) {
  IsolateManagerFunction.customFunction<String, String>(
    params,
    // We stream every event ourselves via `controller.sendResult` (pass-1
    // structure, N token chunks, then a terminal), so the framework must not
    // also auto-send the `onEvent` return value.
    autoHandleResult: false,
    onEvent: (controller, jobJson) {
      // Everything crossing the boundary is a JSON String, NOT a Dart Map: a
      // Web Worker (js_interop) cannot transfer a Dart Map — passing one makes
      // the web result converter throw `Map<Object?,Object?>` is-not-a-subtype.
      // The maintainer's documented workaround is jsonEncode/jsonDecode
      // (isolate_manager issue #31). Native isolates would copy a Map fine, but
      // one code path must satisfy both, so we JSON everywhere.
      final job = jsonDecode(jobJson) as Map<String, dynamic>;
      runDiffJob(job, (event) => controller.sendResult(jsonEncode(event)));
      return '';
    },
  );
}

// ─── Wire encoders (worker side) ─────────────────────────────────────────────

Map<String, dynamic> _encodeTok(int startIndex, List<List<DiffToken>> lines) {
  final lineLens = <int>[];
  final texts = <String>[];
  final colors = <int?>[];
  final bgs = <int?>[];
  for (final line in lines) {
    lineLens.add(line.length);
    for (final t in line) {
      texts.add(t.text);
      colors.add(t.colorValue);
      bgs.add(t.backgroundColorValue);
    }
  }
  return <String, dynamic>{
    DiffWire.type: DiffWire.tok,
    DiffWire.startIndex: startIndex,
    DiffWire.lineLens: lineLens,
    DiffWire.texts: texts,
    DiffWire.colors: colors,
    DiffWire.bgs: bgs,
  };
}

// ─── Tokenizer (shiki engine, per-isolate highlighter) ───────────────────────

bool _tokensEqual(List<DiffToken> a, List<DiffToken> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i].text != b[i].text ||
        a[i].colorValue != b[i].colorValue ||
        a[i].backgroundColorValue != b[i].backgroundColorValue) {
      return false;
    }
  }
  return true;
}

/// The per-isolate highlighter (one per worker isolate / Web Worker; jobs on
/// the same isolate reuse compiled grammars and themes across files).
ShikiHighlighter? _workerHighlighter;
final Set<String> _workerLoadedLangs = <String>{};

/// The shared highlighter with [language]'s grammar loaded, or `null` when
/// the grammar isn't in this worker's bundle (web ships the curated tier;
/// native indexes everything) — rows then render plain, exactly like an
/// unknown language.
ShikiHighlighter? _workerHighlighterFor(String language) {
  final lang = workerGrammarForId(language);
  if (lang == null) {
    return null;
  }
  final highlighter = _workerHighlighter ??= () {
    final h = ShikiHighlighter(
      // The pool on the main side caches finished results per file; a big
      // token cache inside every worker isolate would just duplicate it.
      cache: TokenCache(maxEntries: 4, maxChars: 256 * 1024),
    );
    ensureCcThemes(h);
    return h;
  }();
  if (_workerLoadedLangs.add(language)) {
    highlighter.ensureLanguage(lang);
  }
  return highlighter;
}

/// Tokenizes one hunk's rows with a single shiki call (grammar state carries
/// across rows). Falls back to plain tokens — per row where only a row
/// misaligns, for the whole hunk when tokenization fails outright — so a
/// grammar bug can never break the diff, only un-color it.
List<List<DiffToken>> _tokenizeHunk(
  ShikiHighlighter? highlighter,
  List<DiffLine> rows,
  String? language,
  bool dark,
) {
  List<List<DiffToken>> plain() => [
    for (final row in rows) [DiffToken(row.content, null)],
  ];
  if (highlighter == null || language == null) {
    return plain();
  }
  final text = rows.map((r) => r.content).join('\n');
  List<List<ThemedToken>> lines;
  try {
    lines = highlighter.codeToTokens(
      text,
      TokenizeOptions(
        lang: language,
        theme: ccThemeId(dark: dark),
        // Guard against minified single-line bundles that backtracking
        // grammars choke on; such a line comes back as one plain token.
        tokenizeMaxLineLength: 4000,
      ),
    );
    lines = reattachCarriageReturns(text, lines);
  } on Object {
    return plain();
  }
  if (lines.length != rows.length) {
    // Row alignment is the contract the painter depends on; if the tokenizer
    // sees a different line count than the parser, trust the parser.
    return plain();
  }
  return [
    for (var i = 0; i < rows.length; i++) _rowTokens(lines[i], rows[i].content),
  ];
}

/// Converts one row's [ThemedToken]s to [DiffToken]s, verifying the row
/// round-trips to [content] exactly (the painter draws token text under the
/// parser's line numbers — a mismatch would paint the wrong characters).
List<DiffToken> _rowTokens(List<ThemedToken> line, String content) {
  final tokens = <DiffToken>[];
  var chars = 0;
  for (final t in line) {
    if (t.content.isEmpty) {
      continue;
    }
    tokens.add(DiffToken(t.content, ccArgbForTokenColor(t.color)));
    chars += t.content.length;
  }
  if (tokens.isEmpty || chars != content.length) {
    return [DiffToken(content, null)];
  }
  return tokens;
}
