import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/services/script_globals.dart';
import 'package:test/test.dart';

/// The runner's prelude defines what a script has; [ScriptGlobals] documents
/// it. Every name the prelude gives a script must have a row or be in
/// [ScriptGlobals.documentedElsewhere], and no row may name something the
/// prelude lacks, so a global added to (or removed from) the runner fails
/// here until its row follows.
void main() {
  // The test runs from packages/cc_domain. A Windows checkout may have CRLF
  // line endings; the patterns below match on `\n`.
  final prelude = File(
    '../cc_natives/native/codemode/runner/src/prelude.js',
  ).readAsStringSync().replaceAll('\r\n', '\n');

  /// `define('<name>', …)`, the `tools` property and the members of each
  /// object a define names (`models.embed`).
  Set<String> preludeGlobals() {
    final defined = {
      for (final m in RegExp(
        r"\bdefine\('([A-Za-z_$][\w$]*)'",
      ).allMatches(prelude))
        m.group(1)!,
    };
    final tools = RegExp(
      r"ObjectDefineProperty\(global, '(\w+)'",
    ).allMatches(prelude).map((m) => m.group(1)!);
    final names = {...defined, ...tools};
    // An object a define names: its methods are what a script calls.
    for (final name in defined) {
      final object = RegExp(
        'const $name = \\{\\n([\\s\\S]*?)\\n  \\};',
      ).firstMatch(prelude);
      if (object == null) {
        continue;
      }
      final methods = RegExp(
        r'^    (\w+)\(',
        multiLine: true,
      ).allMatches(object.group(1)!).map((m) => m.group(1)!).toList();
      if (methods.isEmpty) {
        continue;
      }
      names
        ..remove(name)
        ..addAll([for (final method in methods) '$name.$method']);
    }
    return names;
  }

  test('the prelude is read: its defines, `tools` and the models methods', () {
    final names = preludeGlobals();
    expect(
      names,
      containsAll([
        'tools',
        'store',
        'ALL_TOOLS',
        'models.embed',
        'models.rank',
        'models.classify',
      ]),
    );
    // `models` is replaced by its methods; `console` holds functions as
    // properties, not methods, and stays itself.
    expect(names, isNot(contains('models')));
    expect(names, contains('console'));
  });

  test('every global the prelude defines has a row or is documented '
      'elsewhere, and every row names one the prelude defines', () {
    final names = preludeGlobals();
    final rows = {for (final g in ScriptGlobals.all) g.name};
    final undocumented = {
      for (final n in names)
        if (!rows.contains(n) && !ScriptGlobals.documentedElsewhere.contains(n))
          n,
    };
    expect(undocumented, isEmpty, reason: 'add a ScriptGlobals row');
    expect(rows.difference(names), isEmpty, reason: 'the prelude lacks it');
    expect(
      ScriptGlobals.documentedElsewhere.difference(names),
      isEmpty,
      reason: 'documentedElsewhere names one the prelude lacks',
    );
    expect(rows.intersection(ScriptGlobals.documentedElsewhere), isEmpty);
  });

  test('every row is complete and its call form uses its name', () {
    for (final g in ScriptGlobals.all) {
      expect(g.call, contains('${g.name}('), reason: g.name);
      expect(g.signature, startsWith('${g.name}('), reason: g.name);
      expect(g.summary, endsWith('.'), reason: g.name);
      expect(g.returns, endsWith('.'), reason: g.name);
    }
    expect({
      for (final g in ScriptGlobals.all) g.name,
    }, hasLength(ScriptGlobals.all.length));
  });
}
