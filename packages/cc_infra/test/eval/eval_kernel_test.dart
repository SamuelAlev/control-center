import 'dart:io';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/eval/eval_kernel.dart';
import 'package:cc_infra/src/eval/magics_transform.dart';
import 'package:cc_infra/src/harness/eval_tool.dart';
import 'package:cc_infra/src/sandboxing/tool_process_launcher.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// Drives the kernel against a REAL Python.
///
/// The magics transform is pure and pinned separately; this pins the claims
/// only a live interpreter can settle — that state survives between cells, that
/// a figure comes back as an image, and that a cell has no way to call tools.
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

      EvalKernel build({Duration? timeout}) => kernel = EvalKernel(
        language: KernelLanguage.python,
        launcher: HostKernelLauncher(
          workingDirectory: root.path,
          processes: const HostToolProcessLauncher(),
          pythonExecutable: python,
        ),
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
              processes: const HostToolProcessLauncher(),
              pythonExecutable: python,
            ),
            maxOutputChars: 200,
          );
          kernel = k;
          final outcome = await k.run(
            'for i in range(5000):\n    print("x" * 40)',
          );
          // The head and the last quarter, with the count dropped between
          // (eval_kernel_bounds_test.dart pins the shape).
          expect(textOf(outcome), contains('characters (UTF-16 units) of text'));
          expect(textOf(outcome).length, lessThan(2000));
        },
      );

      test('a cell has no tool function: tool(...) is a NameError', () async {
        final outcome = await build().run('tool("read", {})');
        expect(outcome.isError, isTrue);
        expect(
          outcome.error,
          contains("NameError: name 'tool' is not defined"),
        );
      });

      test('reset drops the state', () async {
        final tool = EvalTool(kernelFor: (_) => kernel, hostConfined: true);
        build();
        await kernel.run('marker = 1');
        final after = await tool.execute({
          'code': 'print("marker" in dir())',
          'reset': true,
          'description': 'Check the marker is gone',
        }, const HarnessToolContext(workingDirectory: '/repo'));
        expect(after.content, contains('False'));
      });

      test('the tool surfaces an empty cell honestly', () async {
        final tool = EvalTool(kernelFor: (_) => build(), hostConfined: true);
        final result = await tool.execute({
          'code': 'x = 1',
          'description': 'Assign a variable',
        }, const HarnessToolContext(workingDirectory: '/repo'));
        expect(result.isError, isFalse);
        expect(result.content, contains('no output'));
      });

      test('is exec tier, not parallel-safe, not for scripts, and states the '
          'cell it runs', () {
        final tool = EvalTool(kernelFor: (_) => build(), hostConfined: true);
        expect(tool.approvalTier, ToolApprovalTier.exec);
        expect(tool.actionClasses, contains(ActionClass.processSpawn));
        expect(
          tool.parallelSafe,
          isFalse,
          reason:
              'two cells racing in one interpreter is two halves of two '
              'programs interleaved in one namespace',
        );
        expect(tool.scriptCallable, isFalse);
        // A direct cell is still audited whole.
        expect(tool.executedContent({'code': 'print(1)'}), 'print(1)');
      });
    },
    skip: python == null ? 'python3 is not on PATH' : null,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  // Schema and argument gating need no live interpreter, so these run even
  // where python3 is missing.
  group('EvalTool call description', () {
    test('requires a per-call description in the schema', () {
      final tool = EvalTool(
        kernelFor: (_) => fail('the kernel must not be resolved'),
        hostConfined: true,
      );
      final schema = tool.inputSchema;
      expect(schema['required'], contains('description'));
      expect((schema['properties'] as Map).containsKey('description'), isTrue);
    });

    test(
      'rejects a call without a description before touching a kernel',
      () async {
        final tool = EvalTool(
          kernelFor: (_) => fail('the kernel must not be resolved'),
          hostConfined: true,
        );
        final result = await tool.execute({
          'code': 'x = 1',
        }, const HarnessToolContext(workingDirectory: '/repo'));
        expect(result.isError, isTrue);
        expect(result.content, contains('description'));
      },
    );
  });
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
