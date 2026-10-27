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
      expect(classifier.classify('gh pr ready 12'), {ActionClass.prPublish});
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

    test('preflights pushes even when the remote bypasses URL rewriting', () {
      expect(classifier.classify('git push origin main'), {
        ActionClass.gitPush,
      });
      expect(classifier.classify('git -C /repo push --force'), {
        ActionClass.gitPush,
      });
      expect(
        classifier.classify(
          'for ref in main release; do git push '
          r'https://x-access-token:${GH_TOKEN}@github.com:443/Frontify/web-app.git '
          r'"$ref"; done',
        ),
        {ActionClass.gitPush},
      );
      expect(classifier.classify('git fetch origin main'), isEmpty);
      expect(classifier.classify('git remote -v'), isEmpty);
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
    test('preflights every effect before a compound shell begins', () {
      expect(
        classifier.classify('printf start > sentinel; git push origin main'),
        {ActionClass.gitPush},
      );
      expect(
        classifier.classify('printf start > sentinel; gh pr create --fill'),
        {ActionClass.prCreate},
      );
      expect(
        classifier.classify('printf start > sentinel; gh pr review --approve'),
        {ActionClass.prPublish},
      );
      expect(classifier.classify('printf start > sentinel; rm target'), {
        ActionClass.fileDelete,
      });
    });

    test('recognizes wrapped, nested and multiline PR effects', () {
      for (final command in [
        'GH_TOKEN=secret gh pr create --fill',
        'env GH_TOKEN=secret gh pr create --fill',
        'env -u GH_TOKEN GH_TOKEN=secret command gh pr create',
        'command -- gh pr create',
        'echo starting & gh pr create --fill',
        'gh \\\npr create --fill',
        'if true; then gh pr create --fill; fi',
        'for branch in main release; do gh pr create --fill; done',
        '(cd repo && gh pr create --fill)',
        "env GH_TOKEN=secret sh -c 'gh pr create --fill'",
      ]) {
        expect(
          classifier.classify(command),
          contains(ActionClass.prCreate),
          reason: command,
        );
      }
      for (final command in [
        'env GH_TOKEN=secret gh pr review 12 --approve',
        "command bash -c 'gh pr merge 12'",
        'if true\nthen gh pr comment 12 --body yes\nfi',
        '(cd repo; gh pr review 12 --approve)',
      ]) {
        expect(
          classifier.classify(command),
          contains(ActionClass.prPublish),
          reason: command,
        );
      }
    });

    test('recognizes destructive file commands but not dry-run reads', () {
      for (final command in [
        'rm -rf build',
        'rmdir empty',
        '/usr/bin/unlink file',
        'git rm tracked.txt',
        'git -C repo clean -fd',
        'env X=1 command rm file',
        'sh -c "rm file"',
        'git rm -- --cached',
        'git clean -f -- --dry-run',
      ]) {
        expect(
          classifier.classify(command),
          contains(ActionClass.fileDelete),
          reason: command,
        );
      }
      for (final command in [
        'git clean -nd',
        'git clean --dry-run',
        'git rm -n tracked.txt',
        'git rm --dry-run tracked.txt',
        'git rm --cached tracked.txt',
        'git --no-pager clean -nd',
        'git status',
        'gh pr view 12',
      ]) {
        expect(
          classifier.classify(command),
          isNot(contains(ActionClass.fileDelete)),
          reason: command,
        );
      }
    });

    test('recognizes conventional gh REST pull-request writes only', () {
      expect(
        classifier.classify(
          'gh api -X POST repos/acme/app/pulls -f title=Update',
        ),
        {ActionClass.prCreate},
      );
      expect(
        classifier.classify(
          'env GH_TOKEN=secret gh api repos/acme/app/pulls '
          '-f title=Update',
        ),
        {ActionClass.prCreate},
      );
      expect(
        classifier.classify(
          'gh api --method POST repos/acme/app/pulls/12/reviews '
          '-f event=APPROVE',
        ),
        {ActionClass.prPublish},
      );
      expect(
        classifier.classify('gh api -X PUT repos/acme/app/pulls/12/merge'),
        {ActionClass.prPublish},
      );
      expect(
        classifier.classify(
          r'gh api -X POST repos/acme/app/pulls/$PR/reviews/$REVIEW/events '
          '-f event=APPROVE',
        ),
        {ActionClass.prPublish},
      );
      expect(
        classifier.classify('gh api repos/acme/app/pulls/12/reviews'),
        isEmpty,
      );
      expect(
        classifier.classify('gh api -X GET repos/acme/app/pulls -f page=2'),
        isEmpty,
      );
    });

    test('quoted and printed command text is not an effect', () {
      for (final command in [
        "echo 'git push; gh pr create; rm file'",
        'printf "gh pr review --approve"',
        r'echo \; gh pr create',
        'command -v gh',
        'env GH_TOKEN=secret',
        'for word in gh pr create; do echo ok; done',
      ]) {
        expect(classifier.classify(command), isEmpty, reason: command);
      }
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

  group('ShellActionClassifier.pushRefs', () {
    test('names branches pushed to a plain remote', () {
      expect(ShellActionClassifier.pushRefs('git push origin feature/x'), [
        'feature/x',
      ]);
      expect(
        ShellActionClassifier.pushRefs(
          'cd repo && git -C . push -u --force-with-lease origin '
          'abc:refs/heads/space/f1 +b:c',
        ),
        ['space/f1', 'c'],
      );
      expect(ShellActionClassifier.pushRefs('git push origin --delete old'), [
        'old',
      ]);
      expect(ShellActionClassifier.pushRefs('git push origin :old'), ['old']);
    });

    test('anything that might land elsewhere is unknown', () {
      for (final command in [
        'git push',
        'git push origin',
        'git push origin HEAD',
        r'git push origin "$BRANCH"',
        'git push origin feature/*',
        'git push https://github.com/acme/w.git main',
        'git push ../other main',
        'git -c url.x.pushInsteadOf=y push origin main',
        'git push --all origin',
        'git push --repo=evil origin main',
        'git push origin main && git push',
      ]) {
        expect(
          ShellActionClassifier.pushRefs(command),
          isNull,
          reason: command,
        );
      }
      expect(ShellActionClassifier.pushRefs('git status'), isNull);
    });
  });
}
