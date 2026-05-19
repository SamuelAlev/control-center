import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;

/// One structural match, with the file it came from.
class _Sited {
  const _Sited(this.path, this.match);
  final String path;
  final AstMatch match;
}

/// What a structural search produced.
class _Outcome {
  const _Outcome({
    this.error,
    this.matches = const [],
    this.sources = const {},
    this.languageId = '',
    this.truncated = false,
  });

  final String? error;
  final List<_Sited> matches;

  /// The content each matched file had when it was parsed — the `before` a
  /// staged rewrite is validated against.
  final Map<String, String> sources;
  final String languageId;
  final bool truncated;
}

String _languageHelp() {
  final ids = kLanguageByExtension.values.toSet().toList()..sort();
  return 'Supported: ${ids.join(', ')}.';
}

/// Resolves the language: an explicit id, or inferred from a scoped file path.
String? _languageFor(Map<String, dynamic> args, String? path) {
  final explicit = args['language'];
  if (explicit is String && explicit.isNotEmpty) {
    return kLanguageByExtension.containsValue(explicit) ? explicit : null;
  }
  return path == null ? null : languageIdForPath(path);
}

/// Runs a structural search, shared by `ast_grep` and `ast_edit`.
///
/// **Why this sits on the tree-sitter we already link, not on ast-grep.**
/// `cc_natives` already loads `libtree-sitter` plus the grammars, with a
/// compiled-query cache and a language table. A second structural engine would
/// mean a second parser, a second grammar set to build and stage on every
/// platform in the natives matrix, and two answers to "what is a call
/// expression". The matching layer is a few hundred lines of pure Dart over
/// trees we were parsing anyway.
Future<_Outcome> _search({
  required TreeSitterParser parser,
  required Map<String, dynamic> args,
  required String pattern,
  required String workingDirectory,
  required int maxResults,
  int maxFiles = 2000,
}) async {
  final rawPath = args['path'];
  final scoped = rawPath is String && rawPath.isNotEmpty ? rawPath : null;
  final languageId = _languageFor(args, scoped);
  if (languageId == null) {
    return _Outcome(
      error:
          'Could not tell which language to parse. Pass `language`, or scope '
          '`path` to a file. ${_languageHelp()}',
    );
  }

  final root = scoped == null
      ? workingDirectory
      : p.isAbsolute(scoped)
      ? p.normalize(scoped)
      : p.normalize(p.join(workingDirectory, scoped));
  if (root != workingDirectory && !p.isWithin(workingDirectory, root)) {
    return const _Outcome(error: 'path must stay inside the workspace.');
  }

  // Compiled, not parsed: a fragment needs a scaffold to land in, and the
  // wrong one silently changes what the pattern means — `dispose(x)` parsed at
  // Dart's top level is a valid FUNCTION SIGNATURE, so a matcher built on the
  // bare parse looks for declarations and reports "no matches" for every call.
  final CompiledAstPattern? compiled;
  try {
    compiled = compileAstPattern(
      parser: parser,
      languageId: languageId,
      pattern: pattern,
    );
  } on TreeSitterUnavailable catch (e) {
    return _Outcome(error: e.toString());
  }
  if (compiled == null) {
    return _Outcome(
      error:
          'Could not parse that pattern as $languageId in any context '
          '(statement, expression, class member or declaration). Check the '
          'fragment is valid $languageId with the metavariables read as '
          'identifiers.',
    );
  }
  final matcher = AstPatternMatcher(
    compiled.node,
    sequenceMode: compiled.sequenceMode,
  );

  final List<String> paths;
  if (FileSystemEntity.isFileSync(root)) {
    paths = [root];
  } else {
    // The indexer's own walker, so `node_modules`, build output and the rest
    // are skipped by the same rules the code graph uses — a structural search
    // reporting matches in `.dart_tool` is answering about generated code.
    final walked = await const SourceFileWalker().walk(root);
    paths = [
      for (final file in walked)
        if (languageIdForPath(file.absolutePath) == languageId)
          file.absolutePath,
    ].take(maxFiles).toList();
  }

  final matches = <_Sited>[];
  final sources = <String, String>{};
  var truncated = false;
  for (final path in paths) {
    if (matches.length >= maxResults) {
      truncated = true;
      break;
    }
    final String source;
    try {
      source = File(path).readAsStringSync();
    } on FileSystemException {
      continue;
    }
    final tree = parser.parseTree(languageId: languageId, source: source);
    if (tree == null) {
      continue;
    }
    final found = matcher.findAll(tree, limit: maxResults - matches.length);
    if (found.isEmpty) {
      continue;
    }
    sources[path] = source;
    for (final match in found) {
      matches.add(_Sited(path, match));
    }
  }
  return _Outcome(
    matches: matches,
    sources: sources,
    languageId: languageId,
    truncated: truncated,
  );
}

