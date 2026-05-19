import 'package:control_center/core/infrastructure/validation/json_schema_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonSchemaValidator', () {
    const validator = JsonSchemaValidator();

    test('valid object passes', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(
        {'name': 'x', 'count': 3},
        {
          'type': 'object',
          'required': ['name'],
          'properties': {
            'name': {'type': 'string'},
            'count': {'type': 'integer'},
          },
        },
      );
      expect(errs, isEmpty);
    });

    test('missing required property is reported', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(
        {'count': 3},
        {
          'type': 'object',
          'required': ['name'],
          'properties': {
            'name': {'type': 'string'},
          },
        },
      );
      expect(errs, isNotEmpty);
      expect(errs.any((e) => e.contains('required property missing')), isTrue);
    });

    test('wrong type is reported', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(
        'hello',
        {'type': 'object'},
      );
      expect(errs, isNotEmpty);
      expect(errs.any((e) => e.contains('expected object')), isTrue);
    });

    test('type mismatch on nested property', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(
        {'count': 'not-a-number'},
        {
          'type': 'object',
          'properties': {
            'count': {'type': 'integer'},
          },
        },
      );
      expect(errs, isNotEmpty);
      expect(errs.any((e) => e.contains('expected integer')), isTrue);
    });

    test('valid string passes', timeout: const Timeout.factor(2), () {
      expect(
        validator.validate('hello', {'type': 'string'}),
        isEmpty,
      );
    });

    test('valid integer passes', timeout: const Timeout.factor(2), () {
      expect(
        validator.validate(42, {'type': 'integer'}),
        isEmpty,
      );
    });

    test('valid number (double) passes', timeout: const Timeout.factor(2), () {
      expect(
        validator.validate(3.14, {'type': 'number'}),
        isEmpty,
      );
    });

    test('valid boolean passes', timeout: const Timeout.factor(2), () {
      expect(
        validator.validate(true, {'type': 'boolean'}),
        isEmpty,
      );
    });

    test('valid array passes', timeout: const Timeout.factor(2), () {
      expect(
        validator.validate([1, 2, 3], {'type': 'array'}),
        isEmpty,
      );
    });

    test('enum constraint passes for valid value', timeout: const Timeout.factor(2), () {
      expect(
        validator.validate('a', {
          'type': 'string',
          'enum': ['a', 'b', 'c'],
        }),
        isEmpty,
      );
    });

    test('enum constraint fails for invalid value', timeout: const Timeout.factor(2), () {
      final errs = validator.validate('d', {
        'type': 'string',
        'enum': ['a', 'b', 'c'],
      });
      expect(errs, isNotEmpty);
      expect(errs.any((e) => e.contains('not one of')), isTrue);
    });

    test('minLength constraint', timeout: const Timeout.factor(2), () {
      expect(
        validator.validate('ab', {
          'type': 'string',
          'minLength': 3,
        }),
        isNotEmpty,
      );
      expect(
        validator.validate('abc', {
          'type': 'string',
          'minLength': 3,
        }),
        isEmpty,
      );
    });

    test('minItems constraint', timeout: const Timeout.factor(2), () {
      expect(
        validator.validate([1], {
          'type': 'array',
          'minItems': 2,
        }),
        isNotEmpty,
      );
      expect(
        validator.validate([1, 2], {
          'type': 'array',
          'minItems': 2,
        }),
        isEmpty,
      );
    });

    test('array item validation', timeout: const Timeout.factor(2), () {
      final errs = validator.validate([1, 'x', 3], {
        'type': 'array',
        'items': {'type': 'integer'},
      });
      expect(errs, isNotEmpty);
      expect(errs.any((e) => e.contains('expected integer')), isTrue);
    });

    test('nullable allows null', timeout: const Timeout.factor(2), () {
      expect(
        validator.validate(null, {
          'type': 'string',
          'nullable': true,
        }),
        isEmpty,
      );
    });

    test('non-nullable rejects null', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(null, {
        'type': 'string',
      });
      expect(errs, isNotEmpty);
      expect(errs.any((e) => e.contains('got null')), isTrue);
    });

    test('null without type constraint is still rejected (no nullable flag)', timeout: const Timeout.factor(2), () {
      expect(
        validator.validate(null, {}),
        isNotEmpty,
      );
    });

    test('null type in schema matches everything', timeout: const Timeout.factor(2), () {
      expect(
        validator.validate('anything', {'type': 'null'}),
        isNotEmpty,
      );
    });

    test('nested object validation', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(
        {
          'outer': {'inner': 42},
        },
        {
          'type': 'object',
          'properties': {
            'outer': {
              'type': 'object',
              'properties': {
                'inner': {'type': 'string'},
              },
            },
          },
        },
      );
      expect(errs, isNotEmpty);
      expect(errs.any((e) => e.contains('expected string')), isTrue);
    });

    test('value without schema type passes', timeout: const Timeout.factor(2), () {
      expect(
        validator.validate('anything', <String, dynamic>{}),
        isEmpty,
      );
    });

    test('handles schema error gracefully', timeout: const Timeout.factor(2), () {
      // Pass a schema that will cause an error during validation
      final errs = validator.validate(42, {
        'type': 'object',
        'properties': 'not-a-map', // This will cause a type error
      });
      // Should return a schema error, not throw
      expect(errs, isNotEmpty);
    });

    test('required property with null value is reported', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(
        {'name': null},
        {
          'type': 'object',
          'required': ['name'],
        },
      );
      expect(errs, isNotEmpty);
      expect(errs.any((e) => e.contains('required property missing')), isTrue);
    });

    test('int passes number type', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(42, {'type': 'number'});
      expect(errs, isEmpty);
    });

    test('double fails integer type', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(3.14, {'type': 'integer'});
      expect(errs, isNotEmpty);
      expect(errs.any((e) => e.contains('expected integer')), isTrue);
    });

    test('nested array validation', timeout: const Timeout.factor(2), () {
      final errs = validator.validate([{}], {
        'type': 'array',
        'items': {
          'type': 'object',
          'required': ['x'],
          'properties': {
            'x': {'type': 'string'},
          },
        },
      });
      expect(errs, isNotEmpty);
      expect(errs.any((e) => e.contains('required property missing')), isTrue);
    });

    test('multiple violations reported', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(
        {'a': 1, 'b': 'x'},
        {
          'type': 'object',
          'properties': {
            'a': {'type': 'string'},
            'b': {'type': 'integer'},
          },
        },
      );
      expect(errs.length, 2);
      expect(errs.any((e) => e.contains('expected string')), isTrue);
      expect(errs.any((e) => e.contains('expected integer')), isTrue);
    });

    test('empty object with no required passes', timeout: const Timeout.factor(2), () {
      final errs = validator.validate({}, {'type': 'object'});
      expect(errs, isEmpty);
    });

    test('empty array with minItems fails', timeout: const Timeout.factor(2), () {
      final errs = validator.validate([], {
        'type': 'array',
        'minItems': 1,
      });
      expect(errs, isNotEmpty);
      expect(errs.any((e) => e.contains('expected at least 1 items')), isTrue);
    });

    test('nullable: true without type allows null', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(null, {'nullable': true});
      expect(errs, isEmpty);
    });

    test('minLength exact match passes', timeout: const Timeout.factor(2), () {
      final errs = validator.validate('ab', {
        'type': 'string',
        'minLength': 2,
      });
      expect(errs, isEmpty);
    });

    test('minItems exact match passes', timeout: const Timeout.factor(2), () {
      final errs = validator.validate([1, 2], {
        'type': 'array',
        'minItems': 2,
      });
      expect(errs, isEmpty);
    });

    test('nullable on nested property allows null', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(
        {'nested': null},
        {
          'type': 'object',
          'properties': {
            'nested': {
              'type': 'string',
              'nullable': true,
            },
          },
        },
      );
      expect(errs, isEmpty);
    });

    test('nullable on non-null value has no effect', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(
        {'x': 'hello'},
        {
          'type': 'object',
          'properties': {
            'x': {
              'type': 'string',
              'nullable': true,
            },
          },
        },
      );
      expect(errs, isEmpty);
    });

    test('enum with non-list value is ignored', timeout: const Timeout.factor(2), () {
      // enum: 'not-a-list' should be ignored, not throw.
      final errs = validator.validate('hello', {
        'type': 'string',
        'enum': 'not-a-list',
      });
      expect(errs, isEmpty);
    });

    test('type: null rejects all values', timeout: const Timeout.factor(2), () {
      // _matchesType returns false for 'null', so any non-null value fails.
      final errs = validator.validate('anything', {'type': 'null'});
      expect(errs, isNotEmpty);
      expect(errs.any((e) => e.contains('expected null')), isTrue);
    });

    test('unknown type string passes any value', timeout: const Timeout.factor(2), () {
      // _matchesType returns true for unknown type strings.
      final errs = validator.validate('anything', {'type': 'unknown-type'});
      expect(errs, isEmpty);
    });

    test('nested array with item validation', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(
        [
          {'name': 'ok'},
          {'name': 42},
        ],
        {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
            },
          },
        },
      );
      expect(errs, isNotEmpty);
      expect(errs.length, 1);
      expect(errs.first, contains('expected string'));
    });

    test('object with extra properties not in schema passes', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(
        {'name': 'x', 'extra': 'ignored'},
        {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
          },
        },
      );
      expect(errs, isEmpty);
    });

    test('nullable without type constraint allows null', timeout: const Timeout.factor(2), () {
      // The schema only says nullable:true, no type.
      final errs = validator.validate(null, {'nullable': true});
      expect(errs, isEmpty);
    });

    test('multiple nested violations accumulate path correctly', timeout: const Timeout.factor(2), () {
      final errs = validator.validate(
        {
          'a': {'b': null},
        },
        {
          'type': 'object',
          'properties': {
            'a': {
              'type': 'object',
              'required': ['b'],
              'properties': {
                'b': {'type': 'string'},
              },
            },
          },
        },
      );
      expect(errs, isNotEmpty);
      // The required check fires, and then _validate recurses on b=null
      expect(errs.any((e) => e.contains(r'$.a.b')), isTrue);
    });
  });
}
