import 'dart:io';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/eval/eval_kernel.dart';
import 'package:cc_infra/src/eval/magics_transform.dart';
import 'package:cc_infra/src/harness/eval_tool.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// Drives the kernel against a REAL Python.
///
/// The magics transform is pure and pinned separately; this pins the claims
/// only a live interpreter can settle — that state survives between cells, that
/// a figure comes back as an image, that a bridged tool call re-enters the
/// harness, and that the inactivity budget does not kill a cell waiting on one.
void main() {
  final python = _resolve('python3');

  group('transformPythonMagics', () {
    test('rewrites %pip and evicts the module cache', () {
      // Installing into a live interpreter does nothing for a module that was
      // already imported: the old one stays bound and the version just
      // installed is not the one running.
      final out = transformPythonMagics('%pip install pandas');
      expect(out, contains('"-m", "pip", "install", "pandas"'));
      expect(out, contains('sys.modules.pop'));
    });

    test('rewrites a bang line into a subprocess call', () {
      expect(transformPythonMagics('!ls -la'), contains('shell=True'));
      expect(transformPythonMagics('!ls -la'), contains(r'"ls -la"'));
    });

    test('rewrites %cd', () {
      expect(transformPythonMagics('%cd /tmp'), contains('chdir("/tmp")'));
    });

    test('%%bash consumes the rest of the cell', () {
      final out = transformPythonMagics('%%bash\necho one\necho two');
      expect(out, contains(r'echo one\necho two'));
    });

    test('leaves an unknown cell magic alone rather than mangling it', () {
      // A SyntaxError naming the magic is more honest than a silent rewrite
      // into something that runs and means something else.
      const source = '%%unknown\nwhatever';
      expect(transformPythonMagics(source), source);
    });

    test('leaves ordinary code untouched', () {
      const source = 'x = 1\nprint(x % 2)\n';
      expect(transformPythonMagics(source), source);
    });

    test('does not mistake a modulo for a magic', () {
      expect(transformPythonMagics('y = a % b'), 'y = a % b');
    });

    test('preserves indentation when rewriting inside a block', () {
      final out = transformPythonMagics('if x:\n    !echo hi');
      expect(out, contains('\n    import subprocess'));
    });
  });

  group('transformJsMagics', () {
    test('rewrites a bang line', () {
      expect(transformJsMagics('!ls'), contains('execSync("ls")'));
    });

    test('leaves ordinary code alone', () {
      expect(transformJsMagics('const x = a! + b;'), 'const x = a! + b;');
    });
  });

  group(
    'live python kernel',
    () {
      late Directory root;
      late EvalKernel kernel;

      setUp(() {
        root = Directory.systemTemp.createTempSync('cc_eval');
      });
      tearDown(() async {
        await kernel.dispose();
        await deleteDirBestEffort(root);
      });

      EvalKernel build({KernelToolBridge? bridge, Duration? timeout}) =>
          kernel = EvalKernel(
            language: KernelLanguage.python,
            launcher: HostKernelLauncher(
              workingDirectory: root.path,
              pythonExecutable: python,
            ),
            bridge: bridge,
            inactivityTimeout: timeout ?? const Duration(seconds: 30),
          );

      String textOf(KernelRunOutcome outcome) =>
          outcome.outputs.whereType<KernelText>().map((o) => o.text).join();

      test('prints', () async {
        final outcome = await build().run('print("hello")');
        expect(outcome.isError, isFalse);
        expect(textOf(outcome), contains('hello'));
      });

      test('keeps state between cells', () async {
        // The whole reason this is not `bash python -c`.
        final k = build();
        await k.run('import math\nvalues = [1, 2, 3]');
        final outcome = await k.run('print(sum(values), math.floor(2.7))');
        expect(textOf(outcome).trim(), '6 2');
      });

      test('echoes the trailing expression like a notebook', () async {
        final outcome = await build().run('40 + 2');
        expect(outcome.outputs.whereType<KernelResult>().single.text, '42');
      });

      test('reports a traceback without killing the kernel', () async {
        final k = build();
        final failed = await k.run('1 / 0');
        expect(failed.isError, isTrue);
        expect(failed.error, contains('ZeroDivisionError'));

        // The state from before the error must survive — losing the whole
        // session to one bad cell is what a REPL exists to avoid.
        await k.run('kept = 7');
        expect(textOf(await k.run('print(kept)')).trim(), '7');
      });

      test('streams output as it is produced', () async {
        final outcome = await build().run(
          'for i in range(3):\n    print(i, flush=True)',
        );
        expect(textOf(outcome).trim().split('\n'), ['0', '1', '2']);
      });

      test(
        'truncates a runaway cell rather than filling the context',
        () async {
          final k = EvalKernel(
            language: KernelLanguage.python,
            launcher: HostKernelLauncher(
              workingDirectory: root.path,
              pythonExecutable: python,
            ),
            maxOutputChars: 200,
          );
          kernel = k;
          final outcome = await k.run(
            'for i in range(5000):\n    print("x" * 40)',
          );
          expect(textOf(outcome), contains('output truncated'));
          expect(textOf(outcome).length, lessThan(2000));
        },
      );

      test(
        'a bridged call re-enters the harness and returns its result',
        () async {
          final calls = <String>[];
          final k = build(
            bridge: (name, arguments) async {
              calls.add('$name:${arguments['path']}');
              return (content: 'file contents here', isError: false);
            },
          );
          final outcome = await k.run(
            'print(tool("read", {"path": "lib/a.dart"}))',
          );
          expect(calls, ['read:lib/a.dart']);
          expect(textOf(outcome), contains('file contents here'));
        },
      );

      test('a bridged call SUSPENDS the inactivity budget', () async {
        // The bug this prevents: a cell that fans out to subagents and waits
        // four minutes is not hung, but a wall-clock timeout cannot tell the
        // difference and kills it mid-fanout, losing the kernel's state.
        final k = build(
          timeout: const Duration(milliseconds: 400),
          bridge: (name, arguments) async {
            await Future<void>.delayed(const Duration(milliseconds: 1200));
            return (content: 'slow but fine', isError: false);
          },
        );
        final outcome = await k.run('print(tool("task", {}))');
        expect(
          outcome.timedOut,
          isFalse,
          reason: 'the budget must not run while a bridged call is in flight',
        );
        expect(textOf(outcome), contains('slow but fine'));
      });

      test('a bridge error becomes a Python exception', () async {
        final k = build(
          bridge: (name, arguments) async =>
              (content: 'not allowed', isError: true),
        );
        final outcome = await k.run('tool("write", {})');
        expect(outcome.isError, isTrue);
        expect(outcome.error, contains('not allowed'));
      });

      test('a cell with no bridge wired gets a clear error', () async {
        final outcome = await build().run('tool("read", {})');
        expect(outcome.isError, isTrue);
        expect(outcome.error, contains('no tool bridge'));
      });

      test('reset drops the state', () async {
        final tool = EvalTool(kernelFor: (_) => kernel);
        build();
        await kernel.run('marker = 1');
        final after = await tool.execute({
          'code': 'print("marker" in dir())',
          'reset': true,
        }, const HarnessToolContext(workingDirectory: '/repo'));
        expect(after.content, contains('False'));
      });

      test('the tool surfaces an empty cell honestly', () async {
        final tool = EvalTool(kernelFor: (_) => build());
        final result = await tool.execute({
          'code': 'x = 1',
        }, const HarnessToolContext(workingDirectory: '/repo'));
        expect(result.isError, isFalse);
        expect(result.content, contains('no output'));
      });

      test('is exec tier and not parallel-safe', () {
        final tool = EvalTool(kernelFor: (_) => build());
        expect(tool.approvalTier, ToolApprovalTier.exec);
        expect(tool.actionClasses, contains(ActionClass.processSpawn));
        expect(
          tool.parallelSafe,
          isFalse,
          reason:
              'two cells racing in one interpreter is two halves of two '
              'programs interleaved in one namespace',
        );
      });
    },
    skip: python == null ? 'python3 is not on PATH' : null,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

String? _resolve(String command) {
  try {
    final result = Process.runSync(Platform.isWindows ? 'where' : 'which', [
      command,
    ]);
    if (result.exitCode != 0) {
      return null;
    }
    final first = '${result.stdout}'.split('\n').first.trim();
    return first.isEmpty ? null : first;
  } on Object {
    return null;
  }
}
