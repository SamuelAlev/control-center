import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/transcript_segment_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  group('TranscriptSegmentRow', () {
    testWidgets('read tool shows verb and path', (tester) async {
      await tester.pumpWidget(testWrap(
        TranscriptSegmentRow(
          segment: ToolSegment(
            toolName: 'Read',
            toolCallId: 'c',
            inputs: const {'file_path': 'lib/x.dart'},
            outputs: 'contents',
            status: ToolSegmentStatus.ok,
            startedAt: ts,
            durationMs: 1200,
          ),
          codeFont: 'monospace',
        ),
      ));
      expect(find.textContaining('Read'), findsWidgets);
      expect(find.textContaining('lib/x.dart'), findsWidgets);
    });

    testWidgets('edit tool shows +N −N stats', (tester) async {
      await tester.pumpWidget(testWrap(
        TranscriptSegmentRow(
          segment: ToolSegment(
            toolName: 'Edit',
            toolCallId: 'c',
            inputs: const {
              'file_path': 'x.dart',
              'old_string': 'a\nb',
              'new_string': 'a\nc\nd',
            },
            status: ToolSegmentStatus.ok,
            startedAt: ts,
            durationMs: 500,
          ),
          codeFont: 'monospace',
        ),
      ));
      expect(find.textContaining('+2'), findsWidgets);
      expect(find.textContaining('−1'), findsWidgets);
    });

    testWidgets('error segment is expanded by default with error icon', (tester) async {
      await tester.pumpWidget(testWrap(
        TranscriptSegmentRow(
          segment: ErrorSegment(
            message: 'something went wrong with a long enough message to expand',
            startedAt: ts,
          ),
          codeFont: 'monospace',
        ),
      ));
      // Status uses an icon shape (not color alone).
      expect(find.byIcon(LucideIcons.circleX), findsOneWidget);
      // Default-expanded: the full message renders in the detail markdown.
      expect(find.textContaining('something went wrong'), findsWidgets);
    });

    testWidgets('completed tool is collapsed by default', (tester) async {
      await tester.pumpWidget(testWrap(
        TranscriptSegmentRow(
          segment: ToolSegment(
            toolName: 'Read',
            toolCallId: 'c',
            inputs: const {'file_path': 'x.dart'},
            outputs: 'a' * 200,
            status: ToolSegmentStatus.ok,
            startedAt: ts,
            durationMs: 100,
          ),
          codeFont: 'monospace',
        ),
      ));
      // Check icon for a successful tool.
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      // Tap to expand reveals the code body.
      await tester.tap(find.textContaining('Read').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('aaa'), findsWidgets);
    });

    testWidgets('tool row renders a category left border', (tester) async {
      await tester.pumpWidget(testWrap(
        TranscriptSegmentRow(
          segment: ToolSegment(
            toolName: 'Edit',
            toolCallId: 'c',
            inputs: const {
              'file_path': 'x.dart',
              'old_string': 'a',
              'new_string': 'b',
            },
            status: ToolSegmentStatus.ok,
            startedAt: ts,
            durationMs: 100,
          ),
          codeFont: 'monospace',
        ),
      ));
      // Each row carries a 2px colored left border as an additional (never
      // sole) scannability cue.
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasLeftBorder = containers.any((c) {
        final d = c.decoration;
        return d is BoxDecoration &&
            d.border is Border &&
            (d.border as Border).left.width > 0;
      });
      expect(hasLeftBorder, isTrue);
    });
  });
}
