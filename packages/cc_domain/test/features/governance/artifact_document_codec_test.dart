import 'dart:convert';

import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:test/test.dart';

/// One minimal VALID block per canonical kind.
///
/// Keyed by kind so the "every kind is reachable" tests iterate
/// [artifactBlockKinds] itself rather than a hand-kept copy — a new kind with no
/// fixture here fails the coverage test immediately.
const Map<String, Map<String, dynamic>> _minimalBlocks = {
  'markdown': {'type': 'markdown', 'text': '## Findings\n\nAll good.'},
  'table': {
    'type': 'table',
    'columns': [
      {'key': 'name', 'label': 'Name'},
      {'key': 'count', 'label': 'Count', 'align': 'right'},
    ],
    'rows': [
      ['agents', '12'],
      ['repos', '3'],
    ],
  },
  'chart': {
    'type': 'chart',
    'chartKind': 'bar',
    'title': 'Runs per day',
    'xLabel': 'Day',
    'yLabel': 'Runs',
    'series': [
      {
        'label': 'completed',
        'points': [
          {'x': 'Mon', 'y': 4},
          {'x': 'Tue', 'y': 7.5},
        ],
      },
    ],
  },
  'mermaid': {'type': 'mermaid', 'source': 'flowchart LR\n  A --> B'},
  'code': {
    'type': 'code',
    'code': 'void main() {}',
    'language': 'dart',
    'title': 'lib/main.dart',
    'lineStart': 12,
  },
  'data': {
    'type': 'data',
    'json': {
      'ok': true,
      'items': [1, 2, 3],
    },
  },
};

Map<String, dynamic> _envelope(List<Map<String, dynamic>> blocks) => {
  'format': ArtifactDocument.formatVersion,
  'blocks': blocks,
};

