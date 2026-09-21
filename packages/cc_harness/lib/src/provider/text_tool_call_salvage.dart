import 'dart:convert';

/// One tool call recovered from assistant text.
class SalvagedToolCall {
  /// Creates a [SalvagedToolCall].
  const SalvagedToolCall({required this.name, required this.arguments});

  /// The tool name — always one of the caller's declared tools.
  final String name;

  /// Decoded arguments.
  final Map<String, dynamic> arguments;

  @override
  String toString() => 'SalvagedToolCall($name, $arguments)';
}

/// Recovers tool calls written as prose instead of the structured tool channel.
///
/// A candidate becomes a call only when its name is in the run's declared tool
/// list. Salvage decides what was asked for; the loop's approval gate still
/// decides what is allowed.
///
/// Dialects: `qwen3_xml` / `qwen3_coder` XML; attribute/`parameter` variants
/// (tool list disambiguates tool vs arg names); JSON objects in fences or
/// `<tool_call>` wrappers.
class TextToolCallSalvage {
  /// Creates a [TextToolCallSalvage].
  const TextToolCallSalvage();

  /// Tags that can open or close a call in the XML dialects.
  static final RegExp _tag = RegExp(
    r'<(/?)(function|invoke|tool_call|parameter)([^>]*)>',
    caseSensitive: false,
  );

  /// `name="x"` / `name='x'` attribute form.
  static final RegExp _nameAttr = RegExp(
    '''name\\s*=\\s*(?:"([^"]*)"|'([^']*)')''',
    caseSensitive: false,
  );

  /// Keys a JSON-dialect object may use to name the tool.
  static const List<String> _jsonNameKeys = ['tool', 'name', 'function'];

  /// Keys a JSON-dialect object may use to nest its arguments.
  static const List<String> _jsonArgKeys = ['arguments', 'parameters', 'args'];

  /// Parses [text] and returns the tool calls it contains, in source order.
  ///
  /// Returns an empty list when nothing recognizable is present — which is the
  /// overwhelmingly common case, so callers can invoke this unconditionally.
  /// Only names in [knownToolNames] are ever returned.
  List<SalvagedToolCall> parse(
    String text, {
    required Set<String> knownToolNames,
  }) {
    if (text.isEmpty || knownToolNames.isEmpty) {
      return const [];
    }
    final xml = _parseXml(text, knownToolNames);
    // A model speaks one dialect at a time. Running the JSON pass over text that
    // already yielded XML calls risks double-invoking the same intent, so the
    // XML result wins outright when it found anything.
    if (xml.isNotEmpty) {
      return xml;
    }
    return _parseJson(text, knownToolNames);
  }

  List<SalvagedToolCall> _parseXml(String text, Set<String> known) {
    final calls = <SalvagedToolCall>[];
    String? openName;
    var openArgs = <String, dynamic>{};
    String? paramKey;
    var paramStart = 0;

    void finish() {
      final name = openName;
      if (name != null) {
        calls.add(SalvagedToolCall(name: name, arguments: openArgs));
      }
      openName = null;
      openArgs = <String, dynamic>{};
      paramKey = null;
    }

    for (final m in _tag.allMatches(text)) {
      final isClose = m.group(1) == '/';
      final tag = m.group(2)!.toLowerCase();
      final attrs = m.group(3) ?? '';

      if (isClose) {
        if (tag == 'parameter') {
          final key = paramKey;
          if (key != null) {
            openArgs[key] = _coerce(text.substring(paramStart, m.start));
            paramKey = null;
          }
        } else if (openName != null) {
          // `</function>`, `</invoke>`, `</tool_call>` all close a call. An
          // unterminated parameter is still worth keeping: a truncated call with
          // most of its arguments beats discarding the turn.
          final key = paramKey;
          if (key != null) {
            openArgs[key] = _coerce(text.substring(paramStart, m.start));
          }
          finish();
        }
        continue;
      }

      final name = _tagName(attrs);
      if (openName == null) {
        // Any of the four tags may carry the function name — including
        // `parameter`, which is how the corrupted dialect opens a call.
        if (name != null && known.contains(name)) {
          openName = name;
          openArgs = <String, dynamic>{};
          paramKey = null;
        }
        continue;
      }
      // Inside a call. Only a function-ish tag may start a NEW call; a
      // `parameter` tag is always an argument, even if its name happens to
      // collide with a tool name.
      if (tag != 'parameter' && name != null && known.contains(name)) {
        finish();
        openName = name;
        openArgs = <String, dynamic>{};
        continue;
      }
      if (name != null) {
        paramKey = name;
        paramStart = m.end;
      }
    }
    // Text that ended mid-call (the model was cut off): keep what arrived.
    if (openName != null) {
      final key = paramKey;
      if (key != null) {
        openArgs[key] = _coerce(text.substring(paramStart));
      }
      finish();
    }
    return calls;
  }

