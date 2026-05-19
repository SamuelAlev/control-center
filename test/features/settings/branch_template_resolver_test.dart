import 'package:control_center/features/settings/domain/services/branch_template_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BranchTemplateResolver', () {
    test('renders the default template with all placeholders', () {
      const r = BranchTemplateResolver('{type}/{ticket-key}-{slug}');
      expect(
        r.resolve(type: 'feature', ticketKey: 'PROJ-123', title: 'Add login button'),
        'feature/PROJ-123-add-login-button',
      );
    });

    test('preserves ticket-key case but slugifies the title', () {
      const r = BranchTemplateResolver('{type}/{ticket-key}-{slug}');
      expect(
        r.resolve(type: 'fix', ticketKey: 'ENG-42', title: 'Null crash on logout!'),
        'fix/ENG-42-null-crash-on-logout',
      );
    });

    test('collapses cleanly when ticket-key is empty', () {
      const r = BranchTemplateResolver('{type}/{ticket-key}-{slug}');
      // No dangling separators around the missing key.
      expect(
        r.resolve(type: 'feature', ticketKey: '', title: 'Refactor auth'),
        'feature/refactor-auth',
      );
    });

    test('empty template falls back to the default', () {
      const r = BranchTemplateResolver('');
      expect(
        r.resolve(type: 'feature', ticketKey: 'CC-9', title: 'X'),
        'feature/CC-9-x',
      );
    });

    test('flat template without a namespace', () {
      const r = BranchTemplateResolver('{ticket-key}-{slug}');
      expect(
        r.resolve(ticketKey: 'PROJ-1', title: 'Do thing'),
        'PROJ-1-do-thing',
      );
    });

    test('supports {pr}', () {
      const r = BranchTemplateResolver('review/pr-{pr}');
      expect(r.resolve(prNumber: 4321), 'review/pr-4321');
    });

    test('type defaults to "task" when blank', () {
      const r = BranchTemplateResolver('{type}/x');
      expect(r.resolve(type: ''), 'task/x');
    });

    group('sanitizeBranchName', () {
      test('strips illegal characters and collapses dashes', () {
        expect(sanitizeBranchName('feat/Hello   World!!'), 'feat/Hello-World');
      });

      test('drops empty path segments', () {
        expect(sanitizeBranchName('a//b/'), 'a/b');
      });

      test('trims leading/trailing dots and dashes per segment', () {
        expect(sanitizeBranchName('-foo-/.bar.'), 'foo/bar');
      });

      test('never returns an empty branch name', () {
        expect(sanitizeBranchName('///'), 'agent-work');
        expect(sanitizeBranchName(''), 'agent-work');
      });
    });
  });
}
