import 'package:cc_domain/core/domain/services/active_stream_registry.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_markdown/cc_markdown.dart' show CcSelectionScope;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/live_transcript_controller.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_flow.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_segment_row.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  group('TranscriptFlow', () {
    // A turn whose Claude Code login was revoked mid-way ended as a red mono
    // row repeating the CLI's sentence twice, with no way to sign back in.
    testWidgets('a Claude sign-in failure is a notice with a sign-in action', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            claudeAccountsProvider.overrideWith((ref) async => const []),
          ],
          child: testWrap(
            TranscriptFlow(
              codeFont: 'monospace',
              segments: [
                TextSegment(text: 'Working on it.', startedAt: ts),
                ErrorSegment(
                  message:
                      '[claude] Failed to authenticate: OAuth token revoked. '
                      '(HTTP 401)',
                  code: ErrorSegment.authenticationErrorCode,
                  source: ErrorSegment.claudeCodeSource,
                  startedAt: ts,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CcAlert), findsOneWidget);
      expect(find.byType(TranscriptSegmentRow), findsNothing);
      expect(
        find.text(l10n.transcriptClaudeSignInExpiredTitle),
        findsOneWidget,
      );
      // The upstream sentence stays, once, without the lane prefix.
      expect(
        find.text('Failed to authenticate: OAuth token revoked. (HTTP 401)'),
        findsOneWidget,
      );

      await tester.tap(find.text(l10n.claudeAccountSignIn));
      await tester.pumpAndSettle();
      expect(find.text(l10n.claudeSignInDialogTitle), findsOneWidget);
      expect(find.text('claude auth login'), findsOneWidget);
    });

    testWidgets('a provider sign-in failure explains the fix without a '
        'Claude action', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(
        testWrap(
          TranscriptFlow(
            codeFont: 'monospace',
            segments: [
              ErrorSegment(
                message: 'Anthropic API error 401: invalid x-api-key',
                code: ErrorSegment.authenticationErrorCode,
                source: 'harness',
                startedAt: ts,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text(l10n.transcriptSignInExpiredTitle), findsOneWidget);
      expect(find.text(l10n.claudeAccountSignIn), findsNothing);
    });

    testWidgets('renders reasoning, tools and answer inline in order', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
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
        ),
      );
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
      await tester.pumpWidget(
        testWrap(
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
        ),
      );
      await tester.pump();

      // Last segment closed + still live → the flow reports it is still
      // working rather than going silent.
      expect(find.textContaining('Thinking'), findsWidgets);
    });

    testWidgets(
      'a running tool shows a pending spinner and a live activity tail',
      (tester) async {
        await tester.pumpWidget(
          testWrap(
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
          ),
        );
        await tester.pump();

        // The running tool row carries its own pending spinner (one CcSpinner),
        // and the turn-level tail names the activity class in flight.
        expect(find.byType(CcSpinner), findsOneWidget);
        expect(find.textContaining('Running'), findsWidgets);
      },
    );

    testWidgets('empty + live renders just the thinking tail', (tester) async {
      await tester.pumpWidget(
        testWrap(
          const TranscriptFlow(
            codeFont: 'monospace',
            isLive: true,
            segments: [],
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Thinking'), findsWidgets);
    });
  });

  group('closed-row memoization', () {
    testWidgets(
      'closed rows reuse the identical widget instance across pumps',
      (tester) async {
        await tester.pumpWidget(
          testWrap(
            TranscriptFlow(
              codeFont: 'monospace',
              segments: [
                TextSegment(text: 'first answer', startedAt: ts, durationMs: 5),
              ],
            ),
          ),
        );
        final row = tester.widget<TurnProse>(find.byType(TurnProse));

        // New (value-equal) segment instances + one appended segment: the
        // closed row must come back as the IDENTICAL widget instance so
        // Element.update skips its subtree.
        await tester.pumpWidget(
          testWrap(
            TranscriptFlow(
              codeFont: 'monospace',
              segments: [
                TextSegment(text: 'first answer', startedAt: ts, durationMs: 5),
                TextSegment(
                  text: 'second answer',
                  startedAt: ts,
                  durationMs: 5,
                ),
              ],
            ),
          ),
        );
        final rows = tester
            .widgetList<TurnProse>(find.byType(TurnProse))
            .toList();
        expect(rows, hasLength(2));
        expect(identical(rows.first, row), isTrue);
        expect(find.textContaining('second answer'), findsWidgets);
      },
    );

    testWidgets('a changed segment or code font invalidates the memo', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          TranscriptFlow(
            codeFont: 'monospace',
            segments: [
              TextSegment(text: 'stable', startedAt: ts, durationMs: 5),
            ],
          ),
        ),
      );
      final before = tester.widget<TurnProse>(find.byType(TurnProse));

      // Same value, different code font → rebuilt row.
      await tester.pumpWidget(
        testWrap(
          TranscriptFlow(
            codeFont: 'serif',
            segments: [
              TextSegment(text: 'stable', startedAt: ts, durationMs: 5),
            ],
          ),
        ),
      );
      final afterFont = tester.widget<TurnProse>(find.byType(TurnProse));
      expect(identical(before, afterFont), isFalse);

      // Different value → rebuilt row.
      await tester.pumpWidget(
        testWrap(
          TranscriptFlow(
            codeFont: 'serif',
            segments: [
              TextSegment(text: 'changed', startedAt: ts, durationMs: 5),
            ],
          ),
        ),
      );
      final afterValue = tester.widget<TurnProse>(find.byType(TurnProse));
      expect(identical(afterFont, afterValue), isFalse);
      expect(find.textContaining('changed'), findsWidgets);
    });
  });

  group('live open row', () {
    testWidgets('streams deltas without a parent rebuild', (tester) async {
      final registry = ActiveStreamRegistry();
      registry.register('m1', spaceId: 'c1');
      registry.apply(
        'm1',
        SegmentOpened(0, TextSegment(text: 'Hel', startedAt: ts)),
      );
      final live = LiveTranscriptController(registry, 'm1');
      addTearDown(live.dispose);

      await tester.pumpWidget(
        testWrap(
          TranscriptFlow(
            codeFont: 'monospace',
            isLive: true,
            live: live,
            segments: registry.snapshot('m1')!,
          ),
        ),
      );
      expect(find.textContaining('Hel', findRichText: true), findsWidgets);

      // Deltas pulse ONLY the open row's ValueListenableBuilder — no new
      // TranscriptFlow widget is pumped, yet the rendered text updates.
      registry.apply('m1', const SegmentDelta(0, 'lo there'));
      await tester.pump();
      await tester.pump();
      expect(
        find.textContaining('Hello there', findRichText: true),
        findsWidgets,
      );
      await registry.unregister('m1');
      await tester.pump();
    });

    testWidgets('a row that closes in the feed finalizes in place', (
      tester,
    ) async {
      const text = 'Para one.\n\nPara two.\n\ntail\nx';
      final registry = ActiveStreamRegistry();
      registry.register('m1', spaceId: 'c1');
      registry.apply(
        'm1',
        SegmentOpened(0, TextSegment(text: text, startedAt: ts)),
      );
      final live = LiveTranscriptController(registry, 'm1');
      addTearDown(live.dispose);

      // The feed owns selection, which is what lets the row stay on the
      // streaming renderer once it closes.
      Widget flow() => testWrap(
        CcSelectionScope(
          child: TranscriptFlow(
            codeFont: 'monospace',
            isLive: true,
            live: live,
            segments: registry.snapshot('m1')!,
          ),
        ),
      );

      await tester.pumpWidget(flow());
      final first = find.textContaining('Para one', findRichText: true);
      final before = tester.renderObject(first);

      registry.apply(
        'm1',
        SegmentClosed(0, TextSegment(text: text, startedAt: ts, durationMs: 5)),
      );
      await tester.pumpWidget(flow());

      // Same paragraph render object: closing did not re-parse and relayout
      // the answer (it moved from the delta listener to the closed slot).
      expect(identical(tester.renderObject(first), before), isTrue);
      expect(find.textContaining('tail', findRichText: true), findsWidgets);
      await registry.unregister('m1');
      await tester.pump();
    });
  });
}
