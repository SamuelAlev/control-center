import 'dart:convert';

import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// Applies one programmed compaction result per call, mutating the history the
/// way the described pass would.
class _ProgrammedCompactor implements HarnessCompactor {
  _ProgrammedCompactor(this.plan);

  final List<HarnessCompactionResult> plan;
  int calls = 0;

  @override
  Future<HarnessCompactionResult> maybeCompact(
    List<HarnessMessage> history, {
    required int? contextWindow,
    int overheadTokens = 0,
    int reservedOutputTokens = 0,
    String selfAgentName = 'assistant',
    bool force = false,
  }) async {
    if (calls >= plan.length) {
      return const HarnessCompactionResult.unchanged(0);
    }
    final result = plan[calls++];
    if (result.changed && result.messagesFolded > 0) {
      history.replaceRange(
        result.foldedFromIndex,
        result.foldedFromIndex + result.messagesFolded,
        [
          // A snapshot pass replaces its span with an IMAGE-bearing page, the
          // shape the kernel identifies from the result's `foldedFromIndex`.
          // A text pass replaces it with prose.
          if (result.retainedSnapshotSource != null)
            const HarnessMessage(
              role: HarnessRole.user,
              content: [HarnessTextBlock('[page]'), _image],
            )
          else
            const HarnessMessage(
              role: HarnessRole.system,
              content: [HarnessTextBlock('[folded]')],
            ),
        ],
      );
    }
    return result;
  }

  @override
  int pruneToolResults(List<HarnessMessage> history, {bool force = false}) => 0;
}

class _ScriptedProvider implements LlmProviderPort {
  _ScriptedProvider(this.script);

  final List<List<LlmEvent>> script;
  int calls = 0;

  @override
  String get displayName => 'Scripted';

  @override
  String get defaultModel => 'mock';

  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    final index = calls < script.length ? calls : script.length - 1;
    calls++;
    yield* Stream.fromIterable(script[index]);
  }
}

class _Tool extends HarnessTool {
  _Tool(this.name);

  @override
  final String name;

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  String get description => '$name tool';

  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('ok');
}

const _image = HarnessImageBlock(data: 'QUJD', mediaType: 'image/png');

LlmToolUseDelta _call(String name, [Map<String, dynamic> args = const {}]) =>
    LlmToolUseDelta(
      id: 'tc_$name',
      name: name,
      argumentsJson: jsonEncode(args),
    );

/// Runs one turn and returns the transcript the run saved.
Future<HarnessTranscript> _runAndLoad({
  required List<HarnessMessage> history,
  required List<HarnessCompactionResult> plan,
  required InMemoryHarnessTranscriptStore store,
  List<HarnessTool> tools = const [],
  Map<String, int> checkpoints = const {},
  String? initialSnapshotSource,
  Map<String, Object?> metadata = const {},
  List<List<LlmEvent>>? script,
}) async {
  const key = 'conv-1';
  await const AgentLoopRunner()
      .run(
        history: history,
        userMessage: 'go',
        tools: tools,
        provider: _ScriptedProvider(
          script ??
              [
                [const LlmDone(stopReason: LlmStopReason.endTurn)],
              ],
        ),
        config: AgentLoopConfig(
          model: 'm',
          compactor: _ProgrammedCompactor(plan),
          contextWindow: 200000,
          transcriptStore: store,
          transcriptKey: key,
          initialCheckpoints: checkpoints,
          initialSnapshotSource: initialSnapshotSource,
          transcriptMetadata: metadata,
        ),
      )
      .toList();
  final saved = await store.load(key);
  expect(saved, isNotNull, reason: 'the run never saved a transcript');
  return saved!;
}

