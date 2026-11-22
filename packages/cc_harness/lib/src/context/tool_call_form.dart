/// How a text the model reads names a tool: only in a form the run can use.
///
/// A tool may be direct for one run, callable only from a `repl` script for
/// another, and an MCP tool under its own name for a third (Claude Code).
/// Every model-facing text that suggests a call (a wake's follow-up, a
/// refusal's next step) names the tool through a [ToolCallForms] of the run
/// it is written for, so it never points at a call the run cannot make.
library;

/// The form a tool takes in a text written for one run.
enum ToolCallForm {
  /// On the run's tool list (resident, or deferred and callable by name):
  /// `name({…})`.
  direct,

  /// Callable only from a `repl` script: `await tools.name({…})`.
  script,

  /// Named in plain words: neither form is known to work, as on Claude Code,
  /// where the tool is an MCP tool under its own name: `name(…)`.
  plain,
}

/// The form each tool takes for one run, by name.
typedef ToolCallForms = ToolCallForm Function(String tool);

/// Plain words for every tool: what a text says when it knows nothing of the
/// run's tools.
ToolCallForm plainToolForm(String tool) => ToolCallForm.plain;

/// The forms of a run whose surface is known: a tool in [scriptOnly] is
/// called from a script, one in [callable] directly, and any other in plain
/// words.
ToolCallForms toolFormsOver({
  required Iterable<String> callable,
  required Iterable<String> scriptOnly,
}) {
  final direct = callable.toSet();
  final scripts = scriptOnly.toSet();
  return (tool) => scripts.contains(tool)
      ? ToolCallForm.script
      : direct.contains(tool)
      ? ToolCallForm.direct
      : ToolCallForm.plain;
}

/// [tool] called with [args] (the inside of an object literal, such as
/// `id: "w1"`; null for no arguments) in [form].
String toolCallText(ToolCallForm form, String tool, [String? args]) =>
    switch (form) {
      ToolCallForm.direct => '$tool({${args ?? ''}})',
      ToolCallForm.script => 'await tools.$tool({${args ?? ''}})',
      ToolCallForm.plain => args == null ? tool : '$tool($args)',
    };

/// [tool] with [args] in the form [forms] gives it.
String toolCallIn(ToolCallForms forms, String tool, [String? args]) =>
    toolCallText(forms(tool), tool, args);
