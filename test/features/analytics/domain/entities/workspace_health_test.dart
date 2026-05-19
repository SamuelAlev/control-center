import 'package:control_center/features/analytics/domain/entities/workspace_health.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WorkspaceHealth createHealth({
    String workspaceId = 'ws-1',
    String workspaceName = 'Test Workspace',
    double score = 85.0,
    double activityScore = 90.0,
    double throughputScore = 80.0,
    double reviewHealthScore = 75.0,
    double successRateScore = 95.0,
    int activeAgents = 3,
    int totalAgents = 5,
    int prsMergedThisWeek = 10,
    int openPRs = 4,
    int stalePRs = 1,
    int totalRuns = 100,
    int erroredRuns = 5,
  }) {
    return WorkspaceHealth(
      workspaceId: workspaceId,
      workspaceName: workspaceName,
      score: score,
      activityScore: activityScore,
      throughputScore: throughputScore,
      reviewHealthScore: reviewHealthScore,
      successRateScore: successRateScore,
      activeAgents: activeAgents,
      totalAgents: totalAgents,
      prsMergedThisWeek: prsMergedThisWeek,
      openPRs: openPRs,
      stalePRs: stalePRs,
      totalRuns: totalRuns,
      erroredRuns: erroredRuns,
    );
  }

  group('WorkspaceHealth', () {
    group('constructor', () {
      test('creates health with all fields', timeout: const Timeout.factor(2), () {
        final h = createHealth();
        expect(h.workspaceId, 'ws-1');
        expect(h.workspaceName, 'Test Workspace');
        expect(h.score, 85.0);
        expect(h.activityScore, 90.0);
        expect(h.throughputScore, 80.0);
        expect(h.reviewHealthScore, 75.0);
        expect(h.successRateScore, 95.0);
        expect(h.activeAgents, 3);
        expect(h.totalAgents, 5);
        expect(h.prsMergedThisWeek, 10);
        expect(h.openPRs, 4);
        expect(h.stalePRs, 1);
        expect(h.totalRuns, 100);
        expect(h.erroredRuns, 5);
      });

      test('creates health with zero scores', timeout: const Timeout.factor(2), () {
        final h = createHealth(
          score: 0,
          activityScore: 0,
          throughputScore: 0,
          reviewHealthScore: 0,
          successRateScore: 0,
        );
        expect(h.score, 0);
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', timeout: const Timeout.factor(2), () {
        final h1 = createHealth();
        final h2 = createHealth();
        expect(h1, equals(h2));
      });

      test('== returns true for same reference', timeout: const Timeout.factor(2), () {
        final h = createHealth();
        expect(h, equals(h));
      });

      test('== returns false for different workspaceId', timeout: const Timeout.factor(2), () {
        final h1 = createHealth(workspaceId: 'ws-1');
        final h2 = createHealth(workspaceId: 'ws-2');
        expect(h1, isNot(equals(h2)));
      });

      test('== returns false for different workspaceName', timeout: const Timeout.factor(2), () {
        final h1 = createHealth(workspaceName: 'A');
        final h2 = createHealth(workspaceName: 'B');
        expect(h1, isNot(equals(h2)));
      });

      test('== returns false for different score', timeout: const Timeout.factor(2), () {
        final h1 = createHealth(score: 50.0);
        final h2 = createHealth(score: 90.0);
        expect(h1, isNot(equals(h2)));
      });

      test('== returns false for different activityScore', timeout: const Timeout.factor(2), () {
        final h1 = createHealth(activityScore: 50.0);
        final h2 = createHealth(activityScore: 90.0);
        expect(h1, isNot(equals(h2)));
      });

      test('== returns false for different totalRuns', timeout: const Timeout.factor(2), () {
        final h1 = createHealth(totalRuns: 100);
        final h2 = createHealth(totalRuns: 200);
        expect(h1, isNot(equals(h2)));
      });

      test('== returns false for different erroredRuns', timeout: const Timeout.factor(2), () {
        final h1 = createHealth(erroredRuns: 5);
        final h2 = createHealth(erroredRuns: 10);
        expect(h1, isNot(equals(h2)));
      });

      test('== returns false for different runtime type', timeout: const Timeout.factor(2), () {
        final h = createHealth();
        expect(h, isNot(equals('not health')));
      });

      test('hashCode matches for equal health', timeout: const Timeout.factor(2), () {
        final h1 = createHealth();
        final h2 = createHealth();
        expect(h1.hashCode, equals(h2.hashCode));
      });

      test('hashCode differs for different health', timeout: const Timeout.factor(2), () {
        final h1 = createHealth(workspaceId: 'ws-1');
        final h2 = createHealth(workspaceId: 'ws-2');
        expect(h1.hashCode, isNot(equals(h2.hashCode)));
      });
    });
  });
}
