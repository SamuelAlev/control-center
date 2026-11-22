import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_outline/outline_builder.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_outline/outline_lexer.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_outline/outline_statements.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';

/// Reads what a script will do off its text: the places that call tools and
/// the loops, callbacks, `Promise` combinators, branches and functions around
/// them.
///
/// Never throws, and its time is bounded by a budget linear in the text,
/// whatever the text: the lexer and every forward scan of the recogniser
/// spend from one [scriptOutlineWorkBudget], and a parse that would spend
/// more gives up. Scripts a model writes honestly spend a small fraction of
/// it. Text it cannot follow (longer than any script the runner accepts,
/// unterminated strings, templates or comments, brackets that do not match,
/// nesting deeper than [maxScriptOutlineDepth], more work than the budget)
/// gives an outline marked [ScriptOutline.unparsed], never a partial tree.
///
/// This is not an ECMAScript parser. The text becomes tokens, the tokens a
/// tree of matched brackets, and a small recogniser walks that tree for the
/// constructs in [ScriptOutlineNode]'s subclasses. Everything else is walked
/// in source order for the calls inside it.
ScriptOutline parseScriptOutline(String source) =>
    measureScriptOutline(source).outline;

/// [parseScriptOutline], with the work it spent and the budget it had:
/// [scriptOutlineWorkBudget] of the text's length, or [budget] when given (a
/// smaller one shows a parse giving up).
({ScriptOutline outline, int work, int budget}) measureScriptOutline(
  String source, {
  int? budget,
}) {
  budget ??= scriptOutlineWorkBudget(source.length);
  if (source.length > CodeModeLimits.maxSourceBytes) {
    return (
      outline: ScriptOutline.unparsed(ScriptOutlineFailure.tooLong),
      work: 0,
      budget: budget,
    );
  }
  final work = OutlineWork(budget);
  try {
    final lexer = OutlineLexer(source, work)..run();
    final items = buildOutlineTree(
      lexer.tokens,
      maxDepth: maxScriptOutlineDepth,
    );
    final walker = OutlineWalker(source, work, maxNodes: maxScriptOutlineNodes);
    final top = <DraftNode>[];
    walker.walk(items, 0, items.length, top);
    return (
      outline: freezeOutline(source, top),
      work: work.used,
      budget: budget,
    );
  } on OutlineBail catch (bail) {
    return (
      outline: ScriptOutline.unparsed(bail.failure),
      work: work.used,
      budget: budget,
    );
  }
}

/// Work units a parse may spend per UTF-16 unit of text. Honest scripts
/// measure between 1 and 3 (the parser tests, the shipped examples and
/// generated loops, calls and branches); 16 leaves a wide margin.
const int scriptOutlineWorkFactor = 16;

/// Work units any parse may spend, however short the text.
const int scriptOutlineWorkFloor = 4096;

/// The work a parse of a text of [length] UTF-16 units may spend.
int scriptOutlineWorkBudget(int length) =>
    scriptOutlineWorkFactor * length + scriptOutlineWorkFloor;

/// The deepest bracket nesting [parseScriptOutline] follows.
const int maxScriptOutlineDepth = 64;

/// The most nodes [parseScriptOutline] builds.
const int maxScriptOutlineNodes = 4096;