/// Replaces the UTF-8 byte range `[start, end)` of [text].
///
/// Tree-sitter reports BYTE offsets and a Dart string is UTF-16, so slicing the
/// string at those numbers corrupts any file with a non-ASCII character before
/// the match — a bug that only ever shows up on somebody else's file.
String spliceUtf8Range(String text, int start, int end, String replacement) {
  final bytes = utf8.encode(text);
  final head = utf8.decode(bytes.sublist(0, start), allowMalformed: true);
  final tail = utf8.decode(bytes.sublist(end), allowMalformed: true);
  return '$head$replacement$tail';
}

/// Structural search: find code by SHAPE, with metavariables.
///
/// **What it does that `grep` cannot.** `$X` matches any node and `$$$` matches
/// any run of siblings, so `dispose($X)` finds the call however it is spaced,
/// wrapped or commented — and does not find the same characters inside a string
/// or a comment, because the pattern is parsed by the same grammar as the file.
/// The property that makes it a matcher rather than a regex with extra steps is
/// that a metavariable repeated in one pattern must capture the same text:
/// `if ($X != null) $X.dispose()` finds guards that dispose what they tested,
/// and does not find the bug where they dispose something else.
class AstGrepTool extends HarnessTool {
  /// Creates an [AstGrepTool].
  AstGrepTool({
    required TreeSitterParser parser,
    required String workingDirectory,
  }) : _parser = parser,
       _workingDirectory = workingDirectory;

  final TreeSitterParser _parser;
  final String _workingDirectory;

  @override
  String get name => 'ast_grep';

  @override
  String get description =>
      r'Search code by structure rather than by text. `pattern` is a code '
      r'fragment where $NAME matches any node and $$$NAME matches any run of '
      r'arguments or statements. A repeated $NAME must match the same text, so '
      r'"if ($X != null) $X.dispose()" finds guards that dispose what they '
      r'tested. Prefer this over grep for anything shaped like code.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'pattern': {
        'type': 'string',
        'description':
            r'Code fragment to match. $NAME binds one node, $$$NAME binds a '
            r'run of siblings, $_ is a wildcard that binds nothing.',
      },
      'path': {
        'type': 'string',
        'description':
            'File or directory to search. Defaults to the whole workspace.',
      },
      'language': {
        'type': 'string',
        'description': 'Language id. Inferred when `path` names a file.',
      },
      'max_results': {'type': 'integer', 'description': 'Default 50.'},
    },
    'required': ['pattern'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final pattern = args['pattern'];
    if (pattern is! String || pattern.trim().isEmpty) {
      return HarnessToolResult.error('Missing or invalid argument: pattern');
    }
    final raw = args['max_results'];
    final outcome = await _search(
      parser: _parser,
      args: args,
      pattern: pattern,
      workingDirectory: _workingDirectory,
      maxResults: raw is int ? raw.clamp(1, 500) : 50,
    );
    final error = outcome.error;
    if (error != null) {
      return HarnessToolResult.error(error);
    }
    if (outcome.matches.isEmpty) {
      return HarnessToolResult.success(
        'No structural matches. If the pattern is not valid '
        '${outcome.languageId} on its own the parser may not have found the '
        'construct you meant — try a smaller fragment.',
      );
    }

    final buffer = StringBuffer()
      ..writeln(
        '${outcome.matches.length} match'
        '${outcome.matches.length == 1 ? '' : 'es'}'
        '${outcome.truncated ? ' (truncated)' : ''}:',
      );
    for (final sited in outcome.matches) {
      final rel = p.relative(sited.path, from: _workingDirectory);
      buffer
        ..writeln('$rel:${sited.match.node.startLine}')
        ..writeln(_indent(sited.match.node.text));
    }
    return HarnessToolResult.success(buffer.toString().trimRight());
  }

  static String _indent(String text, {int maxLines = 12}) {
    final lines = text.split('\n');
    final shown = lines.take(maxLines).map((l) => '    $l').join('\n');
    return lines.length > maxLines
        ? '$shown\n    … ${lines.length - maxLines} more lines'
        : shown;
  }
}

