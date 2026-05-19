import 'package:cc_infra/src/util/json_schema_validator.dart';
import 'package:test/test.dart';

/// Exercises the dependency-free JSON Schema subset validator used to enforce
/// structured agent output contracts. Focuses on each keyword branch and the
/// schema-self-validation helper.
void main() {
  const v = JsonSchemaValidator();

  group('JsonSchemaValidator.validate — type matching', () {
    test('accepts a value matching the declared type', () {
      expect(v.validate(42, {'type': 'integer'}), isEmpty);
      expect(v.validate(3.14, {'type': 'number'}), isEmpty);
      expect(v.validate('hi', {'type': 'string'}), isEmpty);
      expect(v.validate(true, {'type': 'boolean'}), isEmpty);
      expect(v.validate(<Object>[], {'type': 'array'}), isEmpty);
      expect(v.validate(<Object, Object>{}, {'type': 'object'}), isEmpty);
    });

    test('reports a type mismatch with the expected/got types', () {
      final errs = v.validate('x', {'type': 'integer'});
      expect(errs, hasLength(1));
      expect(errs.single, contains('expected integer'));
      expect(errs.single, contains('got string'));
    });

    test('null is accepted only when nullable or type is null', () {
      expect(v.validate(null, {'type': 'null'}), isEmpty);
      expect(v.validate(null, {'type': 'string', 'nullable': true}), isEmpty);
      final errs = v.validate(null, {'type': 'string'});
      expect(errs, hasLength(1));
      expect(errs.single, contains('got null'));
    });

    test(
      'integer is not accepted as a number when type is strictly integer',
      () {
        // The matcher special-cases integer; a double fails integer type.
        expect(v.validate(3.14, {'type': 'integer'}), isNotEmpty);
      },
    );

    test('an unknown type falls through as matching (lenient)', () {
      expect(v.validate('x', {'type': 'whatever'}), isEmpty);
    });
  });

  group('JsonSchemaValidator.validate — enum', () {
    test('accepts a value in the enum', () {
      expect(
        v.validate('b', {
          'type': 'string',
          'enum': ['a', 'b', 'c'],
        }),
        isEmpty,
      );
    });

    test('rejects a value not in the enum', () {
      final errs = v.validate('z', {
        'type': 'string',
        'enum': ['a', 'b'],
      });
      expect(errs.single, contains('is not one of'));
      expect(errs.single, contains('z'));
    });
  });

  group('JsonSchemaValidator.validate — objects', () {
    test('reports missing required properties', () {
      final errs = v.validate(
        {'a': 1},
        {
          'type': 'object',
          'required': ['a', 'b'],
          'properties': {
            'a': {'type': 'integer'},
            'b': {'type': 'string'},
          },
        },
      );
      expect(errs, hasLength(1));
      expect(errs.single, contains('required property missing'));
    });

    test('a null required property counts as missing', () {
      final errs = v.validate(
        {'b': null},
        {
          'type': 'object',
          'required': ['b'],
          'properties': {
            'b': {'type': 'string'},
          },
        },
      );
      expect(errs, isNotEmpty);
    });

    test('additionalProperties:false rejects unknown keys', () {
      final errs = v.validate(
        {'a': 1, 'extra': 2},
        {
          'type': 'object',
          'additionalProperties': false,
          'properties': {
            'a': {'type': 'integer'},
          },
        },
      );
      expect(
        errs.any((e) => e.contains('additional property not allowed')),
        isTrue,
      );
    });

    test('recurses into present properties', () {
      final errs = v.validate(
        {'a': 'not an int'},
        {
          'type': 'object',
          'properties': {
            'a': {'type': 'integer'},
          },
        },
      );
      expect(errs.single, contains('expected integer'));
    });
  });

  group('JsonSchemaValidator.validate — arrays', () {
    test('enforces minItems / maxItems', () {
      expect(
        v.validate(<Object>[1], {'type': 'array', 'minItems': 2}),
        isNotEmpty,
      );
      expect(
        v.validate(<Object>[1, 2, 3], {'type': 'array', 'maxItems': 2}),
        isNotEmpty,
      );
    });

    test('validates each item against the items schema', () {
      final errs = v.validate(
        <Object>[1, 'x', 3],
        {
          'type': 'array',
          'items': {'type': 'integer'},
        },
      );
      expect(errs.single, contains('expected integer'));
    });
  });

  group('JsonSchemaValidator.validate — string constraints', () {
    test('enforces minLength / maxLength', () {
      expect(v.validate('ab', {'type': 'string', 'minLength': 3}), isNotEmpty);
      expect(
        v.validate('abcd', {'type': 'string', 'maxLength': 3}),
        isNotEmpty,
      );
    });

    test('enforces pattern', () {
      expect(
        v.validate('xyz', {'type': 'string', 'pattern': '^[0-9]+'}),
        isNotEmpty,
      );
      expect(
        v.validate('123', {'type': 'string', 'pattern': '^[0-9]+'}),
        isEmpty,
      );
    });
  });

  group('JsonSchemaValidator.validateSchema', () {
    test('rejects a non-object nested schema (via properties recursion)', () {
      // The public validateSchema requires a Map, but the recursive helper
      // reaches a non-object child through `properties`/`items`.
      final p = v.validateSchema({
        'properties': {'a': 'not a schema'},
      });
      expect(p.single, contains('schema must be an object'));
    });

    test('flags an unknown type', () {
      final p = v.validateSchema({'type': 'mystery'});
      expect(p.single, contains('unknown type'));
    });

    test('flags a non-string type', () {
      final p = v.validateSchema({'type': 5});
      expect(p.single, contains('must be a string'));
    });

    test('flags a non-list required', () {
      final p = v.validateSchema({'required': 'a'});
      expect(p.single, contains('must be a list'));
    });

    test('flags a non-string required entry', () {
      final p = v.validateSchema({
        'required': [1],
      });
      expect(p.single, contains('every entry must be a string'));
    });

    test('flags a non-object properties', () {
      final p = v.validateSchema({'properties': []});
      expect(p.single, contains('must be an object'));
    });

    test('recurses into properties + items', () {
      final p = v.validateSchema({
        'properties': {
          'a': {'type': 'bogus'},
        },
        'items': {'type': 'alsobogus'},
      });
      expect(p, hasLength(2));
    });

    test('flags a non-list enum', () {
      expect(
        v.validateSchema({'enum': 'x'}).single,
        contains('must be a list'),
      );
    });

    test('flags a non-string pattern', () {
      expect(
        v.validateSchema({'pattern': 5}).single,
        contains('must be a string'),
      );
    });

    test('flags an invalid regex pattern', () {
      expect(
        v.validateSchema({'pattern': '['}).single,
        contains('invalid regular expression'),
      );
    });

    test('flags a malformed additionalProperties', () {
      expect(
        v.validateSchema({'additionalProperties': 'x'}).single,
        contains('must be a boolean or schema object'),
      );
    });

    test('a well-formed schema produces no problems', () {
      expect(
        v.validateSchema({
          'type': 'object',
          'required': ['a'],
          'additionalProperties': false,
          'properties': {
            'a': {'type': 'string', 'pattern': '^[0-9]+\$'},
          },
        }),
        isEmpty,
      );
    });
  });

  test('validate catches a schema error thrown internally', () {
    // A required list that is not a List<String> triggers a cast inside the
    // object branch; the validator wraps the throw into a single violation.
    final errs = v.validate(
      {'a': 1},
      {
        'type': 'object',
        'required': [1, 2, 3], // non-string entries -> cast throws
        'properties': {
          'a': {'type': 'integer'},
        },
      },
    );
    expect(errs, hasLength(1));
    expect(errs.single, startsWith('schema error:'));
  });
}
