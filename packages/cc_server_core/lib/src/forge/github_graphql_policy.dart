/// What a GitHub GraphQL request may carry on an automation client, decided
/// from its document: queries read; a mutation needs the scope its root
/// fields are listed at in [githubGraphQlMutationScopes]; anything else is
/// refused locally.
///
/// The document is tokenized and parsed (comments, strings, aliases,
/// directives, inline fragments and fragment spreads included), never
/// matched with a regular expression over the whole body, so a comment, a
/// string or an alias cannot hide a root field.
library;

import 'package:cc_connect_core/cc_connect_core.dart' show GitHubTokenScope;
import 'package:cc_infra/cc_infra.dart' show ForgeCredentialUnavailable;

/// The GraphQL mutations an automation client may send, each at the scope
/// that carries what it does. It mirrors the REST policy
/// (`githubScopeForRequest`): conversation the issues permission carries
/// (comments, reactions, labels, assignees) is `comment`; reviews, review
/// comments and threads, files viewed and review requests are `bot`;
/// anything that changes a pull request's state, title, base or branch,
/// dismisses a review, or edits or deletes a comment that may be someone
/// else's is `write`, which on a Connect lane only a person's own token
/// holds. Approving stays refused whatever the scope
/// (`refuseAutomatedGitHubApproval`). A mutation not listed here is never
/// sent.
const Map<String, GitHubTokenScope> githubGraphQlMutationScopes = {
  // Conversation, as the bot.
  'addComment': GitHubTokenScope.comment,
  'addReaction': GitHubTokenScope.comment,
  'removeReaction': GitHubTokenScope.comment,
  'addLabelsToLabelable': GitHubTokenScope.comment,
  'removeLabelsFromLabelable': GitHubTokenScope.comment,
  'addAssigneesToAssignable': GitHubTokenScope.comment,
  'removeAssigneesFromAssignable': GitHubTokenScope.comment,
  // Reviews, as the bot.
  'addPullRequestReview': GitHubTokenScope.bot,
  'submitPullRequestReview': GitHubTokenScope.bot,
  'updatePullRequestReview': GitHubTokenScope.bot,
  'deletePullRequestReview': GitHubTokenScope.bot,
  'addPullRequestReviewComment': GitHubTokenScope.bot,
  'addPullRequestReviewThread': GitHubTokenScope.bot,
  'addPullRequestReviewThreadReply': GitHubTokenScope.bot,
  'resolveReviewThread': GitHubTokenScope.bot,
  'unresolveReviewThread': GitHubTokenScope.bot,
  'markFileAsViewed': GitHubTokenScope.bot,
  'unmarkFileAsViewed': GitHubTokenScope.bot,
  'requestReviews': GitHubTokenScope.bot,
  // Editing or deleting a comment that may be another person's.
  'updateIssueComment': GitHubTokenScope.write,
  'deleteIssueComment': GitHubTokenScope.write,
  'updatePullRequestReviewComment': GitHubTokenScope.write,
  'deletePullRequestReviewComment': GitHubTokenScope.write,
  'dismissPullRequestReview': GitHubTokenScope.write,
  // A pull request's own state, title, base or branch.
  'createPullRequest': GitHubTokenScope.write,
  'updatePullRequest': GitHubTokenScope.write,
  'closePullRequest': GitHubTokenScope.write,
  'reopenPullRequest': GitHubTokenScope.write,
  'convertPullRequestToDraft': GitHubTokenScope.write,
  'markPullRequestReadyForReview': GitHubTokenScope.write,
  'mergePullRequest': GitHubTokenScope.write,
  'updatePullRequestBranch': GitHubTokenScope.write,
  'enablePullRequestAutoMerge': GitHubTokenScope.write,
  'disablePullRequestAutoMerge': GitHubTokenScope.write,
};

/// The scope a GraphQL request needs, or why it is refused.
final class GitHubGraphQlVerdict {
  const GitHubGraphQlVerdict._(this.scope, this.refusal);

  /// The scope the request needs; null when [refusal] is set.
  final GitHubTokenScope? scope;

  /// Why the request must not be sent, or null.
  final String? refusal;
}

