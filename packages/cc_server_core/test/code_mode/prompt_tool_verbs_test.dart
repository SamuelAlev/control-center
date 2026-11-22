import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/capability_preamble.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/mode_prompts.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:test/test.dart';

import 'script_callable_pin_test.dart'
    show harnessScriptCallable, mcpScriptCallable;

/// The base prompt and the mode prompts serve a run with `repl` and one
/// without. A tool outside the direct set is script-only in the first, so a
/// sentence that tells the model to call it directly costs a refused call and
/// a round trip every time. They name such a tool as something to use; only
/// a tool the run has directly is something to call.
///
/// Every tool these prompts name must also still exist: the pins in
/// `script_callable_pin_test.dart` hold every tool class's name, read off its
/// source, so a name missing there is a stale one.
void main() {
  const notTools = _notTools;
  final known = {...harnessScriptCallable.keys, ...mcpScriptCallable.keys};

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('cc_prompt_verbs_'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<String> basePrompt() async =>
      (await const HarnessSystemPromptBuilder().build(
        workspaceId: 'ws-1',
        workingDirectory: dir.path,
      )).baseInstructions;

  /// The mode prompt on the widest surface of each lane: the given tools
  /// script-only with `repl`, deferred without.
  List<String> modePrompts(Mode mode, List<String> notDirect) {
    final profile = profileFor(mode);
    final direct = profile.toToolResidencySpec().residentNames.toList();
    return [
      buildCapabilityPreamble(
        profile,
        materializedToolNames: [...direct, 'repl'],
        hasRepl: true,
        scriptToolNames: notDirect,
      ),
      buildCapabilityPreamble(
        profile,
        materializedToolNames: direct,
        deferredToolNames: notDirect,
      ),
    ];
  }

  const notDirect = ['open_pull_request', 'stack_cut', 'lsp', 'list_agents'];

  test('every tool the base prompt and the mode prompts name exists', () async {
    final base = toolMentions(await basePrompt(), notTools: notTools);
    // Non-vacuity: the base prompt's tool sentences are read.
    expect(
      base,
      containsAll([
        'read',
        'ask_user',
        'render_media',
        'stack_cut',
        'stack_publish',
        'open_pull_request',
        'comment_on_pull_request',
        'update_pull_request',
      ]),
    );
    expect(base.difference(known), isEmpty, reason: 'base prompt');

    for (final mode in Mode.values) {
      for (final prompt in modePrompts(mode, notDirect)) {
        final named = toolMentions(prompt, notTools: notTools);
        expect(named.difference(known), isEmpty, reason: mode.name);
      }
      // A mode's own block also names arguments, categories and roles in
      // backticks, so it is held to this where it names a tool to call or
      // not to call (`mode_capability_parity_test` checks the rest).
      final block = buildModeSystemBlock(mode);
      final named = {for (final c in callClauses(block)) ...c.names};
      expect(named.difference(known), isEmpty, reason: '${mode.name} block');
    }
  });

  test('the base prompt calls no tool outside the direct set', () async {
    final called = calledTools(await basePrompt());
    expect(
      called.difference(ModeToolPolicy.directTools),
      isEmpty,
      reason: 'say "use `x`" for a tool that may be script-only',
    );
  });

  test('a mode prompt calls only the tools its mode has directly', () {
    final seen = <String>{};
    for (final mode in Mode.values) {
      final direct = profileFor(mode).toToolResidencySpec().residentNames;
      for (final prompt in [
        ...modePrompts(mode, notDirect),
        buildModeSystemBlock(mode),
      ]) {
        final called = calledTools(prompt);
        expect(called.difference(direct), isEmpty, reason: mode.name);
        seen.addAll(called);
      }
    }
    // Non-vacuity: the required verbs, the exit verb and the discovery verb
    // are each read as called.
    expect(
      seen,
      containsAll([
        'submit_plan',
        'exit_plan_mode',
        'propose_orchestration',
        'search_tools',
      ]),
    );
    // The direct set the base prompt is held to is part of every mode's.
    for (final mode in Mode.values) {
      expect(
        profileFor(mode).toToolResidencySpec().residentNames,
        containsAll(ModeToolPolicy.directTools),
      );
    }
  });

  test('the checks catch a call of a tool that is not direct', () {
    expect(
      calledTools(
        'Push the branch and call open_pull_request; then calling '
        '`stack_cut` or `stack_publish`, call a tool directly.',
      ),
      {'open_pull_request', 'stack_cut', 'stack_publish'},
    );
    expect(
      calledTools(
        'Write a `repl` script for many calls, a loop; use `stack_cut`. '
        'They are callable from `repl`. Do NOT call `create_ticket`, '
        '`close_ticket` or `fail_ticket` here; never call `x_y`.',
      ),
      isEmpty,
    );
    expect(
      {
        for (final c in callClauses(
          'Do NOT call `hire_agent`, `a_b` or `c_d`.',
        ))
          if (c.negated) ...c.names,
      },
      {'hire_agent', 'a_b', 'c_d'},
    );
    expect(toolMentions('use `no_such_tool`', notTools: notTools), {
      'no_such_tool',
    });
  });
}

/// Words in a prompt that are not tools: the stack tool's `at` argument and
/// a checklist item's status.
const _notTools = {'at', 'in_progress'};

final _backticked = RegExp(r'`([a-z][a-z0-9_]*)`');
final _snake = RegExp(r'(?<![\w`.])([a-z][a-z0-9]*(?:_[a-z0-9]+)+)(?![\w`(])');
final _call = RegExp(r'\b[Cc]all(?:s|ing|ed)?\b');
final _clauseEnd = RegExp(r'[.;:(—]|,(?!\s*(?:or\s+|and\s+)?`)');
final _negation = RegExp(r'(?:\bnot|\bnever)\s+$', caseSensitive: false);

/// The tool names [text] mentions: every backticked lowercase identifier and
/// every bare snake_case word, less [notTools].
Set<String> toolMentions(String text, {required Set<String> notTools}) => {
  for (final m in _backticked.allMatches(text)) m.group(1)!,
  for (final m in _snake.allMatches(text)) m.group(1)!,
}.difference(notTools);

/// Every clause that follows a "call", "calls", "calling" or "called":
/// the tool names in it, and whether it is a "do not" / "never" call. A list
/// of names (`a`, `b` or `c`) stays one clause.
List<({Set<String> names, bool negated})> callClauses(String text) => [
  for (final m in _call.allMatches(text))
    (
      names: toolMentions(_clause(text.substring(m.end)), notTools: _notTools),
      negated: _negation.hasMatch(
        text.substring(m.start < 8 ? 0 : m.start - 8, m.start),
      ),
    ),
];

String _clause(String rest) =>
    rest.substring(0, _clauseEnd.firstMatch(rest)?.start ?? rest.length);

/// The tool names [text] tells the model to call: those in a [callClauses]
/// clause that is not a "do not".
Set<String> calledTools(String text) => {
  for (final c in callClauses(text))
    if (!c.negated) ...c.names,
};
