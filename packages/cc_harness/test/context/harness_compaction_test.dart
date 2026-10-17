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

    test('forced overflow cuts deeper than the newest user turns', () async {
      final history = _buildHistory(5);
      for (var i = 0; i < 5; i++) {
        history.add(
          HarnessMessage(
            role: HarnessRole.assistant,
            content: [
              HarnessToolUseBlock(id: 'large-$i', name: 'read', input: {}),
            ],
          ),
        );
        history.add(
          HarnessMessage.toolResults([
            HarnessToolResultBlock(
              toolUseId: 'large-$i',
              content: i == 4
                  ? 'small last result'
                  : 'Long file content $i ' * 800,
            ),
          ]),
        );
      }
      final normal = List<HarnessMessage>.of(history);
      final forced = List<HarnessMessage>.of(history);
      final normalResult = await compactor.maybeCompact(
        normal,
        contextWindow: 5000,
      );
      final forcedResult = await compactor.maybeCompact(
        forced,
        contextWindow: 5000,
        force: true,
      );
      expect(normalResult.changed, isTrue);
      expect(forcedResult.changed, isTrue);
      expect(
        forcedResult.messagesFolded,
        greaterThan(normalResult.messagesFolded),
      );
      expect(forcedResult.tokensAfter, lessThan(normalResult.tokensAfter));
      // The deeper cut must not orphan tool results, even when the budget
      // threshold falls between a tool call and its result.
      final pairedIds = <String>{};
      for (final message in forced.skip(1)) {
        for (final use in message.content.whereType<HarnessToolUseBlock>()) {
          pairedIds.add(use.id);
        }
        for (final result
            in message.content.whereType<HarnessToolResultBlock>()) {
          expect(pairedIds, contains(result.toolUseId));
        }
      }
    });

    test('forced overflow folds an oversized final tool turn', () async {
      final history = <HarnessMessage>[
        HarnessMessage.user('Read this file'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessToolUseBlock(id: 'huge', name: 'read', input: {})],
        ),
        HarnessMessage.toolResults([
          HarnessToolResultBlock(
            toolUseId: 'huge',
            content: 'large output ' * 1000,
          ),
        ]),
      ];
      final result = await compactor.maybeCompact(
        history,
        contextWindow: 4000,
        force: true,
      );
      expect(result.messagesFolded, 3);
      expect(history, hasLength(1));
      expect(history.single.textContent, startsWith(harnessSummaryMarker));
    });

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
        HarnessMessage.toolResults([
          HarnessToolResultBlock(
            toolUseId: 't1',
            content: 'No matches found in ${'nested directories ' * 20}',
          ),
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
      // A substantial empty-search report is worth replacing. Force isolates
      // the classification and newest-result protection from cache economics.
      final elided = compactor.pruneToolResults(h, force: true);
      expect(elided, 1); // only the older one
      final older = h[2].content.first as HarnessToolResultBlock;
      expect(older.content, elidedResultMarker);
      final newest = h[5].content.first as HarnessToolResultBlock;
      expect(newest.content, 'No matches found'); // protected
    });

    test('a trivial reclaim leaves history untouched', () {
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
      ];
      final before = h[2].content.first as HarnessToolResultBlock;
      expect(compactor.pruneToolResults(h), 0);
      // Byte-identical, which is the point: editing history here would cost
      // the provider's cached prefix from this message on, to reclaim three
      // words.
      final after = h[2].content.first as HarnessToolResultBlock;
      expect(identical(before, after), isTrue);
      expect(after.content, 'No matches found');
    });

    test('a reclaim worth its cache rewrite goes ahead unforced', () {
      // One stale screenshot is ~1200 tokens on its own; two clear the
      // default 2000-token threshold. The economics still have to be satisfied:
      // the rewrite must pay back before the run ends, so this run is given
      // enough remaining calls for the reclaim to beat the prefix it rebuilds.
      const image = HarnessImageBlock(data: 'AAAA', mediaType: 'image/png');
      const compactor = DefaultHarnessCompactor(
        economics: CompactionEconomics(assumedRemainingCalls: 40),
      );
      final h = <HarnessMessage>[
        HarnessMessage.user('look'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessToolUseBlock(id: 't1', name: 'shot', input: {})],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(
            toolUseId: 't1',
            content: 'A login form.',
            images: [image, image],
          ),
        ]),
        HarnessMessage.user('again'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessToolUseBlock(id: 't2', name: 'shot', input: {})],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(
            toolUseId: 't2',
            content: 'The dashboard.',
            images: [image],
          ),
        ]),
      ];
      compactor.pruneToolResults(h);
      final older = h[2].content.first as HarnessToolResultBlock;
      expect(older.images, isEmpty, reason: 'stale frames shed');
      expect(older.content, 'A login form.', reason: 'the words survive');
      final newest = h[5].content.first as HarnessToolResultBlock;
      expect(newest.images, hasLength(1), reason: 'newest turn protected');
    });

    test('a large surviving suffix makes a short-horizon rewrite lose', () {
      // Two stale images clear the prune threshold, but on one remaining call
      // their savings cannot repay rebuilding a large surviving cached suffix.
      const image = HarnessImageBlock(data: 'AAAA', mediaType: 'image/png');
      const compactor = DefaultHarnessCompactor(
        economics: CompactionEconomics(assumedRemainingCalls: 1),
      );
      final h = <HarnessMessage>[
        HarnessMessage.user('look'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessToolUseBlock(id: 't1', name: 'shot', input: {})],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(
            toolUseId: 't1',
            content: 'A login form.',
            images: [image, image],
          ),
        ]),
        HarnessMessage.user('again'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessToolUseBlock(id: 't2', name: 'shot', input: {})],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(
            toolUseId: 't2',
            content: 'The dashboard.',
            images: [image],
          ),
        ]),
        HarnessMessage.user('more work ${'z' * 5000}'),
      ];
      expect(compactor.pruneToolResults(h), 0);
      final older = h[2].content.first as HarnessToolResultBlock;
      expect(older.images, hasLength(2), reason: 'cache rebuild costs more');
    });

    test('an image-only or mask-only rewrite reports a non-zero count', () {
      // The count is the caller's rewrite signal, so a pass that changed only
      // images (no elision) must still report it — otherwise the loop leaves
      // its cache anchor pointing into rewritten bytes.
      const image = HarnessImageBlock(data: 'AAAA', mediaType: 'image/png');
      const compactor = DefaultHarnessCompactor();
      final h = <HarnessMessage>[
        HarnessMessage.user('look'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessToolUseBlock(id: 't1', name: 'shot', input: {})],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(
            toolUseId: 't1',
            content: 'A login form.',
            images: [image],
          ),
        ]),
        HarnessMessage.user('again'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessToolUseBlock(id: 't2', name: 'shot', input: {})],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(
            toolUseId: 't2',
            content: 'The dashboard.',
            images: [image],
          ),
        ]),
      ];
      // force: assert the reporting, not the economics gate.
      final changed = compactor.pruneToolResults(h, force: true);
      expect(changed, 1, reason: 'the older frame was shed, nothing elided');
      expect((h[2].content.first as HarnessToolResultBlock).images, isEmpty);
    });
  });

  group('masking policy', () {
    const ref = ToolOutputReference(
      handle: 'out_abcdefghijklmnopqrstuv',
      toolName: 'read',
      byteLength: 40000,
      charLength: 40000,
    );
    final big = 'x' * 40000;

    List<HarnessMessage> history({ToolOutputReference? reference}) => [
      HarnessMessage.user('q0'),
      const HarnessMessage(
        role: HarnessRole.assistant,
        content: [
          HarnessToolUseBlock(
            id: 't0',
            name: 'read',
            input: {'path': 'a.dart'},
          ),
        ],
      ),
      HarnessMessage.toolResults([
        HarnessToolResultBlock(
          toolUseId: 't0',
          content: big,
          outputReference: reference,
        ),
      ]),
      HarnessMessage.user('q1'),
      const HarnessMessage(
        role: HarnessRole.assistant,
        content: [
          HarnessToolUseBlock(
            id: 't1',
            name: 'read',
            input: {'path': 'b.dart'},
          ),
        ],
      ),
      HarnessMessage.toolResults(const [
        HarnessToolResultBlock(toolUseId: 't1', content: 'small b'),
      ]),
      HarnessMessage.user('q2'),
    ];

    test('masks a stale recoverable observation and keeps the pair', () {
      final h = history(reference: ref);
      final result = maskStaleObservations(
        h,
        keepTurns: 2,
        minObservationTokens: 200,
      );
      expect(result.maskedCount, 1);
      expect(result.handles, ['out_abcdefghijklmnopqrstuv']);
      final block = h[2].content.first as HarnessToolResultBlock;
      expect(isMaskedObservation(block.content), isTrue);
      expect(block.outputReference, ref, reason: 'the mask stays recoverable');
      expect(block.toolUseId, 't0', reason: 'the pair is intact');
      // The newest turns are untouched.
      expect((h[5].content.first as HarnessToolResultBlock).content, 'small b');
    });

    test('never masks a non-recoverable observation', () {
      final h = history();
      final result = maskStaleObservations(
        h,
        keepTurns: 2,
        minObservationTokens: 200,
      );
      expect(result.maskedCount, 0);
      expect(
        (h[2].content.first as HarnessToolResultBlock).content,
        big,
        reason: 'no reference means no safe recovery, so leave it verbatim',
      );
    });

    test('never masks an error (unresolved diagnostic)', () {
      final h = <HarnessMessage>[
        HarnessMessage.user('q0'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessToolUseBlock(id: 't0', name: 'bash', input: {})],
        ),
        HarnessMessage.toolResults([
          HarnessToolResultBlock(
            toolUseId: 't0',
            content: big,
            isError: true,
            outputReference: ref,
          ),
        ]),
        HarnessMessage.user('q1'),
        HarnessMessage.user('q2'),
      ];
      final result = maskStaleObservations(
        h,
        keepTurns: 1,
        minObservationTokens: 200,
      );
      expect(result.maskedCount, 0);
    });

    test('never masks an active edit target', () {
      final h = <HarnessMessage>[
        HarnessMessage.user('q0'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessToolUseBlock(
              id: 't0',
              name: 'read',
              input: {'path': 'lib/live.dart'},
            ),
          ],
        ),
        HarnessMessage.toolResults([
          HarnessToolResultBlock(
            toolUseId: 't0',
            content: big,
            outputReference: ref,
          ),
        ]),
        // The newest turn edits that same file, making the read above active.
        HarnessMessage.user('edit it'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessToolUseBlock(
              id: 'e1',
              name: 'edit',
              input: {'file_path': 'lib/live.dart'},
            ),
          ],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(toolUseId: 'e1', content: 'ok'),
        ]),
      ];
      final result = maskStaleObservations(
        h,
        keepTurns: 1,
        minObservationTokens: 200,
      );
      expect(result.maskedCount, 0);
    });

    test('the masking policy can relieve pressure without a summary', () async {
      const compactor = DefaultHarnessCompactor(
        config: CompactionConfig(
          policy: CompactionPolicy.masking,
          buffer: 100,
          prune: false,
        ),
      );
      final h = history(reference: ref);
      final result = await compactor.maybeCompact(h, contextWindow: 5000);
      expect(result.changed, isTrue);
      expect(result.summarized, isFalse);
      expect(result.maskedObservations, 1);
      expect(result.decisionReason, 'masking sufficed');
      // No summary marker was injected.
      expect(
        h.any((m) => m.textContent.startsWith(harnessSummaryMarker)),
        isFalse,
      );
    });

    test('pruneToolResults reports a mask-only rewrite', () {
      const compactor = DefaultHarnessCompactor(
        config: CompactionConfig(policy: CompactionPolicy.masking),
      );
      final h = history(reference: ref);
      final changed = compactor.pruneToolResults(h, force: true);
      expect(changed, 1);
      expect(
        isMaskedObservation(
          (h[2].content.first as HarnessToolResultBlock).content,
        ),
        isTrue,
      );
    });
  });

  group('output reservation and purpose calibration', () {
    List<HarnessMessage> fourTurns(int userChars) => [
      for (var i = 0; i < 4; i++) ...[
        HarnessMessage.user('q$i ${'x' * userChars}'),
        HarnessMessage.assistant('a$i'),
      ],
    ];

    test('a reserved output budget pushes the pass over the window', () async {
      // Prompt alone fits; the output reservation is what must not.
      const prompt = 10000; // ~38000 chars
      final h = fourTurns(9500);
      expect(estimateHarnessHistory(h), greaterThan(prompt * 0.8));
      const compactor = DefaultHarnessCompactor(
        config: CompactionConfig(keepTurns: 3, buffer: 0, prune: false),
      );
      final fits = await compactor.maybeCompact(h, contextWindow: 100000);
      expect(fits.changed, isFalse);
      final reserved = await compactor.maybeCompact(
        List<HarnessMessage>.of(fourTurns(9500)),
        contextWindow: 100000,
        reservedOutputTokens: 99000,
      );
      expect(reserved.changed, isTrue, reason: 'reservation counts');
      expect(reserved.summarized, isTrue);
    });

    test('calibration never shrinks the output reservation', () async {
      // history ≈ 10000 estimated tokens; the calibration halves the PROMPT to
      // ≈5000. With a 6000-token reservation the request must still be treated
      // as over the 10000 window. If the reservation were scaled by the same
      // 0.5 factor the total would be 8000 and no pass would run.
      final calibration = TokenCalibration(minSamples: 1);
      calibration.observe(
        providerId: 'p',
        modelId: 'm',
        estimatedTokens: 1000,
        observedPromptTokens: 500,
      );
      final compactor = DefaultHarnessCompactor(
        config: const CompactionConfig(keepTurns: 3, buffer: 0, prune: false),
        calibration: calibration,
        providerId: 'p',
        modelId: 'm',
      );
      final noReserve = await compactor.maybeCompact(
        fourTurns(9500),
        contextWindow: 10000,
      );
      expect(noReserve.changed, isFalse, reason: '5000 prompt fits 10000');
      final withReserve = await compactor.maybeCompact(
        fourTurns(9500),
        contextWindow: 10000,
        reservedOutputTokens: 6000,
      );
      expect(
        withReserve.changed,
        isTrue,
        reason: 'the unscaled 6000 reservation is what tips it over',
      );
    });

    test('hybrid folds at the boundary even when masking sufficed', () async {
      const ref = ToolOutputReference(
        handle: 'out_abcdefghijklmnopqrstuv',
        toolName: 'read',
        byteLength: 40000,
        charLength: 40000,
      );
      List<HarnessMessage> history() => [
        HarnessMessage.user('q0'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessToolUseBlock(id: 't0', name: 'read', input: {'path': 'a'}),
          ],
        ),
        HarnessMessage.toolResults([
          HarnessToolResultBlock(
            toolUseId: 't0',
            content: 'x' * 40000,
            outputReference: ref,
          ),
        ]),
        HarnessMessage.user('q1'),
        HarnessMessage.assistant('a1'),
        HarnessMessage.user('q2'),
        HarnessMessage.assistant('a2'),
        HarnessMessage.user('q3'),
      ];
      const hybrid = DefaultHarnessCompactor(
        config: CompactionConfig(
          policy: CompactionPolicy.hybrid,
          keepTurns: 2,
          buffer: 100,
          prune: false,
        ),
      );
      final h = history();
      final result = await hybrid.maybeCompact(h, contextWindow: 5000);
      expect(result.changed, isTrue);
      expect(result.summarized, isTrue, reason: 'hybrid summarizes too');
      expect(result.maskedObservations, 1, reason: 'and it masked first');
      expect(h.first.textContent, startsWith(harnessSummaryMarker));

      const maskingOnly = DefaultHarnessCompactor(
        config: CompactionConfig(
          policy: CompactionPolicy.masking,
          keepTurns: 2,
          buffer: 100,
          prune: false,
        ),
      );
      final h2 = history();
      final only = await maskingOnly.maybeCompact(h2, contextWindow: 5000);
      expect(only.summarized, isFalse, reason: 'masking stops at masking');
      expect(only.decisionReason, 'masking sufficed');
      expect(
        h2.any((m) => m.textContent.startsWith(harnessSummaryMarker)),
        isFalse,
      );
    });
  });

  group('staged mutation on summarizer failure', () {
    test('commits the mask and reports the failure, never unchanged', () async {
      const ref = ToolOutputReference(
        handle: 'out_abcdefghijklmnopqrstuv',
        toolName: 'read',
        byteLength: 40000,
        charLength: 40000,
      );
      final h = <HarnessMessage>[
        HarnessMessage.user('q0'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessToolUseBlock(id: 't0', name: 'read', input: {'path': 'a'}),
          ],
        ),
        HarnessMessage.toolResults([
          HarnessToolResultBlock(
            toolUseId: 't0',
            content: 'x' * 40000,
            outputReference: ref,
          ),
        ]),
        HarnessMessage.user('q1'),
        HarnessMessage.assistant('a1'),
        HarnessMessage.user('q2'),
        HarnessMessage.assistant('a2'),
        HarnessMessage.user('q3'),
      ];
      final compactor = DefaultHarnessCompactor(
        summarizer: _ThrowingSummarizer(),
        config: const CompactionConfig(
          policy: CompactionPolicy.hybrid,
          keepTurns: 2,
          buffer: 100,
          prune: false,
        ),
      );
      final result = await compactor.maybeCompact(h, contextWindow: 5000);
      expect(result.changed, isTrue);
      expect(result.summarized, isFalse);
      expect(result.maskedObservations, 1);
      expect(result.decisionReason, contains('summarizer failed'));
      // The staged mask was committed (not lost, not mislabelled unchanged)…
      expect(
        isMaskedObservation(
          (h[2].content.first as HarnessToolResultBlock).content,
        ),
        isTrue,
      );
      // …and the aborted fold wrote nothing.
      expect(
        h.any((m) => m.textContent.startsWith(harnessSummaryMarker)),
        isFalse,
      );
    });

    test('rethrows with history untouched when nothing was staged', () async {
      final h = <HarnessMessage>[
        for (var i = 0; i < 6; i++) ...[
          HarnessMessage.user('q$i ${'x' * 500}'),
          HarnessMessage.assistant('a$i'),
        ],
      ];
      final before = List<HarnessMessage>.of(h);
      final compactor = DefaultHarnessCompactor(
        summarizer: _ThrowingSummarizer(),
        config: const CompactionConfig(buffer: 100, prune: false),
      );
      await expectLater(
        compactor.maybeCompact(h, contextWindow: 700),
        throwsA(isA<StateError>()),
      );
      expect(h, before, reason: 'staged-until-commit means no partial write');
    });
  });

  group('bounded repeated folds', () {
    test('the structural summary does not grow without bound', () async {
      const budget = HarnessEvidenceBudget(totalChars: 2000);
      const compactor = DefaultHarnessCompactor(
        config: CompactionConfig(keepTurns: 2, buffer: 100, prune: false),
        summarizer: StructuralHarnessSummarizer(budget: budget),
      );
      final h = <HarnessMessage>[HarnessMessage.user('the task ' * 50)];
      void grow() {
        for (var i = 0; i < 12; i++) {
          h.add(HarnessMessage.user('q ${'x' * 400}'));
          h.add(HarnessMessage.assistant('a ${'y' * 400}'));
        }
      }

      grow();
      for (var round = 0; round < 4; round++) {
        final r = await compactor.maybeCompact(h, contextWindow: 1800);
        expect(r.summarized, isTrue, reason: 'round $round folded');
        grow();
      }
      final summary = h.first.textContent;
      expect(summary, startsWith(harnessSummaryMarker));
      expect(
        summary.length,
        lessThan(budget.totalChars + 400),
        reason: 'repeated folds must not accumulate the prior summary',
      );
      // The original request still survives across folds.
      expect(summary, contains('the task'));
    });

    test('boundEvidence drops whole lines, never a partial handle', () {
      final text =
          '${List.generate(50, (i) => 'line $i ${'z' * 40}').join('\n')}\n'
          'read_output(handle: "out_abcdefghijklmnopqrstuv")';
      final bounded = boundEvidence(text, 200);
      expect(bounded, contains('earlier evidence dropped'));
      expect(bounded.length, lessThan(260));
      if (bounded.contains('read_output')) {
        expect(
          bounded,
          contains('read_output(handle: "out_abcdefghijklmnopqrstuv")'),
          reason: 'a handle is either whole or absent',
        );
      }
    });
  });

  group('evidence budget binds every category (#7)', () {
    test('error-heavy protected observations stay within the budget', () {
      final h = <HarnessMessage>[
        HarnessMessage.user('# Task\nkeep every diagnostic visible'),
        for (var i = 0; i < 30; i++) ...[
          HarnessMessage(
            role: HarnessRole.assistant,
            content: [HarnessToolUseBlock(id: 'e$i', name: 'bash', input: {})],
          ),
          HarnessMessage.toolResults([
            HarnessToolResultBlock(
              toolUseId: 'e$i',
              content: 'error line ${'x' * 1200}',
              isError: true,
              outputReference: ToolOutputReference(
                handle: 'out_diag${i.toString().padLeft(18, '0')}',
                toolName: 'bash',
                byteLength: 1200,
                charLength: 1200,
              ),
            ),
          ]),
        ],
      ];
      const budget = HarnessEvidenceBudget(totalChars: 6000);
      final out = serializeHarnessHistory(h, budget: budget);
      expect(
        out.length,
        lessThan(budget.totalChars + 1000),
        reason: 'protected evidence must not bypass the total budget',
      );
      // The loss is EXPLICIT and preserves a real recovery handle.
      expect(out, contains('diagnostic/active-edit observation(s) omitted'));
      expect(out, contains('read_output(handle: "out_diag'));
      // Instructions are still present.
      expect(out, contains('keep every diagnostic visible'));
      expect(out, contains(evidencePinBegin));
    });
  });

  group('structural pinning vs Markdown headings (#2)', () {
    test(
      'payload headings do not unpin the instructions across folds',
      () async {
        const budget = HarnessEvidenceBudget(totalChars: 1200);
        const compactor = DefaultHarnessCompactor(
          config: CompactionConfig(keepTurns: 2, buffer: 50, prune: false),
          summarizer: StructuralHarnessSummarizer(budget: budget),
        );
        final h = <HarnessMessage>[
          HarnessMessage.user(
            '# Goal\nbuild the thing\n## Acceptance\n'
            'must pass the suite\n${'filler ' * 20}',
          ),
        ];
        void grow() {
          for (var i = 0; i < 10; i++) {
            h.add(HarnessMessage.user('q $i ${'x' * 300}'));
            h.add(HarnessMessage.assistant('a $i ${'y' * 300}'));
          }
        }

        grow();
        for (var round = 0; round < 3; round++) {
          await compactor.maybeCompact(h, contextWindow: 1000);
          grow();
        }
        final summary = h.first.textContent;
        // The request's own `##` heading must NOT terminate the pinned section
        // and let the acceptance criteria fall into the droppable region.
        expect(
          summary,
          contains(
            '# Goal\nbuild the thing\n## Acceptance\nmust pass the suite',
          ),
        );
        expect(
          '# User (original request)'.allMatches(summary),
          hasLength(1),
          reason: 'later turns must not consume the original request budget',
        );
      },
    );

    test(
      'a live edit keeps exact earlier file evidence across the cut',
      () async {
        const budget = HarnessEvidenceBudget(totalChars: 2400);
        const compactor = DefaultHarnessCompactor(
          config: CompactionConfig(keepTurns: 2, buffer: 50, prune: false),
          summarizer: StructuralHarnessSummarizer(budget: budget),
        );
        final h = <HarnessMessage>[
          HarnessMessage.user('# Goal\npreserve the live edit anchor'),
          const HarnessMessage(
            role: HarnessRole.assistant,
            content: [
              HarnessToolUseBlock(
                id: 'read-live',
                name: 'read',
                input: {'path': 'lib/live.dart'},
              ),
            ],
          ),
          HarnessMessage.toolResults(const [
            HarnessToolResultBlock(
              toolUseId: 'read-live',
              content: 'const live = true; // exact edit anchor 7B',
            ),
          ]),
          for (var i = 0; i < 9; i++) ...[
            HarnessMessage.user('step $i ${'x' * 450}'),
            HarnessMessage.assistant('working $i ${'y' * 450}'),
          ],
          const HarnessMessage(
            role: HarnessRole.assistant,
            content: [
              HarnessToolUseBlock(
                id: 'edit-live',
                name: 'edit',
                input: {'path': 'lib/live.dart'},
              ),
            ],
          ),
          HarnessMessage.toolResults(const [
            HarnessToolResultBlock(toolUseId: 'edit-live', content: 'updated'),
          ]),
        ];
        final r = await compactor.maybeCompact(h, contextWindow: 1600);
        expect(r.summarized, isTrue);
        expect(h.first.textContent, contains('preserve the live edit anchor'));
        expect(
          h.first.textContent,
          contains('Observation (read, ok) [active edit]'),
        );
        expect(
          h.first.textContent,
          contains('const live = true; // exact edit anchor 7B'),
        );
        expect(h.first.textContent.length, lessThan(budget.totalChars + 400));
      },
    );
  });

  group('activation metadata across folds (#1)', () {
    test('the digest carries a machine-readable activation list', () {
      final h = <HarnessMessage>[
        HarnessMessage.user('find a tool'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessToolUseBlock(id: 's1', name: 'search_tools', input: {}),
          ],
        ),
        HarnessMessage.toolResults(
          const [
            HarnessToolResultBlock(
              toolUseId: 's1',
              content: 'found read_docs',
              toolReferences: ['read_docs'],
            ),
          ],
          activatedToolNames: const ['read_docs'],
        ),
      ];
      final out = serializeHarnessHistory(h);
      expect(out, contains(evidenceActivationPrefix));
      expect(out, contains('read_docs'));
    });

    test(
      'a fold unions activations onto its single replacement message',
      () async {
        const compactor = DefaultHarnessCompactor(
          config: CompactionConfig(keepTurns: 3, buffer: 50, prune: false),
        );
        final h = <HarnessMessage>[
          HarnessMessage.user('go'),
          const HarnessMessage(
            role: HarnessRole.assistant,
            content: [
              HarnessToolUseBlock(id: 's1', name: 'search_tools', input: {}),
            ],
          ),
          HarnessMessage.toolResults(
            const [
              HarnessToolResultBlock(
                toolUseId: 's1',
                content: 'found read_docs',
                toolReferences: ['read_docs'],
              ),
            ],
            activatedToolNames: const ['read_docs'],
          ),
          for (var i = 0; i < 12; i++) ...[
            HarnessMessage.user('q $i ${'x' * 300}'),
            HarnessMessage.assistant('a $i ${'y' * 300}'),
          ],
        ];
        final r = await compactor.maybeCompact(h, contextWindow: 1200);
        expect(r.summarized, isTrue);
        expect(
          h.first.activatedToolNames,
          contains('read_docs'),
          reason:
              'the activation must survive the fold that removed its result',
        );
        for (var i = 0; i < 12; i++) {
          h.add(HarnessMessage.user('later $i ${'z' * 300}'));
          h.add(HarnessMessage.assistant('progress $i ${'w' * 300}'));
        }
        final again = await compactor.maybeCompact(h, contextWindow: 1200);
        expect(again.summarized, isTrue);
        expect(h.first.activatedToolNames, contains('read_docs'));
      },
    );

    test('masking preserves a message\'s activation metadata', () {
      const ref = ToolOutputReference(
        handle: 'out_abcdefghijklmnopqrstuv',
        toolName: 'search_tools',
        byteLength: 40000,
        charLength: 40000,
      );
      final h = <HarnessMessage>[
        HarnessMessage.user('q0'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessToolUseBlock(id: 's1', name: 'search_tools', input: {}),
          ],
        ),
        HarnessMessage.toolResults(
          [
            HarnessToolResultBlock(
              toolUseId: 's1',
              content: 'x' * 40000,
              outputReference: ref,
            ),
          ],
          activatedToolNames: const ['read_docs'],
        ),
        HarnessMessage.user('q1'),
        HarnessMessage.user('q2'),
      ];
      final r = maskStaleObservations(
        h,
        keepTurns: 1,
        minObservationTokens: 200,
      );
      expect(r.maskedCount, 1);
      expect(h[2].activatedToolNames, contains('read_docs'));
    });
  });

  group('cache economics with the surviving suffix (#3)', () {
    test('a small surviving suffix makes an ordinary prune pay', () {
      // Removing ~2400 image tokens from a suffix that is almost entirely
      // those images leaves ~60 tokens to rebuild. Charging the removed tokens
      // as rebuild cost refused this at the default eight-call horizon.
      const image = HarnessImageBlock(data: 'AAAA', mediaType: 'image/png');
      const compactor = DefaultHarnessCompactor();
      final h = <HarnessMessage>[
        HarnessMessage.user('look'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessToolUseBlock(id: 't1', name: 'shot', input: {})],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(
            toolUseId: 't1',
            content: 'A form.',
            images: [image, image],
          ),
        ]),
        HarnessMessage.user('again'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessToolUseBlock(id: 't2', name: 'shot', input: {})],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(toolUseId: 't2', content: 'fine'),
        ]),
      ];
      final changed = compactor.pruneToolResults(h);
      expect(
        changed,
        1,
        reason: 'only the surviving suffix is rebuilt, so the prune pays',
      );
      expect((h[2].content.first as HarnessToolResultBlock).images, isEmpty);
    });

    test('the first re-ingestion is priced as new input, not a cache read', () {
      const economics = CompactionEconomics();
      expect(
        economics.cache.effectiveRetrievalFirstPrice,
        economics.cache.cacheWritePrice,
      );
      final d = economics.evaluate(
        reclaimedTokens: 1000,
        rebuildTokens: 0,
        retrievalTokens: 1000,
      );
      expect(
        d.shouldRewrite,
        isFalse,
        reason: 'a retrieval that re-adds what the mask removed cancels it',
      );
    });
  });

  group('calibrated tail selection (#9)', () {
    test('a calibrated run keeps a tail whose calibrated size fits', () async {
      // factor 4: a tail kept in RAW units would occupy 4x its calibrated
      // allowance. The retained region must fit the window afterwards.
      final calibration = TokenCalibration(minSamples: 1);
      calibration.observe(
        providerId: 'p',
        modelId: 'm',
        estimatedTokens: 1000,
        observedPromptTokens: 4000,
      );
      final compactor = DefaultHarnessCompactor(
        config: const CompactionConfig(keepTurns: 3, buffer: 0, prune: false),
        // A small summary so `tokensAfter` is dominated by the retained tail —
        // which is what the calibrated-to-raw conversion controls.
        summarizer: const StructuralHarnessSummarizer(
          budget: HarnessEvidenceBudget(totalChars: 400),
        ),
        calibration: calibration,
        providerId: 'p',
        modelId: 'm',
      );
      final h = <HarnessMessage>[
        HarnessMessage.user('task ${'t' * 250}'),
        // Exactly keepTurns user turns, so the fold uses the TOKEN budget path
        // (the user-turn boundary can never fire) — which is where the
        // calibrated-to-raw conversion matters.
        for (var i = 0; i < 90; i++)
          HarnessMessage.assistant('a $i ${'y' * 250}'),
        HarnessMessage.user('mid ${'z' * 250}'),
        HarnessMessage.user('last ${'z' * 250}'),
      ];
      const window = 10000;
      final r = await compactor.maybeCompact(h, contextWindow: window);
      expect(r.summarized, isTrue);
      expect(
        r.tokensAfter,
        lessThan(window),
        reason: 'the retained tail must fit in CALIBRATED tokens',
      );
    });
  });

  group('zero retained turns (#8)', () {
    test('maskKeepTurns 0 masks without throwing', () {
      const ref = ToolOutputReference(
        handle: 'out_abcdefghijklmnopqrstuv',
        toolName: 'read',
        byteLength: 40000,
        charLength: 40000,
      );
      final h = <HarnessMessage>[
        HarnessMessage.user('q0'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessToolUseBlock(id: 't0', name: 'read', input: {'path': 'a'}),
          ],
        ),
        HarnessMessage.toolResults([
          HarnessToolResultBlock(
            toolUseId: 't0',
            content: 'x' * 40000,
            outputReference: ref,
          ),
        ]),
        HarnessMessage.user('q1'),
      ];
      final r = maskStaleObservations(
        h,
        keepTurns: 0,
        minObservationTokens: 200,
      );
      expect(r.maskedCount, 1);
    });
  });

  group('serializeHarnessHistory', () {
    test('renders user turns and assistant answer + call trail', () {
      final h = [
        HarnessMessage.user('build the thing'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessTextBlock('Done.'),
            HarnessToolUseBlock(
              id: 'x',
              name: 'edit',
              input: {'path': 'a.dart'},
            ),
          ],
        ),
      ];
      final out = serializeHarnessHistory(h, selfAgentName: 'dev');
      expect(out, contains('# User (original request)'));
      expect(out, contains('build the thing'));
      expect(out, contains('# dev'));
      expect(out, contains('Done.'));
      expect(out, contains('(call: edit {"path":"a.dart"})'));
    });

    test('carries tool arguments, observations and system steering', () {
      final h = [
        HarnessMessage.user('fix the parser'),
        HarnessMessage.system('Do not touch workspace.internal'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessToolUseBlock(
              id: 'c1',
              name: 'read',
              input: {'path': 'lib/parser.dart'},
            ),
          ],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(
            toolUseId: 'c1',
            content: 'class Parser { static const magic = 42; }',
          ),
        ]),
      ];
      final out = serializeHarnessHistory(h);
      // Source path from the ARGUMENTS survives.
      expect(out, contains('lib/parser.dart'));
      // The observation body survives, labelled as an observation.
      expect(out, contains('Observation (read, ok)'));
      expect(out, contains('magic = 42'));
      // Critical steering survives verbatim.
      expect(out, contains('workspace.internal'));
    });

    test('bounds the total and names what it dropped', () {
      final h = <HarnessMessage>[
        HarnessMessage.user('the task'),
        for (var i = 0; i < 40; i++) ...[
          HarnessMessage.user('question $i ${'x' * 400}'),
          HarnessMessage.assistant('answer $i ${'y' * 400}'),
        ],
      ];
      final out = serializeHarnessHistory(
        h,
        budget: const HarnessEvidenceBudget(totalChars: 3000),
      );
      expect(out.length, lessThan(3000 + 400));
      expect(out, contains('omitted to stay within the evidence budget'));
      // The original request always survives.
      expect(out, contains('the task'));
      // And it is structurally pinned.
      expect(out, contains(evidencePinBegin));
      expect(out, contains(evidencePinEnd));
    });

    test('marks an active edit target and keeps it out of the drop', () {
      final h = <HarnessMessage>[
        for (var i = 0; i < 30; i++)
          HarnessMessage.user('older $i ${'z' * 300}'),
        HarnessMessage.user('now edit it'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessToolUseBlock(
              id: 'e1',
              name: 'edit',
              input: {'file_path': 'lib/live.dart'},
            ),
          ],
        ),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(
            toolUseId: 'e1',
            content: 'const live = true;',
          ),
        ]),
      ];
      final targets = collectActiveEditTargets(h);
      expect(targets, contains('lib/live.dart'));
      final out = serializeHarnessHistory(
        h,
        budget: const HarnessEvidenceBudget(totalChars: 2000),
        activeEditTargets: targets,
      );
      expect(out, contains('lib/live.dart'));
      expect(out, contains('[active edit]'));
      expect(out, contains('const live = true;'));
    });
  });
}

/// A summarizer that always fails, to prove the compactor stages its mutation.
class _ThrowingSummarizer implements HarnessSummarizerPort {
  @override
  Future<String> summarize(HarnessCompactionInput input) =>
      throw StateError('summarizer exploded');
}