/// The scope [body] (a GraphQL request body: `{query, variables}`) needs on
/// an automation client, or a refusal.
///
/// Every operation in the document counts, whichever one
/// `operationName` picks, so the verdict is the highest scope any of them
/// needs: queries `read`, a mutation the highest of its root fields' listed
/// scopes. A mutation root field that is not listed, a subscription, or a
/// document that does not parse is refused.
GitHubGraphQlVerdict githubGraphQlScope(Object? body) {
  final query = body is Map ? body['query'] : null;
  if (query is! String) {
    return const GitHubGraphQlVerdict._(
      null,
      'Automation sends only GraphQL requests whose document it can read.',
    );
  }
  final List<GraphQlOperation> operations;
  try {
    operations = parseGraphQlOperations(query);
  } on FormatException catch (e) {
    return GitHubGraphQlVerdict._(
      null,
      'Automation sends only GraphQL documents it can read: ${e.message}',
    );
  }
  var scope = GitHubTokenScope.read;
  for (final operation in operations) {
    switch (operation.kind) {
      case GraphQlOperationKind.query:
        continue;
      case GraphQlOperationKind.subscription:
        return const GitHubGraphQlVerdict._(
          null,
          'Automation never sends a GraphQL subscription.',
        );
      case GraphQlOperationKind.mutation:
        for (final field in operation.rootFields) {
          if (field.startsWith('__')) {
            continue;
          }
          final needed = githubGraphQlMutationScopes[field];
          if (needed == null) {
            return GitHubGraphQlVerdict._(
              null,
              'Automation does not send the GitHub GraphQL mutation '
              '`$field`; a person must do this from their own account.',
            );
          }
          if (needed.index > scope.index) {
            scope = needed;
          }
        }
    }
  }
  return GitHubGraphQlVerdict._(scope, null);
}

/// [githubGraphQlScope]'s scope, or the refusal as the
/// [ForgeCredentialUnavailable] a credential lookup throws (403: nothing is
/// sent).
GitHubTokenScope requireGitHubGraphQlScope(Object? body) {
  final verdict = githubGraphQlScope(body);
  return verdict.scope ??
      (throw ForgeCredentialUnavailable(403, verdict.refusal!));
}

/// Whether a GraphQL request body may change anything: any operation that
/// is not a query, or a document that does not parse.
bool isGraphQlWrite(Object? body) {
  final query = body is Map ? body['query'] : null;
  if (query is! String) {
    return true;
  }
  try {
    return parseGraphQlOperations(
      query,
    ).any((o) => o.kind != GraphQlOperationKind.query);
  } on FormatException {
    return true;
  }
}

/// A GraphQL operation's type.
enum GraphQlOperationKind {
  /// `query`, or the `{ … }` shorthand.
  query,

  /// `mutation`.
  mutation,

  /// `subscription`.
  subscription,
}

/// One executable operation: its type and the names (never the aliases) of
/// the fields at its root, fragments included.
typedef GraphQlOperation = ({
  GraphQlOperationKind kind,
  Set<String> rootFields,
});

/// Every operation in [source], an executable GraphQL document, with its
/// root field names. Throws [FormatException] when [source] is not one: an
/// unterminated string, an unknown fragment, a type-system definition, an
/// empty document.
List<GraphQlOperation> parseGraphQlOperations(String source) =>
    _GraphQlParser(_lex(source)).document();

const _punctuators = '!\$&()[]{}:=@|';

List<String> _lex(String s) {
  final tokens = <String>[];
  var i = 0;
  bool isNameStart(int c) =>
      c == 0x5F || (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);
  bool isNamePart(int c) => isNameStart(c) || (c >= 0x30 && c <= 0x39);
  while (i < s.length) {
    final c = s.codeUnitAt(i);
    final ch = s[i];
    if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' || ch == ',') {
      i++;
    } else if (c == 0xFEFF) {
      i++;
    } else if (ch == '#') {
      while (i < s.length && s[i] != '\n' && s[i] != '\r') {
        i++;
      }
    } else if (s.startsWith('"""', i)) {
      var j = i + 3;
      while (j < s.length && !s.startsWith('"""', j)) {
        j += s.startsWith(r'\"""', j) ? 4 : 1;
      }
      if (j >= s.length) {
        throw const FormatException('unterminated block string');
      }
      tokens.add('"');
      i = j + 3;
    } else if (ch == '"') {
      var j = i + 1;
      while (j < s.length && s[j] != '"') {
        if (s[j] == '\n' || s[j] == '\r') {
          throw const FormatException('unterminated string');
        }
        j += s[j] == r'\' ? 2 : 1;
      }
      if (j >= s.length) {
        throw const FormatException('unterminated string');
      }
      tokens.add('"');
      i = j + 1;
    } else if (s.startsWith('...', i)) {
      tokens.add('...');
      i += 3;
    } else if (_punctuators.contains(ch)) {
      tokens.add(ch);
      i++;
    } else if (isNameStart(c)) {
      final start = i;
      while (i < s.length && isNamePart(s.codeUnitAt(i))) {
        i++;
      }
      tokens.add(s.substring(start, i));
    } else if (ch == '-' || (c >= 0x30 && c <= 0x39)) {
      i++;
      while (i < s.length && '0123456789.eE+-'.contains(s[i])) {
        i++;
      }
      // A number is a value; values only appear inside skipped groups.
      tokens.add('0');
    } else {
      throw FormatException('unexpected character "$ch"');
    }
  }
  return tokens;
}

