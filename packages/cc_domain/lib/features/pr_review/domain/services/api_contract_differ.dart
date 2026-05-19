// Pure OpenAPI contract differ (PRD 18 §5). Diffs two PARSED OpenAPI documents
// (the server reads + parses the YAML/JSON spec files; this stays pure) into
// CC's stable `ApiContractChange` schema, each classified breaking /
// non-breaking / info. Deterministic — no tokens, no guessing. Diffing
// EXPLICIT specs only; deriving a contract from handler code is out of scope
// (PRD 18 adversarial notes) and, if ever added, is advisory-only.

import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';

/// Diffs two OpenAPI documents into classified contract changes.
class OpenApiContractDiffer {
  /// Creates an [OpenApiContractDiffer].
  const OpenApiContractDiffer();

  static const _methods = [
    'get',
    'put',
    'post',
    'delete',
    'patch',
    'options',
    'head',
  ];

  /// Computes the classified change list from [before] to [after].
  List<ApiContractChange> diff(
    Map<String, dynamic> before,
    Map<String, dynamic> after,
  ) {
    final changes = <ApiContractChange>[];
    _diffPaths(before, after, changes);
    _diffSchemas(before, after, changes);
    // Deterministic order: breaking first, then by path.
    changes.sort((a, b) {
      final bySeverity = _severityRank(
        a.severity,
      ).compareTo(_severityRank(b.severity));
      if (bySeverity != 0) {
        return bySeverity;
      }
      return '${a.path}${a.method ?? ''}'.compareTo(
        '${b.path}${b.method ?? ''}',
      );
    });
    return changes;
  }

  void _diffPaths(
    Map<String, dynamic> before,
    Map<String, dynamic> after,
    List<ApiContractChange> out,
  ) {
    final beforePaths = _asMap(before['paths']);
    final afterPaths = _asMap(after['paths']);
    final allPaths = {...beforePaths.keys, ...afterPaths.keys};
    for (final path in allPaths) {
      final beforeOps = _asMap(beforePaths[path]);
      final afterOps = _asMap(afterPaths[path]);
      for (final method in _methods) {
        final b = beforeOps[method];
        final a = afterOps[method];
        if (b == null && a == null) {
          continue;
        }
        final upperMethod = method.toUpperCase();
        if (b == null) {
          out.add(
            _change(
              ApiChangeKind.endpointAdded,
              ApiChangeSeverity.nonBreaking,
              path,
              method: upperMethod,
              detail: 'Added $upperMethod $path',
            ),
          );
          continue;
        }
        if (a == null) {
          out.add(
            _change(
              ApiChangeKind.endpointRemoved,
              ApiChangeSeverity.breaking,
              path,
              method: upperMethod,
              detail: 'Removed $upperMethod $path (breaks existing clients)',
            ),
          );
          continue;
        }
        _diffOperation(path, upperMethod, _asMap(b), _asMap(a), out);
      }
    }
  }

  void _diffOperation(
    String path,
    String method,
    Map<String, dynamic> before,
    Map<String, dynamic> after,
    List<ApiContractChange> out,
  ) {
    // Parameters — keyed by (name, in).
    final beforeParams = _paramsByKey(before['parameters']);
    final afterParams = _paramsByKey(after['parameters']);
    for (final key in {...beforeParams.keys, ...afterParams.keys}) {
      final b = beforeParams[key];
      final a = afterParams[key];
      if (b == null && a != null) {
        final required = a['required'] == true;
        out.add(
          _change(
            ApiChangeKind.paramAdded,
            required
                ? ApiChangeSeverity.breaking
                : ApiChangeSeverity.nonBreaking,
            path,
            method: method,
            detail:
                'Added ${required ? 'required' : 'optional'} '
                'parameter `${a['name']}` (${a['in']})',
          ),
        );
      } else if (a == null && b != null) {
        out.add(
          _change(
            ApiChangeKind.paramRemoved,
            ApiChangeSeverity.breaking,
            path,
            method: method,
            detail: 'Removed parameter `${b['name']}` (${b['in']})',
          ),
        );
      } else if (a != null && b != null) {
        final bReq = b['required'] == true;
        final aReq = a['required'] == true;
        final bType = _typeOf(b['schema']);
        final aType = _typeOf(a['schema']);
        if (!bReq && aReq) {
          out.add(
            _change(
              ApiChangeKind.paramModified,
              ApiChangeSeverity.breaking,
              path,
              method: method,
              detail: 'Parameter `${a['name']}` is now required',
            ),
          );
        } else if (bReq && !aReq) {
          out.add(
            _change(
              ApiChangeKind.paramModified,
              ApiChangeSeverity.nonBreaking,
              path,
              method: method,
              detail: 'Parameter `${a['name']}` is now optional',
            ),
          );
        }
        if (bType != aType) {
          out.add(
            _change(
              ApiChangeKind.paramModified,
              ApiChangeSeverity.breaking,
              path,
              method: method,
              detail:
                  'Parameter `${a['name']}` type changed '
                  '$bType → $aType',
            ),
          );
        }
      }
    }

    // Responses — status-code presence.
    final beforeResponses = _asMap(before['responses']);
    final afterResponses = _asMap(after['responses']);
    for (final status in {...beforeResponses.keys, ...afterResponses.keys}) {
      final hasBefore = beforeResponses.containsKey(status);
      final hasAfter = afterResponses.containsKey(status);
      if (hasBefore && !hasAfter) {
        out.add(
          _change(
            ApiChangeKind.responseChanged,
            ApiChangeSeverity.breaking,
            path,
            method: method,
            detail: 'Removed response `$status`',
          ),
        );
      } else if (!hasBefore && hasAfter) {
        out.add(
          _change(
            ApiChangeKind.responseChanged,
            ApiChangeSeverity.nonBreaking,
            path,
            method: method,
            detail: 'Added response `$status`',
          ),
        );
      }
    }
  }

