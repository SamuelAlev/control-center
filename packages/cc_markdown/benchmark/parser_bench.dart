// Pure-Dart parser benchmark harness — `fvm dart run benchmark/parser_bench.dart`.
//
// Imports only the Flutter-free slices of the engine (block parser, options,
// plugins, boundary scanner); NOT the barrel and NOT the cache/controller,
// which pull in flutter/foundation.
//
// Benchmarks:
//   a) one-shot parseMarkdownDocument over three authored fixtures
//      (typical chat answer, code-heavy, Renovate-style PR body);
//   b) streaming replay of the chat fixture in ~40-char deltas through
//      CcBlockBoundaryScanner, parsing each newly sealed range;
//   c) a parse-cache-shaped map-hit micro-bench (long source-string keys,
//      LRU touch on hit);
//   d) mermaid dialect parsing (the pure-Dart half of the diagram engine; the
//      layout half needs Flutter's text metrics, so it is exercised by
//      test/mermaid/mermaid_layout_test.dart instead).
//
// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:cc_markdown/src/mermaid/parse/mermaid_parser.dart';
import 'package:cc_markdown/src/parser/block_parser.dart';
import 'package:cc_markdown/src/parser/parse_options.dart';
import 'package:cc_markdown/src/plugins/plugin.dart';
import 'package:cc_markdown/src/stream/boundary_scanner.dart';

// --- Fixtures ---------------------------------------------------------------

/// Typical LLM chat answer (~2KB): prose, headings, lists, inline code,
/// a fenced code block, a blockquote, a link.
const String chatFixture = r'''
## How to debounce a search field in Flutter

Great question — there are two common approaches, and which one you want
depends on whether you need the *latest* value or every intermediate one.

### 1. Timer-based debounce

The classic approach keeps a `Timer` and resets it on every keystroke:

```dart
Timer? _debounce;

void _onSearchChanged(String query) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 300), () {
    ref.read(searchProvider.notifier).search(query);
  });
}
```

Key points to remember:

- Always cancel the previous timer **before** scheduling a new one.
- Dispose the timer in `dispose()` or you will leak callbacks.
- 250–350 ms is the sweet spot for search-as-you-type.

### 2. Stream-based debounce

If you already have a stream pipeline, `debounceTime` is cleaner:

1. Expose the field as a `Stream<String>`.
2. Apply `.debounceTime(const Duration(milliseconds: 300))`.
3. Use `switchMap` so stale requests are cancelled.

> Note: `switchMap` is the important half — debouncing alone still lets
> out-of-order responses overwrite newer ones.

### Which one should you pick?

Both approaches work fine; for a single field the `Timer` version has fewer
moving parts, so I would start there. If the query feeds several listeners
(analytics, suggestions, the result list), promote it to a stream once and
share it — do **not** debounce twice, or the delays stack up.

See the [Flutter cookbook](https://docs.flutter.dev/cookbook) for a runnable
sample of both patterns, and remember to test with a slow network profile:
debounce bugs only show up when responses arrive out of order.

One last gotcha: in widget tests a pending `Timer` fails the test with
"A Timer is still pending" — either `await tester.pump(const
Duration(milliseconds: 300))` past the debounce window, or expose the
duration and set it to `Duration.zero` in tests. The stream variant avoids
this entirely because `fakeAsync` drives `debounceTime` deterministically.
''';

/// One section of the code-heavy fixture (~2KB); repeated to reach ~8KB.
const String _codeSection = r'''
## Repository implementation

The DAO exposes a watch query; the repository maps rows into entities:

```dart
class DriftTicketRepository implements TicketRepository {
  DriftTicketRepository(this._dao);

  final TicketDao _dao;

  @override
  Stream<List<Ticket>> watchOpen(String workspaceId) {
    return _dao.watchOpenTickets(workspaceId).map(
          (rows) => rows.map(_toEntity).toList(growable: false),
        );
  }

  Ticket _toEntity(TicketRow row) => Ticket(
        id: row.id,
        workspaceId: row.workspaceId,
        title: row.title,
        status: TicketStatus.values.byName(row.status),
      );
}
```

The matching migration adds the covering index:

```sql
CREATE INDEX IF NOT EXISTS idx_tickets_ws_status
  ON tickets (workspace_id, status)
  WHERE deleted_at IS NULL;
```

And the TypeScript client mirrors the shape:

```ts
export interface Ticket {
  id: string;
  workspaceId: string;
  title: string;
  status: "open" | "in_progress" | "done";
}

export async function fetchOpenTickets(ws: string): Promise<Ticket[]> {
  const res = await rpc.call("tickets.listOpen", { workspace_id: ws });
  return res.tickets as Ticket[];
}
```

Wire it up in the composition root and the watcher re-emits on every write.
The test fake keeps the same contract without a database:

```dart
class FakeTicketRepository implements TicketRepository {
  final _controller = StreamController<List<Ticket>>.broadcast();

  @override
  Stream<List<Ticket>> watchOpen(String workspaceId) => _controller.stream;

  void emit(List<Ticket> tickets) => _controller.add(tickets);
}
```
''';

