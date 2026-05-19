import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/transcript_flow.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  group('TranscriptFlow', () {
    testWidgets('renders reasoning, tools, and answer inline in order',
        (tester) async {
      await tester.pumpWidget(testWrap(
        TranscriptFlow(
          codeFont: 'monospace',
          segments: [
            ReasoningSegment(
              text: 'Let me think about this.',
              startedAt: ts,
              durationMs: 3000,
            ),
            ToolSegment(
              toolName: 'Read',
              toolCallId: 'c',
              inputs: const {'file_path': 'lib/x.dart'},
              outputs: 'data',
              status: ToolSegmentStatus.ok,
              startedAt: ts,
              durationMs: 1000,
            ),
            TextSegment(text: 'All done.', startedAt: ts, durationMs: 100),
          ],
        ),
      ));
      await tester.pump();

      // Reasoning is shown inline by default — not hidden behind a master
      // "Thought for · N tool calls" accordion.
      expect(find.textContaining('Let me think about this.'), findsWidgets);
      // The tool call renders inline where it happened.
      expect(find.textContaining('Read'), findsWidgets);
      expect(find.textContaining('lib/x.dart'), findsWidgets);
      // The answer prose is part of the same flow, not a separate trailing block.
      expect(find.textContaining('All done.'), findsWidgets);
    });

    testWidgets('shows a live status tail between steps', (tester) async {
      await tester.pumpWidget(testWrap(
        TranscriptFlow(
          codeFont: 'monospace',
          isLive: true,
          segments: [
            ToolSegment(
              toolName: 'Read',
              toolCallId: 'c',
              inputs: const {'file_path': 'x.dart'},
              outputs: 'data',
              status: ToolSegmentStatus.ok,
              startedAt: ts,
              durationMs: 500,
            ),
          ],
        ),
      ));
      await tester.pump();

      // Last segment closed + still live → the flow reports it is still
      // working rather than going silent.
      expect(find.textContaining('Thinking'), findsWidgets);
    });

    testWidgets('a running tool shows a pending spinner and a live activity tail',
        (tester) async {
      await tester.pumpWidget(testWrap(
        TranscriptFlow(
          codeFont: 'monospace',
          isLive: true,
          segments: [
            ToolSegment(
              toolName: 'Bash',
              toolCallId: 'c',
              inputs: const {'command': 'echo hi'},
              status: ToolSegmentStatus.running,
              startedAt: ts,
            ),
          ],
        ),
      ));
      await tester.pump();

      // The running tool row carries its own pending spinner (one CcSpinner),
      // and the turn-level tail names the activity class in flight.
      expect(find.byType(CcSpinner), findsOneWidget);
      expect(find.textContaining('Running'), findsWidgets);
    });

    testWidgets('empty + live renders just the thinking tail', (tester) async {
      await tester.pumpWidget(testWrap(
        const TranscriptFlow(
          codeFont: 'monospace',
          isLive: true,
          segments: [],
        ),
      ));
      await tester.pump();

      expect(find.textContaining('Thinking'), findsWidgets);
    });
  });
}
