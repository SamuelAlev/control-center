import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/eval/eval_kernel.dart';
import 'package:cc_infra/src/harness/eval_tool.dart';
import 'package:cc_infra/src/sandboxing/tool_process_launcher.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// What a cell's result keeps of a flood of output (its head and the end of
/// it), and what the first cell after the interpreter died is told, against
/// a real Python.
void main() {
  final python = _resolve('python3');

  group(
    'eval output and restarts',
    () {
      late Directory root;
      late EvalKernel kernel;

      setUp(() {
        root = Directory.systemTemp.createTempSync('cc_eval_bounds');
      });
      tearDown(() async {
        await kernel.dispose();
        await deleteDirBestEffort(root);
      });

      EvalKernel build({int maxOutputChars = 100000}) => kernel = EvalKernel(
        language: KernelLanguage.python,
        launcher: HostKernelLauncher(
          workingDirectory: root.path,
          processes: const HostToolProcessLauncher(),
          pythonExecutable: python,
        ),
        inactivityTimeout: const Duration(seconds: 30),
        maxOutputChars: maxOutputChars,
      );

      String textOf(KernelRunOutcome outcome) =>
          outcome.outputs.whereType<KernelText>().map((o) => o.text).join();

      test(
        'a flood keeps its head, its last quarter and the dropped count',
        () async {
          final outcome = await build(maxOutputChars: 1000).run(
            'for i in range(2000):\n    print(f"line {i:04d}")\n'
            'print("THE END")',
          );
          expect(outcome.isError, isFalse);
          final text = textOf(outcome);
          // 2000 lines of 10 characters, then 8: 20,008 printed.
          expect(text, startsWith('line 0000\nline 0001\n'));
          expect(text.trimRight(), endsWith('line 1999\nTHE END'));
          final marker = RegExp(
            r'… dropped here: (\d+) characters \(UTF-16 units\) of text\. The '
            r'cell printed more than 1000 characters of text; its first 750 '
            r'and last 250 are kept …',
          ).firstMatch(text);
          expect(marker, isNotNull, reason: text);
          expect(int.parse(marker!.group(1)!), 20008 - 1000);
          final kept = text.replaceFirst(RegExp(r'\n… [^\n]*…\n'), '');
          expect(kept.length, 1000);
        },
      );

      test('images dropped from the tail are counted apart from the text, '
          'and images in the head are kept', () async {
        final outcome = await build(maxOutputChars: 1000).run(
          'class P:\n    def _repr_png_(self):\n        return b"png"\n'
          'display(P())\n'
          'for i in range(1000):\n    print(f"line {i:04d}")\n'
          'for i in range(3):\n    display(P())\n'
          'for i in range(1000):\n    print(f"more {i:04d}")\n',
        );
        expect(outcome.isError, isFalse);
        expect(outcome.outputs.first, isA<KernelImage>());
        expect(outcome.outputs.whereType<KernelImage>(), hasLength(1));
        final marker = RegExp(
          r'… dropped here: (\d+) characters \(UTF-16 units\) of text and '
          r'3 images\.',
        ).firstMatch(textOf(outcome));
        expect(marker, isNotNull, reason: textOf(outcome));
        expect(int.parse(marker!.group(1)!), 20000 - 1000);
      });

      test('output within the cap comes back whole, with no marker', () async {
        final outcome = await build(
          maxOutputChars: 1000,
        ).run('print("x" * 900)');
        expect(textOf(outcome).trim(), 'x' * 900);
        expect(textOf(outcome), isNot(contains('dropped')));
      });

      test('the first cell after the interpreter died is told, once', () async {
        final k = build();
        await k.run('kept = 7');
        final died = await k.run('import os\nos._exit(3)');
        expect(died.isError, isTrue);
        expect(died.restarted, isFalse);

        final next = await k.run('print("kept" in globals())');
        expect(next.restarted, isTrue);
        expect(textOf(next).trim(), 'False');

        final after = await k.run('print(1)');
        expect(after.restarted, isFalse);
      });

      test('a reset is asked for, so the next cell is not told', () async {
        final k = build();
        await k.run('kept = 7');
        await k.dispose();
        final next = await k.run('print(2)');
        expect(next.restarted, isFalse);
      });

      test('the eval tool puts the notice before the cell output', () async {
        final k = build();
        final tool = EvalTool(kernelFor: (_) => k, hostConfined: true);
        const context = HarnessToolContext(workingDirectory: '/repo');
        Future<HarnessToolResult> cell(String code) => tool.execute({
          'code': code,
          'description': 'Probe the kernel',
        }, context);
        await cell('kept = 7');
        await cell('import os\nos._exit(3)');
        final told = await cell('print("again")');
        expect(told.content, startsWith(EvalTool.restartNotice));
        expect(told.content, contains('again'));
        final quiet = await cell('print("quiet")');
        expect(quiet.content, isNot(contains('interpreter stopped')));
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