/// A root selection set: the field names it selects directly, and the
/// fragments it spreads (named, resolved once the document is read).
typedef _Selection = ({Set<String> fields, Set<String> spreads});

final class _GraphQlParser {
  _GraphQlParser(this._tokens);

  final List<String> _tokens;
  var _at = 0;

  String? get _peek => _at < _tokens.length ? _tokens[_at] : null;

  String _next() {
    if (_at >= _tokens.length) {
      throw const FormatException('unexpected end of document');
    }
    return _tokens[_at++];
  }

  void _expect(String token) {
    final got = _next();
    if (got != token) {
      throw FormatException('expected "$token", found "$got"');
    }
  }

  static bool _isName(String? t) =>
      t != null && t.isNotEmpty && RegExp(r'^[_A-Za-z]').hasMatch(t);

  String _name() {
    final t = _next();
    if (!_isName(t)) {
      throw FormatException('expected a name, found "$t"');
    }
    return t;
  }

  List<GraphQlOperation> document() {
    final operations = <({GraphQlOperationKind kind, _Selection selection})>[];
    final fragments = <String, _Selection>{};
    while (_peek != null) {
      final t = _peek!;
      if (t == '{') {
        operations.add((kind: GraphQlOperationKind.query, selection: _set()));
        continue;
      }
      _next();
      switch (t) {
        case 'query' || 'mutation' || 'subscription':
          final kind = GraphQlOperationKind.values.byName(t);
          if (_isName(_peek)) {
            _name();
          }
          if (_peek == '(') {
            _skipGroup('(', ')');
          }
          _directives();
          operations.add((kind: kind, selection: _set()));
        case 'fragment':
          final name = _name();
          if (name == 'on' || _name() != 'on') {
            throw const FormatException('malformed fragment definition');
          }
          _name();
          _directives();
          if (fragments.containsKey(name)) {
            throw FormatException('fragment "$name" is defined twice');
          }
          fragments[name] = _set();
        default:
          throw FormatException('"$t" does not start an operation');
      }
    }
    if (operations.isEmpty) {
      throw const FormatException('no operation');
    }
    Set<String> resolve(_Selection selection, Set<String> seen) => {
      ...selection.fields,
      for (final spread in selection.spreads)
        if (seen.add(spread))
          ...resolve(
            fragments[spread] ??
                (throw FormatException('unknown fragment "$spread"')),
            seen,
          ),
    };
    return [
      for (final o in operations)
        (kind: o.kind, rootFields: resolve(o.selection, <String>{})),
    ];
  }

  /// A selection set, read one level deep: nested selections are skipped,
  /// inline fragments fold into this level.
  _Selection _set() {
    final fields = <String>{};
    final spreads = <String>{};
    void into() {
      _expect('{');
      while (_peek != '}') {
        final t = _next();
        if (t == '...') {
          if (_peek == 'on') {
            _next();
            _name();
            _directives();
            into();
          } else if (_peek == '{' || _peek == '@') {
            _directives();
            into();
          } else {
            spreads.add(_name());
            _directives();
          }
          continue;
        }
        if (!_isName(t)) {
          throw FormatException('expected a field, found "$t"');
        }
        var field = t;
        if (_peek == ':') {
          _next();
          field = _name();
        }
        fields.add(field);
        if (_peek == '(') {
          _skipGroup('(', ')');
        }
        _directives();
        if (_peek == '{') {
          _skipGroup('{', '}');
        }
      }
      _next();
    }

    into();
    if (fields.isEmpty && spreads.isEmpty) {
      // `{}` selects nothing; GitHub would reject it as well.
      throw const FormatException('empty selection set');
    }
    return (fields: fields, spreads: spreads);
  }

  void _directives() {
    while (_peek == '@') {
      _next();
      _name();
      if (_peek == '(') {
        _skipGroup('(', ')');
      }
    }
  }

  void _skipGroup(String open, String close) {
    _expect(open);
    final stack = <String>[close];
    while (stack.isNotEmpty) {
      final t = _next();
      if (t == '(' || t == '{' || t == '[') {
        stack.add(switch (t) {
          '(' => ')',
          '{' => '}',
          _ => ']',
        });
      } else if (t == ')' || t == '}' || t == ']') {
        if (stack.removeLast() != t) {
          throw FormatException('unbalanced "$t"');
        }
      }
    }
  }
}
