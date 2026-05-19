import 'package:cc_domain/features/pipelines/domain/services/step_label.dart';
import 'package:test/test.dart';

void main() {
  group('renderStepLabel', () {
    test('resolves placeholders against run state', () {
      expect(
        renderStepLabel(
          'Code analysis · {{repo_name}}',
          state: {'repo_name': 'web-app'},
          fallback: 'space',
        ),
        'Code analysis · web-app',
      );
    });

    test('falls back to the trigger payload', () {
      expect(
        renderStepLabel(
          'Review #{{pr_number}}',
          state: const {},
          trigger: {'pr_number': 42},
          fallback: 'review',
        ),
        'Review #42',
      );
    });

    test('drops the separator a missing value leaves behind', () {
      // A scheduled run carries no PR number and a `RepoAdded` run no repo
      // name, so an unresolved placeholder renders empty. Without tidying the
      // node reads `PR digest ·`.
      expect(
        renderStepLabel(
          'PR digest · {{pr_number}}',
          state: const {},
          fallback: 'digest',
        ),
        'PR digest',
      );
    });

    test('falls back when a label is nothing but placeholders', () {
      expect(
        renderStepLabel('{{missing}}', state: const {}, fallback: 'analyze'),
        'analyze',
      );
    });

    test('leaves a plain label untouched', () {
      expect(
        renderStepLabel(
          'Index repository code',
          state: const {},
          fallback: 'index',
        ),
        'Index repository code',
      );
    });

    test('falls back on an absent or blank label', () {
      expect(renderStepLabel(null, state: const {}, fallback: 'step'), 'step');
      expect(renderStepLabel('   ', state: const {}, fallback: 'step'), 'step');
    });
  });
}