  void _diffSchemas(
    Map<String, dynamic> before,
    Map<String, dynamic> after,
    List<ApiContractChange> out,
  ) {
    final beforeSchemas = _asMap(_asMap(before['components'])['schemas']);
    final afterSchemas = _asMap(_asMap(after['components'])['schemas']);
    for (final name in {...beforeSchemas.keys, ...afterSchemas.keys}) {
      final b = beforeSchemas[name];
      final a = afterSchemas[name];
      if (b == null && a != null) {
        out.add(
          _change(
            ApiChangeKind.schemaAdded,
            ApiChangeSeverity.nonBreaking,
            name,
            detail: 'Added schema `$name`',
          ),
        );
      } else if (a == null && b != null) {
        out.add(
          _change(
            ApiChangeKind.schemaRemoved,
            ApiChangeSeverity.breaking,
            name,
            detail: 'Removed schema `$name`',
          ),
        );
      } else if (a != null && b != null) {
        _diffSchemaProps(name, _asMap(b), _asMap(a), out);
      }
    }
  }

  void _diffSchemaProps(
    String schema,
    Map<String, dynamic> before,
    Map<String, dynamic> after,
    List<ApiContractChange> out,
  ) {
    final beforeProps = _asMap(before['properties']);
    final afterProps = _asMap(after['properties']);
    final beforeRequired = _asStringList(before['required']).toSet();
    final afterRequired = _asStringList(after['required']).toSet();
    for (final prop in {...beforeProps.keys, ...afterProps.keys}) {
      final b = beforeProps[prop];
      final a = afterProps[prop];
      if (b == null && a != null) {
        final required = afterRequired.contains(prop);
        out.add(
          _change(
            ApiChangeKind.schemaModified,
            required
                ? ApiChangeSeverity.breaking
                : ApiChangeSeverity.nonBreaking,
            schema,
            detail:
                'Added ${required ? 'required' : 'optional'} '
                'property `$prop`',
          ),
        );
      } else if (a == null && b != null) {
        out.add(
          _change(
            ApiChangeKind.schemaModified,
            ApiChangeSeverity.breaking,
            schema,
            detail: 'Removed property `$prop`',
          ),
        );
      } else if (a != null && b != null) {
        final bType = _typeOf(a);
        final aType = _typeOf(b);
        if (bType != aType) {
          out.add(
            _change(
              ApiChangeKind.schemaModified,
              ApiChangeSeverity.breaking,
              schema,
              detail: 'Property `$prop` type changed $aType → $bType',
            ),
          );
        }
        if (!beforeRequired.contains(prop) && afterRequired.contains(prop)) {
          out.add(
            _change(
              ApiChangeKind.schemaModified,
              ApiChangeSeverity.breaking,
              schema,
              detail: 'Property `$prop` is now required',
            ),
          );
        }
      }
    }
  }

  ApiContractChange _change(
    ApiChangeKind kind,
    ApiChangeSeverity severity,
    String path, {
    String? method,
    String detail = '',
  }) {
    final id = _slug('${kind.wireName}:${method ?? ''}:$path:$detail');
    return ApiContractChange(
      id: id,
      kind: kind,
      severity: severity,
      path: path,
      method: method,
      detail: detail,
    );
  }

  Map<String, dynamic> _asMap(Object? v) =>
      v is Map ? v.cast<String, dynamic>() : const {};

  List<String> _asStringList(Object? v) =>
      v is List ? v.whereType<String>().toList() : const [];

  Map<String, Map<String, dynamic>> _paramsByKey(Object? params) {
    final out = <String, Map<String, dynamic>>{};
    if (params is List) {
      for (final p in params) {
        if (p is Map) {
          final m = p.cast<String, dynamic>();
          final key = '${m['name']}|${m['in']}';
          out[key] = m;
        }
      }
    }
    return out;
  }

  String _typeOf(Object? schema) {
    if (schema is! Map) {
      return 'unknown';
    }
    final m = schema.cast<String, dynamic>();
    if (m[r'$ref'] is String) {
      return (m[r'$ref'] as String).split('/').last;
    }
    final type = m['type'];
    if (type is String) {
      if (type == 'array') {
        return 'array<${_typeOf(m['items'])}>';
      }
      return type;
    }
    return 'object';
  }

  int _severityRank(ApiChangeSeverity s) {
    switch (s) {
      case ApiChangeSeverity.breaking:
        return 0;
      case ApiChangeSeverity.nonBreaking:
        return 1;
      case ApiChangeSeverity.info:
        return 2;
    }
  }

  String _slug(String input) {
    var hash = 0x811c9dc5;
    for (final code in input.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(36);
  }
}
