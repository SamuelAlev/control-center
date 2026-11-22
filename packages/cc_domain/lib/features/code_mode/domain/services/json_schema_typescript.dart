import 'dart:convert';

/// Renders JSON Schemas as TypeScript types, and tools as one-line
/// TypeScript declarations, for a code mode script's documentation.
///
/// The output is documentation the model reads, not code a compiler checks:
/// scripts are plain JavaScript. What matters is that it is short, accurate
/// enough to call the tool right the first time, and deterministic. The same
/// schema always renders to the same bytes (properties sorted by name), because
/// declarations sit in the cached prompt prefix.
///
/// Never throws. A schema that is malformed or recursive past what can be
/// shown becomes `unknown`, which is honest and still callable: the model can
/// ask `describeTool` for the raw schema.
///
/// A schema is input from an untrusted server, so every render has one work
/// budget, [maxNodes], that everything it does counts against: each schema
/// node, `$ref` hop, enum member, union or intersection arm, property, tuple
/// element, value shown in JSDoc, and every 64 characters it scans again. The
/// output stops at [maxTypeChars] while it is built, not after. A render
/// that reaches either stops at once and gives [truncated].
///
/// Supported: `type` (single or list), `properties` and `required`,
/// `additionalProperties`, `items` / `prefixItems` (arrays and tuples),
/// `enum`, `const`, `oneOf` / `anyOf` (unions), `allOf` (intersections), local
/// `$ref` into `#/definitions/…` or `#/$defs/…` (cycles become `unknown`),
/// OpenAPI's `nullable`, and property `description` plus constraints as
/// JSDoc on the property.
class JsonSchemaTypeScript {
  /// Creates a renderer.
  const JsonSchemaTypeScript({
    this.maxTypeChars = 16000,
    this.maxDepth = 24,
    this.maxNodes = 20000,
    this.docs = true,
  });

  /// The longest type this renders; anything longer is [truncated].
  final int maxTypeChars;

  /// The deepest nesting this follows; deeper parts are `unknown`.
  final int maxDepth;

  /// The work budget of one render, in units: one per schema node, `$ref`
  /// hop, enum member, union or intersection arm, property, tuple element and
  /// JSDoc value node, and one per 64 characters scanned again. It bounds
  /// what a render costs whatever the schema (a 64k-value enum, a non-cyclic
  /// `$ref` fan-out that would expand exponentially); past it the type is
  /// [truncated].
  final int maxNodes;

  /// Whether property descriptions and constraints are rendered as JSDoc.
  /// Off for a compact signature ([signature]).
  final bool docs;

  /// The JSDoc tags rendered from property constraints, in output order.
  static const List<String> constraintTags = [
    'format',
    'minimum',
    'exclusiveMinimum',
    'maximum',
    'exclusiveMaximum',
    'multipleOf',
    'minLength',
    'maxLength',
    'pattern',
    'minItems',
    'maxItems',
    'uniqueItems',
    'minProperties',
    'maxProperties',
    'default',
  ];

  /// What a type too large or too costly to render becomes: `unknown`,
  /// marked so the model knows the schema was cut, not absent.
  static const String truncated = 'unknown /* too large to show */';

  /// The TypeScript type for [schema], [truncated] when it is over the
  /// budget ([maxNodes], [maxTypeChars]).
  ///
  /// [schema] is also the root that local `$ref`s resolve against.
  String typeOf(Object? schema) {
    try {
      return _Renderer(this, schema).render(schema, 0);
    } on _Overflow {
      return truncated;
    } on Object {
      return 'unknown';
    }
  }

  /// The one-line declaration of a tool a script calls as
  /// `tools.<identifier>(args)`:
  ///
  /// ```ts
  /// declare const tools: { search(args: { pattern: string; path?: string; }): Promise<unknown>; };
  /// ```
  ///
  /// `args` is optional when the input schema requires nothing. The result
  /// type is `unknown` when the tool declares no [outputSchema].
  String declaration(
    String identifier,
    Map<String, dynamic> inputSchema, {
    Map<String, dynamic>? outputSchema,
  }) {
    final args = typeOf(inputSchema);
    final required = inputSchema['required'];
    final optional = required is! List || required.isEmpty;
    final result = outputSchema == null ? 'unknown' : typeOf(outputSchema);
    return 'declare const tools: { $identifier(args${optional ? '?' : ''}: '
        '$args): Promise<$result>; };';
  }