void main() {
  group('canonical kind list', () {
    test('every kind has a fixture and decodes to that kind', () {
      for (final kind in artifactBlockKinds) {
        final fixture = _minimalBlocks[kind];
        expect(
          fixture,
          isNotNull,
          reason:
              'No fixture for kind "$kind" — a kind added to '
              'artifactBlockKinds must be decodable, renderable, and tested.',
        );
        final document = ArtifactDocumentCodec.decodeStrict(
          _envelope([fixture!]),
        );
        expect(document.blocks.single.type, kind);
      }
    });

    test('a kind outside the canonical list is refused', () {
      // The anti-"invisible kind" guard from the other direction: the decoder
      // must not quietly accept something the schema never advertised.
      expect(
        () => ArtifactDocumentCodec.decodeStrict(
          _envelope([
            {'type': 'html', 'html': '<b>no</b>'},
          ]),
        ),
        throwsA(isA<ArtifactFormatException>()),
      );
    });

    test('the kind list has no duplicates', () {
      expect(artifactBlockKinds.toSet(), hasLength(artifactBlockKinds.length));
    });
  });

  group('round trip', () {
    test('every kind survives decode → toJson → decode', () {
      for (final kind in artifactBlockKinds) {
        final first = ArtifactBlock.fromJson(_minimalBlocks[kind]!);
        final second = ArtifactBlock.fromJson(first.toJson());
        expect(second, first, reason: 'kind "$kind" lost data on re-encode');
      }
    });

    test('the whole document survives the persisted envelope', () {
      final blocks = [
        for (final kind in artifactBlockKinds) _minimalBlocks[kind]!,
      ];
      final document = ArtifactDocumentCodec.decodeStrict(_envelope(blocks));
      final restored = ArtifactDocument.tryParseContent(
        document.toEnvelopeJsonString(),
      );
      expect(restored, isNotNull);
      expect(restored!.blocks, document.blocks);
      expect(
        jsonDecode(document.toEnvelopeJsonString()),
        containsPair('format', 'blocks@1'),
      );
    });

    test('ids survive the round trip', () {
      final stamped = ArtifactDocumentCodec.assignBlockIds([
        for (final kind in artifactBlockKinds)
          ArtifactBlock.fromJson(_minimalBlocks[kind]!),
      ]);
      final restored = ArtifactDocument.fromEnvelopeJson(
        ArtifactDocument(blocks: stamped).toEnvelopeJson(),
      );
      expect(restored.blocks.map((b) => b.id).toList(), [
        'b1',
        'b2',
        'b3',
        'b4',
        'b5',
        'b6',
      ]);
    });

    test('a non-envelope revision body is not an artifact document', () {
      // Work products predate artifacts: `save_work_product_revision` writes
      // plain markdown, and reading it as an empty artifact would be a lie.
      expect(ArtifactDocument.tryParseContent('# just markdown'), isNull);
      expect(ArtifactDocument.tryParseContent('{"format":"blocks@2"}'), isNull);
    });
  });

  group('decodeStrict', () {
    test('rejects a malformed block and names it', () {
      Object? captured;
      try {
        ArtifactDocumentCodec.decodeStrict(
          _envelope([
            _minimalBlocks['markdown']!,
            {'type': 'chart', 'chartKind': 'bar', 'series': const []},
          ]),
        );
      } on ArtifactFormatException catch (e) {
        captured = e;
      }
      expect(captured, isA<ArtifactFormatException>());
      expect(
        (captured! as ArtifactFormatException).violations.single,
        'blocks[1].chart: series is empty',
      );
    });

    test('rejects a non-list blocks payload', () {
      expect(
        () => ArtifactDocumentCodec.decodeStrict({'blocks': 'nope'}),
        throwsA(isA<ArtifactFormatException>()),
      );
    });

    test('rejects an unknown envelope format', () {
      expect(
        () => ArtifactDocumentCodec.decodeStrict({
          'format': 'blocks@99',
          'blocks': [_minimalBlocks['markdown']!],
        }),
        throwsA(isA<ArtifactFormatException>()),
      );
    });

    test('rejects an empty document', () {
      expect(
        () => ArtifactDocumentCodec.decodeStrict(_envelope(const [])),
        throwsA(isA<ArtifactFormatException>()),
      );
    });

    test('a warning alone does not fail a strict decode', () {
      final document = ArtifactDocumentCodec.decodeStrict(
        _envelope([
          {'type': 'mermaid', 'source': 'gantt\n  title nope'},
        ]),
      );
      expect(document.blocks, hasLength(1));
    });
  });

  group('decodeLoose', () {
    test('drops ONE bad block, keeps the rest, and reports the path', () {
      final result = ArtifactDocumentCodec.decodeLoose([
        _minimalBlocks['markdown'],
        {'type': 'chart', 'chartKind': 'line', 'series': const []},
        _minimalBlocks['table'],
      ]);

      expect(result.document.blocks, hasLength(2));
      expect(result.document.blocks.first.type, 'markdown');
      expect(result.document.blocks.last.type, 'table');
      expect(result.errors, ['blocks[1].chart: series is empty']);
    });

    test('accepts a bare block list or a full envelope', () {
      final bare = ArtifactDocumentCodec.decodeLoose([
        _minimalBlocks['markdown'],
      ]);
      final wrapped = ArtifactDocumentCodec.decodeLoose(
        _envelope([_minimalBlocks['markdown']!]),
      );
      expect(bare.document, wrapped.document);
      expect(bare.errors, isEmpty);
    });

    test('coerces junk optionals instead of failing', () {
      final result = ArtifactDocumentCodec.decodeLoose([
        {
          'type': 'table',
          'columns': [
            {'key': 'n', 'label': 'N', 'align': 'justify'},
          ],
          // A number where text belongs, and a stray non-list row.
          'rows': [
            [7],
            'not a row',
          ],
        },
      ]);
      final table = result.document.blocks.single as ArtifactTableBlock;
      expect(table.columns.single.align, isNull, reason: 'unknown align drops');
      expect(table.rows, [
        ['7'],
      ]);
      expect(result.errors, isEmpty);
    });

    test('an unknown block type is dropped with its index', () {
      final result = ArtifactDocumentCodec.decodeLoose([
        {'type': 'video', 'url': 'x'},
        _minimalBlocks['code'],
      ]);
      expect(result.document.blocks, hasLength(1));
      expect(result.errors.single, startsWith('blocks[0]: unknown block type'));
    });

    test('a non-list payload reports one error and no blocks', () {
      final result = ArtifactDocumentCodec.decodeLoose('markdown please');
      expect(result.document.isEmpty, isTrue);
      expect(result.errors.single, contains('expected a list of blocks'));
    });

    test('an unknown envelope format warns but still reads the blocks', () {
      final result = ArtifactDocumentCodec.decodeLoose({
        'format': 'blocks@2',
        'blocks': [_minimalBlocks['markdown']!],
      });
      expect(result.document.blocks, hasLength(1));
      expect(result.warnings.single, contains('format'));
    });
  });

  group('chart validation', () {
    test('empty series is rejected', () {
      final result = ArtifactDocumentCodec.decodeLoose([
        {'type': 'chart', 'chartKind': 'bar', 'series': const []},
      ]);
      expect(result.document.isEmpty, isTrue);
      expect(result.errors.single, endsWith('series is empty'));
    });

    test('a series with no points is rejected', () {
      final result = ArtifactDocumentCodec.decodeLoose([
        {
          'type': 'chart',
          'chartKind': 'line',
          'series': [
            {'label': 'a', 'points': const []},
          ],
        },
      ]);
      expect(result.errors.single, contains('has no points'));
    });

    test('a non-finite y is rejected', () {
      final result = ArtifactDocumentCodec.decodeLoose([
        {
          'type': 'chart',
          'chartKind': 'bar',
          'series': [
            {
              'label': 'a',
              'points': [
                {'x': 'Mon', 'y': 'not a number'},
              ],
            },
          ],
        },
      ]);
      expect(result.document.isEmpty, isTrue);
      expect(
        result.errors.single,
        'blocks[0].chart: series[0].points[0].y is not a finite number',
      );
    });

    test('a quoted number is coerced, not rejected', () {
      final result = ArtifactDocumentCodec.decodeLoose([
        {
          'type': 'chart',
          'chartKind': 'bar',
          'series': [
            {
              'label': 'a',
              'points': [
                {'x': 'Mon', 'y': '4.5'},
              ],
            },
          ],
        },
      ]);
      expect(result.errors, isEmpty);
      final chart = result.document.blocks.single as ArtifactChartBlock;
      expect(chart.series.single.points.single.y, 4.5);
    });

    test('an unknown chartKind is dropped, not defaulted', () {
      final result = ArtifactDocumentCodec.decodeLoose([
        {
          'type': 'chart',
          'chartKind': 'donut',
          'series': [
            {
              'label': 'a',
              'points': [
                {'x': 'Mon', 'y': 1},
              ],
            },
          ],
        },
      ]);
      expect(result.document.isEmpty, isTrue);
      expect(result.errors.single, contains('chartKind'));
    });

    test('a pie chart with extra series warns but renders', () {
      final result = ArtifactDocumentCodec.decodeLoose([
        {
          'type': 'chart',
          'chartKind': 'pie',
          'series': [
            {
              'label': 'a',
              'points': [
                {'x': 'Mon', 'y': 1},
              ],
            },
            {
              'label': 'b',
              'points': [
                {'x': 'Mon', 'y': 2},
              ],
            },
          ],
        },
      ]);
      expect(result.document.blocks, hasLength(1));
      expect(result.errors, isEmpty);
      expect(result.warnings.single, contains('first series only'));
    });
  });

  group('mermaid renderability', () {
    test('an unsupported dialect warns but is NOT rejected', () {
      // It degrades to a code block in the renderer, so the content still
      // reaches the reader — dropping the block would throw away the diagram.
      final result = ArtifactDocumentCodec.decodeLoose([
        {'type': 'mermaid', 'source': 'gantt\n  title Release'},
      ]);
      expect(result.document.blocks, hasLength(1));
      expect(result.errors, isEmpty);
      expect(result.warnings.single, contains('code block'));
    });

    test('every drawable dialect passes without a warning', () {
      const sources = {
        'flowchart LR\n  A --> B': 'flowchart',
        'graph TD;A-->B;': 'graph',
        'stateDiagram-v2\n  [*] --> Idle': 'statediagram-v2',
        'classDiagram\n  Animal <|-- Duck': 'classdiagram',
        'erDiagram\n  A ||--o{ B : has': 'erdiagram',
        'sequenceDiagram\n  A->>B: hi': 'sequencediagram',
        'pie title Split\n  "a" : 10': 'pie',
        'timeline\n  title T\n  2026 : ship': 'timeline',
      };
      for (final entry in sources.entries) {
        expect(
          artifactMermaidDialect(entry.key),
          entry.value,
          reason: 'dialect misread for:\n${entry.key}',
        );
        final result = ArtifactDocumentCodec.decodeLoose([
          {'type': 'mermaid', 'source': entry.key},
        ]);
        expect(
          result.warnings,
          isEmpty,
          reason: '"${entry.value}" is drawable but warned',
        );
      }
    });

    test('front matter, init directives, and comments are skipped', () {
      const source =
          '---\ntitle: X\n---\n%%{init: {"theme":"dark"}}%%\n'
          '%% a comment\nflowchart TD\n  A --> B';
      expect(artifactMermaidDialect(source), 'flowchart');
    });

    test('an empty source is an error, not a warning', () {
      final result = ArtifactDocumentCodec.decodeLoose([
        {'type': 'mermaid', 'source': '   '},
      ]);
      expect(result.document.isEmpty, isTrue);
      expect(result.errors.single, endsWith('source is empty'));
    });
  });

  group('other per-kind validation', () {
    test('empty markdown, table, and code are rejected', () {
      final result = ArtifactDocumentCodec.decodeLoose([
        {'type': 'markdown', 'text': '  '},
        {'type': 'table', 'columns': const [], 'rows': const []},
        {'type': 'code', 'code': ''},
        {'type': 'data'},
      ]);
      expect(result.document.isEmpty, isTrue);
      expect(result.errors, hasLength(greaterThanOrEqualTo(4)));
      expect(result.errors, contains('blocks[0].markdown: text is empty'));
      expect(result.errors, contains('blocks[2].code: code is empty'));
      expect(result.errors, contains('blocks[3].data: json is missing'));
    });

    test('a ragged table row warns but still renders', () {
      final result = ArtifactDocumentCodec.decodeLoose([
        {
          'type': 'table',
          'columns': [
            {'key': 'a', 'label': 'A'},
            {'key': 'b', 'label': 'B'},
          ],
          'rows': [
            ['1'],
          ],
        },
      ]);
      expect(result.document.blocks, hasLength(1));
      expect(result.warnings.single, contains('1 cells for 2 columns'));
    });

    test('lineStart below 1 is rejected', () {
      final result = ArtifactDocumentCodec.decodeLoose([
        {'type': 'code', 'code': 'x', 'lineStart': 0},
      ]);
      expect(result.errors.single, endsWith('lineStart must be 1 or greater'));
    });
  });

  group('block ids', () {
    test('are short, sequential, and stamped only where missing', () {
      final blocks = ArtifactDocumentCodec.assignBlockIds([
        const ArtifactMarkdownBlock(text: 'a'),
        const ArtifactMarkdownBlock(text: 'b', id: 'keep'),
        const ArtifactMarkdownBlock(text: 'c'),
      ]);
      expect(blocks.map((b) => b.id), ['b1', 'keep', 'b2']);
    });

    test('never reuse an id spent by an earlier revision', () {
      // An id must mean the same block for the artifact's whole history, or a
      // per-block anchor silently retargets when a block is deleted.
      final blocks = ArtifactDocumentCodec.assignBlockIds(
        [
          const ArtifactMarkdownBlock(text: 'a'),
          const ArtifactMarkdownBlock(text: 'b'),
        ],
        reserved: {'b1', 'b2', 'b3'},
      );
      expect(blocks.map((b) => b.id), ['b4', 'b5']);
    });

    test('a duplicate supplied id is replaced, not honoured twice', () {
      final blocks = ArtifactDocumentCodec.assignBlockIds([
        const ArtifactMarkdownBlock(text: 'a', id: 'dup'),
        const ArtifactMarkdownBlock(text: 'b', id: 'dup'),
      ]);
      expect(blocks.first.id, 'dup');
      expect(blocks.last.id, 'b1');
    });

    test('blockIdsOf collects exactly the stamped ids', () {
      final blocks = ArtifactDocumentCodec.assignBlockIds([
        const ArtifactMarkdownBlock(text: 'a'),
        const ArtifactMarkdownBlock(text: 'b'),
      ]);
      expect(ArtifactDocumentCodec.blockIdsOf(blocks), {'b1', 'b2'});
    });
  });
}