/// Structural rewrite, staged rather than written.
///
/// **Why it stages.** A structural rewrite is the widest edit an agent can
/// make: one pattern, forty files, and nobody reads the result line by line.
/// Writing it and reporting "done" means the first honest look at the change is
/// a `git diff` afterwards. So this reports what it WOULD do — counts, files,
/// matched sites — and the change lands only when `resolve` commits it. That is
/// also what lets the UI put a diff and an Accept/Discard in front of a human
/// before anything reaches disk.
class AstEditTool extends HarnessTool {
  /// Creates an [AstEditTool].
  AstEditTool({
    required TreeSitterParser parser,
    required String workingDirectory,
    required StagedEditStore store,
  }) : _parser = parser,
       _workingDirectory = workingDirectory,
       _store = store;

  final TreeSitterParser _parser;
  final String _workingDirectory;
  final StagedEditStore _store;

  @override
  String get name => 'ast_edit';

  @override
  String get description =>
      r'Rewrite code by structure. `pattern` selects sites the way ast_grep '
      r'does; `rewrite` is the replacement with the same $NAME metavariables '
      r'substituted back in. NOTHING IS WRITTEN: the change is staged and the '
      r'result names the edit_id to pass to `resolve`.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.write;

  /// Nothing reaches disk here — `resolve` writes. Declared as a file write
  /// anyway: the guardrail question an operator is answering is "may this
  /// agent rewrite files", and staging is the first half of doing so.
  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.fileWriteOutsideWorktree,
  };

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'pattern': {
        'type': 'string',
        'description': r'Code fragment to match, with $NAME metavariables.',
      },
      'rewrite': {
        'type': 'string',
        'description':
            r'Replacement fragment. $NAME is substituted with what the '
            r'pattern captured at that site.',
      },
      'path': {
        'type': 'string',
        'description':
            'File or directory to rewrite. Defaults to the whole workspace.',
      },
      'language': {'type': 'string', 'description': 'Language id.'},
    },
    'required': ['pattern', 'rewrite'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final pattern = args['pattern'];
    final rewrite = args['rewrite'];
    if (pattern is! String || pattern.trim().isEmpty) {
      return HarnessToolResult.error('Missing or invalid argument: pattern');
    }
    if (rewrite is! String) {
      return HarnessToolResult.error('Missing or invalid argument: rewrite');
    }

    final outcome = await _search(
      parser: _parser,
      args: args,
      pattern: pattern,
      workingDirectory: _workingDirectory,
      maxResults: 1000,
    );
    final error = outcome.error;
    if (error != null) {
      return HarnessToolResult.error(error);
    }
    if (outcome.matches.isEmpty) {
      return HarnessToolResult.success(
        'No structural matches — nothing to rewrite.',
      );
    }

    final byFile = <String, List<_Sited>>{};
    for (final sited in outcome.matches) {
      byFile.putIfAbsent(sited.path, () => []).add(sited);
    }

    final files = <StagedFileEdit>[];
    for (final entry in byFile.entries) {
      final before = outcome.sources[entry.key]!;
      // Applied from the LAST site backwards so an earlier replacement never
      // shifts a later one's byte offsets.
      final sites = entry.value.toList()
        ..sort(
          (a, b) => b.match.node.startByte.compareTo(a.match.node.startByte),
        );
      var text = before;
      var applied = 0;
      // Nested matches would corrupt each other: rewriting an inner site and
      // then the outer one replaces text that was already rewritten. The outer
      // site wins and the inner one is dropped, rather than silently mangled.
      var lastStart = 1 << 62;
      var lastEnd = 1 << 62;
      for (final sited in sites) {
        final node = sited.match.node;
        if (node.endByte > lastStart && node.startByte < lastEnd) {
          continue;
        }
        text = spliceUtf8Range(
          text,
          node.startByte,
          node.endByte,
          renderAstRewrite(rewrite, sited.match),
        );
        lastStart = node.startByte;
        lastEnd = node.endByte;
        applied++;
      }
      files.add(
        StagedFileEdit(
          path: entry.key,
          before: before,
          after: text,
          replacements: applied,
        ),
      );
    }
    files.sort((a, b) => a.path.compareTo(b.path));

    final changed = files.where((f) => !f.isNoop).toList();
    if (changed.isEmpty) {
      return HarnessToolResult.success(
        'Every match already reads exactly like the rewrite — nothing to do.',
      );
    }
    final staged = _store.stage(
      tool: name,
      summary: 'ast_edit: $pattern → $rewrite',
      files: changed,
    );
    return HarnessToolResult.success(describeStagedEdit(staged));
  }
}
