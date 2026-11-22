import 'package:cc_domain/features/code_mode/domain/services/script_fix_hints.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_result_formatter.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:test/test.dart';

/// What a script that hit a limit is told to do next, and the return budget
/// a script reads as `limits().returnBudgetChars`.
void main() {
  group('ScriptFixHints', () {
    test('the timeout text names every way to finish in time', () {
      expect(
        ScriptFixHints.timeout(stores: true),
        'To finish in time: return partial results before the limit runs '
        'out (`limits().wallMsRemaining` and `cpuMsRemaining` say what is '
        'left), `store()` progress so the next script continues from it, '
        'pass a larger `timeout_ms`, or split the work into several scripts.',
      );
    });

    test('the output text names keep and the return budget', () {
      expect(
        ScriptFixHints.output(keeps: true),
        'Return counts, digests and the part you need, not whole payloads: '
        'filter in the script, `keep(value, label)` a large intermediate for '
        'a later script, and check `limits().returnBudgetChars`, how much of '
        'what you return is read whole.',
      );
    });

    test('the call limit text names the limit and the fixes', () {
      expect(
        ScriptFixHints.callLimit(500, stores: true),
        'This script has made 500 tool calls, its limit. Return what you '
        'have and `store()` progress, then continue in another script; or '
        'make fewer calls, one that lists or searches many items instead of '
        'one per item.',
      );
    });

    test('a run that may not store or keep is not told to', () {
      expect(
        ScriptFixHints.timeout(stores: false),
        'To finish in time: return partial results before the limit runs '
        'out (`limits().wallMsRemaining` and `cpuMsRemaining` say what is '
        'left), pass a larger `timeout_ms`, or split the work into several '
        'scripts.',
      );
      expect(
        ScriptFixHints.output(keeps: false),
        'Return counts, digests and the part you need, not whole payloads: '
        'filter in the script, and check `limits().returnBudgetChars`, how '
        'much of what you return is read whole.',
      );
      expect(
        ScriptFixHints.callLimit(500, stores: false),
        'This script has made 500 tool calls, its limit. Return what you '
        'have, then continue in another script; or make fewer calls, one '
        'that lists or searches many items instead of one per item.',
      );
    });

    test('each limit kind gets its fix, other kinds none', () {
      String? fix(String? kind) =>
          ScriptFixHints.forKind(kind, stores: true, keeps: false);
      expect(
        fix(CodeExecutionErrorKind.deadline),
        ScriptFixHints.timeout(stores: true),
      );
      expect(
        fix(CodeExecutionErrorKind.cpu),
        ScriptFixHints.timeout(stores: true),
      );
      expect(
        fix(CodeExecutionErrorKind.output),
        ScriptFixHints.output(keeps: false),
      );
      expect(fix(CodeExecutionErrorKind.scriptError), isNull);
      expect(fix(null), isNull);
      expect(
        ScriptFixHints.withFix(
          'Ran out of time.',
          'cpu',
          stores: false,
          keeps: false,
        ),
        'Ran out of time.\n${ScriptFixHints.timeout(stores: false)}',
      );
      expect(
        ScriptFixHints.withFix(null, 'output', stores: true, keeps: true),
        ScriptFixHints.output(keeps: true),
      );
      expect(
        ScriptFixHints.withFix(
          'Threw.',
          'script_error',
          stores: true,
          keeps: true,
        ),
        'Threw.',
      );
    });
  });

  group('returnBudgetChars', () {
    const formatter = ScriptResultFormatter();

    test('is the longest output a budget keeps whole', () {
      for (final tokens in [1, 100, 2000, 10000, 50000]) {
        final chars = formatter.returnBudgetChars(tokens);
        expect(formatter.exceedsBudget('x' * chars, tokens), isFalse);
        expect(formatter.exceedsBudget('x' * (chars + 1), tokens), isTrue);
      }
    });

    test('is what the default budget states', () {
      expect(formatter.returnBudgetChars(10000), 38000);
    });
  });
}
