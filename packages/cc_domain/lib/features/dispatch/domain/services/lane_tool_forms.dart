import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart'
    show AdapterTransport;
import 'package:cc_harness/context.dart' show ToolCallForm, ToolCallForms;

/// How a run on [transport] in [mode] calls a tool, for a text written
/// before its tool surface is built (the per-turn prompt).
///
/// [hasRepl] is whether the server's code mode runner can run scripts now
/// (the dispatch's `codeExecutions` availability, the value the live run's
/// surface is built from). With it, the mode's direct tools (its direct
/// names and pinned verbs) are called directly and every other tool from a
/// `repl` script, on every transport: Claude Code and ACP runs get `repl`
/// through the MCP endpoint, which redirects a script-only tool to it.
/// Without it, every tool is called directly. On Claude Code and ACP a
/// direct call is the tool's name in plain words: its tools are MCP tools
/// under their own names. A run whose surface is known names tools through
/// its own forms (`toolFormsOver`) instead.
ToolCallForms laneToolForms({
  required AdapterTransport? transport,
  required Mode mode,
  required bool hasRepl,
}) {
  final direct = transport == AdapterTransport.harness
      ? ToolCallForm.direct
      : ToolCallForm.plain;
  if (!hasRepl) {
    return (_) => direct;
  }
  final names = {
    ...ModeToolPolicy.directNamesFor(mode),
    ...profileFor(mode).pinnedVerbs,
  };
  return (tool) => names.contains(tool) ? direct : ToolCallForm.script;
}
