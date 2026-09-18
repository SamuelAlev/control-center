import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

void main() {
  group('withRequiredCallDescription', () {
    test('merges the property and appends to required', () {
      final schema = withRequiredCallDescription({
        'type': 'object',
        'properties': {
          'command': {'type': 'string'},
        },
        'required': ['command'],
      });

      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.keys, containsAll(['command', 'description']));
      expect(properties['description'], callDescriptionProperty);
      expect(schema['required'], ['command', 'description']);
    });

    test('handles a schema with no required list', () {
      final schema = withRequiredCallDescription({
        'type': 'object',
        'properties': {
          'code': {'type': 'string'},
        },
      });
      expect(schema['required'], ['description']);
    });

    test('leaves the input schema untouched', () {
      final original = {
        'type': 'object',
        'properties': {
          'command': {'type': 'string'},
        },
        'required': ['command'],
      };
      withRequiredCallDescription(original);
      expect(original['required'], ['command']);
      expect(
        (original['properties'] as Map).containsKey('description'),
        isFalse,
      );
    });
  });

  group('missingCallDescription', () {
    test('accepts a non-empty description', () {
      expect(
        missingCallDescription({'description': 'List the repo files'}),
        isNull,
      );
    });

    test('rejects a missing description', () {
      final result = missingCallDescription({'command': 'ls'});
      expect(result, isNotNull);
      expect(result!.isError, isTrue);
      expect(result.content, 'Missing or invalid argument: description');
    });

    test('rejects a blank description', () {
      final result = missingCallDescription({'description': '   '});
      expect(result, isNotNull);
      expect(result!.isError, isTrue);
    });

    test('rejects a non-string description', () {
      expect(missingCallDescription({'description': 42}), isNotNull);
    });
  });
}
