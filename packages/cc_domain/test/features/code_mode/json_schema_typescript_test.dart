import 'package:cc_domain/features/code_mode/domain/services/json_schema_typescript.dart';
import 'package:test/test.dart';

void main() {
  const ts = JsonSchemaTypeScript();

  group('typeOf', () {
    test('primitives', () {
      expect(ts.typeOf({'type': 'string'}), 'string');
      expect(ts.typeOf({'type': 'integer'}), 'number');
      expect(ts.typeOf({'type': 'number'}), 'number');
      expect(ts.typeOf({'type': 'boolean'}), 'boolean');
      expect(ts.typeOf({'type': 'null'}), 'null');
      expect(ts.typeOf(true), 'unknown');
      expect(ts.typeOf(false), 'never');
      expect(ts.typeOf(const {}), 'unknown');
    });

    test('objects sort properties and mark optional ones', () {
      expect(
        ts.typeOf({
          'type': 'object',
          'properties': {
            'pattern': {'type': 'string'},
            'path': {'type': 'string'},
          },
          'required': ['pattern'],
        }),
        '{ path?: string; pattern: string; }',
      );
    });

    test('the same schema in any key order renders the same bytes', () {
      final a = ts.typeOf({
        'type': 'object',
        'properties': {
          'b': {'type': 'number'},
          'a': {'type': 'string'},
        },
      });
      final b = ts.typeOf({
        'properties': {
          'a': {'type': 'string'},
          'b': {'type': 'number'},
        },
        'type': 'object',
      });
      expect(a, b);
    });

    test('quotes keys that are not identifiers', () {
      expect(
        ts.typeOf({
          'type': 'object',
          'properties': {
            'my-key': {'type': 'string'},
            'ok': {'type': 'string'},
            '1st': {'type': 'string'},
          },
        }),
        '{ "1st"?: string; "my-key"?: string; ok?: string; }',
      );
    });

    test('enum and const are literal unions', () {
      expect(
        ts.typeOf({
          'enum': ['a', 'b', 1, true, null],
        }),
        '"a" | "b" | 1 | true | null',
      );
      expect(ts.typeOf({'const': 'x'}), '"x"');
      expect(ts.typeOf({'const': 'say "hi"'}), r'"say \"hi\""');
      expect(
        ts.typeOf({
          'const': {'a': 1},
        }),
        'unknown',
      );
    });

    test('oneOf and anyOf are unions, allOf is an intersection', () {
      expect(
        ts.typeOf({
          'oneOf': [
            {'type': 'string'},
            {'type': 'number'},
          ],
        }),
        'string | number',
      );
      expect(
        ts.typeOf({
          'anyOf': [
            {'type': 'string'},
            {'type': 'string'},
          ],
        }),
        'string',
      );
      expect(
        ts.typeOf({
          'allOf': [
            {
              'type': 'object',
              'properties': {
                'a': {'type': 'string'},
              },
            },
            {
              'type': 'object',
              'properties': {
                'b': {'type': 'string'},
              },
            },
          ],
        }),
        '{ a?: string; } & { b?: string; }',
      );
    });

    test('a union of variants that only pick required keys keeps the base', () {
      expect(
        ts.typeOf({
          'type': 'object',
          'properties': {
            'a': {'type': 'string'},
            'b': {'type': 'string'},
          },
          'oneOf': [
            {
              'required': ['a'],
            },
            {
              'required': ['b'],
            },
          ],
        }),
        '{ a?: string; b?: string; }',
      );
    });

    test('nullable types', () {
      expect(
        ts.typeOf({
          'type': ['string', 'null'],
        }),
        'string | null',
      );
      expect(ts.typeOf({'type': 'string', 'nullable': true}), 'string | null');
    });

    test('arrays and tuples', () {
      expect(
        ts.typeOf({
          'type': 'array',
          'items': {'type': 'string'},
        }),
        'string[]',
      );
      expect(
        ts.typeOf({
          'type': 'array',
          'items': {
            'type': ['string', 'number'],
          },
        }),
        '(string | number)[]',
      );
      expect(ts.typeOf({'type': 'array'}), 'unknown[]');
      expect(
        ts.typeOf({
          'type': 'array',
          'prefixItems': [
            {'type': 'string'},
            {'type': 'number'},
          ],
          'items': false,
        }),
        '[string, number]',
      );
      expect(
        ts.typeOf({
          'type': 'array',
          'prefixItems': [
            {'type': 'string'},
          ],
          'items': {'type': 'boolean'},
        }),
        '[string, ...boolean[]]',
      );
      expect(
        ts.typeOf({
          'type': 'array',
          'items': [
            {'type': 'string'},
            {'type': 'number'},
          ],
          'additionalItems': false,
        }),
        '[string, number]',
      );
    });

    test('additionalProperties', () {
      expect(
        ts.typeOf({
          'type': 'object',
          'additionalProperties': {'type': 'number'},
        }),
        '{ [key: string]: number; }',
      );
      expect(ts.typeOf({'type': 'object'}), '{ [key: string]: unknown; }');
      expect(
        ts.typeOf({'type': 'object', 'properties': <String, dynamic>{}}),
        '{}',
      );
      expect(
        ts.typeOf({'type': 'object', 'additionalProperties': false}),
        '{}',
      );
      expect(
        ts.typeOf({
          'type': 'object',
          'properties': {
            'a': {'type': 'string'},
          },
          'additionalProperties': {'type': 'number'},
        }),
        '{ a?: string; [key: string]: unknown; }',
      );
    });

    test('descriptions and constraints become JSDoc on properties', () {
      expect(
        ts.typeOf({
          'type': 'object',
          'properties': {
            'limit': {
              'type': 'integer',
              'description': 'How many\n  results.',
              'minimum': 1,
              'maximum': 100,
              'default': 10,
            },
            'url': {'type': 'string', 'format': 'uri', 'maxLength': 2048},
            'old': {'type': 'string', 'deprecated': true},
          },
        }),
        '{ /** How many results. @minimum 1 @maximum 100 @default 10 */ '
        'limit?: number; /** @deprecated */ old?: string; '
        '/** @format uri @maxLength 2048 */ url?: string; }',
      );
    });

    test('a hostile description cannot close the comment', () {
      final type = ts.typeOf({
        'type': 'object',
        'properties': {
          'x': {
            'type': 'string',
            'description': 'evil */ }; declare const pwned: 1; /*',
            'pattern': r'^a*/b$',
          },
        },
      });
      expect(type, isNot(contains('evil */')));
      expect(type, contains(r'evil *\/ }; declare const pwned: 1; /*'));
      expect(type, contains(r'@pattern ^a*\/b$'));
      // Exactly one comment close: the escaped ones do not count.
      expect('*/'.allMatches(type).length, 1);
    });

    test(r'local $ref resolves, a recursive one becomes unknown', () {
      final schema = {
        r'$defs': {
          'Node': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
              'children': {
                'type': 'array',
                'items': {r'$ref': r'#/$defs/Node'},
              },
            },
            'required': ['name'],
          },
        },
        'type': 'object',
        'properties': {
          'root': {r'$ref': r'#/$defs/Node'},
        },
      };
      expect(
        ts.typeOf(schema),
        '{ root?: { children?: unknown[]; name: string; }; }',
      );
      expect(
        ts.typeOf({
          'definitions': {
            'Id': {'type': 'string'},
          },
          r'$ref': '#/definitions/Id',
        }),
        'string',
      );
      expect(ts.typeOf({r'$ref': '#'}), 'unknown');
      expect(ts.typeOf({r'$ref': 'https://example.com/s.json'}), 'unknown');
      expect(ts.typeOf({r'$ref': '#/definitions/Missing'}), 'unknown');
    });

    test('malformed schemas become unknown rather than throwing', () {
      expect(ts.typeOf({'type': 'object', 'properties': 'nope'}), 'unknown');
      expect(ts.typeOf({'type': 42}), 'unknown');
      expect(ts.typeOf({'type': 'strange'}), 'unknown');
      expect(ts.typeOf({'oneOf': 'x'}), 'unknown');
      expect(ts.typeOf({'enum': <Object>[]}), 'unknown');
      expect(ts.typeOf('string'), 'unknown');
      expect(ts.typeOf(null), 'unknown');
      expect(
        ts.typeOf({
          'type': 'object',
          'properties': {
            'a': {'type': 'string'},
            'b': 'not a schema',
          },
          'required': 'a',
        }),
        '{ a?: string; b?: unknown; }',
      );
    });

    test('a type longer than 16,000 characters is truncated', () {
      final properties = {
        for (var i = 0; i < 2000; i++) 'property_number_$i': {'type': 'string'},
      };
      expect(
        ts.typeOf({'type': 'object', 'properties': properties}),
        JsonSchemaTypeScript.truncated,
      );
      const small = JsonSchemaTypeScript(maxTypeChars: 10);
      expect(
        small.typeOf({
          'type': 'object',
          'properties': {
            'abcdef': {'type': 'string'},
          },
        }),
        JsonSchemaTypeScript.truncated,
      );
    });

    test(r'non-cyclic $ref fan-out is bounded', () {
      // Each level references the next twice: 2^30 expansions unbounded.
      final defs = <String, dynamic>{};
      for (var i = 0; i < 30; i++) {
        defs['L$i'] = {
          'type': 'object',
          'properties': {
            'a': {r'$ref': '#/\$defs/L${i + 1}'},
            'b': {r'$ref': '#/\$defs/L${i + 1}'},
          },
        };
      }
      defs['L30'] = {'type': 'string'};
      final stopwatch = Stopwatch()..start();
      expect(
        ts.typeOf({r'$defs': defs, r'$ref': r'#/$defs/L0'}),
        JsonSchemaTypeScript.truncated,
      );
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    });
  });

  group('one budget for every construct', () {
    // Each construct alone fits a budget of 40 at 10 members and is
    // truncated at 100: what it does counts, not only the nodes it visits.
    const budget = JsonSchemaTypeScript(maxNodes: 40);

    Map<String, dynamic> enumOf(int n) => {
      'enum': [for (var i = 0; i < n; i++) 'v$i'],
    };
    Map<String, dynamic> anyOf(int n) => {
      'anyOf': [
        for (var i = 0; i < n; i++) {'const': i},
      ],
    };
    Map<String, dynamic> objectOf(int n) => {
      'type': 'object',
      'properties': {for (var i = 0; i < n; i++) 'p$i': true},
    };
    Map<String, dynamic> typeList(int n) => {
      'type': [for (var i = 0; i < n; i++) 'string'],
    };
    Map<String, dynamic> tuple(int n) => {
      'type': 'array',
      'prefixItems': [for (var i = 0; i < n; i++) true],
    };

    for (final (label, build) in [
      ('enum members', enumOf),
      ('anyOf arms', anyOf),
      ('properties', objectOf),
      ('type-list entries', typeList),
      ('tuple elements', tuple),
    ]) {
      test(label, () {
        expect(budget.typeOf(build(10)), isNot(JsonSchemaTypeScript.truncated));
        expect(budget.typeOf(build(100)), JsonSchemaTypeScript.truncated);
      });
    }

    test(r'$ref hops', () {
      // A chain of 20 hops (inside maxDepth), each hop counted.
      final defs = {
        for (var i = 0; i < 20; i++) 'D$i': {r'$ref': '#/\$defs/D${i + 1}'},
        'D20': {'type': 'string'},
      };
      final schema = {r'$defs': defs, r'$ref': r'#/$defs/D0'};
      expect(ts.typeOf(schema), 'string');
      expect(
        const JsonSchemaTypeScript(maxNodes: 20).typeOf(schema),
        JsonSchemaTypeScript.truncated,
      );
    });

    test(r'a $ref longer than 1,024 characters is not followed', () {
      expect(ts.typeOf({r'$ref': '#/${'a' * 2000}'}), 'unknown');
    });

    test('values shown in JSDoc count, and a description past the size '
        'bound stops the render', () {
      const docs = JsonSchemaTypeScript(maxNodes: 40);
      expect(
        docs.declaration('t', {
          'type': 'object',
          'properties': {
            'a': {
              'type': 'string',
              'default': [for (var i = 0; i < 100; i++) i],
            },
          },
        }),
        contains(JsonSchemaTypeScript.truncated),
      );
      expect(
        const JsonSchemaTypeScript(maxTypeChars: 100).declaration('t', {
          'type': 'object',
          'properties': {
            'a': {'type': 'string', 'description': 'x' * 500},
          },
        }),
        contains(JsonSchemaTypeScript.truncated),
      );
    });

    test('a 64,000-value enum is truncated at once, and stays cheap', () {
      final schema = {
        'type': 'object',
        'properties': {
          'kind': {
            'type': 'string',
            'enum': [for (var i = 0; i < 64000; i++) 'value_$i'],
          },
        },
        'required': ['kind'],
      };
      final stopwatch = Stopwatch()..start();
      expect(ts.typeOf(schema), JsonSchemaTypeScript.truncated);
      // The bound is the budget, not the clock; this only catches a render
      // that walks the members again (6 s per hit before).
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('a union of many distinct members is built in one pass', () {
      const wide = JsonSchemaTypeScript(
        maxNodes: 1 << 20,
        maxTypeChars: 1 << 22,
      );
      final stopwatch = Stopwatch()..start();
      final type = wide.typeOf(enumOf(20000));
      expect(type, startsWith('"v0" | "v1" | '));
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });
  });

  group('signature', () {
    test('falls back to the argument names when the type is truncated', () {
      const small = JsonSchemaTypeScript(maxTypeChars: 30, docs: false);
      expect(
        small.signature('f', {
          'type': 'object',
          'properties': {
            'path': {'type': 'string'},
            'limit': {
              'enum': [for (var i = 0; i < 50; i++) i],
            },
          },
          'required': ['path'],
        }),
        'f(args: { limit?, path })',
      );
    });

    test('lists no names past the cap, and cuts a long list', () {
      const small = JsonSchemaTypeScript(maxTypeChars: 30, docs: false);
      final many = {
        'type': 'object',
        'properties': {
          for (var i = 0; i <= JsonSchemaTypeScript.maxSignatureNames; i++)
            'p$i': {'type': 'string'},
        },
      };
      expect(
        small.signature('f', many),
        'f(args?: ${JsonSchemaTypeScript.truncated})',
      );
      final some = {
        'type': 'object',
        'properties': {
          for (var i = 0; i < 40; i++) 'property_$i': {'type': 'string'},
        },
      };
      expect(small.signature('f', some), endsWith(', … })'));
    });
  });

  group('declaration', () {
    test('matches the plan example shape', () {
      expect(
        ts.declaration(
          'search',
          {
            'type': 'object',
            'properties': {
              'pattern': {'type': 'string'},
              'path': {'type': 'string'},
            },
            'required': ['pattern'],
          },
          outputSchema: {
            'type': 'object',
            'properties': {
              'matches': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'properties': {
                    'path': {'type': 'string'},
                    'line': {'type': 'integer'},
                    'text': {'type': 'string'},
                  },
                  'required': ['path', 'line', 'text'],
                },
              },
            },
            'required': ['matches'],
          },
        ),
        'declare const tools: { search(args: { path?: string; pattern: '
        'string; }): Promise<{ matches: { line: number; path: string; text: '
        'string; }[]; }>; };',
      );
    });

    test(
      'args are optional when nothing is required; no output is unknown',
      () {
        expect(
          ts.declaration('list', {
            'type': 'object',
            'properties': {
              'limit': {'type': 'integer'},
            },
          }),
          'declare const tools: { list(args?: { limit?: number; }): '
          'Promise<unknown>; };',
        );
      },
    );

    test('is one line', () {
      final d = ts.declaration('x', {
        'type': 'object',
        'properties': {
          'a': {'type': 'string', 'description': 'line one\nline two'},
        },
      });
      expect(d, isNot(contains('\n')));
    });
  });
}