void main() {
  group('checkpoint remap across a fold', () {
    test('keeps head boundaries and shifts the rest around the real span', () {
      final checkpoints = {
        'before': 0,
        'atStart': 1,
        'inside': 2,
        'edge': 3,
        'after': 5,
        'far': 9,
      };
      // Fold [1, 4) into one replacement at index 1.
      remapCheckpointsAcrossFold(
        checkpoints,
        foldedFromIndex: 1,
        messagesFolded: 3,
      );
      expect(checkpoints, {
        'before': 0,
        'atStart': 2,
        'inside': 2,
        'edge': 2,
        'after': 3,
        'far': 7,
      });
    });

    test('reproduces the old rule exactly for a leading fold', () {
      // A text fold starts at 0, where the previous formula
      // (`index >= foldedCount ? index - foldedCount + 1 : 1`) must be
      // unchanged or every existing transcript rewinds differently.
      for (final foldedCount in [1, 2, 5]) {
        final old = <String, int>{};
        for (var i = 0; i <= foldedCount + 3; i++) {
          old['k$i'] = i;
        }
        final remapped = Map<String, int>.of(old);
        remapCheckpointsAcrossFold(
          remapped,
          foldedFromIndex: 0,
          messagesFolded: foldedCount,
        );
        old.updateAll(
          (_, index) => index >= foldedCount ? index - foldedCount + 1 : 1,
        );
        expect(remapped, old, reason: 'foldedCount $foldedCount');
      }
    });

    test('no-ops for a mask-only or empty pass', () {
      final checkpoints = {'a': 3};
      remapCheckpointsAcrossFold(
        checkpoints,
        foldedFromIndex: 1,
        messagesFolded: 0,
      );
      expect(checkpoints, {'a': 3});
    });
  });

  group('snapshot source persistence', () {
    test(
      'a snapshot pass persists the source, metadata and remapped labels',
      () async {
        final store = InMemoryHarnessTranscriptStore();
        final saved = await _runAndLoad(
          // Index 0 is the caller's first turn; the fold below collapses the
          // span after the verbatim head, like a page.
          history: [
            HarnessMessage.user('one'),
            HarnessMessage.assistant('two'),
            HarnessMessage.user('three'),
          ],
          plan: [
            const HarnessCompactionResult(
              changed: true,
              summarized: false,
              messagesFolded: 2,
              foldedFromIndex: 1,
              retainedSnapshotSource: 'SNAP-1',
              tokensBefore: 900,
              tokensAfter: 100,
            ),
          ],
          checkpoints: {'before': 0, 'atStart': 1, 'after': 5},
          metadata: const {
            'cc.promptCursor': {
              'revision': 'r7',
              'sectionKeys': ['a'],
            },
          },
          store: store,
        );

        expect(saved.retainedSnapshotSource, 'SNAP-1');
        expect(
          saved.messages.any((m) => m.isSnapshotCarrier),
          isTrue,
          reason:
              'the page the result named is stamped, so its identity is '
              'persisted and a restart can tell it from an ordinary image',
        );
        expect(saved.metadata, {
          'cc.promptCursor': {
            'revision': 'r7',
            'sectionKeys': ['a'],
          },
        });
        expect(
          saved.checkpoints,
          {'before': 0, 'atStart': 2, 'after': 4},
          reason:
              'the span after the head collapsed, so later boundaries moved '
              'by the real folded count',
        );
      },
    );

    test('a resumed run keeps the source and the host metadata', () async {
      final store = InMemoryHarnessTranscriptStore();
      final first = await _runAndLoad(
        history: [HarnessMessage.user('one')],
        plan: [
          const HarnessCompactionResult(
            changed: true,
            summarized: false,
            messagesFolded: 1,
            foldedFromIndex: 1,
            retainedSnapshotSource: 'SNAP-1',
            tokensBefore: 900,
            tokensAfter: 100,
          ),
        ],
        metadata: const {'cc.promptCursor': 'r7'},
        store: store,
      );
      expect(first.retainedSnapshotSource, 'SNAP-1');

      // Restart: the host seeds the loop from the loaded record, exactly as the
      // resume path does.
      final store2 = InMemoryHarnessTranscriptStore();
      final second = await _runAndLoad(
        history: [...first.messages],
        plan: const [],
        checkpoints: first.checkpoints,
        initialSnapshotSource: first.retainedSnapshotSource,
        metadata: first.metadata,
        store: store2,
      );

      expect(
        second.retainedSnapshotSource,
        'SNAP-1',
        reason:
            'an untouched pass must carry the source forward, or a later '
            'refusal folds the page by its caption and loses the region',
      );
      expect(second.metadata, {'cc.promptCursor': 'r7'});
      expect(second.checkpoints, first.checkpoints);
    });

    test('an unchanged pass keeps the source', () async {
      final saved = await _runAndLoad(
        history: [HarnessMessage.user('one')],
        plan: const [HarnessCompactionResult.unchanged(10)],
        initialSnapshotSource: 'KEEP',
        store: InMemoryHarnessTranscriptStore(),
      );
      expect(saved.retainedSnapshotSource, 'KEEP');
    });

    test(
      'a mask-only pass keeps the source while the page is still present',
      () async {
        final saved = await _runAndLoad(
          history: [
            HarnessMessage.user('one'),
            const HarnessMessage(
              role: HarnessRole.assistant,
              content: [HarnessTextBlock('page:'), _image],
              isSnapshotCarrier: true,
            ),
          ],
          plan: const [
            HarnessCompactionResult(
              changed: true,
              summarized: false,
              messagesFolded: 0,
              maskedObservations: 3,
              tokensBefore: 900,
              tokensAfter: 400,
            ),
          ],
          initialSnapshotSource: 'KEEP',
          store: InMemoryHarnessTranscriptStore(),
        );
        expect(
          saved.retainedSnapshotSource,
          'KEEP',
          reason:
              'the page is still in history after a mask, so its text is '
              'still the only way to recover what it represents',
        );
      },
    );

    test('an unrelated image must not keep a stale source alive', () async {
      // The defect this identity exists for: a screenshot is not the page, so
      // counting images would leave the source describing a region that is
      // gone — and a later refusal would rehydrate discarded material.
      final saved = await _runAndLoad(
        history: [
          HarnessMessage.user('one'),
          HarnessMessage.toolResults(const [
            HarnessToolResultBlock(
              toolUseId: 't1',
              content: 'screenshot',
              images: [_image],
            ),
          ]),
        ],
        plan: const [
          HarnessCompactionResult(
            changed: true,
            summarized: false,
            messagesFolded: 0,
            maskedObservations: 1,
            tokensBefore: 900,
            tokensAfter: 400,
          ),
        ],
        initialSnapshotSource: 'STALE',
        store: InMemoryHarnessTranscriptStore(),
      );
      expect(saved.retainedSnapshotSource, isNull);
    });

    test('a changed pass that removed the carrier clears it', () async {
      // The combined shape the snapshot compactor produces: it rehydrated a
      // refused region to text and the fallback then only masked something —
      // `messagesFolded: 0`, but no image is left to describe.
      final saved = await _runAndLoad(
        history: [HarnessMessage.user('one')],
        plan: const [
          HarnessCompactionResult(
            changed: true,
            summarized: false,
            messagesFolded: 0,
            maskedObservations: 2,
            tokensBefore: 900,
            tokensAfter: 400,
            decisionReason: 'snapshot region rehydrated to text',
          ),
        ],
        initialSnapshotSource: 'SPENT',
        store: InMemoryHarnessTranscriptStore(),
      );
      expect(saved.retainedSnapshotSource, isNull);
    });

    test('a text fold clears it', () async {
      final saved = await _runAndLoad(
        history: [HarnessMessage.user('one'), HarnessMessage.assistant('two')],
        plan: const [
          HarnessCompactionResult(
            changed: true,
            summarized: true,
            messagesFolded: 2,
            foldedFromIndex: 0,
            tokensBefore: 900,
            tokensAfter: 100,
          ),
        ],
        initialSnapshotSource: 'GONE',
        store: InMemoryHarnessTranscriptStore(),
      );
      expect(
        saved.retainedSnapshotSource,
        isNull,
        reason: 'the region the source described was replaced by a summary',
      );
      expect(
        saved.messages.any((m) => m.isSnapshotCarrier),
        isFalse,
        reason: 'a text summary is not a page and must not be stamped as one',
      );
    });

    test('a bare rehydration clears it', () async {
      // The snapshot compactor's fallback reports exactly this shape when it
      // restored a page to text and the fallback then found nothing to fold.
      final saved = await _runAndLoad(
        history: [HarnessMessage.user('one')],
        plan: const [
          HarnessCompactionResult(
            changed: true,
            summarized: false,
            messagesFolded: 0,
            tokensBefore: 900,
            tokensAfter: 500,
            decisionReason: 'snapshot region rehydrated to text',
          ),
        ],
        initialSnapshotSource: 'SPENT',
        store: InMemoryHarnessTranscriptStore(),
      );
      expect(
        saved.retainedSnapshotSource,
        isNull,
        reason: 'the image became text, so the source is no longer a page\'s',
      );
    });
  });

  group('rewind and the snapshot carrier', () {
    Future<HarnessTranscript> runRewind(
      List<HarnessMessage> history, {
      Map<String, int> checkpoints = const {},
      Map<String, dynamic> args = const {},
    }) => _runAndLoad(
      history: history,
      plan: const [],
      initialSnapshotSource: 'SNAP',
      tools: [_Tool('rewind')],
      checkpoints: checkpoints,
      script: [
        [
          _call('rewind', args),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
        [const LlmDone(stopReason: LlmStopReason.endTurn)],
      ],
      store: InMemoryHarnessTranscriptStore(),
    );

    test('clears the source when the rewind drops the page', () async {
      final saved = await runRewind([
        HarnessMessage.user('task'),
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessTextBlock('page:'), _image],
          isSnapshotCarrier: true,
        ),
        HarnessMessage.assistant('later work'),
      ]);
      expect(
        saved.retainedSnapshotSource,
        isNull,
        reason:
            'resurrecting text the rewind discarded is worse than losing '
            'recovery for a page the run chose to drop',
      );
    });

    test(
      'clears it when the page is dropped and an unrelated image stays',
      () async {
        // The parent's case, made precise by an explicit boundary: the label
        // keeps the first two messages, so the screenshot survives while the page
        // does not.
        final saved = await runRewind(
          [
            HarnessMessage.user('task'),
            HarnessMessage.toolResults(const [
              HarnessToolResultBlock(
                toolUseId: 't1',
                content: 'screenshot',
                images: [_image],
              ),
            ]),
            const HarnessMessage(
              role: HarnessRole.assistant,
              content: [HarnessTextBlock('page:'), _image],
              isSnapshotCarrier: true,
            ),
            HarnessMessage.assistant('later work'),
          ],
          checkpoints: const {'keep-image': 2},
          args: const {'checkpoint': 'keep-image'},
        );
        expect(
          saved.retainedSnapshotSource,
          isNull,
          reason:
              'an unrelated image is not the page, so its survival must not '
              'keep discarded text recoverable',
        );
      },
    );

    test('keeps it when only an unrelated image is dropped', () async {
      // The reverse hazard: the page is NOT in the dropped span, so clearing
      // here would silently lose the region the page still represents. An
      // image count cannot tell these two cases apart; the identity can.
      final saved = await runRewind([
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessTextBlock('page:'), _image],
          isSnapshotCarrier: true,
        ),
        HarnessMessage.user('task'),
        HarnessMessage.toolResults(const [
          HarnessToolResultBlock(
            toolUseId: 't1',
            content: 'screenshot',
            images: [_image],
          ),
        ]),
        HarnessMessage.assistant('later work'),
      ]);
      expect(saved.retainedSnapshotSource, 'SNAP');
    });

    test('keeps the source when the rewind leaves the page in place', () async {
      final saved = await runRewind([
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [HarnessTextBlock('page:'), _image],
          isSnapshotCarrier: true,
        ),
        HarnessMessage.user('task'),
        HarnessMessage.assistant('later work'),
      ]);
      expect(
        saved.retainedSnapshotSource,
        'SNAP',
        reason: 'the carrier survived, so its text is still recoverable',
      );
    });
  });

  group('snapshot carrier identity', () {
    test('round-trips and participates in equality', () {
      const carrier = HarnessMessage(
        role: HarnessRole.assistant,
        content: [HarnessTextBlock('page:'), _image],
        isSnapshotCarrier: true,
      );
      const plain = HarnessMessage(
        role: HarnessRole.assistant,
        content: [HarnessTextBlock('page:'), _image],
      );
      expect(carrier == plain, isFalse);
      expect(carrier.copyWith().isSnapshotCarrier, isTrue);
      expect(
        plain.copyWith(isSnapshotCarrier: true),
        carrier,
        reason: 'the marker is the identity, not the image in the content',
      );

      final restored = HarnessMessage.fromJson(
        jsonDecode(jsonEncode(carrier.toJson())) as Map<String, dynamic>,
      );
      expect(restored.isSnapshotCarrier, isTrue);
      expect(restored, carrier);
      expect(restored.toJson()['snapshot_carrier'], isTrue);
      // Absent (an older transcript, or a rehydrated text message) reads false.
      expect(plain.toJson().containsKey('snapshot_carrier'), isFalse);
      expect(
        HarnessMessage.fromJson({
          'role': 'assistant',
          'content': const [],
        }).isSnapshotCarrier,
        isFalse,
      );
    });

    test('a resumed run keeps the source for a persisted page', () async {
      final store = InMemoryHarnessTranscriptStore();
      final first = await _runAndLoad(
        history: [
          HarnessMessage.user('one'),
          const HarnessMessage(
            role: HarnessRole.assistant,
            content: [HarnessTextBlock('page:'), _image],
            isSnapshotCarrier: true,
          ),
        ],
        plan: [
          const HarnessCompactionResult(
            changed: true,
            summarized: false,
            messagesFolded: 0,
            maskedObservations: 0,
            retainedSnapshotSource: 'SNAP-2',
            tokensBefore: 900,
            tokensAfter: 100,
          ),
        ],
        store: store,
      );
      expect(first.retainedSnapshotSource, 'SNAP-2');
      expect(
        first.messages.any((m) => m.isSnapshotCarrier),
        isTrue,
        reason: 'the marker travels with the persisted transcript',
      );

      final store2 = InMemoryHarnessTranscriptStore();
      final second = await _runAndLoad(
        history: [...first.messages],
        plan: const [
          HarnessCompactionResult(
            changed: true,
            summarized: false,
            messagesFolded: 0,
            maskedObservations: 2,
            tokensBefore: 900,
            tokensAfter: 400,
          ),
        ],
        initialSnapshotSource: first.retainedSnapshotSource,
        store: store2,
      );
      expect(second.retainedSnapshotSource, 'SNAP-2');
    });

    test(
      'a rehydrated page is text, so the source does not survive it',
      () async {
        // The producer drops the marker when it restores the region to text;
        // a resumed run over such a transcript must not keep a source alive.
        final saved = await _runAndLoad(
          history: [
            HarnessMessage.user('one'),
            HarnessMessage.assistant('text'),
          ],
          plan: const [
            HarnessCompactionResult(
              changed: true,
              summarized: false,
              messagesFolded: 0,
              tokensBefore: 900,
              tokensAfter: 500,
              decisionReason: 'snapshot region rehydrated to text',
            ),
          ],
          initialSnapshotSource: 'SPENT',
          store: InMemoryHarnessTranscriptStore(),
        );
        expect(saved.retainedSnapshotSource, isNull);
      },
    );
  });
}