/// Code-heavy document (~8KB): repeated repository/migration sections.
final String codeHeavyFixture = List<String>.filled(5, _codeSection).join('\n');

/// Renovate-style PR body (~10KB): update table, per-dependency `<details>`
/// release-note sections, reference links, and footnotes.
final String renovateFixture = _buildRenovateFixture();

String _buildRenovateFixture() {
  const deps = <(String, String, String)>[
    ('dio', '5.4.0', '5.7.2'),
    ('riverpod', '2.5.1', '2.6.3'),
    ('go_router', '14.2.0', '14.8.1'),
    ('drift', '2.20.2', '2.28.0'),
    ('collection', '1.18.0', '1.19.1'),
    ('freezed', '2.5.2', '2.5.8'),
    ('mocktail', '1.0.3', '1.0.4'),
    ('web_socket_channel', '2.4.5', '3.0.1'),
    ('shared_preferences', '2.2.3', '2.3.5'),
    ('path_provider', '2.1.3', '2.1.5'),
    ('flutter_secure_storage', '9.0.0', '9.2.4'),
  ];
  final b = StringBuffer()
    ..writeln('This PR contains the following updates:')
    ..writeln()
    ..writeln('| Package | Change | Age | Adoption | Confidence |')
    ..writeln('|---|---|---|---|---|');
  for (final (name, from, to) in deps) {
    b.writeln(
      '| [$name](https://pub.dev/packages/$name) '
      '([source][$name-src]) | `$from` -> `$to` | '
      '[![age](https://developer.mend.io/api/mc/badges/age/pub/$name)][mend] | '
      '[![adoption](https://developer.mend.io/api/mc/badges/adoption/pub/$name)][mend] | '
      '[![confidence](https://developer.mend.io/api/mc/badges/confidence/pub/$name)][mend] |',
    );
  }
  b
    ..writeln()
    ..writeln('---')
    ..writeln()
    ..writeln('### Release Notes');
  var footnote = 1;
  for (final (name, from, to) in deps) {
    b
      ..writeln()
      ..writeln('<details>')
      ..writeln('<summary>$name ($from -> $to)</summary>')
      ..writeln()
      ..writeln('#### v$to')
      ..writeln()
      ..writeln(
        '- **fix**: guard against a null response body in `$name` '
        '([#${1200 + footnote}][$name-src])',
      )
      ..writeln(
        '- **feat**: expose a `retryPolicy` knob, see the '
        'migration guide[^$footnote]',
      )
      ..writeln('- **chore**: drop the deprecated `${name}Legacy` shim')
      ..writeln()
      ..writeln('```dart')
      ..writeln("import 'package:$name/$name.dart';")
      ..writeln()
      ..writeln('final client = ${name.replaceAll('_', '')}Client(')
      ..writeln('  retryPolicy: RetryPolicy.exponential(maxAttempts: 3),')
      ..writeln(');')
      ..writeln('```')
      ..writeln()
      ..writeln('</details>');
    footnote++;
  }
  b
    ..writeln()
    ..writeln('---')
    ..writeln()
    ..writeln('### Configuration')
    ..writeln()
    ..writeln(
      '- [ ] <!-- rebase-check -->If you want to rebase/retry this '
      'PR, check this box',
    )
    ..writeln()
    ..writeln(
      'This PR was generated by [Mend Renovate][mend]. View the '
      '[repository job log][joblog].',
    )
    ..writeln();
  footnote = 1;
  for (final (name, _, to) in deps) {
    b.writeln(
      '[^$footnote]: Upgrade notes for $name v$to live in the '
      'package changelog.',
    );
    footnote++;
  }
  b.writeln();
  for (final (name, _, _) in deps) {
    b.writeln('[$name-src]: https://github.com/dart-lang/$name');
  }
  b
    ..writeln('[mend]: https://developer.mend.io')
    ..writeln('[joblog]: https://developer.mend.io/github/renovate-demo');
  return b.toString();
}