  /// A compact one-line call signature for a search hit:
  /// `identifier(args: { path: string; limit?: number; })`, without JSDoc.
  ///
  /// When the argument type renders longer than [maxTypeChars] (construct
  /// this renderer with a small one), it falls back to the top-level argument
  /// names, a `?` after each optional one: `identifier(args: { path, limit? })`;
  /// past [maxTypeChars] of names, `…` ends the list. A tool with more than
  /// [maxSignatureNames] arguments lists none of them.
  String signature(String identifier, Map<String, dynamic> inputSchema) {
    final required = inputSchema['required'];
    final requiredNames = <String>{
      if (required is List)
        for (final r in required.take(maxSignatureNames))
          if (r is String) r,
    };
    final optional = requiredNames.isEmpty ? '?' : '';
    var args = typeOf(inputSchema);
    if (args == 'unknown' || args == truncated) {
      final properties = inputSchema['properties'];
      if (properties is Map &&
          properties.isNotEmpty &&
          properties.length <= maxSignatureNames) {
        final keys = [for (final k in properties.keys) '$k']..sort();
        final shown = <String>[];
        var chars = 0;
        for (final k in keys) {
          final name = requiredNames.contains(k) ? k : '$k?';
          chars += name.length + 2;
          if (chars > maxTypeChars) {
            shown.add('…');
            break;
          }
          shown.add(name);
        }
        args = '{ ${shown.join(', ')} }';
      }
    }
    return '$identifier(args$optional: $args)';
  }

  /// The most top-level arguments a [signature] falls back to listing.
  static const int maxSignatureNames = 256;

  /// [text] as the inside of a one-line `/** … */` comment: whitespace runs
  /// collapsed to one space and every `*/` escaped as `*\/`, so no
  /// description can close the comment and inject declarations.
  static String commentText(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim().replaceAll('*/', r'*\/');
}

/// Thrown inside a render when the output passes the size or node budget.
class _Overflow implements Exception {
  const _Overflow();
}

class _Renderer {
  _Renderer(this.options, this.root);

  final JsonSchemaTypeScript options;
  final Object? root;
  final List<String> _refStack = [];
  int _nodes = 0;

  static final RegExp _identifier = RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$');

  static const String _openObject = '{ [key: string]: unknown; }';

  String render(Object? node, int depth) {
    _spend(1);
    final type = _render(node, depth);
    _fits(type.length);
    return type;
  }

  /// Counts [units] of work against the budget.
  void _spend(int units) {
    _nodes += units;
    if (_nodes > options.maxNodes) {
      throw const _Overflow();
    }
  }

  /// Stops when a type of [chars] characters would be too long.
  void _fits(int chars) {
    if (chars > options.maxTypeChars) {
      throw const _Overflow();
    }
  }

  /// Counts a scan of [text] against the budget: one unit per 64 characters.
  void _scan(String text) => _spend(1 + text.length ~/ 64);

  String _render(Object? node, int depth) {
    if (node == true) {
      return 'unknown';
    }
    if (node == false) {
      return 'never';
    }
    if (node is! Map || depth > options.maxDepth) {
      return 'unknown';
    }
    final ref = node[r'$ref'];
    if (ref != null) {
      return _renderRef(ref, depth);
    }

    var base = _baseType(node, depth);
    final implicit = base == null;
    final members = <String>[];

    final alternatives = node['oneOf'] ?? node['anyOf'];
    if (alternatives != null) {
      if (alternatives is! List) {
        return 'unknown';
      }
      _spend(alternatives.length);
      final rendered = [
        for (final alt in alternatives)
          if (_hasStructure(alt)) render(alt, depth + 1),
      ];
      if (rendered.isNotEmpty) {
        members.add(_union(rendered));
      }
    }
    final all = node['allOf'];
    if (all != null) {
      if (all is! List) {
        return 'unknown';
      }
      _spend(all.length);
      for (final part in all) {
        if (_hasStructure(part)) {
          members.add(render(part, depth + 1));
        }
      }
    }

    String type;
    if (members.isEmpty) {
      type = base ?? 'unknown';
    } else {
      // `type: object` with no properties says nothing the alternatives do
      // not, and intersecting with an open record only adds noise.
      if (implicit || base == _openObject) {
        base = null;
      }
      type = _intersection([?base, ...members]);
    }
    if (node['nullable'] == true && type != 'unknown') {
      type = _union([type, 'null']);
    }
    return type;
  }

  /// The type from `const`, `enum`, `type` or the structural keywords, or
  /// null when the node says nothing about its shape.
  String? _baseType(Map<dynamic, dynamic> node, int depth) {
    if (node.containsKey('const')) {
      return _literal(node['const']);
    }
    final values = node['enum'];
    if (values != null) {
      if (values is! List || values.isEmpty) {
        return 'unknown';
      }
      _spend(values.length);
      // Lazily: the union stops at the size bound before rendering the rest.
      return _union(values.map(_literal));
    }
    final type = node['type'];
    if (type is String) {
      return _single(type, node, depth);
    }
    if (type is List) {
      if (type.isEmpty) {
        return 'unknown';
      }
      _spend(type.length);
      return _union([
        for (final t in type) t is String ? _single(t, node, depth) : 'unknown',
      ]);
    }
    if (type != null) {
      return 'unknown';
    }
    if (node.containsKey('properties') ||
        node.containsKey('additionalProperties') ||
        node.containsKey('required')) {
      return _object(node, depth);
    }
    if (node.containsKey('items') || node.containsKey('prefixItems')) {
      return _array(node, depth);
    }
    return null;
  }

