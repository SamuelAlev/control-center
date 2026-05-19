import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_chart.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_table.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_view.dart';
import 'package:control_center/shared/widgets/artifacts/json_tree_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

/// The artifact renderer: every declared block kind must draw and a block the
/// engine cannot draw must degrade rather than throw.
///
/// The canonical kind list is the contract — if a kind is added to
/// `artifactBlockKinds` and not to the renderer's switch, the switch stops
/// compiling. This suite covers the other direction: that each kind actually
/// produces a widget rather than a silent hole.
void main() {
  Future<void> pump(WidgetTester tester, ArtifactDocument document) async {
    await tester.pumpWidget(
      testWrap(
        SizedBox(
          width: 800,
          height: 600,
          child: SingleChildScrollView(child: ArtifactView(document: document)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('a markdown block renders through the app markdown engine', (
    tester,
  ) async {
    await pump(
      tester,
      const ArtifactDocument(
        blocks: [ArtifactMarkdownBlock(text: 'Hello **there**')],
      ),
    );
    expect(find.byType(CcMarkdown), findsOneWidget);
  });

  testWidgets('a table block renders headers and cells', (tester) async {
    await pump(
      tester,
      const ArtifactDocument(
        blocks: [
          ArtifactTableBlock(
            columns: [
              ArtifactColumn(key: 'name', label: 'Name'),
              ArtifactColumn(
                key: 'count',
                label: 'Count',
                align: ArtifactColumnAlign.right,
              ),
            ],
            rows: [
              ['alpha', '3'],
              ['beta', '11'],
            ],
          ),
        ],
      ),
    );
    expect(find.byType(ArtifactTable), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
  });

  testWidgets('a short row renders blank cells instead of throwing', (
    tester,
  ) async {
    // A persisted artifact must always come back out, even if a row is ragged.
    await pump(
      tester,
      const ArtifactDocument(
        blocks: [
          ArtifactTableBlock(
            columns: [
              ArtifactColumn(key: 'a', label: 'A'),
              ArtifactColumn(key: 'b', label: 'B'),
            ],
            rows: [
              ['only one'],
            ],
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('only one'), findsOneWidget);
  });

  testWidgets('a table scrolls horizontally rather than overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        SizedBox(
          width: 200,
          height: 300,
          child: ArtifactView(
            document: ArtifactDocument(
              blocks: [
                ArtifactTableBlock(
                  columns: [
                    for (var i = 0; i < 8; i++)
                      ArtifactColumn(key: 'c$i', label: 'Column $i'),
                  ],
                  rows: const [
                    ['1', '2', '3', '4', '5', '6', '7', '8'],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // No RenderFlex overflow: the wide content lives in its own scroller.
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(ArtifactTable),
        matching: find.byType(SingleChildScrollView),
      ),
      findsWidgets,
    );
  });

  testWidgets('a chart renders with a labelled legend', (tester) async {
    // Series identity must never rest on color alone.
    await pump(
      tester,
      const ArtifactDocument(
        blocks: [
          ArtifactChartBlock(
            chartKind: ArtifactChartKind.bar,
            title: 'Tokens by day',
            series: [
              ArtifactSeries(
                label: 'input',
                points: [
                  ArtifactPoint(x: 'Mon', y: 3),
                  ArtifactPoint(x: 'Tue', y: 5),
                ],
              ),
              ArtifactSeries(
                label: 'output',
                points: [
                  ArtifactPoint(x: 'Mon', y: 1),
                  ArtifactPoint(x: 'Tue', y: 2),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    expect(find.byType(ArtifactChart), findsOneWidget);
    expect(find.text('Tokens by day'), findsOneWidget);
    expect(find.text('input'), findsOneWidget);
    expect(find.text('output'), findsOneWidget);
  });

  testWidgets('a chart with no usable series renders nothing, not an error', (
    tester,
  ) async {
    await pump(
      tester,
      const ArtifactDocument(
        blocks: [
          ArtifactChartBlock(
            chartKind: ArtifactChartKind.line,
            series: [ArtifactSeries(label: 'empty', points: [])],
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a mermaid block draws natively', (tester) async {
    await pump(
      tester,
      const ArtifactDocument(
        blocks: [
          ArtifactMermaidBlock(source: 'flowchart TD\n  a["One"] --> b["Two"]'),
        ],
      ),
    );
    expect(find.byType(CcMermaidView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wide mermaid diagram fits the width instead of being cut', (
    tester,
  ) async {
    // The regression: the artifact's own diagram frame wrapped the view in a
    // horizontal scroller, which hands it UNBOUNDED width — so it laid out at
    // its natural size and the right-hand side was simply cut off the card.
    // Bounded, the engine scales it down to fit (and only scrolls once it would
    // shrink past legibility).
    await pump(
      tester,
      const ArtifactDocument(
        blocks: [
          ArtifactMermaidBlock(
            source:
                'sequenceDiagram\n'
                '  participant User\n'
                '  participant PR_Detail\n'
                '  participant Tab_System\n'
                '  participant Chat_Tab\n'
                '  participant Messaging_Context\n'
                '  User->>PR_Detail: Navigate to PR\n'
                '  PR_Detail->>Tab_System: Load tabs for PR\n'
                '  Tab_System->>Chat_Tab: Include chat tab\n'
                '  Chat_Tab->>Messaging_Context: Initialize with PR info\n',
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(CcMermaidView)).width,
      lessThanOrEqualTo(800),
      reason: 'a diagram laid out wider than the card is a diagram cut in half',
    );
  });

  testWidgets('an undrawable mermaid dialect degrades without throwing', (
    tester,
  ) async {
    // `gitGraph` is not one of the engine's dialects; the fallback is a code
    // block, never an exception (the engine never throws on any input).
    await pump(
      tester,
      const ArtifactDocument(
        blocks: [ArtifactMermaidBlock(source: 'gitGraph\n  commit')],
      ),
    );
    expect(tester.takeException(), isNull);
    // The degraded path is a code block showing the source, so nothing is lost:
    // no diagram widget is mounted at all.
    expect(find.byType(CcMermaidView), findsNothing);
    expect(find.textContaining('gitGraph'), findsWidgets);
  });

  testWidgets('a code block renders its title and body', (tester) async {
    await pump(
      tester,
      const ArtifactDocument(
        blocks: [
          ArtifactCodeBlock(
            code: 'final x = 1;',
            language: 'dart',
            title: 'example.dart',
          ),
        ],
      ),
    );
    expect(find.text('example.dart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a data block renders a JSON tree', (tester) async {
    await pump(
      tester,
      const ArtifactDocument(
        blocks: [
          ArtifactDataBlock(json: {'name': 'cc', 'count': 2}),
        ],
      ),
    );
    expect(find.byType(JsonTreeView), findsOneWidget);
    expect(find.textContaining('name'), findsWidgets);
  });

  testWidgets('every declared block kind renders in one document', (
    tester,
  ) async {
    // The anti-"invisible kind" check at the render layer: one fixture per
    // canonical kind, all in a single document, none of them throwing.
    await pump(
      tester,
      const ArtifactDocument(
        blocks: [
          ArtifactMarkdownBlock(text: 'prose'),
          ArtifactTableBlock(
            columns: [ArtifactColumn(key: 'a', label: 'A')],
            rows: [
              ['1'],
            ],
          ),
          ArtifactChartBlock(
            chartKind: ArtifactChartKind.pie,
            series: [
              ArtifactSeries(
                label: 'share',
                points: [
                  ArtifactPoint(x: 'a', y: 1),
                  ArtifactPoint(x: 'b', y: 3),
                ],
              ),
            ],
          ),
          ArtifactMermaidBlock(source: 'flowchart TD\n  a --> b'),
          ArtifactCodeBlock(code: 'x', language: 'dart'),
          ArtifactDataBlock(json: {'k': 'v'}),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(artifactBlockKinds, hasLength(6));
  });

  testWidgets('an empty document renders nothing', (tester) async {
    await pump(tester, const ArtifactDocument(blocks: []));
    expect(find.byType(ArtifactTable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('JsonTreeView', () {
    testWidgets('renders nested objects and arrays', (tester) async {
      await tester.pumpWidget(
        testWrap(
          const SizedBox(
            width: 400,
            height: 400,
            child: SingleChildScrollView(
              child: JsonTreeView(
                value: {
                  'a': 1,
                  'b': ['x', 'y'],
                  'c': {'d': true},
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('a'), findsOneWidget);
      expect(find.text('[2]'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('falls back to raw text for non-JSON input', (tester) async {
      await tester.pumpWidget(
        testWrap(
          SizedBox(width: 400, child: JsonTreeView.fromRaw('not json at all')),
        ),
      );
      await tester.pump();
      expect(find.text('not json at all'), findsOneWidget);
    });

    testWidgets('renders null as an italic literal, not a blank', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          const SizedBox(
            width: 400,
            child: JsonTreeView(value: {'missing': null}),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('null'), findsOneWidget);
    });
  });
}
