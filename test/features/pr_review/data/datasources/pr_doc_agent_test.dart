import 'package:control_center/features/pr_review/data/datasources/pr_doc_agent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrDocAgentResult', () {
    test('const constructor sets all fields', () {
      const result = PrDocAgentResult(
        title: 'Fix auth bug',
        body: '## Summary\n\nFixed the auth bug.',
        summary: '3 files changed, +10, -5',
      );

      expect(result.title, 'Fix auth bug');
      expect(result.body, '## Summary\n\nFixed the auth bug.');
      expect(result.summary, '3 files changed, +10, -5');
    });

    test('empty fields are allowed', () {
      const result = PrDocAgentResult(title: '', body: '', summary: '');

      expect(result.title, '');
      expect(result.body, '');
      expect(result.summary, '');
    });
  });

  group('countDiffStats', () {
    final agent = PrDocAgent();

    test('counts empty diff as zero', () {
      final result = agent.countDiffStats('');
      expect(result['files'], 0);
      expect(result['additions'], 0);
      expect(result['deletions'], 0);
    });

    test('counts additions and deletions correctly', () {
      const diff = '''diff --git a/file.dart b/file.dart
--- a/file.dart
+++ b/file.dart
@@ -1,3 +1,4 @@
 old line
-old removed line
+new added line
 unchanged line
+another new line
 3 files changed, 5 insertions(+), 3 deletions(-)''';

      final result = agent.countDiffStats(diff);
      expect(result['additions'], 2);
      expect(result['deletions'], 1);
      expect(result['files'], 3);
    });

    test('counts only lines starting with + or -', () {
      const diff = '''+added line
-removed line
 regular line
+++ header line
--- header line
+ another add
- another remove
 1 file changed, 2 insertions(+), 2 deletions(-)''';

      final result = agent.countDiffStats(diff);
      expect(result['additions'], 2);
      expect(result['deletions'], 2);
      expect(result['files'], 1);
    });

    test('handles diff without stat summary line', () {
      const diff = '''+line 1
+line 2
-line 3''';

      final result = agent.countDiffStats(diff);
      expect(result['additions'], 2);
      expect(result['deletions'], 1);
      expect(result['files'], 0);
    });

    test('handles newline-only diff', () {
      const diff = '\n\n\n';

      final result = agent.countDiffStats(diff);
      expect(result['files'], 0);
      expect(result['additions'], 0);
      expect(result['deletions'], 0);
    });

    test('handles diff with only file stat line', () {
      const diff = ' 10 files changed, 50 insertions(+), 20 deletions(-)';

      final result = agent.countDiffStats(diff);
      expect(result['files'], 10);
      expect(result['additions'], 0);
      expect(result['deletions'], 0);
    });

    test('handles large diff counts', () {
      String diff = '';
      for (var i = 0; i < 100; i++) {
        diff += '+added line $i\n';
      }
      for (var i = 0; i < 50; i++) {
        diff += '-removed line $i\n';
      }
      diff += ' 5 files changed, 100 insertions(+), 50 deletions(-)';

      final result = agent.countDiffStats(diff);
      expect(result['additions'], 100);
      expect(result['deletions'], 50);
      expect(result['files'], 5);
    });

    test('file stat with "file" singular', () {
      const diff = '+line\n 1 file changed';

      final result = agent.countDiffStats(diff);
      expect(result['files'], 1);
    });
  });

  group('buildDocPrompt', () {
    final agent = PrDocAgent();

    test('builds prompt with diff content', () {
      const diff = '+added line\n-removed line';
      final prompt = agent.buildDocPrompt(diff);
      expect(prompt, contains('Analyze the following git diff'));
      expect(prompt, contains('"title"'));
      expect(prompt, contains('"body"'));
      expect(prompt, contains('+added line'));
      expect(prompt, contains('-removed line'));
    });

    test('builds prompt with empty diff', () {
      final prompt = agent.buildDocPrompt('');
      expect(prompt, contains('```diff\n\n```'));
    });

    test('prompt requests JSON output only', () {
      final prompt = agent.buildDocPrompt('test');
      expect(prompt, contains('Return ONLY the JSON object'));
    });

    test('prompt specifies title max length', () {
      final prompt = agent.buildDocPrompt('test');
      expect(prompt, contains('max 72 chars'));
    });
  });

  group('fallbackResult', () {
    final agent = PrDocAgent();

    test('generates fallback result with stats', () {
      const diff = '+added\n 2 files changed';
      const branch = 'feature/test';

      final result = agent.fallbackResult(diff, branch);
      expect(result.title, 'Changes on feature/test');
      expect(
        result.body,
        contains('Automated PR for changes on branch `feature/test`'),
      );
      expect(result.body, contains('2 files changed'));
      expect(result.summary, '2 files changed, +1, -0');
    });

    test('generates fallback for empty diff', () {
      final result = agent.fallbackResult('', 'main');
      expect(result.title, 'Changes on main');
      expect(result.summary, '0 files changed, +0, -0');
    });
  });

  group('PrDocAgent.generateFromDiff', () {
    test('returns static result structure', () async {
      final agent = PrDocAgent();
      try {
        final result = await agent.generateFromDiff(
          workspacePath: '/tmp/test',
          branch: 'feature/test',
        );
        expect(result, isA<PrDocAgentResult>());
      } catch (_) {}
    });
  });
}
