import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:test/test.dart';

List<HarnessMessage> _buildHistory(int turns) {
  final h = <HarnessMessage>[];
  for (var i = 0; i < turns; i++) {
    h.add(HarnessMessage.user('Question number $i with some detail ' * 20));
    h.add(HarnessMessage.assistant('Answer number $i explaining things ' * 20));
  }
  return h;
}

void main() {
  const compactor = DefaultHarnessCompactor();

  group('DefaultHarnessCompactor.maybeCompact', () {
    test('null context window is a no-op', () async {
      final h = _buildHistory(10);
      final before = h.length;
      final r = await compactor.maybeCompact(h, contextWindow: null);
      expect(r.changed, isFalse);
      expect(h.length, before);
    });

    test('under budget is a no-op', () async {
      final h = _buildHistory(2);
      final r = await compactor.maybeCompact(h, contextWindow: 1000000);
      expect(r.changed, isFalse);
    });

    test(
      'over budget folds older turns and injects one summary marker',
      () async {
        final h = _buildHistory(10);
        final r = await compactor.maybeCompact(h, contextWindow: 500);
        expect(r.changed, isTrue);
        expect(r.summarized, isTrue);
        // Summary is the first message and marked.
        expect(h.first.role, HarnessRole.user);
        expect(h.first.textContent, startsWith(harnessSummaryMarker));
        // Kept the newest keepTurns (default 3) user turns verbatim after summary.
        final userTurns = h.where((m) => m.role == HarnessRole.user).length;
        expect(userTurns, CompactionConfig.defaults.keepTurns + 1); // +summary
        expect(r.messagesFolded, greaterThan(0));
      },
    );

    test(
      'folds within a single user turn (autonomous /goal or /loop run)',
      () async {
        // One user message, then a long assistant<->tool exchange — the shape of
        // an autonomous run. The user-boundary rule can never fold this; the
        // token-budget path must.
        final h = <HarnessMessage>[
          HarnessMessage.user('Do the big task ' * 10),
        ];
        for (var i = 0; i < 20; i++) {
          h.add(
            HarnessMessage(
              role: HarnessRole.assistant,
              content: [
                HarnessTextBlock('Working on step $i ' * 10),
                HarnessToolUseBlock(
                  id: 't$i',
                  name: 'read',
                  input: {'path': '$i'},
                ),
              ],
            ),
          );
          h.add(
            HarnessMessage.toolResults([
              HarnessToolResultBlock(
                toolUseId: 't$i',
                content: 'file $i ' * 30,
              ),
            ]),
          );
        }
        final foldedFrom = h.length;
        final r = await compactor.maybeCompact(h, contextWindow: 2000);
        expect(r.changed, isTrue, reason: 'single-turn history must compact');
        expect(r.summarized, isTrue);
        expect(h.length, lessThan(foldedFrom));
        // Summary is first and marked.
        expect(h.first.role, HarnessRole.user);
        expect(h.first.textContent, startsWith(harnessSummaryMarker));
        // The kept tail never starts on an orphaned tool result.
        expect(h[1].role, isNot(HarnessRole.tool));
        // Every kept tool result still has its tool_use earlier in history.
        for (var i = 0; i < h.length; i++) {
          final m = h[i];
          if (m.role != HarnessRole.tool) {
            continue;
          }
          for (final b in m.content.whereType<HarnessToolResultBlock>()) {
            final hasUse = h
                .take(i)
                .any(
                  (p) => p.content.whereType<HarnessToolUseBlock>().any(
                    (u) => u.id == b.toolUseId,
                  ),
                );
            expect(
              hasUse,
              isTrue,
              reason: 'tool_result ${b.toolUseId} orphaned after fold',
            );
          }
        }
      },
    );

    test('re-anchors on an existing summary rather than nesting', () async {
      final h = _buildHistory(10);
      await compactor.maybeCompact(h, contextWindow: 500);
      final firstSummary = h.first.textContent;
      // Grow again and compact a second time.
      h.addAll(_buildHistory(8));
      final r2 = await compactor.maybeCompact(h, contextWindow: 500);
      expect(r2.changed, isTrue);
      // Still exactly one summary marker at the front.
      expect(h.first.textContent, startsWith(harnessSummaryMarker));
      final markers = h
          .where((m) => m.textContent.startsWith(harnessSummaryMarker))
          .length;
      expect(markers, 1);
      expect(h.first.textContent, isNot(equals(firstSummary)));
    });
  });

  group('pruneToolResults', () {
    test('elides an uneventful older tool result, protects the newest', () {
      final h = <HarnessMessage>[
        HarnessMessage.user('do things'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessToolUseBlock(id: 't1', name: 'search', input: {})],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(toolUseId: 't1', content: 'No matches found'),
        ]),
        HarnessMessage.user('more'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessToolUseBlock(id: 't2', name: 'search', input: {})],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(toolUseId: 't2', content: 'No matches found'),
        ]),
      ];
      final elided = compactor.pruneToolResults(h);
      expect(elided, 1); // only the older one
      final older = h[2].content.first as HarnessToolResultBlock;
      expect(older.content, elidedResultMarker);
      final newest = h[5].content.first as HarnessToolResultBlock;
      expect(newest.content, 'No matches found'); // protected
    });
  });

  group('serializeHarnessHistory', () {
    test('renders user turns and assistant answer + action trail', () {
      final h = [
        HarnessMessage.user('build the thing'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessTextBlock('Done.'),
            HarnessToolUseBlock(id: 'x', name: 'edit', input: {}),
          ],
        ),
      ];
      final out = serializeHarnessHistory(h, selfAgentName: 'dev');
      expect(out, contains('# User'));
      expect(out, contains('build the thing'));
      expect(out, contains('# dev'));
      expect(out, contains('Done.'));
      expect(out, contains('(actions: edit)'));
    });
  });
}
