import 'package:control_center/features/pipelines/domain/ports/schema_validator_port.dart';

/// Pure-Dart implementation of [SchemaValidatorPort] supporting the subset of
/// JSON Schema that pipeline node output contracts need: `type`, `required`,
/// `properties`, `items`, `enum`, `minLength`, `minItems`, and `nullable`.
///
/// Deliberately dependency-free (no external schema package) so it can ship
/// without a network-dependent `pub add` and keeps validation behaviour
/// inspectable in one file.
class JsonSchemaValidator implements SchemaValidatorPort {
  /// Creates a [JsonSchemaValidator].
  const JsonSchemaValidator();

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
      case 'array':
        final list = value as List;
        final minItems = (schema['minItems'] as num?)?.toInt();
        if (minItems != null && list.length < minItems) {
          out.add('$path: expected at least $minItems items, got ${list.length}');
        }
        final items = schema['items'];
        if (items is Map) {
          final itemSchema = items.cast<String, dynamic>();
          for (var i = 0; i < list.length; i++) {
            _validate(list[i], itemSchema, '$path[$i]', out);
          }
        }
      case 'string':
        final minLength = (schema['minLength'] as num?)?.toInt();
        if (minLength != null && (value as String).length < minLength) {
          out.add('$path: string shorter than minLength $minLength');
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

  String _jsonType(Object value) => switch (value) {
        Map() => 'object',
        List() => 'array',
        String() => 'string',
        int() => 'integer',
        num() => 'number',
        bool() => 'boolean',
        _ => value.runtimeType.toString(),
      };
}