  String _single(String type, Map<dynamic, dynamic> node, int depth) =>
      switch (type) {
        'string' => 'string',
        'number' || 'integer' => 'number',
        'boolean' => 'boolean',
        'null' => 'null',
        'array' => _array(node, depth),
        'object' => _object(node, depth),
        _ => 'unknown',
      };

  String _renderRef(Object? ref, int depth) {
    if (ref is! String || !ref.startsWith('#') || ref.length > _maxRefChars) {
      return 'unknown';
    }
    _scan(ref);
    if (_refStack.contains(ref)) {
      return 'unknown';
    }
    final target = _resolvePointer(ref.substring(1));
    if (target == null) {
      return 'unknown';
    }
    _refStack.add(ref);
    try {
      return render(target, depth + 1);
    } finally {
      _refStack.removeLast();
    }
  }

  /// The longest `$ref` this follows.
  static const int _maxRefChars = 1024;

  /// Resolves a JSON pointer (`/definitions/Foo`) against [root].
  Object? _resolvePointer(String pointer) {
    if (pointer.isEmpty) {
      return root;
    }
    if (!pointer.startsWith('/')) {
      return null;
    }
    Object? current = root;
    for (final raw in pointer.substring(1).split('/')) {
      final key = Uri.decodeComponent(
        raw,
      ).replaceAll('~1', '/').replaceAll('~0', '~');
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else if (current is List) {
        final index = int.tryParse(key);
        if (index == null || index < 0 || index >= current.length) {
          return null;
        }
        current = current[index];
      } else {
        return null;
      }
    }
    return current;
  }

  String _array(Map<dynamic, dynamic> node, int depth) {
    final prefix =
        node['prefixItems'] ?? (node['items'] is List ? node['items'] : null);
    if (prefix != null) {
      if (prefix is! List) {
        return 'unknown';
      }
      _spend(prefix.length);
      final elements = [for (final p in prefix) render(p, depth + 1)];
      final rest = node['prefixItems'] != null
          ? node['items']
          : node['additionalItems'];
      final maxItems = node['maxItems'];
      final closed =
          rest == false || (maxItems is int && maxItems <= elements.length);
      if (!closed) {
        final restType = rest is Map ? render(rest, depth + 1) : 'unknown';
        elements.add('...${_arrayOf(restType)}');
      }
      _fits(elements.fold(0, (n, e) => n + e.length + 2));
      return '[${elements.join(', ')}]';
    }
    final items = node['items'];
    if (items == null) {
      return 'unknown[]';
    }
    return _arrayOf(render(items, depth + 1));
  }

  String _arrayOf(String element) =>
      _isSimple(element) ? '$element[]' : '($element)[]';

  String _object(Map<dynamic, dynamic> node, int depth) {
    final properties = node['properties'];
    if (properties != null && properties is! Map) {
      return 'unknown';
    }
    final rawRequired = node['required'];
    final required = <String>{
      if (rawRequired is List)
        for (final r in rawRequired)
          if (r is String) r,
    };
    final additional = node['additionalProperties'];
    final members = <String>[];
    var chars = 0;
    if (properties is Map) {
      _spend(properties.length);
      final keys = [for (final k in properties.keys) '$k']..sort();
      for (final key in keys) {
        _fits(chars + key.length);
        final schema = properties[key];
        final doc = _doc(schema);
        final optional = required.contains(key) ? '' : '?';
        final member =
            '$doc${_key(key)}$optional: ${render(schema, depth + 1)};';
        chars += member.length + 1;
        _fits(chars);
        members.add(member);
      }
    }
    final open = additional != false;
    if (open) {
      final hasProperties = properties is Map && properties.isNotEmpty;
      if (additional is Map && !hasProperties) {
        members.add('[key: string]: ${render(additional, depth + 1)};');
      } else if (properties == null ||
          additional is Map ||
          additional == true) {
        // An open object with named properties keeps `unknown` values: a
        // narrower index signature would conflict with the named ones.
        members.add('[key: string]: unknown;');
      }
    }
    if (members.isEmpty) {
      return '{}';
    }
    return '{ ${members.join(' ')} }';
  }

