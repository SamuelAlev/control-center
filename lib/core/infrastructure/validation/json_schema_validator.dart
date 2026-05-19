import 'package:control_center/core/domain/ports/schema_validator_port.dart';

/// Pure-Dart implementation of [SchemaValidatorPort] supporting the subset of
/// JSON Schema that structured agent output contracts need: `type`, `required`,
/// `properties`, `items`, `enum`, `minLength`, `maxLength`, `minItems`,
/// `maxItems`, `pattern`, `additionalProperties`, and `nullable`.
///
/// Deliberately dependency-free (no external schema package) so it can ship
/// without a network-dependent `pub add` and keeps validation behaviour
/// inspectable in one file.
class JsonSchemaValidator implements SchemaValidatorPort {
  /// Creates a [JsonSchemaValidator].
  const JsonSchemaValidator();

  static const Set<String> _knownTypes = {
    'object',
    'array',
    'string',
    'integer',
    'number',
    'boolean',
    'null',
  };

  @override
  List<String> validate(Object? value, Map<String, dynamic> schema) {
    final violations = <String>[];
    try {
      _validate(value, schema, r'$', violations);
    } on Object catch (e) {
      return ['schema error: $e'];
    }
    return violations;
  }

  @override
  List<String> validateSchema(Map<String, dynamic> schema) {
    final problems = <String>[];
    _validateSchemaDoc(schema, r'$', problems);
    return problems;
  }

  void _validateSchemaDoc(
    Object? schema,
    String path,
    List<String> out,
  ) {
    if (schema is! Map) {
      out.add('$path: schema must be an object, got ${_jsonType(schema)}');
      return;
    }
    final type = schema['type'];
    if (type != null) {
      if (type is! String) {
        out.add('$path.type: must be a string, got ${_jsonType(type)}');
      } else if (!_knownTypes.contains(type)) {
        out.add('$path.type: unknown type "$type"');
      }
    }
    final required = schema['required'];
    if (required != null) {
      if (required is! List) {
        out.add('$path.required: must be a list of property names');
      } else {
        for (final key in required) {
          if (key is! String) {
            out.add('$path.required: every entry must be a string');
            break;
          }
        }
      }
    }
    final props = schema['properties'];
    if (props != null) {
      if (props is! Map) {
        out.add('$path.properties: must be an object');
      } else {
        for (final entry in props.entries) {
          _validateSchemaDoc(entry.value, '$path.properties.${entry.key}', out);
        }
      }
    }
    final items = schema['items'];
    if (items != null) {
      _validateSchemaDoc(items, '$path.items', out);
    }
    final enumValues = schema['enum'];
    if (enumValues != null && enumValues is! List) {
      out.add('$path.enum: must be a list');
    }
    final pattern = schema['pattern'];
    if (pattern != null) {
      if (pattern is! String) {
        out.add('$path.pattern: must be a string');
      } else {
        try {
          RegExp(pattern);
        } on FormatException catch (e) {
          out.add('$path.pattern: invalid regular expression ($e)');
        }
      }
    }
    final additional = schema['additionalProperties'];
    if (additional != null && additional is! bool && additional is! Map) {
      out.add('$path.additionalProperties: must be a boolean or schema object');
    }
  }

  void _validate(
    Object? value,
    Map<String, dynamic> schema,
    String path,
    List<String> out,
  ) {
    final nullable = schema['nullable'] == true;
    if (value == null) {
      if (!nullable && _typeOf(schema) != 'null') {
        out.add('$path: expected ${_typeOf(schema) ?? 'a value'}, got null');
      }
      return;
    }

    final type = _typeOf(schema);
    if (type != null && !_matchesType(value, type)) {
      out.add('$path: expected $type, got ${_jsonType(value)}');
      return;
    }

    final enumValues = schema['enum'];
    if (enumValues is List && !enumValues.contains(value)) {
      out.add('$path: "$value" is not one of $enumValues');
    }

    switch (type) {
      case 'object':
        final map = value as Map;
        final required = (schema['required'] as List?)?.cast<String>() ?? const [];
        for (final key in required) {
          if (!map.containsKey(key) || map[key] == null) {
            out.add('$path.$key: required property missing');
          }
        }
        final props = schema['properties'];
        if (props is Map) {
          for (final entry in props.entries) {
            final key = entry.key as String;
            if (map.containsKey(key)) {
              _validate(
                map[key],
                (entry.value as Map).cast<String, dynamic>(),
                '$path.$key',
                out,
              );
            }
          }
        }
        if (schema['additionalProperties'] == false && props is Map) {
          final allowed = props.keys.cast<String>().toSet();
          for (final key in map.keys) {
            if (!allowed.contains(key)) {
              out.add('$path.$key: additional property not allowed');
            }
          }
        }
      case 'array':
        final list = value as List;
        final minItems = (schema['minItems'] as num?)?.toInt();
        if (minItems != null && list.length < minItems) {
          out.add('$path: expected at least $minItems items, got ${list.length}');
        }
        final maxItems = (schema['maxItems'] as num?)?.toInt();
        if (maxItems != null && list.length > maxItems) {
          out.add('$path: expected at most $maxItems items, got ${list.length}');
        }
        final items = schema['items'];
        if (items is Map) {
          final itemSchema = items.cast<String, dynamic>();
          for (var i = 0; i < list.length; i++) {
            _validate(list[i], itemSchema, '$path[$i]', out);
          }
        }
      case 'string':
        final str = value as String;
        final minLength = (schema['minLength'] as num?)?.toInt();
        if (minLength != null && str.length < minLength) {
          out.add('$path: string shorter than minLength $minLength');
        }
        final maxLength = (schema['maxLength'] as num?)?.toInt();
        if (maxLength != null && str.length > maxLength) {
          out.add('$path: string longer than maxLength $maxLength');
        }
        final pattern = schema['pattern'];
        if (pattern is String && !RegExp(pattern).hasMatch(str)) {
          out.add('$path: "$str" does not match pattern /$pattern/');
        }
      default:
        break;
    }
  }

  String? _typeOf(Map<String, dynamic> schema) => schema['type'] as String?;

  bool _matchesType(Object value, String type) => switch (type) {
        'object' => value is Map,
        'array' => value is List,
        'string' => value is String,
        'integer' => value is int,
        'number' => value is num,
        'boolean' => value is bool,
        'null' => false,
        _ => true,
      };

  String _jsonType(Object? value) => switch (value) {
        null => 'null',
        Map() => 'object',
        List() => 'array',
        String() => 'string',
        int() => 'integer',
        num() => 'number',
        bool() => 'boolean',
        _ => value.runtimeType.toString(),
      };
}
