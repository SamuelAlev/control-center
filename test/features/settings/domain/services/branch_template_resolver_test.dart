import 'package:control_center/features/settings/domain/services/branch_template_resolver.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // BranchTemplateResolver
  // ---------------------------------------------------------------------------

  group('BranchTemplateResolver', () {
    group('constructor', () {
      test(
        'holds the template string',
        timeout: const Timeout.factor(2),
        () {
          const resolver = BranchTemplateResolver('{type}/my-branch');
          expect(resolver.template, '{type}/my-branch');
        },
      );

      test(
        'default template applied when template is empty',
        timeout: const Timeout.factor(2),
        () {
          const resolver = BranchTemplateResolver('');
          final result = resolver.resolve(
            type: 'feature',
            ticketKey: 'abc-123',
            title: 'Add Login',
          );
          // ticketKey preserves case from input; slugify lowercases the slug
          expect(result, 'feature/abc-123-add-login');
        },
      );
    });

    group('resolve', () {
      test(
        'substitutes all placeholders: type, ticket-key, slug, pr',
        timeout: const Timeout.factor(2),
        () {
          const resolver = BranchTemplateResolver(
            '{type}/{ticket-key}-{slug}-pr-{pr}',
          );
          final result = resolver.resolve(
            type: 'fix',
            ticketKey: 'bug-456',
            title: 'Fix Crash On Startup',
            prNumber: 42,
          );
          // ticketKey preserves its case; slugify lowercases title
          expect(result, 'fix/bug-456-fix-crash-on-startup-pr-42');
        },
      );

      test(
        'empty type defaults to task',
        timeout: const Timeout.factor(2),
        () {
          const resolver = BranchTemplateResolver('{type}/work');
          final result = resolver.resolve(type: '  ');
          expect(result, 'task/work');
        },
      );

      test(
        'empty ticketKey collapses cleanly',
        timeout: const Timeout.factor(2),
        () {
          const resolver = BranchTemplateResolver(
            '{type}/{ticket-key}-{slug}',
          );
          final result = resolver.resolve(
            type: 'feature',
            ticketKey: '  ',
            title: 'Hello World',
          );
          expect(result, 'feature/hello-world');
        },
      );

      test(
        'empty title produces empty slug',
        timeout: const Timeout.factor(2),
        () {
          const resolver = BranchTemplateResolver(
            '{type}/{ticket-key}-{slug}',
          );
          final result = resolver.resolve(
            type: 'feature',
            ticketKey: 'abc-1',
            title: '  ',
          );
          // slug is empty string after sanitization, segment is dropped.
          // ticketKey preserves case from input.
          expect(result, 'feature/abc-1');
        },
      );

      test(
        'prNumber renders as number string',
        timeout: const Timeout.factor(2),
        () {
          const resolver = BranchTemplateResolver('pr-{pr}');
          final result = resolver.resolve(prNumber: 7);
          expect(result, 'pr-7');
        },
      );

      test(
        'null optional params handled',
        timeout: const Timeout.factor(2),
        () {
          const resolver = BranchTemplateResolver(
            '{type}/{ticket-key}-{slug}-{pr}',
          );
          // type defaults to 'feature', ticketKey null→'', slug empty, pr empty
          // After sanitize: 'feature/' → trailing empty segment dropped → 'feature'
          final result = resolver.resolve(); // all defaults/nulls
          expect(result, 'feature');
        },
      );

      test(
        'complex template with all placeholders',
        timeout: const Timeout.factor(2),
        () {
          const resolver = BranchTemplateResolver(
            '{type}/{ticket-key}/{pr}/{slug}-work',
          );
          final result = resolver.resolve(
            type: 'chore',
            ticketKey: 'deps-10',
            title: 'Update Dependencies',
            prNumber: 99,
          );
          // ticketKey preserves case; slugify lowercases the title
          expect(result, 'chore/deps-10/99/update-dependencies-work');
        },
      );

      test(
        'missing placeholders are sanitized (brackets become dashes)',
        timeout: const Timeout.factor(2),
        () {
          const resolver = BranchTemplateResolver('{type}/dev-{unknown}');
          final result = resolver.resolve(type: 'feature');
          // {unknown} is not recognized → stays as "{unknown}"
          // Then sanitizeBranchName replaces { and } with -
          // So "{unknown}" → "-unknown-" → stripped to "unknown"
          expect(result, 'feature/dev-unknown');
        },
      );
    });
  });

  // ---------------------------------------------------------------------------
  // sanitizeBranchName
  // ---------------------------------------------------------------------------

  group('sanitizeBranchName', () {
    test(
      'removes illegal characters, collapses multiple dashes, strips leading/trailing dots and dashes',
      timeout: const Timeout.factor(2),
      () {
        // sanitizeBranchName preserves case (A-Z kept)
        expect(sanitizeBranchName('fix/My Bug!!!'), 'fix/My-Bug');
        expect(sanitizeBranchName('  hello---world  '), 'hello-world');
        expect(sanitizeBranchName('---leading-dash'), 'leading-dash');
        expect(sanitizeBranchName('trailing-dash---'), 'trailing-dash');
        expect(sanitizeBranchName('...dots...'), 'dots');
        expect(sanitizeBranchName('-.-mixed.-'), 'mixed');
      },
    );

    test(
      'preserves slashes as segment separators',
      timeout: const Timeout.factor(2),
      () {
        expect(
          sanitizeBranchName('type/feature/branch-name'),
          'type/feature/branch-name',
        );
        expect(
          sanitizeBranchName('a/b/c'),
          'a/b/c',
        );
      },
    );

    test(
      'drops empty segments',
      timeout: const Timeout.factor(2),
      () {
        // Segment becomes empty after stripping illegal chars.
        expect(sanitizeBranchName('type///feature'), 'type/feature');
        expect(sanitizeBranchName('/leading-segment'), 'leading-segment');
        expect(sanitizeBranchName('trailing-segment/'), 'trailing-segment');
        expect(sanitizeBranchName(r'a/!@#$/c'), 'a/c');
      },
    );

    test(
      'returns agent-work for empty result',
      timeout: const Timeout.factor(2),
      () {
        expect(sanitizeBranchName(''), 'agent-work');
        expect(sanitizeBranchName('!!!'), 'agent-work');
        expect(sanitizeBranchName('---...'), 'agent-work');
      },
    );
  });
}
