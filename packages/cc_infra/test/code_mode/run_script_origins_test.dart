import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_infra/src/code_mode/run_script_origins.dart';
import 'package:test/test.dart';

/// Which execution a script's nested call belongs to: the one the execution
/// service registered while the script runs, and none otherwise. And what
/// each script may still ask of a person.
void main() {
  late RunScriptOrigins origins;

  setUp(() => origins = RunScriptOrigins(runId: 'run-1'));

  ScriptCallOrigin origin(String parent, [String? execution]) =>
      ScriptCallOrigin(parentToolCallId: parent, executionId: execution);

  test('before a script registers, no execution is named', () {
    expect(origins.originOf('toolu_a'), origin('toolu_a'));
  });

  test('while a script runs, the id the service chose; after it ends, none '
      'again', () {
    origins.begin('toolu_a', 'run-1/toolu_a#2');
    expect(origins.originOf('toolu_a'), origin('toolu_a', 'run-1/toolu_a#2'));
    expect(
      origins.originOf('toolu_b'),
      origin('toolu_b'),
      reason: 'another call is not that script',
    );

    origins.end('toolu_a', 'run-1/toolu_a#2');
    expect(origins.originOf('toolu_a'), origin('toolu_a'));
  });

  test('an ending script never takes a later one\'s id away', () {
    origins
      ..begin('toolu_a', 'run-1/toolu_a')
      ..begin('toolu_a', 'run-1/toolu_a#2')
      ..end('toolu_a', 'run-1/toolu_a');
    expect(origins.originOf('toolu_a').executionId, 'run-1/toolu_a#2');
  });

  test('each script has its own approval budget, kept while it runs', () {
    origins.begin('toolu_a', 'run-1/toolu_a');
    final a = origins.approvalsOf('toolu_a')..asking();
    // Registering the same execution again keeps what it asked.
    origins.begin('toolu_a', 'run-1/toolu_a');
    expect(origins.approvalsOf('toolu_a').asked, 1);
    expect(identical(origins.approvalsOf('toolu_a'), a), isTrue);

    // A later script under the same call id starts again.
    origins.begin('toolu_a', 'run-1/toolu_a#2');
    expect(origins.approvalsOf('toolu_a').asked, 0);
  });

  test('a parent nothing registered keeps one budget for the run', () {
    origins.approvalsOf('toolu_x').answered(approved: false, unanswered: false);
    expect(origins.approvalsOf('toolu_x').declined, isTrue);
    expect(origins.approvalsOf('toolu_y').declined, isFalse);
  });

  test('refuses empty ids', () {
    expect(() => RunScriptOrigins(runId: ''), throwsArgumentError);
    expect(() => origins.begin('', 'x'), throwsArgumentError);
    expect(() => origins.begin('toolu_a', ''), throwsArgumentError);
    expect(() => origins.originOf(''), throwsArgumentError);
  });
}
