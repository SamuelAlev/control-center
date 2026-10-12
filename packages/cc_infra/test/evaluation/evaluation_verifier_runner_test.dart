import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_infra/src/evaluation/evaluation_verifier_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The verifier runner is the evaluation's independent evidence, so these
/// tests drive it against a REAL temporary workspace: real processes for the
/// command checks and real bytes for the file checks.
void main() {
  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('cc_eval_verifier');
    File(
      p.join(workspace.path, 'ok.sh'),
    ).writeAsStringSync('#!/usr/bin/env bash\nexit 0\n');
    File(
      p.join(workspace.path, 'fail.sh'),
    ).writeAsStringSync('#!/usr/bin/env bash\necho bad >&2\nexit 3\n');
    File(
      p.join(workspace.path, 'note.txt'),
    ).writeAsStringSync('alpha\nbeta\nMAX_WORKERS: 7\n');
  });

  tearDown(() {
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  Future<List<EvaluationVerificationResult>> runVerifiers(
    List<EvaluationVerifier> verifiers, {
    EvaluationExecutionMode mode = EvaluationExecutionMode.live,
  }) => const EvaluationVerifierRunner().run(
    verifiers: verifiers,
    workspaceRoot: workspace.path,
    mode: mode,
  );

  test(
    'a command check reads the real exit status of a TRUSTED program',
    () async {
      final results = await runVerifiers(const [
        EvaluationVerifier(
          id: 'ok',
          kind: EvaluationVerifierKind.commandExit,
          params: {'trustedScript': 'exit 0'},
        ),
        EvaluationVerifier(
          id: 'fail',
          kind: EvaluationVerifierKind.commandExit,
          params: {'trustedScript': 'echo bad >&2\nexit 3'},
        ),
        EvaluationVerifier(
          id: 'expected_failure',
          kind: EvaluationVerifierKind.commandExit,
          params: {
            'trustedScript': 'exit 3',
            'expectExit': [3],
          },
        ),
      ]);
      expect(results[0].passed, isTrue);
      expect(results[1].passed, isFalse);
      expect(results[1].detail, contains('exit 3'));
      expect(results[1].detail, contains('bad'));
      expect(results[2].passed, isTrue);
    },
  );

  test(
    'an authoritative check cannot run a program inside the workspace',
    () async {
      final results = await runVerifiers(const [
        EvaluationVerifier(
          id: 'inline',
          kind: EvaluationVerifierKind.commandExit,
          params: {'command': './ok.sh'},
        ),
        EvaluationVerifier(
          id: 'advisory_inline',
          kind: EvaluationVerifierKind.commandExit,
          params: {'command': 'exit 0'},
          authoritative: false,
        ),
      ]);
      expect(results[0].passed, isFalse);
      expect(results[0].detail, contains('trustedScript'));
      // A non-authoritative (advisory) check may still use an inline command.
      expect(results[1].passed, isTrue);
    },
  );

  test('a timeout is a failure, not a pass', () async {
    final results = await runVerifiers(const [
      EvaluationVerifier(
        id: 'slow',
        kind: EvaluationVerifierKind.commandExit,
        params: {'trustedScript': 'sleep 5', 'timeoutSeconds': 1},
      ),
    ]);
    expect(results.single.passed, isFalse);
    expect(results.single.detail, contains('timed out'));
  });

  test('line-anchored patterns match per line by default', () async {
    File(
      p.join(workspace.path, 'lines.txt'),
    ).writeAsStringSync('alpha\nMAX_WORKERS: 7\nFACT: 7 and 42\nomega\n');
    final results = await runVerifiers(const [
      EvaluationVerifier(
        id: 'anchored',
        kind: EvaluationVerifierKind.fileContains,
        params: {'path': 'lines.txt', 'pattern': '^FACT:.*\\b7\\b'},
      ),
      EvaluationVerifier(
        id: 'anchored_off',
        kind: EvaluationVerifierKind.fileContains,
        params: {
          'path': 'lines.txt',
          'pattern': r'^alpha$',
          'multiLine': false,
        },
      ),
    ]);
    expect(results[0].passed, isTrue);
    // `^alpha$` only matches the whole text without multiline, so opting out
    // makes the check FLIP — the flag is real.
    expect(results[1].passed, isFalse);
  });

  test('file checks are regex-aware and count-aware', () async {
    final results = await runVerifiers(const [
      EvaluationVerifier(
        id: 'contains',
        kind: EvaluationVerifierKind.fileContains,
        params: {'path': 'note.txt', 'pattern': 'MAX_WORKERS:\\s*7'},
      ),
      EvaluationVerifier(
        id: 'missing',
        kind: EvaluationVerifierKind.fileContains,
        params: {'path': 'note.txt', 'needle': 'TIMEOUT_S'},
      ),
      EvaluationVerifier(
        id: 'excludes',
        kind: EvaluationVerifierKind.fileExcludes,
        params: {'path': 'note.txt', 'needle': 'TIMEOUT_S'},
      ),
      EvaluationVerifier(
        id: 'count',
        kind: EvaluationVerifierKind.fileContains,
        params: {'path': 'note.txt', 'needle': 'a', 'count': 3},
      ),
      EvaluationVerifier(
        id: 'wrong_count',
        kind: EvaluationVerifierKind.fileContains,
        params: {'path': 'note.txt', 'needle': 'a', 'count': 1},
      ),
      EvaluationVerifier(
        id: 'absent_file',
        kind: EvaluationVerifierKind.fileContains,
        params: {'path': 'nope.txt', 'needle': 'x'},
      ),
    ]);
    expect(results[0].passed, isTrue);
    expect(results[1].passed, isFalse);
    expect(results[2].passed, isTrue);
    expect(results[3].passed, isTrue);
    expect(results[4].passed, isFalse);
    expect(results[5].passed, isFalse);
    expect(results[5].detail, contains('does not exist'));
  });

  test('a path escaping the workspace can never pass', () async {
    final outside = File(p.join(workspace.parent.path, 'outside.txt'))
      ..writeAsStringSync('secret');
    addTearDown(() {
      if (outside.existsSync()) {
        outside.deleteSync();
      }
    });
    final results = await runVerifiers(const [
      EvaluationVerifier(
        id: 'escape',
        kind: EvaluationVerifierKind.fileContains,
        params: {'path': '../outside.txt', 'needle': 'secret'},
      ),
      EvaluationVerifier(
        id: 'escape_cwd',
        kind: EvaluationVerifierKind.commandExit,
        params: {'command': 'true', 'cwd': '../'},
      ),
    ]);
    expect(results[0].passed, isFalse);
    expect(results[0].detail, contains('escapes the workspace'));
    expect(results[1].passed, isFalse);
  });

  test('declarationExists matches a pattern across files', () async {
    Directory(p.join(workspace.path, 'lib')).createSync();
    File(
      p.join(workspace.path, 'lib', 'helper.sh'),
    ).writeAsStringSync('start_server() {\n  true\n}\n');
    final results = await runVerifiers(const [
      EvaluationVerifier(
        id: 'decl',
        kind: EvaluationVerifierKind.declarationExists,
        params: {
          'path': 'lib',
          'pattern': '^start_server\\(\\)',
          'extensions': ['.sh'],
        },
      ),
      EvaluationVerifier(
        id: 'decl_missing',
        kind: EvaluationVerifierKind.declarationExists,
        params: {'path': 'lib', 'pattern': '^stop_server\\(\\)'},
      ),
    ]);
    expect(results[0].passed, isTrue);
    expect(results[1].passed, isFalse);
  });

  test('noWrites is skipped (never passed) outside a git workspace', () async {
    final results = await runVerifiers(const [
      EvaluationVerifier(
        id: 'no_writes',
        kind: EvaluationVerifierKind.noWrites,
      ),
    ]);
    expect(results.single.passed, isFalse);
    expect(results.single.skippedReason, isNotNull);
  });

  test(
    'git-backed checks find the repository above a task sub-directory',
    () async {
      await Process.run('git', [
        'init',
        '--quiet',
      ], workingDirectory: workspace.path);
      await Process.run('git', ['add', '-A'], workingDirectory: workspace.path);
      await Process.run('git', [
        '-c',
        'user.email=t@t',
        '-c',
        'user.name=t',
        'commit',
        '--quiet',
        '-m',
        'base',
      ], workingDirectory: workspace.path);
      final subdir = Directory(p.join(workspace.path, 'sub', 'deeper'))
        ..createSync(recursive: true);
      final results = await const EvaluationVerifierRunner().run(
        verifiers: const [
          EvaluationVerifier(
            id: 'no_writes',
            kind: EvaluationVerifierKind.noWrites,
          ),
        ],
        // The candidate works in a sub-directory, but the repository is above it.
        workspaceRoot: subdir.path,
        gitRoot: workspace.path,
      );
      expect(results.single.skippedReason, isNull);
      expect(results.single.passed, isTrue);

      File(p.join(workspace.path, 'note.txt')).writeAsStringSync('changed\n');
      final dirty = await const EvaluationVerifierRunner().run(
        verifiers: const [
          EvaluationVerifier(
            id: 'no_writes',
            kind: EvaluationVerifierKind.noWrites,
          ),
        ],
        workspaceRoot: subdir.path,
        gitRoot: workspace.path,
      );
      expect(dirty.single.passed, isFalse);
      expect(dirty.single.detail, contains('note.txt'));
    },
  );

  test('a broken git repository cannot prove no writes', () async {
    Directory(p.join(workspace.path, '.git')).createSync();
    final results = await runVerifiers(const [
      EvaluationVerifier(
        id: 'no_writes',
        kind: EvaluationVerifierKind.noWrites,
      ),
    ]);
    expect(results.single.passed, isFalse);
    expect(results.single.skippedReason, isNull);
    expect(results.single.detail, contains('git status failed'));
  });

  test('noWrites is behavioral inside a git workspace', () async {
    await Process.run('git', [
      'init',
      '--quiet',
    ], workingDirectory: workspace.path);
    await Process.run('git', ['add', '-A'], workingDirectory: workspace.path);
    await Process.run('git', [
      '-c',
      'user.email=t@t',
      '-c',
      'user.name=t',
      'commit',
      '--quiet',
      '-m',
      'base',
    ], workingDirectory: workspace.path);

    final clean = await runVerifiers(const [
      EvaluationVerifier(
        id: 'no_writes',
        kind: EvaluationVerifierKind.noWrites,
      ),
    ]);
    expect(clean.single.passed, isTrue);

    File(p.join(workspace.path, 'note.txt')).writeAsStringSync('changed\n');
    final dirty = await runVerifiers(const [
      EvaluationVerifier(
        id: 'no_writes',
        kind: EvaluationVerifierKind.noWrites,
      ),
    ]);
    expect(dirty.single.passed, isFalse);
    expect(dirty.single.detail, contains('note.txt'));

    final allowed = await runVerifiers(const [
      EvaluationVerifier(
        id: 'no_writes',
        kind: EvaluationVerifierKind.noWrites,
        params: {
          'allow': ['note.txt'],
        },
      ),
    ]);
    expect(allowed.single.passed, isTrue);
  });

  test('diffApplies checks a real patch and rejects a stale one', () async {
    await Process.run('git', [
      'init',
      '--quiet',
    ], workingDirectory: workspace.path);
    await Process.run('git', ['add', '-A'], workingDirectory: workspace.path);
    await Process.run('git', [
      '-c',
      'user.email=t@t',
      '-c',
      'user.name=t',
      'commit',
      '--quiet',
      '-m',
      'base',
    ], workingDirectory: workspace.path);

    const patch =
        '--- a/note.txt\n'
        '+++ b/note.txt\n'
        '@@ -1,3 +1,3 @@\n'
        ' alpha\n'
        '-beta\n'
        '+gamma\n'
        ' MAX_WORKERS: 7\n';
    final fresh = await runVerifiers(const [
      EvaluationVerifier(
        id: 'diff',
        kind: EvaluationVerifierKind.diffApplies,
        params: {'patch': patch},
      ),
    ]);
    expect(fresh.single.passed, isTrue);

    File(p.join(workspace.path, 'note.txt')).writeAsStringSync('rewritten\n');
    final stale = await runVerifiers(const [
      EvaluationVerifier(
        id: 'diff',
        kind: EvaluationVerifierKind.diffApplies,
        params: {'patch': patch},
      ),
    ]);
    expect(stale.single.passed, isFalse);
  });

  test('fileUnchanged compares a real digest', () async {
    final digest = sha256
        .convert(File(p.join(workspace.path, 'note.txt')).readAsBytesSync())
        .toString();
    final results = await runVerifiers([
      EvaluationVerifier(
        id: 'unchanged',
        kind: EvaluationVerifierKind.fileUnchanged,
        params: {'path': 'note.txt', 'sha256': digest},
      ),
      const EvaluationVerifier(
        id: 'changed',
        kind: EvaluationVerifierKind.fileUnchanged,
        params: {'path': 'note.txt', 'sha256': 'deadbeef'},
      ),
    ]);
    expect(results[0].passed, isTrue);
    expect(results[1].passed, isFalse);
  });

  test('replay stamps deterministic provenance on every verdict', () async {
    final results = await runVerifiers(const [
      EvaluationVerifier(
        id: 'ok',
        kind: EvaluationVerifierKind.commandExit,
        params: {'command': './ok.sh'},
      ),
    ], mode: EvaluationExecutionMode.offlineReplay);
    expect(
      results.single.provenance,
      VerificationProvenance.replayDeterministic,
    );
  });

  test('a misconfigured verifier fails instead of passing', () async {
    final results = await runVerifiers(const [
      EvaluationVerifier(id: 'empty', kind: EvaluationVerifierKind.commandExit),
      EvaluationVerifier(
        id: 'empty_advisory',
        kind: EvaluationVerifierKind.commandExit,
        authoritative: false,
      ),
      EvaluationVerifier(
        id: 'bad_pattern',
        kind: EvaluationVerifierKind.fileContains,
        params: {'path': 'note.txt', 'pattern': '('},
      ),
    ]);
    // An authoritative command check with no program is refused (fail closed).
    expect(results[0].passed, isFalse);
    expect(results[0].detail, contains('trustedScript'));
    // An advisory one with no program is simply misconfigured.
    expect(results[1].passed, isFalse);
    expect(results[1].detail, contains('misconfigured'));
    expect(results[2].passed, isFalse);
  });
  test(
    'contained oracle keeps host-only answers outside candidate execution',
    () async {
      final secret = File(
        p.join(
          workspace.parent.path,
          'cc-eval-hidden-${DateTime.now().microsecondsSinceEpoch}',
        ),
      )..writeAsStringSync('expected-answer');
      addTearDown(() {
        if (secret.existsSync()) secret.deleteSync();
      });
      File(p.join(workspace.path, 'probe.py')).writeAsStringSync(
        'from pathlib import Path\n'
        'def transform(value):\n'
        '    try:\n'
        '        exposed = Path(${jsonEncode(secret.path)}).read_text() == "expected-answer"\n'
        '    except OSError:\n'
        '        exposed = False\n'
        '    return {"host_answer_exposed": exposed}\n',
      );
      const verifier = EvaluationVerifier(
        id: 'host-only',
        kind: EvaluationVerifierKind.tests,
        params: {
          'oracle': {
            'kind': 'python-module-cases',
            'path': 'probe.py',
            'function': 'transform',
            'cases': [
              [
                <String, Object?>{},
                {'host_answer_exposed': false},
              ],
            ],
          },
        },
      );
      expect(
        EvaluationVerifierRunner.supportsContainedOracle(verifier),
        isTrue,
      );
      final results = await const EvaluationVerifierRunner().run(
        verifiers: [verifier],
        workspaceRoot: workspace.path,
        controlled: true,
      );
      expect(results.single.passed, isTrue);
    },
  );

  test('exit zero without structured output cannot prove success', () async {
    File(p.join(workspace.path, 'probe.py')).writeAsStringSync(
      'import os\n'
      'def transform(value):\n'
      '    os._exit(0)\n',
    );
    final results = await const EvaluationVerifierRunner().run(
      verifiers: const [
        EvaluationVerifier(
          id: 'premature-exit',
          kind: EvaluationVerifierKind.tests,
          params: {
            'oracle': {
              'kind': 'python-module-cases',
              'path': 'probe.py',
              'function': 'transform',
              'cases': [
                [
                  {},
                  {'ok': true},
                ],
              ],
            },
          },
        ),
      ],
      workspaceRoot: workspace.path,
      controlled: true,
    );
    expect(results.single.passed, isFalse);
  });

  test('oversized sparse output fails before verifier allocates it', () async {
    final sparse = File(
      p.join(workspace.path, 'output.bin'),
    ).openSync(mode: FileMode.write);
    sparse.truncateSync(9 * 1024 * 1024);
    sparse.closeSync();
    final results = await const EvaluationVerifierRunner().run(
      verifiers: const [
        EvaluationVerifier(
          id: 'artifact',
          kind: EvaluationVerifierKind.tests,
          params: {
            'oracle': {
              'kind': 'json-artifact',
              'path': 'answer.json',
              'expected': {'ok': true},
            },
          },
        ),
      ],
      workspaceRoot: workspace.path,
      controlled: true,
    );
    expect(results.single.passed, isFalse);
  });

  test(
    'candidate mutation of grading copy cannot carry into later cases',
    () async {
      File(p.join(workspace.path, 'probe.py')).writeAsStringSync(
        'from pathlib import Path\n'
        'def transform(value):\n'
        '    Path("probe.py").write_text("def transform(value): return value")\n'
        '    return {"ok": True}\n',
      );
      final results = await const EvaluationVerifierRunner().run(
        verifiers: const [
          EvaluationVerifier(
            id: 'mutable-check',
            kind: EvaluationVerifierKind.tests,
            params: {
              'oracle': {
                'kind': 'python-module-cases',
                'path': 'probe.py',
                'function': 'transform',
                'cases': [
                  [
                    {},
                    {'ok': true},
                  ],
                  [
                    {},
                    {'ok': true},
                  ],
                ],
              },
            },
          ),
        ],
        workspaceRoot: workspace.path,
        controlled: true,
      );
      expect(results.single.passed, isFalse);
    },
  );

  test('contained validation refuses executable checker scripts', () {
    expect(
      EvaluationVerifierRunner.supportsContainedOracle(
        const EvaluationVerifier(
          id: 'unsafe',
          kind: EvaluationVerifierKind.tests,
          params: {'trustedScript': 'exit 0'},
        ),
      ),
      isFalse,
    );
  });
}
