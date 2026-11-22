/// Maps raw tool names to the JavaScript identifiers a script calls them by.
///
/// A raw name (`mcp__github__list-issues`, `2fa_check`, `class`) is often not
/// a usable identifier, and a few valid identifiers are dangerous as property
/// names on the `tools` object (`__proto__`, `constructor`, `then`). The
/// mapping is a pure function of the SET of names: the same names in any
/// order give the same identifiers, which keeps the `repl` description
/// byte-stable in the cached prompt prefix.
///
/// Rules, in order:
/// 1. Every character outside `[A-Za-z0-9_$]` becomes `_` (non-ASCII letters
///    included: an identifier the model has to reproduce exactly should not
///    depend on Unicode normalisation).
/// 2. An empty result becomes `_`.
/// 3. A leading digit, a reserved word, or a name in [guardedNames] gets a
///    leading `_`.
/// 4. A name that is already a valid identifier keeps it. The others, in
///    sorted raw-name order, take their base identifier if it is free, or the
///    first free `<base>_<n>` for n = 2, 3, …
class ScriptIdentifierMap {
  ScriptIdentifierMap._(this._idByName, this._nameById);

  /// Builds the mapping for [rawNames]. Duplicates are ignored.
  factory ScriptIdentifierMap.build(Iterable<String> rawNames) {
    final names = rawNames.toSet().toList()..sort();
    final idByName = <String, String>{};
    final nameById = <String, String>{};

    void assign(String name, String id) {
      idByName[name] = id;
      nameById[id] = name;
    }

    // Pass 1: names that are already safe identifiers keep themselves. Raw
    // names are unique, so these can never collide with each other, and an
    // exact name must not lose its own spelling to a sanitised neighbour.
    final pending = <String>[];
    for (final name in names) {
      if (baseIdentifier(name) == name) {
        assign(name, name);
      } else {
        pending.add(name);
      }
    }
    // Pass 2: everything else, in sorted order, deterministically suffixed.
    for (final name in pending) {
      final base = baseIdentifier(name);
      var id = base;
      var n = 2;
      while (nameById.containsKey(id)) {
        id = '${base}_$n';
        n++;
      }
      assign(name, id);
    }
    return ScriptIdentifierMap._(idByName, nameById);
  }

  final Map<String, String> _idByName;
  final Map<String, String> _nameById;

  /// Names that are valid identifiers but must not be property names on the
  /// `tools` object: they reach the prototype chain, or make the object look
  /// like a promise (`then`) or a serialisable value (`toJSON`).
  static const Set<String> guardedNames = {
    '__proto__',
    '__defineGetter__',
    '__defineSetter__',
    '__lookupGetter__',
    '__lookupSetter__',
    'constructor',
    'prototype',
    'then',
    'catch',
    'finally',
    'toString',
    'toLocaleString',
    'toJSON',
    'valueOf',
    'hasOwnProperty',
    'isPrototypeOf',
    'propertyIsEnumerable',
  };

  /// JavaScript reserved words, strict-mode reserved words, and the
  /// contextual keywords and global value names a script would trip over.
  static const Set<String> reservedWords = {
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'debugger',
    'default',
    'delete',
    'do',
    'else',
    'enum',
    'export',
    'extends',
    'false',
    'finally',
    'for',
    'function',
    'if',
    'import',
    'in',
    'instanceof',
    'new',
    'null',
    'return',
    'super',
    'switch',
    'this',
    'throw',
    'true',
    'try',
    'typeof',
    'var',
    'void',
    'while',
    'with',
    'yield',
    'let',
    'static',
    'implements',
    'interface',
    'package',
    'private',
    'protected',
    'public',
    'arguments',
    'eval',
    'async',
    'of',
    'get',
    'set',
    'undefined',
    'NaN',
    'Infinity',
  };

  static final RegExp _invalid = RegExp(r'[^A-Za-z0-9_$]');
  static final RegExp _leadingDigit = RegExp('^[0-9]');

  /// The identifier [rawName] maps to before collisions are resolved.
  static String baseIdentifier(String rawName) {
    var id = rawName.replaceAll(_invalid, '_');
    if (id.isEmpty) {
      return '_';
    }
    if (_leadingDigit.hasMatch(id) ||
        reservedWords.contains(id) ||
        guardedNames.contains(id)) {
      id = '_$id';
    }
    return id;
  }

  /// Whether [value] is a JavaScript identifier this mapping could produce
  /// unchanged: ASCII, not starting with a digit, not reserved, not guarded.
  static bool isSafeIdentifier(String value) =>
      value.isNotEmpty && baseIdentifier(value) == value;

  /// The identifier for [rawName], or null when it is not mapped.
  String? idFor(String rawName) => _idByName[rawName];

  /// The raw name for [identifier], or null when it is not mapped.
  String? nameFor(String identifier) => _nameById[identifier];

  /// Resolves [nameOrId] to a raw name: an exact raw name first, then an
  /// identifier. Null when it is neither.
  String? resolve(String nameOrId) =>
      _idByName.containsKey(nameOrId) ? nameOrId : _nameById[nameOrId];

  /// Every raw name, sorted.
  List<String> get names => _idByName.keys.toList()..sort();

  /// Every identifier, sorted.
  List<String> get identifiers => _nameById.keys.toList()..sort();

  /// Raw name to identifier, as an unmodifiable map.
  Map<String, String> get idByName => Map.unmodifiable(_idByName);

  /// Number of mapped names.
  int get length => _idByName.length;
}