/// A representative diagram of each drawn dialect.
const List<(String, String)> mermaidFixtures = [
  (
    'flowchart',
    r'''
flowchart TD
  A([Incoming PR]) --> B{CI green?}
  B -->|yes| C[Request review]
  B -->|no| D[/Post failures/]
  subgraph review [Review loop]
    C --> E[Reviewer reads diff]
    E --> F{Changes requested?}
    F -->|yes| G[Author pushes fix]
    G --> E
  end
  F -->|no| H[(Merge queue)]
  H --> I((Merged))
  D -.-> G
''',
  ),
  (
    'sequence',
    r'''
sequenceDiagram
  autonumber
  actor Dev
  participant CC as Control Center
  participant GH as GitHub
  Dev->>CC: open PR review
  CC->>+GH: fetch diff
  GH-->>-CC: files + comments
  loop each file
    CC->>CC: highlight + word-diff
  end
  alt approved
    CC->>GH: submit review
  else changes requested
    CC->>GH: post comments
  end
  Note over Dev,CC: review lands in the inbox
''',
  ),
  (
    'class',
    r'''
classDiagram
  class Principal {
    <<interface>>
    +String id
    +String displayName
  }
  Principal <|-- UserPrincipal
  Principal <|-- AgentPrincipal
  UserPrincipal "1" --> "0..*" Device : registers
''',
  ),
];

// --- Harness ----------------------------------------------------------------

const CcParseOptions _options = CcParseOptions();
const CcPluginSet _plugins = CcPluginSet.empty;

/// Sink that keeps the optimizer from eliding parse work.
int _sink = 0;

double _benchMermaid(String source, {int warmup = 30, int iterations = 200}) {
  // The engine memoizes by source, so each iteration measures a COLD parse.
  for (var i = 0; i < warmup; i++) {
    clearMermaidParseCache();
    _sink += parseMermaid(source).hashCode & 1;
  }
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    clearMermaidParseCache();
    _sink += parseMermaid(source).hashCode & 1;
  }
  sw.stop();
  return sw.elapsedMicroseconds / iterations;
}

double _benchParse(String source, {int warmup = 30, int iterations = 200}) {
  for (var i = 0; i < warmup; i++) {
    _sink += parseMarkdownDocument(
      source,
      options: _options,
      plugins: _plugins,
    ).blocks.length;
  }
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    _sink += parseMarkdownDocument(
      source,
      options: _options,
      plugins: _plugins,
    ).blocks.length;
  }
  sw.stop();
  return sw.elapsedMicroseconds / iterations;
}

List<String> _deltasOf(String text, int size) {
  final deltas = <String>[];
  for (var i = 0; i < text.length; i += size) {
    deltas.add(text.substring(i, math.min(i + size, text.length)));
  }
  return deltas;
}

/// One streaming replay: append deltas, scan, parse each newly sealed range,
/// then parse the final tail. Returns (total µs, max single-append µs).
(int, int) _replayOnce(List<String> deltas) {
  final scanner = CcBlockBoundaryScanner();
  final buffer = StringBuffer();
  var sealedUpTo = 0;
  var maxAppendUs = 0;
  final total = Stopwatch()..start();
  final single = Stopwatch();
  for (final delta in deltas) {
    single
      ..reset()
      ..start();
    buffer.write(delta);
    final text = buffer.toString();
    scanner.scan(text);
    final boundary = scanner.boundary;
    if (boundary > sealedUpTo) {
      _sink += parseMarkdownDocument(
        text.substring(sealedUpTo, boundary),
        options: _options,
        plugins: _plugins,
      ).blocks.length;
      sealedUpTo = boundary;
    }
    single.stop();
    maxAppendUs = math.max(maxAppendUs, single.elapsedMicroseconds);
  }
  // Stream end: parse the volatile tail once.
  _sink += parseMarkdownDocument(
    buffer.toString().substring(sealedUpTo),
    options: _options,
    plugins: _plugins,
  ).blocks.length;
  total.stop();
  return (total.elapsedMicroseconds, maxAppendUs);
}

