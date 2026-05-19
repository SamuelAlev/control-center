import 'package:cc_domain/features/pr_review/domain/services/review_guidelines.dart';
import 'package:test/test.dart';

void main() {
  const resolver = ReviewGuidelineResolver();

  group('matchesGlob', () {
    test('matches a single-segment wildcard without crossing directories', () {
      expect(matchesGlob('lib/*.dart', 'lib/main.dart'), isTrue);
      expect(matchesGlob('lib/*.dart', 'lib/src/main.dart'), isFalse);
    });

    test('** crosses directories', () {
      expect(matchesGlob('lib/**/*.dart', 'lib/src/deep/main.dart'), isTrue);
      expect(matchesGlob('lib/**', 'lib/a/b/c.dart'), isTrue);
    });

    test('**/ also matches zero directories', () {
      expect(matchesGlob('lib/**/main.dart', 'lib/main.dart'), isTrue);
      expect(matchesGlob('lib/**/main.dart', 'lib/src/main.dart'), isTrue);
    });

    test('a bare directory prefix means everything under it', () {
      expect(matchesGlob('lib/api', 'lib/api/routes.dart'), isTrue);
      expect(matchesGlob('lib/api', 'lib/apiary/x.dart'), isFalse);
      expect(matchesGlob('lib/api/', 'lib/api/deep/x.dart'), isTrue);
    });

    test('supports brace alternation', () {
      expect(matchesGlob('**/*.{ts,tsx}', 'src/app.tsx'), isTrue);
      expect(matchesGlob('**/*.{ts,tsx}', 'src/app.ts'), isTrue);
      expect(matchesGlob('**/*.{ts,tsx}', 'src/app.js'), isFalse);
    });

    test('? matches exactly one non-separator character', () {
      expect(matchesGlob('lib/a?.dart', 'lib/ab.dart'), isTrue);
      expect(matchesGlob('lib/a?.dart', 'lib/abc.dart'), isFalse);
    });

    test('treats a dot literally rather than as any-character', () {
      expect(matchesGlob('lib/*.dart', 'lib/mainXdart'), isFalse);
    });

    test('normalizes windows separators', () {
      expect(matchesGlob('lib/**', r'lib\src\main.dart'), isTrue);
    });

    test('an empty glob matches nothing', () {
      expect(matchesGlob('', 'lib/main.dart'), isFalse);
    });
  });

  group('ReviewGuidelineResolver.applicable', () {
    const global = ReviewGuideline(instruction: 'Prefer sealed classes.');
    const apiRule = ReviewGuideline(
      instruction: 'Check auth on every route.',
      pathGlob: 'lib/api/**',
    );
    const uiRule = ReviewGuideline(
      instruction: 'No Material widgets.',
      pathGlob: 'packages/cc_ui/**',
    );

    test('unscoped guidelines always apply', () {
      final result = resolver.applicable(
        all: const [global],
        changedFiles: const ['docs/readme.md'],
      );
      expect(result, hasLength(1));
    });

    test('a scoped guidelines applies when a changed file matches', () {
      final result = resolver.applicable(
        all: const [apiRule, uiRule],
        changedFiles: const ['lib/api/routes.dart'],
      );
      expect(result.map((g) => g.instruction), ['Check auth on every route.']);
    });

    test('a scoped guideline is dropped when nothing matches', () {
      final result = resolver.applicable(
        all: const [apiRule],
        changedFiles: const ['docs/readme.md'],
      );
      expect(result, isEmpty);
    });

    test('no changed files means only unscoped guidelines survive', () {
      final result = resolver.applicable(
        all: const [global, apiRule],
        changedFiles: const [],
      );
      expect(result, hasLength(1));
      expect(result.single.isScoped, isFalse);
    });
  });

  group('ReviewGuidelineResolver.render', () {
    test('renders nothing when there is nothing to say', () {
      expect(resolver.render(guidelines: const []), isEmpty);
    });

    test('states the precedence rule explicitly', () {
      final rendered = resolver.render(
        guidelines: const [
          ReviewGuideline(instruction: 'Check auth.', pathGlob: 'lib/api/**'),
        ],
      );
      expect(rendered, contains('Precedence'));
      expect(rendered, contains('review-suppressions'));
    });

    test('separates path-scoped from repository-wide rules', () {
      final rendered = resolver.render(
        guidelines: const [
          ReviewGuideline(instruction: 'Check auth.', pathGlob: 'lib/api/**'),
          ReviewGuideline(instruction: 'Prefer sealed classes.'),
        ],
      );
      expect(rendered, contains('### Path-scoped'));
      expect(rendered, contains('### Repository-wide'));
      expect(rendered, contains('`lib/api/**`'));
    });

    test('includes REVIEW.md content when present', () {
      final rendered = resolver.render(
        guidelines: const [],
        repoInstructions: 'Always verify migrations run backwards.',
      );
      expect(rendered, contains('REVIEW.md'));
      expect(rendered, contains('backwards'));
    });
  });
}
