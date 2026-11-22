import 'package:cc_domain/features/code_mode/domain/services/script_globals.dart';
import 'package:cc_domain/features/dispatch/domain/modes/read_only_run_profile.dart';
import 'package:test/test.dart';

/// Every function a script has is decided for a read-only run, as every tool
/// is: a read its scripts keep, or a write they are refused. A global added
/// to [ScriptGlobals] fails here until someone decides it.
void main() {
  test('every script global is decided for a read-only run, once', () {
    final names = {for (final g in ScriptGlobals.all) g.name};
    const reads = ReadOnlyRunProfile.scriptGlobalReads;
    const writes = ReadOnlyRunProfile.scriptGlobalWrites;
    expect(reads.intersection(writes), isEmpty);
    expect(
      names.difference({...reads, ...writes}),
      isEmpty,
      reason: 'decide it in ReadOnlyRunProfile.scriptGlobalReads or Writes',
    );
    expect(
      {...reads, ...writes}.difference(names),
      isEmpty,
      reason: 'decided globals that no longer exist',
    );
  });

  test('the globals that keep something past the script are the writes', () {
    expect(ReadOnlyRunProfile.scriptGlobalWrites, {'store', 'keep'});
    expect(
      ReadOnlyRunProfile.scriptGlobalReads,
      containsAll(['load', 'storedKeys', 'history', 'outputs', 'loadOutput']),
    );
  });

  test('the description lists only the globals it always listed', () {
    final listed = ScriptGlobals.listedNames();
    for (final name in ['storedKeys', 'history', 'outputs', 'keep']) {
      expect(listed, isNot(contains('`$name`')), reason: name);
    }
    expect(listed, contains('`store`'));
    expect(listed, contains('`models.*`'));
  });
}