  /// The JSDoc for one property, or empty: its description and constraints.
  String _doc(Object? schema) {
    if (schema is! Map || !options.docs) {
      return '';
    }
    final parts = <String>[];
    final description = schema['description'];
    if (description is String) {
      _fits(description.length);
      _scan(description);
      if (description.trim().isNotEmpty) {
        parts.add(description);
      }
    }
    for (final tag in JsonSchemaTypeScript.constraintTags) {
      if (!schema.containsKey(tag)) {
        continue;
      }
      final value = schema[tag];
      _spendValue(value);
      final shown = value is String && tag != 'default' ? value : _json(value);
      if (shown != null) {
        parts.add('@$tag $shown');
      }
    }
    if (schema['deprecated'] == true) {
      parts.add('@deprecated');
    }
    if (parts.isEmpty) {
      return '';
    }
    final text = JsonSchemaTypeScript.commentText(parts.join(' '));
    return text.isEmpty ? '' : '/** $text */ ';
  }

  String _key(String key) => _identifier.hasMatch(key) ? key : jsonEncode(key);

  String _literal(Object? value) {
    if (value is String) {
      _fits(value.length);
    }
    if (value == null || value is bool || value is num || value is String) {
      return jsonEncode(value);
    }
    return 'unknown';
  }

  /// Counts a value shown in JSDoc against the budget, one unit per node,
  /// before it is encoded; a string longer than the type bound stops it.
  void _spendValue(Object? value) {
    _spend(1);
    if (value is String) {
      _fits(value.length);
    } else if (value is Map) {
      for (final entry in value.entries) {
        _spendValue(entry.key);
        _spendValue(entry.value);
      }
    } else if (value is List) {
      for (final item in value) {
        _spendValue(item);
      }
    }
  }

  String? _json(Object? value) {
    try {
      return jsonEncode(value);
    } on Object {
      return null;
    }
  }

  /// Whether [node] says anything about a shape (as opposed to only
  /// constraints such as `required`, which a union member often carries to
  /// pick a variant).
  bool _hasStructure(Object? node) {
    if (node is! Map) {
      return node == false;
    }
    const keys = {
      r'$ref',
      'type',
      'const',
      'enum',
      'properties',
      'additionalProperties',
      'items',
      'prefixItems',
      'oneOf',
      'anyOf',
      'allOf',
    };
    return node.keys.any(keys.contains);
  }

  /// `a | b | …`, each member once, in first-seen order. Built in one pass
  /// with an insertion-ordered set; stops at the size bound while it is built.
  String _union(Iterable<String> members) {
    final unique = <String>{};
    var chars = 0;
    for (final m in members) {
      if (m == 'unknown') {
        return 'unknown';
      }
      if (m != 'never' && unique.add(m)) {
        chars += m.length + 3;
        _fits(chars);
      }
    }
    if (unique.isEmpty) {
      return 'never';
    }
    if (unique.length == 1) {
      return unique.single;
    }
    return unique
        .map((m) {
          _scan(m);
          return m.contains(' & ') ? '($m)' : m;
        })
        .join(' | ');
  }

  /// `a & b & …`, built like [_union].
  String _intersection(List<String> members) {
    final unique = <String>{};
    var chars = 0;
    for (final m in members) {
      if (m == 'never') {
        return 'never';
      }
      if (m != 'unknown' && unique.add(m)) {
        chars += m.length + 5;
        _fits(chars);
      }
    }
    if (unique.isEmpty) {
      return 'unknown';
    }
    if (unique.length == 1) {
      return unique.single;
    }
    return unique.map((m) => _isSimple(m) ? m : '($m)').join(' & ');
  }

  /// Whether [type] can take a postfix `[]` or sit in an intersection
  /// without parentheses.
  bool _isSimple(String type) {
    _scan(type);
    return !type.contains(' | ') && !type.contains(' & ') ||
        (type.startsWith('{') && type.endsWith('}') && _balancedObject(type));
  }

  /// Whether [type] is one object literal, not `{…} | {…}`.
  bool _balancedObject(String type) {
    var depth = 0;
    var inString = false;
    for (var i = 0; i < type.length; i++) {
      final c = type[i];
      if (inString) {
        if (c == r'\') {
          i++;
        } else if (c == '"') {
          inString = false;
        }
        continue;
      }
      if (c == '/' && i + 1 < type.length && type[i + 1] == '*') {
        // A JSDoc comment: its text may hold any bracket. Descriptions have
        // every `*/` escaped, so the first one closes it.
        final close = type.indexOf('*/', i + 2);
        if (close < 0) {
          return false;
        }
        i = close + 1;
        continue;
      }
      if (c == '"') {
        inString = true;
      } else if (c == '{' || c == '[' || c == '(') {
        depth++;
      } else if (c == '}' || c == ']' || c == ')') {
        depth--;
        if (depth == 0 && i != type.length - 1) {
          return false;
        }
      }
    }
    return depth == 0;
  }
}
