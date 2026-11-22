import 'dart:convert';

import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_catalog.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_globals.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart';
import 'package:cc_harness/tools.dart';

/// The `repl` tool's name, description and input schema: what the model
/// reads before it writes a script.
///
/// The description declares no tool. It says what a script is, when to write
/// one rather than call a tool directly, how a call behaves, how to look a
/// tool up, what a script receives from each direct tool, and which
/// first-party namespaces hold the rest. Everything in it that names or
/// counts a tool is generated from the run's callable set, so a tool added
/// to the registry is counted without anyone editing this file.
///
/// The description sits in the cached tools prefix, so [build] is a pure
/// function of the callable set. The same tools in any order give the same
/// bytes, and connecting or disconnecting an external MCP server changes
/// nothing, because external tools are never listed or counted here.
// ignore: avoid_classes_with_only_static_members
abstract final class ReplToolDescription {
  /// The tool's name on both surfaces.
  static const String toolName = 'repl';

  /// The most bytes the whole `repl` definition (name, description and the
  /// JSON of [inputSchema]) may take for the standard chat surface, pinned
  /// by cc_server_core's `repl_definition_size_test.dart`.
  static const int maxDefinitionBytes = 4096;

  /// What a script is, when to write one, and how a call behaves. The
  /// script's own functions are listed from [ScriptGlobals.all].
  static final String intro =
      '''
JavaScript, run as the body of an async function (top-level `await` and `return` work). No file system, network, process or modules: the only way out is `tools`.

Write a script for many calls, a loop, a choice on a result, parallel calls, or a large result of which you need a part (filter it, return the part). Call a tool directly for one call whose whole result you will read. Never wrap one direct tool call in a script.

- `await tools.<name>({...})` takes one argument object; it rejects with an Error when the call fails or is denied. Use `Promise.allSettled` for independent calls. Await every call: one pending when the script returns may never run.
'''
      '- A JSON result arrives parsed; one of more than '
      '${CodeModeLimits.maxNestedResultItems} values arrives as text to '
      '`JSON.parse`. Arguments hold at most '
      '${CodeModeLimits.maxCallArgumentItems} values, a command '
      '${GuardDecision.maxActionNameBytes ~/ 1024} KiB.\n'
      '''- A call needing approval, or `ask_user`, waits for the person.
- Only what you `return`, `text(v)`, `image(b)` or `console.log` comes back. Each script starts clean; `store(key, v)` and `load(key)` keep JSON between scripts. Not tools: '''
      '${ScriptGlobals.listedNames()} (more: `describeNamespace(\'script\')`); '
      '`describeTool(name)` explains one. '
      '''Plain JavaScript: no types, `import` or `require`.
- A tool that is not one of your direct tools has no definition in this request. Before the first call to one, look it up with `describeTool(name)` or `searchTools(query)`, unless its exact call shape was already shown to you in this conversation. Never guess a name or an argument. `ALL_TOOLS` lists every tool; `describeNamespace(name)` one namespace.''';

  /// The heading over the result notes of the direct tools.
  static const String directResultsHeading =
      'What direct tools return to a script:';

  /// The heading over the namespace lines.
  static const String namespacesHeading = 'Other tools, by namespace:';

  /// The fixed line that points at external servers' tools, and says what
  /// their result text is: cut at `BridgedMcpTool.maxResultChars` (pinned in
  /// cc_server_core's `external_result_cut_test`), so a cut JSON text does
  /// not parse. Structured content within that size arrives whole.
  static const String externalToolsLine =
      '- Connected MCP servers: find them with `searchTools`; their result '
      'text is cut at 262,144 characters (cut text no longer parses).';

  /// What a refused script's result ends with when the run stops sending
  /// tools through scripts (`CodeExecutionErrorKind.withdrawsScripts`) and
  /// the run has a `search_tools`.
  static const String scriptsWithdrawnSearch =
      'Scripts cannot run right now: load the tools you need with '
      '`search_tools` and call them directly.';

  /// [scriptsWithdrawnSearch] for a run with no `search_tools`, where every
  /// tool is listed by name.
  static const String scriptsWithdrawnDirect =
      'Scripts cannot run right now: call the tools you need directly.';

  /// [scriptsWithdrawnSearch] on the MCP surface, whose `tools/list` then
  /// lists every tool, when that includes its search, `search_tool_bm25`
  /// ([scriptsWithdrawnDirect] when it does not).
  static const String scriptsWithdrawnMcp =
      'Scripts cannot run right now: find the tools you need with '
      '`search_tool_bm25` and call them directly.';

  /// The closing rule about side effects.
  static const String sideEffectsLine =
      "A failed script's calls are not undone: check what it did before you "
      'run it again.';

