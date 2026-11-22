import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';

/// One function a script has that is not a tool (`store`, `models.embed`):
/// what `describeTool` and `searchTools` answer for it, under the namespace
/// [ScriptGlobals.namespace].
///
/// It is never in the catalog: not in `ALL_TOOLS`, not under `tools.`, and no
/// gate decides it. The runner's `prelude.js` defines it; this row only
/// documents it, and `script_globals_pin_test.dart` holds the two together.
class ScriptGlobal {
  /// Creates a row.
  const ScriptGlobal({
    required this.name,
    required this.call,
    required this.summary,
    required this.signature,
    required this.returns,
    required this.listed,
  });

  /// The name a script writes (`store`, `models.embed`).
  final String name;

  /// How a script calls it (`await sleep(ms)`).
  final String call;

  /// What it does, in one sentence.
  final String summary;

  /// Its TypeScript-style signature.
  final String signature;

  /// What a script gets back: the role a tool's `resultNote` has.
  final String returns;

  /// Whether the `repl` description names it ([ScriptGlobals.listedNames]).
  /// The description is pinned at `ReplToolDescription.maxDefinitionBytes`,
  /// so a global added later is found through `searchTools`, `describeTool`
  /// and `describeNamespace("script")` only.
  final bool listed;

  /// The answer `describeTool(name)` gives: marked `kind: "global"` and
  /// namespace `script`, with no `id` and no tier, so it cannot be read as a
  /// tool.
  Map<String, Object?> toJson() => {
    'kind': ScriptGlobals.kind,
    'name': name,
    'namespace': ScriptGlobals.namespace,
    'call': call,
    'summary': summary,
    'signature': signature,
    'returns': returns,
  };
}

/// The script's own functions, documented once.
///
/// The `repl` description lists their names from [all]; `describeTool` and
/// `searchTools` answer from it (a tool of the same name wins);
/// `describeNamespace("script")` lists it.
// ignore: avoid_classes_with_only_static_members
abstract final class ScriptGlobals {
  /// The namespace a global is answered under. Not a tool namespace: it has
  /// no tools, no count and no line in the description's namespace list.
  static const String namespace = ScriptToolNamespace.script;

  /// The `kind` of a global's answer.
  static const String kind = 'global';

  /// What [namespace] holds, for `describeNamespace("script")`.
  static const String namespaceDescription =
      "The script's own functions: not tools, called by name, never through "
      '`tools.`.';

  /// Names `prelude.js` defines for a script that have no row here, because
  /// the `repl` description itself says how to use them: `tools` (the call
  /// form), `console` (output), the lookups `searchTools`, `describeTool` and
  /// `describeNamespace`, and `ALL_TOOLS`.
  static const Set<String> documentedElsewhere = {
    'tools',
    'console',
    'searchTools',
    'describeTool',
    'describeNamespace',
    'ALL_TOOLS',
  };

