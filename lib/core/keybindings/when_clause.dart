import 'package:flutter/foundation.dart';

/// A parsed VS Code-style `when` clause.
///
/// Supports the operators used by VS Code keybinding rules:
///
///   * bare context keys, evaluated for truthiness — `editorFocus`
///   * negation — `!textInputFocus`
///   * equality / inequality — `route == '/dashboard'`, `mode != insert`
///   * regex match — `route =~ /^\/pull-requests\//`
///   * boolean `&&` and `||` with `()` grouping
///
/// A clause is evaluated against a `Map<String, Object?>` context. A key is
/// truthy when present and not one of `null`, `false`, `''`, `0`, `'false'`.
/// Right-hand comparison values may be quoted (`'x'` / `"x"`) or bare words
/// (so a path literal like `/settings/agents` works unquoted).
///
/// Parsing is cached per clause string, so repeated evaluation (the dispatcher
/// re-evaluates every clause whenever the context changes) is cheap.
class WhenClause {
  WhenClause._(this._predicate);

  final bool Function(Map<String, Object?> context) _predicate;

  static final Map<String, WhenClause> _cache = {};

  /// Parses [expression] into a reusable clause. An empty/null clause always
  /// evaluates to `true`. A malformed clause logs in debug and evaluates to
  /// `false` (a binding with a broken guard is disabled, never always-on).
  static WhenClause parse(String? expression) {
    final src = expression?.trim() ?? '';
    if (src.isEmpty) {
      return _alwaysTrue;
    }
    return _cache.putIfAbsent(src, () {
      try {
        final tokens = _tokenize(src);
        final parser = _Parser(tokens);
        final predicate = parser.parseExpression();
        parser.expectEnd();
        return WhenClause._(predicate);
      } on FormatException catch (e) {
        assert(() {
          debugPrint('Invalid when-clause "$src": ${e.message}');
          return true;
        }());
        return _alwaysFalse;
      }
    });
  }

  static final WhenClause _alwaysTrue = WhenClause._((_) => true);
  static final WhenClause _alwaysFalse = WhenClause._((_) => false);

  /// Evaluates the clause against [context].
  bool evaluate(Map<String, Object?> context) => _predicate(context);

  /// Whether [value] from the context is considered truthy.
  static bool truthy(Object? value) {
    if (value == null || value == false || value == 0) {
      return false;
    }
    if (value is String) {
      return value.isNotEmpty && value != 'false';
    }
    return true;
  }

  static String _stringify(Object? value) => value?.toString() ?? '';

  // ── Tokenizer ──────────────────────────────────────────────────────────

  static List<_Token> _tokenize(String src) {
    final tokens = <_Token>[];
    var i = 0;
    while (i < src.length) {
      final c = src[i];
      if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
        i++;
        continue;
      }
      if (c == '(') {
        tokens.add(const _Token(_TokenType.lparen, '('));
        i++;
        continue;
      }
      if (c == ')') {
        tokens.add(const _Token(_TokenType.rparen, ')'));
        i++;
        continue;
      }
      if (c == '&' && i + 1 < src.length && src[i + 1] == '&') {
        tokens.add(const _Token(_TokenType.and, '&&'));
        i += 2;
        continue;
      }
      if (c == '|' && i + 1 < src.length && src[i + 1] == '|') {
        tokens.add(const _Token(_TokenType.or, '||'));
        i += 2;
        continue;
      }
      if (c == '=' && i + 1 < src.length && src[i + 1] == '=') {
        tokens.add(const _Token(_TokenType.eq, '=='));
        i += 2;
        continue;
      }
      if (c == '!' && i + 1 < src.length && src[i + 1] == '=') {
        tokens.add(const _Token(_TokenType.neq, '!='));
        i += 2;
        continue;
      }
      if (c == '=' && i + 1 < src.length && src[i + 1] == '~') {
        tokens.add(const _Token(_TokenType.match, '=~'));
        i += 2;
        continue;
      }
      if (c == '!') {
        tokens.add(const _Token(_TokenType.not, '!'));
        i++;
        continue;
      }
      if (c == "'" || c == '"') {
        final quote = c;
        final buf = StringBuffer();
        i++;
        while (i < src.length && src[i] != quote) {
          if (src[i] == r'\' && i + 1 < src.length) {
            buf.write(src[i + 1]);
            i += 2;
          } else {
            buf.write(src[i]);
            i++;
          }
        }
        if (i >= src.length) {
          throw const FormatException('unterminated string');
        }
        i++; // closing quote
        tokens.add(_Token(_TokenType.value, buf.toString()));
        continue;
      }
      if (c == '/') {
        // Regex literal: /pattern/ with \/ as an escaped slash.
        final buf = StringBuffer();
        i++;
        while (i < src.length && src[i] != '/') {
          if (src[i] == r'\' && i + 1 < src.length && src[i + 1] == '/') {
            buf.write('/');
            i += 2;
          } else {
            buf.write(src[i]);
            i++;
          }
        }
        if (i >= src.length) {
          throw const FormatException('unterminated regex');
        }
        i++; // closing slash
        tokens.add(_Token(_TokenType.regex, buf.toString()));
        continue;
      }
      // Bareword: identifier, number, or path-like literal.
      final start = i;
      while (i < src.length && !_isBarewordBreak(src, i)) {
        i++;
      }
      if (i == start) {
        throw FormatException('unexpected character "$c"');
      }
      tokens.add(_Token(_TokenType.word, src.substring(start, i)));
    }
    tokens.add(const _Token(_TokenType.end, ''));
    return tokens;
  }

  static bool _isBarewordBreak(String src, int i) {
    final c = src[i];
    if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
      return true;
    }
    if (c == '(' || c == ')' || c == "'" || c == '"') {
      return true;
    }
    if (c == '&' && i + 1 < src.length && src[i + 1] == '&') {
      return true;
    }
    if (c == '|' && i + 1 < src.length && src[i + 1] == '|') {
      return true;
    }
    if (c == '=' &&
        i + 1 < src.length &&
        (src[i + 1] == '=' || src[i + 1] == '~')) {
      return true;
    }
    if (c == '!' && i + 1 < src.length && src[i + 1] == '=') {
      return true;
    }
    return false;
  }
}

