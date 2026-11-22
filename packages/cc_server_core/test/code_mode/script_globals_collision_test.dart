import 'package:cc_domain/features/code_mode/domain/services/script_globals.dart';
import 'package:test/test.dart';

import 'script_callable_pin_test.dart'
    show harnessScriptCallable, mcpScriptCallable;

/// `describeTool(name)` answers a tool before a script function of the same
/// name, so on a standard surface no first-party tool may take a global's
/// name: the pins hold every first-party tool class's name, read off its
/// source.
///
/// An external server's tool may still have such a name (`store`). Then
/// `describeTool("store")` describes that tool and `tools.store` calls it,
/// while the global `store()` is unchanged and still found by
/// `searchTools` (under the namespace `script`) and
/// `describeNamespace("script")`.
void main() {
  test('no first-party tool has the name of a script function', () {
    final firstParty = {...harnessScriptCallable.keys, ...mcpScriptCallable.keys};
    final globals = {
      for (final g in ScriptGlobals.all) ...[g.name, g.name.split('.').first],
      ...ScriptGlobals.documentedElsewhere,
    };
    expect(firstParty.intersection(globals), isEmpty);
    // Non-vacuity: the pins are read.
    expect(firstParty, containsAll(['read', 'todo_write', 'repl']));
  });
}