  /// Every documented global, in the order the description lists them.
  static const List<ScriptGlobal> all = [
    ScriptGlobal(
      name: 'text',
      call: 'text(value)',
      summary:
          'Adds value to what the script returns: a string as it is, '
          'anything else as readable text.',
      signature: 'text(value: unknown): void',
      returns: 'Nothing.',
      listed: true,
    ),
    ScriptGlobal(
      name: 'image',
      call: 'image(block)',
      summary:
          'Adds an image block a tool returned to what the script returns.',
      signature:
          'image(block: { type: "image"; mediaType: string; data: string }): '
          'void',
      returns: 'Nothing; throws a TypeError for anything but an image block.',
      listed: true,
    ),
    ScriptGlobal(
      name: 'store',
      call: 'store(key, value)',
      summary:
          "Keeps a JSON value under key for this conversation's later scripts; "
          'value undefined deletes the key.',
      signature: 'store(key: string, value: unknown): void',
      returns:
          'Nothing. Saved only when the script completes. Throws for a value '
          'that is not JSON or is over the store limits, and in a run with no '
          'conversation.',
      listed: true,
    ),
    ScriptGlobal(
      name: 'load',
      call: 'load(key)',
      summary: 'The value stored under key, by an earlier script or this one.',
      signature: 'load(key: string): unknown',
      returns: 'A fresh copy of the value (not a promise), or undefined.',
      listed: true,
    ),
    ScriptGlobal(
      name: 'sleep',
      call: 'await sleep(ms)',
      summary:
          "Waits ms milliseconds; the wait counts toward the script's "
          'deadline.',
      signature: 'sleep(ms: number): Promise<void>',
      returns: 'A promise that resolves with undefined.',
      listed: true,
    ),
    ScriptGlobal(
      name: 'setTimeout',
      call: 'setTimeout(fn, ms, ...args)',
      summary: 'Calls fn(...args) once, ms milliseconds from now.',
      signature:
          'setTimeout(fn: (...args: unknown[]) => void, ms?: number, '
          '...args: unknown[]): number',
      returns: 'The timer id for clearTimeout. At most 10,000 may be pending.',
      listed: true,
    ),
    ScriptGlobal(
      name: 'clearTimeout',
      call: 'clearTimeout(id)',
      summary: 'Cancels a timer setTimeout started.',
      signature: 'clearTimeout(id: number): void',
      returns: 'Nothing.',
      listed: true,
    ),
    ScriptGlobal(
      name: 'limits',
      call: 'limits()',
      summary: "What is left of this script's budgets, now.",
      signature:
          'limits(): { wallMsRemaining: number; cpuMsRemaining: number; '
          'callsRemaining: number; returnBudgetChars: number; '
          'outputItemsRemaining: number }',
      returns:
          'An object with those five numbers (not a promise). '
          'returnBudgetChars is how many characters of what the script '
          'returns and prints the model reads whole; longer output keeps its '
          'head and tail.',
      listed: true,
    ),
    ScriptGlobal(
      name: 'exit',
      call: 'exit()',
      summary:
          'Ends the script at once as completed, with no return value; what it '
          'already output stays.',
      signature: 'exit(): never',
      returns: 'Never returns.',
      listed: true,
    ),
    ScriptGlobal(
      name: 'models.embed',
      call: 'await models.embed(texts)',
      summary: "Embeds texts with the server's on-device embedding model.",
      signature: 'models.embed(texts: string[]): Promise<number[][]>',
      returns:
          'One vector per text, in order. At most '
          '${CodeModeLimits.maxModelBatch} texts of '
          '${CodeModeLimits.maxModelTextBytes ~/ 1024} KiB a call; rejects '
          'when the server has no embedding model.',
      listed: true,
    ),
    ScriptGlobal(
      name: 'models.rank',
      call: 'await models.rank(query, candidates, { top })',
      summary: 'Ranks candidates by closeness in meaning to query.',
      signature:
          'models.rank(query: string, candidates: string[], '
          'options?: { top?: number }): Promise<{ index: number; '
          'score: number; text: string }[]>',
      returns:
          'Best first: the position in candidates, the cosine score and the '
          'text; top keeps that many.',
      listed: true,
    ),
    ScriptGlobal(
      name: 'models.classify',
      call: 'await models.classify(texts, labels)',
      summary: 'Gives each text the label closest to it in meaning.',
      signature:
          'models.classify(texts: string[], labels: string[]): '
          'Promise<{ label: string; index: number; score: number }[]>',
      returns:
          'One result per text, in order: the label, its position in labels '
          'and the cosine score.',
      listed: true,
    ),
    ScriptGlobal(
      name: 'storedKeys',
      call: 'storedKeys()',
      summary:
          'Lists the keys store() keeps for this conversation, with the size '
          'of each value.',
      signature: 'storedKeys(): { key: string; bytes: number }[]',
      returns:
          'An array of {key, bytes} (not a promise): what load(key) can read, '
          "this script's own writes included; empty in a run without a store.",
      listed: false,
    ),
    ScriptGlobal(
      name: 'history',
      call: 'await history({ start, limit, role, tool })',
      summary:
          "Pages this conversation's transcript, oldest first: messages, each "
          'tool call with its input and output, folded turns, and each '
          'compaction where it happened (a subagent: its own run only).',
      signature:
          'history(options?: { start?: string | 0; limit?: number; role?: '
          'string | string[]; tool?: string | string[]; row?: string; '
          'offset?: number }): Promise<{ rows: { id: string; role: string; '
          'tool?: string; text: string; folded?: true; cut?: true; '
          'full_length?: number; output_handle?: string; output_lost?: true; '
          'at: string }[]; message_count?: number; next_start: string | '
          'null }>',
      returns:
          'At most ${CodeModeLimits.maxHistoryRows} rows and 64 KiB of text a '
          'call; role is person, agent, tool, system or compaction. Omit '
          "start (or pass 0) for the first page, or a page's next_start (an "
          'opaque place in the conversation, not a row count: a message '
          'reverted or deleted between pages moves it nowhere); a call '
          'scans at most ${CodeModeLimits.historyScanMessages} messages, so a '
          'filtered page can come back short or empty with next_start set: '
          'read on until it is null. message_count is how many messages the '
          'conversation holds. A row cut at 16,384 characters has cut and '
          'full_length: history({row: id, offset}) returns {row_id, offset, '
          'text, full_length, next_offset}. A tool output the run cut has '
          'output_handle for loadOutput.',
      listed: false,
    ),
    ScriptGlobal(
      name: 'outputs',
      call: 'await outputs({ limit, tool })',
      summary:
          "Lists the tool outputs this conversation's runs stored whole, "
          'newest first, with the handles loadOutput and read_output read '
          '(a subagent: its own run only).',
      signature:
          'outputs(options?: { limit?: number; tool?: string }): '
          'Promise<{ outputs: { handle: string; tool: string; label?: '
          'string; chars: number; bytes: number; is_error: boolean; at: '
          'string }[]; total: number }>',
      returns:
          'At most ${CodeModeLimits.maxHistoryRows} entries a call; total '
          'counts every match. Values kept with keep() are listed under tool '
          '"keep" with their label.',
      listed: false,
    ),
    ScriptGlobal(
      name: 'loadOutput',
      call: 'await loadOutput(handle, { offset, limit })',
      summary:
          'Reads a stored tool output or a kept value by its handle, a page '
          'at a time.',
      signature:
          'loadOutput(handle: string, options?: { offset?: number; limit?: '
          'number }): Promise<{ handle: string; text: string; offset: number; '
          'total_chars: number; next_offset: number | null }>',
      returns:
          'At most ${CodeModeLimits.maxLoadOutputChars} characters a call '
          '(the default). Only handles of this run (a subagent: of its own '
          'run) are found. JSON.parse the text of a kept object once you '
          'have read all of it.',
      listed: false,
    ),
    ScriptGlobal(
      name: 'keep',
      call: 'await keep(value, label)',
      summary:
          'Keeps a large intermediate value for later scripts, past the '
          "store's limits, and gives back a handle to read it with "
          'loadOutput.',
      signature:
          'keep(value: unknown, label: string): Promise<{ handle: string; '
          'label: string; chars: number }>',
      returns:
          'A handle, usable at once in this script; saved only when the '
          'script completes. A string is kept as it is, anything else as '
          'JSON. At most 1 MiB a value, ${CodeModeLimits.maxKeepsPerRun} '
          'values and 16 MiB a run; refused in a read-only run.',
      listed: false,
    ),
  ];

  /// The globals [name] names: the one row of that name, every
  /// `<name>.*` row for an object (`models`), or none.
  static List<ScriptGlobal> named(String name) {
    final exact = [
      for (final g in all)
        if (g.name == name) g,
    ];
    if (exact.isNotEmpty) {
      return exact;
    }
    return [
      for (final g in all)
        if (g.name.startsWith('$name.')) g,
    ];
  }

  /// The row whose [ScriptGlobal.name] is [name], or null.
  static ScriptGlobal? byName(String name) {
    for (final g in all) {
      if (g.name == name) {
        return g;
      }
    }
    return null;
  }

  /// The names the description lists, each in backticks, the members of an
  /// object once as `<object>.*`: `` `text`, …, `models.*` ``. Only the
  /// [ScriptGlobal.listed] rows.
  static String listedNames() {
    final names = <String>[];
    for (final g in all) {
      if (!g.listed) {
        continue;
      }
      final dot = g.name.indexOf('.');
      final listed = dot < 0 ? g.name : '${g.name.substring(0, dot)}.*';
      if (!names.contains(listed)) {
        names.add(listed);
      }
    }
    return names.map((n) => '`$n`').join(', ');
  }
}
