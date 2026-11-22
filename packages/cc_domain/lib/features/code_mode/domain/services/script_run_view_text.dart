import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';

// How the outline's groups and arms read as code in a script's call tree.
// Shared by every client that draws one; the words around them (Loop, For
// each, Queued) are each client's own localized copy.

/// The code a group's header shows after its kind: the loop's header, the
/// list and parameters an each walks, the combinator, the function's
/// signature.
String scriptGroupCode(ScriptOutlineNode node) => switch (node) {
  ScriptLoopNode(:final kind, :final label) => switch (kind) {
    ScriptLoopKind.whileLoop => 'while ($label)',
    ScriptLoopKind.doWhile => 'do … while ($label)',
    _ => 'for ($label)',
  },
  ScriptEachNode(:final callee, :final parameters) => '$callee($parameters)',
  ScriptParallelNode(:final kind) => 'Promise.${kind.name}',
  ScriptFunctionNode(:final name, :final parameters) => '$name($parameters)',
  _ => '',
};

/// An arm as code: `if r.ok`, `else if …`, `else`, `case 'a'`, `default`,
/// `catch (e)`, `finally`. JavaScript keywords, not prose: they stay as
/// written in every language. A conditional expression's arms read as
/// `if`/`else` too, so a reader who does not know `?:` still follows them.
String scriptArmCode(ScriptArmNode arm) {
  final condition = arm.condition;
  return switch (arm.kind) {
    ScriptArmKind.ifArm ||
    ScriptArmKind.conditionalThen => condition == null ? 'if' : 'if $condition',
    ScriptArmKind.elseIfArm =>
      condition == null ? 'else if' : 'else if $condition',
    ScriptArmKind.elseArm || ScriptArmKind.conditionalElse => 'else',
    ScriptArmKind.caseArm => condition == null ? 'case' : 'case $condition',
    ScriptArmKind.defaultArm => 'default',
    ScriptArmKind.catchArm =>
      condition == null ? 'catch' : 'catch ($condition)',
    ScriptArmKind.finallyArm => 'finally',
  };
}

/// How many characters [scriptToolLabel] keeps, its `…` included.
const int scriptToolLabelLength = 24;

// Control (Cc) and format (Cf) characters, the bidirectional controls and
// zero-width joiners among them, and the line and paragraph separators.
final RegExp _invisible = RegExp(r'[\p{Cc}\p{Cf}\u2028\u2029]', unicode: true);

/// A tool's name as a script's call tree draws it, when the name comes from
/// the script's source or from a record: without control and format
/// characters (U+202E cannot turn the line around, U+200D adds nothing
/// unseen) or line separators, and at most [scriptToolLabelLength]
/// characters, the last of them `…` when cut. A name chosen by a script, or
/// a long external tool's, then cannot push what follows it off the line.
String scriptToolLabel(String name) {
  final visible = name.replaceAll(_invisible, '');
  final runes = visible.runes;
  if (runes.length <= scriptToolLabelLength) {
    return visible;
  }
  return '${String.fromCharCodes(runes.take(scriptToolLabelLength - 1))}…';
}
