import 'package:control_center/features/agents/data/services/run_liveness_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunLivenessClass', () {
    test('tryParse matches labels case-insensitively', () {
      expect(RunLivenessClass.tryParse('productive'), RunLivenessClass.productive);
      expect(RunLivenessClass.tryParse('PRODUCTIVE'), RunLivenessClass.productive);
      expect(RunLivenessClass.tryParse('completed'), RunLivenessClass.completed);
      expect(RunLivenessClass.tryParse('blocked'), RunLivenessClass.blocked);
      expect(RunLivenessClass.tryParse('empty'), RunLivenessClass.empty);
      expect(RunLivenessClass.tryParse('looping'), RunLivenessClass.looping);
      expect(RunLivenessClass.tryParse('failed'), RunLivenessClass.failed);
    });

    test('tryParse returns empty for null', () {
      expect(RunLivenessClass.tryParse(null), RunLivenessClass.empty);
    });

    test('tryParse returns empty for unknown value', () {
      expect(RunLivenessClass.tryParse('unknown'), RunLivenessClass.empty);
    });

    test('label returns human-readable form', () {
      expect(RunLivenessClass.productive.label, 'productive');
      expect(RunLivenessClass.failed.label, 'failed');
    });
  });

  group('RunLivenessEvidence', () {
    test('defaults all fields to zero', () {
      const e = RunLivenessEvidence();
      expect(e.filesChanged, 0);
      expect(e.commitsMade, 0);
      expect(e.commentsCreated, 0);
      expect(e.toolCallsExecuted, 0);
      expect(e.uniqueCommands, 0);
      expect(e.totalCommands, 0);
      expect(e.exitCode, 0);
      expect(e.thinkingBlocks, 0);
      expect(e.errorMessages, 0);
    });

    test('can set specific fields', () {
      const e = RunLivenessEvidence(
        filesChanged: 3,
        commitsMade: 1,
        exitCode: 1,
      );
      expect(e.filesChanged, 3);
      expect(e.commitsMade, 1);
      expect(e.exitCode, 1);
      expect(e.toolCallsExecuted, 0);
    });
  });

  group('RunLivenessClassifier.classify', () {
    test('non-zero exit code with error messages → failed', () {
      const e = RunLivenessEvidence(exitCode: 1, errorMessages: 3);
      expect(RunLivenessClassifier.classify(e), RunLivenessClass.failed);
    });

    test('non-zero exit code without error messages → failed', () {
      const e = RunLivenessEvidence(exitCode: 1, errorMessages: 0);
      expect(RunLivenessClassifier.classify(e), RunLivenessClass.failed);
    });

    test('looping: many total commands, few unique, no files or commits', () {
      const e = RunLivenessEvidence(
        totalCommands: 5,
        uniqueCommands: 2,
        filesChanged: 0,
        commitsMade: 0,
      );
      expect(RunLivenessClassifier.classify(e), RunLivenessClass.looping);
    });

    test('looping: exactly at threshold', () {
      const e = RunLivenessEvidence(
        totalCommands: 3,
        uniqueCommands: 1,
        filesChanged: 0,
        commitsMade: 0,
      );
      expect(RunLivenessClassifier.classify(e), RunLivenessClass.looping);
    });

    test('looping: uniqueCommands == 0 still loops', () {
      const e = RunLivenessEvidence(
        totalCommands: 4,
        uniqueCommands: 0,
        filesChanged: 0,
        commitsMade: 0,
      );
      expect(RunLivenessClassifier.classify(e), RunLivenessClass.looping);
    });

    test('not looping when unique commands > 2', () {
      const e = RunLivenessEvidence(
        totalCommands: 5,
        uniqueCommands: 3,
        filesChanged: 0,
        commitsMade: 0,
      );
      final result = RunLivenessClassifier.classify(e);
      expect(result, isNot(RunLivenessClass.looping));
    });

    test('not looping when files changed', () {
      const e = RunLivenessEvidence(
        totalCommands: 5,
        uniqueCommands: 1,
        filesChanged: 1,
        commitsMade: 0,
      );
      final result = RunLivenessClassifier.classify(e);
      expect(result, isNot(RunLivenessClass.looping));
    });

    test('not looping when commits made', () {
      const e = RunLivenessEvidence(
        totalCommands: 5,
        uniqueCommands: 1,
        filesChanged: 0,
        commitsMade: 1,
      );
      final result = RunLivenessClassifier.classify(e);
      expect(result, isNot(RunLivenessClass.looping));
    });

    test('completed: commits + files changed', () {
      const e = RunLivenessEvidence(filesChanged: 2, commitsMade: 1);
      expect(RunLivenessClassifier.classify(e), RunLivenessClass.completed);
    });

    test('productive: files changed but no commits', () {
      const e = RunLivenessEvidence(filesChanged: 3, commitsMade: 0);
      expect(RunLivenessClassifier.classify(e), RunLivenessClass.productive);
    });

    test('productive: comments created', () {
      const e = RunLivenessEvidence(commentsCreated: 2, filesChanged: 0, commitsMade: 0);
      expect(RunLivenessClassifier.classify(e), RunLivenessClass.productive);
    });

    test('productive: tool calls executed', () {
      const e = RunLivenessEvidence(toolCallsExecuted: 5, filesChanged: 0, commitsMade: 0);
      expect(RunLivenessClassifier.classify(e), RunLivenessClass.productive);
    });

    test('empty: thinking blocks with no commands', () {
      const e = RunLivenessEvidence(thinkingBlocks: 3, totalCommands: 0);
      expect(RunLivenessClassifier.classify(e), RunLivenessClass.empty);
    });

    test('empty: no output at all', () {
      const e = RunLivenessEvidence();
      expect(RunLivenessClassifier.classify(e), RunLivenessClass.empty);
    });
  });

  group('RunLivenessClassifier.description', () {
    test('each class has a non-empty description', () {
      for (final cls in RunLivenessClass.values) {
        final desc = RunLivenessClassifier.description(cls);
        expect(desc, isNotEmpty);
      }
    });

    test('description includes key terms', () {
      expect(
        RunLivenessClassifier.description(RunLivenessClass.failed),
        contains('failed'),
      );
      expect(
        RunLivenessClassifier.description(RunLivenessClass.completed),
        contains('completed'),
      );
      expect(
        RunLivenessClassifier.description(RunLivenessClass.looping),
        contains('repeating'),
      );
    });
  });
}
