import 'package:cc_domain/features/pr_review/domain/services/api_contract_differ.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:test/test.dart';

/// Exercises [OpenApiContractDiffer] — the pure OpenAPI contract differ that
/// classifies path/operation/schema changes as breaking or non-breaking.
void main() {
  const differ = OpenApiContractDiffer();

  /// Finds the first change matching [kind] (optionally at [path]/[method]).
  ApiContractChange? find(
    List<ApiContractChange> changes,
    ApiChangeKind kind, {
    String? path,
  }) {
    for (final c in changes) {
      if (c.kind == kind && (path == null || c.path == path)) {
        return c;
      }
    }
    return null;
  }

  group('OpenApiContractDiffer paths', () {
    test('a new endpoint is non-breaking', () {
      final changes = differ.diff({}, {
        'paths': {
          '/users': {
            'get': {'responses': {}},
          },
        },
      });
      final added = find(changes, ApiChangeKind.endpointAdded);
      expect(added, isNotNull);
      expect(added!.severity, ApiChangeSeverity.nonBreaking);
      expect(added.method, 'GET');
      expect(added.path, '/users');
    });

    test('a removed endpoint is breaking', () {
      final changes = differ.diff({
        'paths': {
          '/users': {
            'get': {'responses': {}},
          },
        },
      }, {});
      final removed = find(changes, ApiChangeKind.endpointRemoved);
      expect(removed, isNotNull);
      expect(removed!.severity, ApiChangeSeverity.breaking);
    });

    test('identical specs produce no changes', () {
      final spec = {
        'paths': {
          '/users': {
            'get': {
              'parameters': [],
              'responses': {'200': {}},
            },
          },
        },
      };
      expect(differ.diff(spec, spec), isEmpty);
    });
  });

  group('OpenApiContractDiffer parameters', () {
    final baseOp = {
      'paths': {
        '/x': {
          'get': {
            'responses': {'200': {}},
          },
        },
      },
    };

    test('adding a required parameter is breaking', () {
      final after = {
        'paths': {
          '/x': {
            'get': {
              'parameters': [
                {'name': 'id', 'in': 'query', 'required': true},
              ],
              'responses': {'200': {}},
            },
          },
        },
      };
      final changes = differ.diff(baseOp, after);
      final added = find(changes, ApiChangeKind.paramAdded);
      expect(added, isNotNull);
      expect(added!.severity, ApiChangeSeverity.breaking);
    });

    test('adding an optional parameter is non-breaking', () {
      final after = {
        'paths': {
          '/x': {
            'get': {
              'parameters': [
                {'name': 'filter', 'in': 'query', 'required': false},
              ],
              'responses': {'200': {}},
            },
          },
        },
      };
      final changes = differ.diff(baseOp, after);
      final added = find(changes, ApiChangeKind.paramAdded);
      expect(added!.severity, ApiChangeSeverity.nonBreaking);
    });

    test('removing a parameter is breaking', () {
      final before = {
        'paths': {
          '/x': {
            'get': {
              'parameters': [
                {'name': 'id', 'in': 'query', 'required': true},
              ],
              'responses': {'200': {}},
            },
          },
        },
      };
      final changes = differ.diff(before, baseOp);
      final removed = find(changes, ApiChangeKind.paramRemoved);
      expect(removed, isNotNull);
      expect(removed!.severity, ApiChangeSeverity.breaking);
    });

    test('optional → required is breaking', () {
      final before = {
        'paths': {
          '/x': {
            'get': {
              'parameters': [
                {'name': 'id', 'in': 'query', 'required': false},
              ],
              'responses': {'200': {}},
            },
          },
        },
      };
      final after = {
        'paths': {
          '/x': {
            'get': {
              'parameters': [
                {'name': 'id', 'in': 'query', 'required': true},
              ],
              'responses': {'200': {}},
            },
          },
        },
      };
      final changes = differ.diff(before, after);
      expect(
        changes.any(
          (c) =>
              c.kind == ApiChangeKind.paramModified &&
              c.severity == ApiChangeSeverity.breaking,
        ),
        isTrue,
      );
    });

    test('required → optional is non-breaking', () {
      final before = {
        'paths': {
          '/x': {
            'get': {
              'parameters': [
                {'name': 'id', 'in': 'query', 'required': true},
              ],
              'responses': {'200': {}},
            },
          },
        },
      };
      final after = {
        'paths': {
          '/x': {
            'get': {
              'parameters': [
                {'name': 'id', 'in': 'query', 'required': false},
              ],
              'responses': {'200': {}},
            },
          },
        },
      };
      final changes = differ.diff(before, after);
      expect(
        changes.any(
          (c) =>
              c.kind == ApiChangeKind.paramModified &&
              c.severity == ApiChangeSeverity.nonBreaking,
        ),
        isTrue,
      );
    });

    test('a parameter type change is breaking', () {
      final before = {
        'paths': {
          '/x': {
            'get': {
              'parameters': [
                {
                  'name': 'id',
                  'in': 'query',
                  'required': true,
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {'200': {}},
            },
          },
        },
      };
      final after = {
        'paths': {
          '/x': {
            'get': {
              'parameters': [
                {
                  'name': 'id',
                  'in': 'query',
                  'required': true,
                  'schema': {'type': 'integer'},
                },
              ],
              'responses': {'200': {}},
            },
          },
        },
      };
      final changes = differ.diff(before, after);
      expect(
        changes.any(
          (c) =>
              c.kind == ApiChangeKind.paramModified &&
              c.detail.contains('type changed'),
        ),
        isTrue,
      );
    });
  });

  group('OpenApiContractDiffer responses', () {
    test('a removed response status is breaking', () {
      final before = {
        'paths': {
          '/x': {
            'get': {
              'responses': {'200': {}, '404': {}},
            },
          },
        },
      };
      final after = {
        'paths': {
          '/x': {
            'get': {
              'responses': {'200': {}},
            },
          },
        },
      };
      final changes = differ.diff(before, after);
      final resp = find(changes, ApiChangeKind.responseChanged);
      expect(resp, isNotNull);
      expect(resp!.severity, ApiChangeSeverity.breaking);
    });

    test('an added response status is non-breaking', () {
      final before = {
        'paths': {
          '/x': {
            'get': {
              'responses': {'200': {}},
            },
          },
        },
      };
      final after = {
        'paths': {
          '/x': {
            'get': {
              'responses': {'200': {}, '404': {}},
            },
          },
        },
      };
      final changes = differ.diff(before, after);
      final resp = find(changes, ApiChangeKind.responseChanged);
      expect(resp!.severity, ApiChangeSeverity.nonBreaking);
    });
  });

  group('OpenApiContractDiffer schemas', () {
    test('a new schema is non-breaking', () {
      final changes = differ.diff({}, {
        'components': {
          'schemas': {
            'User': {
              'type': 'object',
              'properties': {
                'id': {'type': 'string'},
              },
            },
          },
        },
      });
      final added = find(changes, ApiChangeKind.schemaAdded);
      expect(added, isNotNull);
      expect(added!.severity, ApiChangeSeverity.nonBreaking);
    });

    test('a removed schema is breaking', () {
      final changes = differ.diff({
        'components': {
          'schemas': {
            'User': {
              'type': 'object',
              'properties': {
                'id': {'type': 'string'},
              },
            },
          },
        },
      }, {});
      final removed = find(changes, ApiChangeKind.schemaRemoved);
      expect(removed!.severity, ApiChangeSeverity.breaking);
    });

    test('adding a required property is breaking', () {
      final before = {
        'components': {
          'schemas': {
            'User': {
              'type': 'object',
              'properties': {
                'id': {'type': 'string'},
              },
              'required': ['id'],
            },
          },
        },
      };
      final after = {
        'components': {
          'schemas': {
            'User': {
              'type': 'object',
              'properties': {
                'id': {'type': 'string'},
                'email': {'type': 'string'},
              },
              'required': ['id', 'email'],
            },
          },
        },
      };
      final changes = differ.diff(before, after);
      expect(
        changes.any(
          (c) =>
              c.kind == ApiChangeKind.schemaModified &&
              c.severity == ApiChangeSeverity.breaking &&
              c.detail.contains('required'),
        ),
        isTrue,
      );
    });

    test('removing a property is breaking', () {
      final before = {
        'components': {
          'schemas': {
            'User': {
              'type': 'object',
              'properties': {
                'id': {'type': 'string'},
                'email': {'type': 'string'},
              },
            },
          },
        },
      };
      final after = {
        'components': {
          'schemas': {
            'User': {
              'type': 'object',
              'properties': {
                'id': {'type': 'string'},
              },
            },
          },
        },
      };
      final changes = differ.diff(before, after);
      expect(
        changes.any(
          (c) =>
              c.kind == ApiChangeKind.schemaModified &&
              c.severity == ApiChangeSeverity.breaking &&
              c.detail.contains('Removed property'),
        ),
        isTrue,
      );
    });
  });

  group('OpenApiContractDiffer sort order', () {
    test('breaking changes sort before non-breaking', () {
      final changes = differ.diff(
        {
          'paths': {
            '/a': {
              'get': {'responses': {}},
            },
          },
        },
        {
          'paths': {
            '/b': {
              'get': {'responses': {}},
            },
          },
        },
      );
      // /a removed (breaking) should come before /b added (non-breaking).
      expect(changes.first.kind, ApiChangeKind.endpointRemoved);
      expect(changes.last.kind, ApiChangeKind.endpointAdded);
    });
  });

  group('ApiContractChange id', () {
    test('each change has a deterministic non-empty id', () {
      final changes = differ.diff({}, {
        'paths': {
          '/x': {
            'get': {'responses': {}},
          },
        },
      });
      for (final c in changes) {
        expect(c.id, isNotEmpty);
      }
    });
  });
}
