import 'package:cc_domain/core/domain/entities/run_transcript.dart';
import 'package:cc_domain/core/domain/repositories/run_transcript_repository.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/run_transcript_recorder.dart';
import 'package:test/test.dart';

/// Records every write so a test can assert the persisted shape and the flush
/// count without a database.
class _SpyRepo implements RunTranscriptRepository {
  final writes =
      <
        ({
          List<Map<String, dynamic>> segments,
          int chars,
          TurnOutcome? outcome,
          bool complete,
        })
      >[];

  @override
  Future<RunTranscript?> getForRun(String workspaceId, String runId) async =>
      null;

  @override
  Future<int> deleteForRun(String workspaceId, String runId) async => 0;

  @override
  Future<void> upsert({
    required String runId,
    required String workspaceId,
    required List<Map<String, dynamic>> segmentsJson,
    required int transcriptChars,
    required DateTime startedAt,
    required DateTime updatedAt,
    TurnOutcome? outcome,
    bool complete = false,
  }) async {
    writes.add((
      segments: segmentsJson,
      chars: transcriptChars,
      outcome: outcome,
      complete: complete,
    ));
  }
}

/// A repo whose writes always blow up — a transcript write must never fail the
/// run it is describing.
class _ThrowingRepo implements RunTranscriptRepository {
  @override
  Future<RunTranscript?> getForRun(String workspaceId, String runId) async =>
      null;

  @override
  Future<int> deleteForRun(String workspaceId, String runId) async => 0;

  @override
  Future<void> upsert({
    required String runId,
    required String workspaceId,
    required List<Map<String, dynamic>> segmentsJson,
    required int transcriptChars,
    required DateTime startedAt,
    required DateTime updatedAt,
    TurnOutcome? outcome,
    bool complete = false,
  }) async => throw StateError('disk on fire');
}

final _t0 = DateTime.utc(2026, 7, 26);

void main() {
  late ActiveStreamRegistry registry;
  late _SpyRepo repo;
  late RunTranscriptRecorder recorder;

  setUp(() {
    registry = ActiveStreamRegistry();
    repo = _SpyRepo();
    recorder = RunTranscriptRecorder(registry: registry, repo: repo);
  });

  RunTranscriptRecording open([String runId = 'run-1']) =>
      recorder.begin(runId: runId, workspaceId: 'ws-1', startedAt: _t0)!;

  group('begin', () {
    test('registers the run so a subscription finds it live', () {
      open();

      expect(registry.isActive('run-1'), isTrue);
    });

    test('returns null without a workspace to scope the transcript to', () {
      final warnings = <String>[];
      final scopeless = RunTranscriptRecorder(
        registry: registry,
        repo: repo,
        onWarn: warnings.add,
      );

      expect(
        scopeless.begin(runId: 'run-1', workspaceId: '', startedAt: _t0),
        isNull,
      );
      expect(registry.isActive('run-1'), isFalse);
      expect(warnings.single, contains('no workspace'));
    });
  });

  group('folding', () {
    test('folds a tool call and its result into one closed segment', () async {
      final rec = open();

      rec
        ..add(
          ToolCallEvent(
            toolName: 'Read',
            toolCallId: 'call-1',
            inputs: const {'path': 'a.dart'},
          ),
        )
        ..add(
          ToolResultEvent(
            toolCallId: 'call-1',
            outputs: 'file body',
            toolName: 'Read',
          ),
        );

      final segments = rec.segments;
      expect(segments, hasLength(1));
      final tool = segments.single as ToolSegment;
      expect(tool.toolName, 'Read');
      expect(tool.outputs, 'file body');
      expect(tool.status, ToolSegmentStatus.ok);
    });

    test('reasoning and text become distinct segments in order', () {
      final rec = open();

      rec
        ..add(ThinkingEvent(content: 'considering'))
        ..add(TextEvent(content: 'the answer'));

      expect(rec.segments.map((s) => s.runtimeType.toString()), [
        'ReasoningSegment',
        'TextSegment',
      ]);
    });

    test('an error event becomes an ErrorSegment', () {
      final rec = open();

      rec.add(ErrorEvent(content: 'boom', source: 'harness'));

      expect((rec.segments.single as ErrorSegment).message, 'boom');
    });

    test('cost, diagnostics and completion events are not folded', () {
      final rec = open();

      rec
        ..add(DebugEvent(content: 'noise'))
        ..add(DoneEvent());

      expect(rec.segments, isEmpty);
    });

    test('broadcasts each change on the run stream', () async {
      final rec = open();
      final updates = <TranscriptUpdate>[];
      final sub = registry.updatesFor('run-1')!.listen(updates.add);

      rec.add(ToolCallEvent(toolName: 'Read', toolCallId: 'call-1'));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(updates.single, isA<SegmentOpened>());
    });
  });

  group('finish', () {
    test('writes the final row and releases the live stream', () async {
      final rec = open();
      rec.add(TextEvent(content: 'done'));

      await rec.finish(TurnOutcome.completed);

      expect(repo.writes.last.complete, isTrue);
      expect(repo.writes.last.outcome, TurnOutcome.completed);
      expect(repo.writes.last.segments, hasLength(1));
      expect(registry.isActive('run-1'), isFalse);
    });

    test('marks a still-running tool interrupted', () async {
      final rec = open();
      rec.add(ToolCallEvent(toolName: 'Bash', toolCallId: 'call-1'));

      await rec.finish(TurnOutcome.interrupted);

      final tool = rec.segments.single as ToolSegment;
      expect(tool.status, ToolSegmentStatus.interrupted);
    });

    test('reports the terminal frame before unregistering', () async {
      final rec = open();
      rec.add(TextEvent(content: 'done'));
      final updates = <TranscriptUpdate>[];
      final sub = registry.updatesFor('run-1')!.listen(updates.add);

      await rec.finish(TurnOutcome.completed);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(updates.last, isA<TurnFinished>());
      expect((updates.last as TurnFinished).outcome, TurnOutcome.completed);
    });

    test('is idempotent', () async {
      final rec = open();
      rec.add(TextEvent(content: 'done'));

      await rec.finish(TurnOutcome.completed);
      final after = repo.writes.length;
      await rec.finish(TurnOutcome.failed);

      expect(repo.writes, hasLength(after));
      expect(repo.writes.last.outcome, TurnOutcome.completed);
    });

    test('events after finish are ignored', () async {
      final rec = open();
      await rec.finish(TurnOutcome.completed);

      rec.add(TextEvent(content: 'too late'));

      expect(rec.segments, isEmpty);
    });

    test('a failing transcript write never throws into the run', () async {
      final rec = RunTranscriptRecorder(
        registry: registry,
        repo: _ThrowingRepo(),
      ).begin(runId: 'run-2', workspaceId: 'ws-1', startedAt: _t0)!;
      rec.add(TextEvent(content: 'done'));

      await expectLater(rec.finish(TurnOutcome.completed), completes);
      expect(registry.isActive('run-2'), isFalse);
    });

    test(
      'records without a repo, streaming live but persisting nothing',
      () async {
        final rec = RunTranscriptRecorder(
          registry: registry,
        ).begin(runId: 'run-3', workspaceId: 'ws-1', startedAt: _t0)!;
        rec.add(TextEvent(content: 'done'));

        await expectLater(rec.finish(TurnOutcome.completed), completes);
        expect(repo.writes, isEmpty);
      },
    );
  });
}
