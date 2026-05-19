import 'package:cc_domain/features/pr_review/domain/value_objects/pr_search_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrSearchQuery.parse', () {
    test('empty input yields an inactive query', () {
      final q = PrSearchQuery.parse('   ');
      expect(q.isActive, isFalse);
      expect(q.authors, isEmpty);
      expect(q.text, isEmpty);
    });

    test('extracts an author token with @ and leaves free text', () {
      final q = PrSearchQuery.parse('author:@octocat fix login');
      expect(q.authors, {'octocat'});
      expect(q.text, 'fix login');
      expect(q.isActive, isTrue);
    });

    test('accepts author tokens without @ and lowercases the login', () {
      final q = PrSearchQuery.parse('author:OctoCat');
      expect(q.authors, {'octocat'});
      expect(q.text, isEmpty);
    });

    test('collects multiple author tokens anywhere in the string', () {
      final q = PrSearchQuery.parse('flaky author:@alice retry author:bob');
      expect(q.authors, {'alice', 'bob'});
      expect(q.text, 'flaky retry');
    });

    test('drops a dangling author token mid-typing', () {
      final q = PrSearchQuery.parse('author:@ widget');
      expect(q.authors, isEmpty);
      expect(q.text, 'widget');
    });

    test('renders backend-neutral qualifiers', () {
      final q = PrSearchQuery.parse('author:@alice some title');
      expect(q.toQualifiers(), 'author:alice some title');
    });

    test('equality is value-based so identical parses do not differ', () {
      expect(
        PrSearchQuery.parse('author:@alice  fix '),
        PrSearchQuery.parse('author:alice fix'),
      );
    });
  });
}
