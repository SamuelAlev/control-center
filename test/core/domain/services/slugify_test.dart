import 'package:control_center/core/domain/services/slugify.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('slugify', () {
    test('basic slugification', () {
      expect(slugify('Hello World'), 'hello-world');
    });

    test('handles special characters', () {
      expect(slugify('foo@bar!baz'), 'foo-bar-baz');
    });

    test('handles multiple consecutive special chars', () {
      expect(slugify('a---b___c   d'), 'a-b-c-d');
    });

    test('handles leading/trailing special chars', () {
      expect(slugify('--hello world--'), 'hello-world');
    });

    test('returns empty for all-special-char input', () {
      expect(slugify('---@@@!!!'), '');
    });

    test('handles unicode', () {
      expect(slugify('café résumé'), 'caf-r-sum');
    });

    test('handles numbers', () {
      expect(slugify('agent 42'), 'agent-42');
    });

    test('handles mixed case', () {
      expect(slugify('HelloWorld'), 'helloworld');
    });

    test('handles empty string', () {
      expect(slugify(''), '');
    });
  });
}