  /// Builds the description for [catalog].
  ///
  /// After [intro]: one line per direct tool a script may also call
  /// ([directToolNames] that are in [catalog]), in catalog order, from the
  /// tool's own result note (a direct tool with no note gets no line); one
  /// line per first-party namespace with its tool count and description;
  /// the fixed [externalToolsLine]; and [sideEffectsLine].
  static String build(
    ScriptCatalog catalog, {
    Set<String> directToolNames = const {},
  }) {
    final buffer = StringBuffer(intro);
    final notes = <String>[];
    for (final entry in catalog.entries) {
      if (entry.tool.isExternal || !directToolNames.contains(entry.name)) {
        continue;
      }
      final note = _oneLine(entry.tool.resultNote ?? '');
      if (note.isNotEmpty) {
        notes.add('- ${entry.name}: $note');
      }
    }
    if (notes.isNotEmpty) {
      buffer
        ..write('\n\n')
        ..writeln(directResultsHeading)
        ..write(notes.join('\n'));
    }
    buffer
      ..write('\n\n')
      ..writeln(namespacesHeading);
    for (final summary in catalog.namespaces) {
      if (ScriptToolNamespace.isExternal(summary.name)) {
        continue;
      }
      final count = summary.toolCount == 1
          ? '1 tool'
          : '${summary.toolCount} tools';
      final description = summary.description.isEmpty
          ? ''
          : ': ${_oneLine(summary.description)}';
      buffer.writeln('- ${summary.name} ($count)$description');
    }
    buffer
      ..writeln(externalToolsLine)
      ..write('\n')
      ..write(sideEffectsLine);
    return buffer.toString();
  }

  /// The UTF-8 size of the whole definition a provider receives for [build]'s
  /// [description]: the name, the description and the JSON of [inputSchema].
  static int definitionBytes(String description) => utf8
      .encode(
        jsonEncode({
          'name': toolName,
          'description': description,
          'input_schema': inputSchema(),
        }),
      )
      .length;

  /// The `repl` input schema, with the required per-call `description`
  /// merged in so the transcript row has a readable label.
  ///
  /// Constant on purpose: the bounds are the absolute floor and ceiling, not
  /// a workspace's values, so the schema is the same bytes for every run and
  /// the host clamps per call ([CodeModeLimits.clamp]).
  static Map<String, dynamic> inputSchema() => withRequiredCallDescription({
    'type': 'object',
    'properties': {
      'code': {
        'type': 'string',
        'description': 'At most ${CodeModeLimits.maxSourceBytes ~/ 1024} KiB.',
      },
      'timeout_ms': {
        'type': 'integer',
        'minimum': CodeModeLimits.wallClock.floor,
        'maximum': CodeModeLimits.wallClock.ceiling,
        'description':
            'Deadline in ms; the workspace limit '
            '(${CodeModeLimits.wallClock.defaultValue} unless changed) is the '
            'default and the most. Waiting for a person does not count.',
      },
      'max_output_tokens': {
        'type': 'integer',
        'minimum': CodeModeLimits.outputTokens.floor,
        'maximum': CodeModeLimits.outputTokens.ceiling,
        'description':
            'Output budget in tokens; the workspace limit '
            '(${CodeModeLimits.outputTokens.defaultValue} unless changed) is '
            'the default and the most. Longer output keeps its head and tail.',
      },
    },
    'required': ['code'],
    'additionalProperties': false,
  });

  static String _oneLine(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// The `repl` arguments, parsed once for both surfaces so the harness tool
/// and the MCP tool cannot disagree about what a valid call is.
class ReplArguments {
  const ReplArguments._({
    this.error,
    this.code = '',
    this.description = '',
    this.timeoutMs,
    this.maxOutputTokens,
  });

  /// Parses [args]. [error] is set when the call cannot run; the other fields
  /// are meaningful only when it is null.
  ///
  /// The source size is not checked here: an oversized script is recorded as
  /// a refused execution, which needs the parsed source.
  factory ReplArguments.parse(Map<String, dynamic> args) {
    final code = args['code'];
    if (code is! String || code.trim().isEmpty) {
      return const ReplArguments._(error: 'Missing or invalid argument: code');
    }
    final rawDescription = args['description'];
    final description = rawDescription is String
        ? CodeExecution.boundDescription(rawDescription)
        : '';
    if (description.isEmpty) {
      return const ReplArguments._(
        error: 'Missing or invalid argument: description',
      );
    }
    final timeout = _integer(args['timeout_ms']);
    if (timeout.invalid) {
      return const ReplArguments._(
        error: 'Invalid argument: timeout_ms must be an integer',
      );
    }
    final output = _integer(args['max_output_tokens']);
    if (output.invalid) {
      return const ReplArguments._(
        error: 'Invalid argument: max_output_tokens must be an integer',
      );
    }
    return ReplArguments._(
      code: code,
      description: description,
      timeoutMs: timeout.value,
      maxOutputTokens: output.value,
    );
  }

  /// Why the arguments are unusable, or null.
  final String? error;

  /// The script source.
  final String code;

  /// The one-line label, as [CodeExecution.boundDescription] keeps it: one
  /// line of at most [CodeExecution.maxDescriptionChars] characters. A longer
  /// or multi-line label is shortened, never refused.
  final String description;

  /// The model's wall-clock request, when given.
  final int? timeoutMs;

  /// The model's output budget request, when given.
  final int? maxOutputTokens;

  static ({int? value, bool invalid}) _integer(Object? raw) {
    if (raw == null) {
      return (value: null, invalid: false);
    }
    if (raw is int) {
      return (value: raw, invalid: false);
    }
    if (raw is double && raw.isFinite && raw == raw.truncateToDouble()) {
      return (value: raw.toInt(), invalid: false);
    }
    return (value: null, invalid: true);
  }
}
