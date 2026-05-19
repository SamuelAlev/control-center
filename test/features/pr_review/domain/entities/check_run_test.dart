import 'package:control_center/features/pr_review/domain/entities/check_run.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 5, 18, 9, 0);

  CheckRun createCheckRun({
    String name = 'CI / build',
    CheckRunStatus status = CheckRunStatus.completed,
    CheckRunConclusion? conclusion = CheckRunConclusion.success,
    String htmlUrl = '',
    DateTime? completedAt,
    String output = '',
  }) {
    return CheckRun(
      name: name,
      status: status,
      conclusion: conclusion,
      htmlUrl: htmlUrl,
      completedAt: completedAt,
      output: output,
    );
  }

  group('CheckRun constructor', () {
    test('creates instance with all fields', () {
      final cr = CheckRun(
        name: 'CI / test',
        status: CheckRunStatus.inProgress,
        conclusion: null,
        htmlUrl: 'https://github.com/org/repo/runs/1',
        completedAt: now,
        output: 'Running tests...',
      );

      expect(cr.name, 'CI / test');
      expect(cr.status, CheckRunStatus.inProgress);
      expect(cr.conclusion, isNull);
      expect(cr.htmlUrl, 'https://github.com/org/repo/runs/1');
      expect(cr.completedAt, now);
      expect(cr.output, 'Running tests...');
    });

    test('default values for optional fields', () {
      final cr = CheckRun(
        name: 'lint',
        status: CheckRunStatus.queued,
        conclusion: null,
      );
      expect(cr.htmlUrl, '');
      expect(cr.completedAt, isNull);
      expect(cr.output, '');
    });

    test('throws assertion error for empty name', () {
      expect(
        () => CheckRun(
          name: '',
          status: CheckRunStatus.queued,
          conclusion: null,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('CheckRun computed properties', () {
    test('isComplete returns true for completed status', () {
      expect(createCheckRun(status: CheckRunStatus.completed).isComplete, isTrue);
      expect(createCheckRun(status: CheckRunStatus.queued).isComplete, isFalse);
      expect(createCheckRun(status: CheckRunStatus.inProgress).isComplete, isFalse);
    });

    test('isSuccess returns true for success conclusion', () {
      expect(
        createCheckRun(conclusion: CheckRunConclusion.success).isSuccess,
        isTrue,
      );
      expect(
        createCheckRun(conclusion: CheckRunConclusion.failure).isSuccess,
        isFalse,
      );
    });

    test('isSuccess returns false when conclusion is null', () {
      final cr = createCheckRun(conclusion: null);
      expect(cr.isSuccess, isFalse);
    });

    test('isFailing returns true for failure conclusion', () {
      expect(
        createCheckRun(conclusion: CheckRunConclusion.failure).isFailing,
        isTrue,
      );
    });

    test('isFailing returns true for timedOut conclusion', () {
      expect(
        createCheckRun(conclusion: CheckRunConclusion.timedOut).isFailing,
        isTrue,
      );
    });

    test('isFailing returns true for actionRequired conclusion', () {
      expect(
        createCheckRun(conclusion: CheckRunConclusion.actionRequired).isFailing,
        isTrue,
      );
    });

    test('isFailing returns false for success', () {
      expect(
        createCheckRun(conclusion: CheckRunConclusion.success).isFailing,
        isFalse,
      );
    });

    test('isFailing returns false for neutral', () {
      expect(
        createCheckRun(conclusion: CheckRunConclusion.neutral).isFailing,
        isFalse,
      );
    });

    test('isFailing returns false when conclusion is null', () {
      final cr = createCheckRun(conclusion: null);
      expect(cr.isFailing, isFalse);
    });
  });

  group('CheckRun == and hashCode', () {
    test('identical instances are equal', () {
      final a = createCheckRun();
      final b = createCheckRun();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different name makes unequal', () {
      final a = createCheckRun(name: 'ci');
      final b = createCheckRun(name: 'lint');
      expect(a, isNot(equals(b)));
    });

    test('same name but different status are equal (identity by name)', () {
      final a = createCheckRun(name: 'ci', status: CheckRunStatus.queued);
      final b = createCheckRun(name: 'ci', status: CheckRunStatus.completed);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('self equality', () {
      final a = createCheckRun();
      expect(a, equals(a));
    });
  });

  group('CheckRunStatus', () {
    group('name', () {
      test('queued returns queued', () {
        expect(CheckRunStatus.queued.name, 'queued');
      });
      test('inProgress returns in_progress', () {
        expect(CheckRunStatus.inProgress.name, 'in_progress');
      });
      test('completed returns completed', () {
        expect(CheckRunStatus.completed.name, 'completed');
      });
    });

    group('fromString', () {
      test('parses queued', () {
        expect(CheckRunStatusExtension.fromString('queued').name, CheckRunStatus.queued.name);
      });
      test('parses in_progress', () {
        expect(CheckRunStatusExtension.fromString('in_progress').name, CheckRunStatus.inProgress.name);
      });
      test('parses completed', () {
        expect(CheckRunStatusExtension.fromString('completed').name, CheckRunStatus.completed.name);
      });
      test('unknown defaults to queued', () {
        expect(CheckRunStatusExtension.fromString('bogus').name, CheckRunStatus.queued.name);
      });
      test('empty string defaults to queued', () {
        expect(CheckRunStatusExtension.fromString('').name, CheckRunStatus.queued.name);
      });
    });
  });

  group('CheckRunConclusion', () {
    group('name', () {
      test('success returns success', () {
        expect(CheckRunConclusion.success.name, 'success');
      });
      test('failure returns failure', () {
        expect(CheckRunConclusion.failure.name, 'failure');
      });
      test('neutral returns neutral', () {
        expect(CheckRunConclusion.neutral.name, 'neutral');
      });
      test('cancelled returns cancelled', () {
        expect(CheckRunConclusion.cancelled.name, 'cancelled');
      });
      test('skipped returns skipped', () {
        expect(CheckRunConclusion.skipped.name, 'skipped');
      });
      test('timedOut returns timed_out', () {
        expect(CheckRunConclusion.timedOut.name, 'timed_out');
      });
      test('actionRequired returns action_required', () {
        expect(CheckRunConclusion.actionRequired.name, 'action_required');
      });
      test('stale returns stale', () {
        expect(CheckRunConclusion.stale.name, 'stale');
      });
    });

    group('fromString', () {
      test('parses success', () {
        expect(CheckRunConclusionExtension.fromString('success').name, CheckRunConclusion.success.name);
      });
      test('parses failure', () {
        expect(CheckRunConclusionExtension.fromString('failure').name, CheckRunConclusion.failure.name);
      });
      test('parses neutral', () {
        expect(CheckRunConclusionExtension.fromString('neutral').name, CheckRunConclusion.neutral.name);
      });
      test('parses cancelled', () {
        expect(CheckRunConclusionExtension.fromString('cancelled').name, CheckRunConclusion.cancelled.name);
      });
      test('parses skipped', () {
        expect(CheckRunConclusionExtension.fromString('skipped').name, CheckRunConclusion.skipped.name);
      });
      test('parses timed_out', () {
        expect(CheckRunConclusionExtension.fromString('timed_out').name, CheckRunConclusion.timedOut.name);
      });
      test('parses action_required', () {
        expect(CheckRunConclusionExtension.fromString('action_required').name, CheckRunConclusion.actionRequired.name);
      });
      test('parses stale', () {
        expect(CheckRunConclusionExtension.fromString('stale').name, CheckRunConclusion.stale.name);
      });
      test('unknown defaults to neutral', () {
        expect(CheckRunConclusionExtension.fromString('bogus').name, CheckRunConclusion.neutral.name);
      });
      test('empty string defaults to neutral', () {
        expect(CheckRunConclusionExtension.fromString('').name, CheckRunConclusion.neutral.name);
      });
    });
  });

  group('CheckRun copyWith', () {
    test('copyWith overrides workflowName', () {
      final cr = CheckRun(
        name: 'CI / build',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
        workflowName: 'old',
      );
      final updated = cr.copyWith(workflowName: 'CI');
      expect(updated.workflowName, 'CI');
      expect(updated.name, cr.name);
      expect(updated.status, cr.status);
      expect(updated.conclusion, cr.conclusion);
      expect(updated.checkSuiteId, cr.checkSuiteId);
    });

    test('copyWith overrides checkSuiteId', () {
      final cr = CheckRun(
        name: 'CI / build',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
        checkSuiteId: 1,
      );
      final updated = cr.copyWith(checkSuiteId: 42);
      expect(updated.checkSuiteId, 42);
      expect(updated.name, cr.name);
      expect(updated.status, cr.status);
      expect(updated.conclusion, cr.conclusion);
      expect(updated.workflowName, cr.workflowName);
    });

    test('copyWith preserves other fields when overriding', () {
      final cr = createCheckRun(
        name: 'mycheck',
        status: CheckRunStatus.inProgress,
        conclusion: null,
      );
      final updated = cr.copyWith(workflowName: 'new');
      expect(updated.workflowName, 'new');
      expect(updated.name, 'mycheck');
      expect(updated.status, CheckRunStatus.inProgress);
      expect(updated.conclusion, isNull);
    });

    test('copyWith returns new instance with same fields when no args', () {
      final cr = createCheckRun();
      final updated = cr.copyWith();
      expect(updated, equals(cr));
      expect(identical(updated, cr), isFalse);
    });

    test('copyWith passes through null to keep existing workflowName', () {
      final cr = CheckRun(
        name: 'CI / build',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
        workflowName: 'CI',
      );
      final updated = cr.copyWith(workflowName: null);
      expect(updated.workflowName, 'CI');
    });
  });
}
