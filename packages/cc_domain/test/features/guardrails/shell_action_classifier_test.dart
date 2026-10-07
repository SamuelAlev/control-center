import 'package:cc_domain/features/guardrails/domain/services/shell_action_classifier.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:test/test.dart';

void main() {
  const classifier = ShellActionClassifier();

  group('ShellActionClassifier', () {
    test('names the pull-request rows', () {
      expect(classifier.classify('gh pr create --fill'), {
        ActionClass.prCreate,
      });
      expect(classifier.classify('gh pr merge 12 --squash'), {
        ActionClass.prPublish,
      });
      expect(classifier.classify('gh pr review 12 --approve'), {
        ActionClass.prPublish,
      });
      expect(classifier.classify('gh pr comment 12 --body hi'), {
        ActionClass.prPublish,
      });
    });

    test('reading a pull request is not an effect', () {
      expect(classifier.classify('gh pr view 12'), isEmpty);
      expect(classifier.classify('gh pr list'), isEmpty);
    });

    test('names commits, including through global flags', () {
      expect(classifier.classify('git commit -m x'), {ActionClass.gitCommit});
      expect(classifier.classify('git -C /repo commit -m x'), {
        ActionClass.gitCommit,
      });
      expect(classifier.classify('/usr/bin/git rebase main'), {
        ActionClass.gitCommit,
      });
    });

    test('leaves git push to the gateway', () {
      // Classifying it here too would ask the operator twice for one push.
      expect(classifier.classify('git push origin main'), isEmpty);
      expect(classifier.classify('git push --force'), isEmpty);
    });

    test('a git subcommand that only starts like one is not it', () {
      expect(classifier.classify('git commit-graph write'), isEmpty);
      expect(classifier.classify('git status'), isEmpty);
    });

    test('every part of a compound command contributes', () {
      expect(
        classifier.classify('git add -A && git commit -m x && gh pr create'),
        {ActionClass.gitCommit, ActionClass.prCreate},
      );
      expect(classifier.classify('cd repo; npm install left-pad | tee log'), {
        ActionClass.packageInstall,
      });
    });

    test('looks inside a nested shell', () {
      expect(classifier.classify("bash -c 'gh pr merge 3'"), {
        ActionClass.prPublish,
      });
    });

    test('names tracker writes, installs and raw network fetches', () {
      expect(classifier.classify('gh issue create -t bug'), {
        ActionClass.vendorSyncWrite,
      });
      expect(classifier.classify('pip install requests'), {
        ActionClass.packageInstall,
      });
      expect(classifier.classify('curl -fsSL https://example.com'), {
        ActionClass.networkEgress,
      });
    });

    test('an ordinary command is not classified', () {
      expect(classifier.classify('ls -la'), isEmpty);
      expect(classifier.classify(''), isEmpty);
    });
  });
}