(double, int) _benchStreaming(
  List<String> deltas, {
  int warmup = 5,
  int iterations = 20,
}) {
  for (var i = 0; i < warmup; i++) {
    _replayOnce(deltas);
  }
  var totalUs = 0;
  var maxAppendUs = 0;
  for (var i = 0; i < iterations; i++) {
    final (total, maxAppend) = _replayOnce(deltas);
    totalUs += total;
    maxAppendUs = math.max(maxAppendUs, maxAppend);
  }
  return (totalUs / iterations, maxAppendUs);
}

/// Parse-cache-shaped hit micro-bench: a LinkedHashMap keyed by long source
/// strings (the real cache keys on `(source, options, plugins)`), LRU-touch
/// (remove + reinsert) on every hit.
(double, double) _benchCacheHits({int entries = 128, int hits = 200000}) {
  final cache = <String, Object>{};
  final keys = List<String>.generate(entries, (i) => '$chatFixture#$i');
  for (final key in keys) {
    cache[key] = Object();
  }
  // Warmup (also populates the VM's lazy string-hash caches).
  for (var i = 0; i < hits ~/ 10; i++) {
    _sink += cache[keys[i % entries]] == null ? 1 : 0;
  }
  final plain = Stopwatch()..start();
  for (var i = 0; i < hits; i++) {
    _sink += cache[keys[i % entries]] == null ? 1 : 0;
  }
  plain.stop();
  final touch = Stopwatch()..start();
  for (var i = 0; i < hits; i++) {
    final key = keys[i % entries];
    final value = cache.remove(key);
    cache[key] = value!;
  }
  touch.stop();
  return (plain.elapsedMicroseconds / hits, touch.elapsedMicroseconds / hits);
}

String _row(String label, List<String> cells, List<int> widths) {
  final b = StringBuffer(label.padRight(22));
  for (var i = 0; i < cells.length; i++) {
    b.write(cells[i].padLeft(widths[i]));
  }
  return b.toString();
}

void main() {
  const iterations = 200;
  final fixtures = <(String, String)>[
    ('chat-answer', chatFixture),
    ('code-heavy', codeHeavyFixture),
    ('renovate-pr', renovateFixture),
  ];

  print(
    'cc_markdown parser bench '
    '($iterations iters after warmup, whole-document parse)',
  );
  final widths = [10, 12, 14];
  print(_row('fixture', ['bytes', 'us/parse', 'MB/s'], widths));
  for (final (name, source) in fixtures) {
    final usPerParse = _benchParse(source, iterations: iterations);
    final mbPerSec = source.length / usPerParse; // bytes/us == MB/s.
    print(
      _row(name, [
        '${source.length}',
        usPerParse.toStringAsFixed(1),
        mbPerSec.toStringAsFixed(1),
      ], widths),
    );
  }

  final deltas = _deltasOf(chatFixture, 40);
  final (avgTotalUs, maxAppendUs) = _benchStreaming(deltas);
  print('');
  print(
    'streaming replay (chat-answer, ${deltas.length} x ~40-char deltas, '
    'avg of 20 replays)',
  );
  print(_row('replay', ['total us', 'max append us'], [12, 16]));
  print(
    _row(
      'scanner+parse',
      [avgTotalUs.toStringAsFixed(0), '$maxAppendUs'],
      [12, 16],
    ),
  );

  print('');
  print(
    'mermaid dialect parse ($iterations iters after warmup, cold each time)',
  );
  print(_row('diagram', ['bytes', 'us/parse'], [12, 12]));
  for (final (name, source) in mermaidFixtures) {
    final usPerParse = _benchMermaid(source, iterations: iterations);
    print(
      _row(name, ['${source.length}', usPerParse.toStringAsFixed(1)], [12, 12]),
    );
  }

  final (plainUs, touchUs) = _benchCacheHits();
  print('');
  print(
    'parse-cache-shaped map hit (128 entries, 2KB string keys, '
    '200000 hits)',
  );
  print(_row('lookup', ['us/hit'], [12]));
  print(_row('plain get', [plainUs.toStringAsFixed(3)], [12]));
  print(_row('LRU touch', [touchUs.toStringAsFixed(3)], [12]));

  // Keep the sink alive so no benchmarked work is dead code.
  if (_sink < 0) {
    print(_sink);
  }
}