enum _TokenType { word, value, regex, and, or, not, eq, neq, match, lparen, rparen, end }

class _Token {
  const _Token(this.type, this.text);
  final _TokenType type;
  final String text;
}

/// Recursive-descent parser that compiles tokens into a predicate closure.
/// Precedence (low → high): `||`, `&&`, `!` / comparison / primary.
class _Parser {
  _Parser(this._tokens);
  final List<_Token> _tokens;
  int _pos = 0;

  _Token get _peek => _tokens[_pos];
  _Token _next() => _tokens[_pos++];

  void expectEnd() {
    if (_peek.type != _TokenType.end) {
      throw FormatException('unexpected token "${_peek.text}"');
    }
  }

  bool Function(Map<String, Object?>) parseExpression() => _parseOr();

  bool Function(Map<String, Object?>) _parseOr() {
    var left = _parseAnd();
    while (_peek.type == _TokenType.or) {
      _next();
      final right = _parseAnd();
      final l = left;
      left = (ctx) => l(ctx) || right(ctx);
    }
    return left;
  }

  bool Function(Map<String, Object?>) _parseAnd() {
    var left = _parseUnary();
    while (_peek.type == _TokenType.and) {
      _next();
      final right = _parseUnary();
      final l = left;
      left = (ctx) => l(ctx) && right(ctx);
    }
    return left;
  }

  bool Function(Map<String, Object?>) _parseUnary() {
    if (_peek.type == _TokenType.not) {
      _next();
      final operand = _parseUnary();
      return (ctx) => !operand(ctx);
    }
    return _parseComparison();
  }

  bool Function(Map<String, Object?>) _parseComparison() {
    if (_peek.type == _TokenType.lparen) {
      _next();
      final inner = _parseOr();
      if (_peek.type != _TokenType.rparen) {
        throw const FormatException('missing ")"');
      }
      _next();
      return inner;
    }

    final keyToken = _next();
    if (keyToken.type == _TokenType.word) {
      final lowered = keyToken.text;
      if (lowered == 'true') {
        return (_) => true;
      }
      if (lowered == 'false') {
        return (_) => false;
      }
    } else {
      throw FormatException('expected a context key, got "${keyToken.text}"');
    }
    final key = keyToken.text;

    switch (_peek.type) {
      case _TokenType.eq:
        _next();
        final value = _readValue();
        return (ctx) => WhenClause._stringify(ctx[key]) == value;
      case _TokenType.neq:
        _next();
        final value = _readValue();
        return (ctx) => WhenClause._stringify(ctx[key]) != value;
      case _TokenType.match:
        _next();
        if (_peek.type != _TokenType.regex && _peek.type != _TokenType.value) {
          throw const FormatException('=~ expects a /regex/');
        }
        final pattern = _next().text;
        final regex = RegExp(pattern);
        return (ctx) => regex.hasMatch(WhenClause._stringify(ctx[key]));
      default:
        return (ctx) => WhenClause.truthy(ctx[key]);
    }
  }

  String _readValue() {
    final t = _next();
    if (t.type == _TokenType.value || t.type == _TokenType.word) {
      return t.text;
    }
    throw FormatException('expected a value, got "${t.text}"');
  }
}
