import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/services/run_liveness_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunLivenessClassifier', () {
    const classifier = RunLivenessClassifier();

    AgentRunLog makeRun({
      RunStatus status = RunStatus.running,
      String? summary,
      RunErrorFamily? errorFamily,
      DateTime? lastOutputAt,
    }) {
      return AgentRunLog(
        id: 'run-1',
        agentId: 'agent-1',
        startedAt: DateTime(2026, 1, 1),
        status: status,
        summary: summary,
        errorFamily: errorFamily,
        lastOutputAt: lastOutputAt,
      );
    }

    test('running with recent output → alive', () {
      final run = makeRun(
        status: RunStatus.running,
        lastOutputAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(classifier.classify(run), RunLiveness.alive);
    });

    test('running with no output → alive', () {
      final run = makeRun(status: RunStatus.running);
      expect(classifier.classify(run), RunLiveness.alive);
    });

    test('running with old output (>1h) → stalled', () {
      final run = makeRun(
        status: RunStatus.running,
        lastOutputAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(classifier.classify(run), RunLiveness.stalled);
    });

    test('completed with summary → productive', () {
      final run = makeRun(
        status: RunStatus.completed,
        summary: 'All tasks finished successfully.',
      );
      expect(classifier.classify(run), RunLiveness.productive);
    });

    test('completed with no summary → empty', () {
      final run = makeRun(status: RunStatus.completed);
      expect(classifier.classify(run), RunLiveness.empty);
    });

    test('completed with blocked indicators → blocked', () {
      final run = makeRun(
        status: RunStatus.completed,
        summary: 'Waiting for upstream dependency.',
      );
      expect(classifier.classify(run), RunLiveness.blocked);
    });

    test('error with processLost → dead', () {
      final run = makeRun(
        status: RunStatus.error,
        errorFamily: RunErrorFamily.processLost,
      );
      expect(classifier.classify(run), RunLiveness.dead);
    });

    test('error with blocked indicators → blocked', () {
      final run = makeRun(
        status: RunStatus.error,
        errorFamily: RunErrorFamily.silentRun,
      );
      expect(classifier.classify(run), RunLiveness.blocked);
    });

    test('error without blocked → failed', () {
      final run = makeRun(
        status: RunStatus.error,
        errorFamily: RunErrorFamily.unknown,
      );
      expect(classifier.classify(run), RunLiveness.failed);
    });

    test('pending → empty', () {
      final run = makeRun(status: RunStatus.pending);
      expect(classifier.classify(run), RunLiveness.empty);
    });

    test('uses lastOutputAt parameter when provided', () {
      final run = makeRun(status: RunStatus.running);
      // run.lastOutputAt is null, but we provide explicit lastOutputAt
      expect(
        classifier.classify(
          run,
          lastOutputAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        RunLiveness.stalled,
      );
    });
  });
}