  /// The name carried by a tag's attribute text: `=read` or `name="read"`.
  static String? _tagName(String attrs) {
    final trimmed = attrs.trim();
    if (trimmed.startsWith('=')) {
      final raw = trimmed.substring(1).trim();
      final unquoted = _unquote(raw);
      return unquoted.isEmpty ? null : unquoted;
    }
    final m = _nameAttr.firstMatch(trimmed);
    final value = m?.group(1) ?? m?.group(2);
    return (value == null || value.isEmpty) ? null : value;
  }

  static String _unquote(String s) {
    if (s.length >= 2 &&
        ((s.startsWith('"') && s.endsWith('"')) ||
            (s.startsWith("'") && s.endsWith("'")))) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }

  /// Converts a parameter's raw text to a typed value.
  ///
  /// Only `[`/`{`-prefixed values are JSON-decoded. Decoding every scalar would
  /// silently retype real string arguments — a query of `true` or an id that
  /// happens to be all digits must stay a string.
  static dynamic _coerce(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      try {
        return jsonDecode(trimmed);
      } on FormatException {
        return trimmed;
      }
    }
    return trimmed;
  }

  /// Recovers calls from JSON objects, but only inside a fenced code block or a
  /// `<tool_call>` wrapper, or when the object is the entire message.
  ///
  /// The delimiter requirement is the false-positive guard: an assistant
  /// explaining a tool in prose must not have its example executed.
  List<SalvagedToolCall> _parseJson(String text, Set<String> known) {
    final calls = <SalvagedToolCall>[];
    for (final region in _candidateRegions(text)) {
      for (final obj in _jsonObjectsIn(region)) {
        final call = _callFromJson(obj, known);
        if (call != null) {
          calls.add(call);
        }
      }
    }
    return calls;
  }

  /// Fenced blocks, `<tool_call>` bodies and — when it is the whole message —
  /// the text itself.
  static List<String> _candidateRegions(String text) {
    final regions = <String>[];
    for (final m in RegExp(
      r'```[^\n]*\n([\s\S]*?)```',
      multiLine: true,
    ).allMatches(text)) {
      regions.add(m.group(1)!);
    }
    for (final m in RegExp(
      r'<tool_call[^>]*>([\s\S]*?)(?:</tool_call>|$)',
      caseSensitive: false,
    ).allMatches(text)) {
      regions.add(m.group(1)!);
    }
    final trimmed = text.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      regions.add(trimmed);
    }
    return regions;
  }

  /// Top-level `{...}` objects in [s], found by brace matching that respects
  /// strings and escapes (a regex cannot balance braces).
  static List<Map<String, dynamic>> _jsonObjectsIn(String s) {
    final out = <Map<String, dynamic>>[];
    var i = 0;
    while (i < s.length) {
      if (s[i] != '{') {
        i++;
        continue;
      }
      var depth = 0;
      var inString = false;
      var escaped = false;
      var end = -1;
      for (var j = i; j < s.length; j++) {
        final c = s[j];
        if (escaped) {
          escaped = false;
          continue;
        }
        if (c == r'\') {
          escaped = true;
          continue;
        }
        if (c == '"') {
          inString = !inString;
          continue;
        }
        if (inString) {
          continue;
        }
        if (c == '{') {
          depth++;
        } else if (c == '}') {
          depth--;
          if (depth == 0) {
            end = j;
            break;
          }
        }
      }
      if (end < 0) {
        return out;
      }
      try {
        final decoded = jsonDecode(s.substring(i, end + 1));
        if (decoded is Map<String, dynamic>) {
          out.add(decoded);
        }
      } on FormatException {
        // Not JSON — a prose brace. Skip it and keep scanning.
      }
      i = end + 1;
    }
    return out;
  }

  static SalvagedToolCall? _callFromJson(
    Map<String, dynamic> obj,
    Set<String> known,
  ) {
    String? name;
    String? nameKey;
    for (final key in _jsonNameKeys) {
      final value = obj[key];
      if (value is String && known.contains(value)) {
        name = value;
        nameKey = key;
        break;
      }
    }
    if (name == null) {
      return null;
    }
    for (final key in _jsonArgKeys) {
      final nested = obj[key];
      if (nested is Map<String, dynamic>) {
        return SalvagedToolCall(name: name, arguments: nested);
      }
      if (nested is String) {
        // Some servers double-encode the arguments object.
        try {
          final decoded = jsonDecode(nested);
          if (decoded is Map<String, dynamic>) {
            return SalvagedToolCall(name: name, arguments: decoded);
          }
        } on FormatException {
          // Fall through to the flat form.
        }
      }
    }
    // Flat form: every key except the one that named the tool is an argument.
    final args = <String, dynamic>{
      for (final e in obj.entries)
        if (e.key != nameKey) e.key: e.value,
    };
    return SalvagedToolCall(name: name, arguments: args);
  }
}
