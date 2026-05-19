import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/job_run_detail.dart';
import 'package:control_center/features/pr_review/presentation/widgets/workflow_job_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('processJobLogs', () {
    test('strips ANSI escapes and GitHub timestamp prefixes', () {
      const raw =
          '2024-06-16T15:31:05.0218443Z \u001b[36;1mRun tests\u001b[0m\n'
          '2024-06-16T15:31:05.0222967Z hello\n';
      expect(processJobLogs(raw), 'Run tests\nhello\n');
    });

    test('leaves already-clean text untouched', () {
      const raw = 'hello\nworld\n';
      expect(processJobLogs(raw), raw);
    });
  });

  group('sliceJobLog (classic dialect)', () {
    test('slices groups, preamble and tail in order', () {
      const log =
          'preamble line\n'
          '##[group]Build app\n'
          'build output 1\n'
          'build output 2\n'
          '##[endgroup]\n'
          '##[group]Upload artifacts\n'
          'uploading\n'
          '##[endgroup]\n'
          'tail line\n';
      final sections = sliceJobLog(log);
      expect(sections.map((s) => s.title), [
        'Set up job',
        'Build app',
        'Upload artifacts',
        'Complete job',
      ]);
      expect(sections[0].body.trim(), 'preamble line');
      expect(sections[1].body.trim(), 'build output 1\nbuild output 2');
      expect(sections[2].body.trim(), 'uploading');
      expect(sections[3].body.trim(), 'tail line');
    });

    test('omits blank preamble and tail', () {
      const log = '##[group]Build app\noutput\n##[endgroup]\n';
      final sections = sliceJobLog(log);
      expect(sections.map((s) => s.title), ['Build app']);
    });

    test('treats a nested group open as body text', () {
      const log =
          '##[group]Outer\n'
          '##[group]Inner\n'
          'body\n'
          '##[endgroup]\n';
      final sections = sliceJobLog(log);
      expect(sections.single.title, 'Outer');
      expect(sections.single.body, contains('##[group]Inner'));
    });

    test('an unclosed group still yields its section', () {
      const log = '##[group]Build app\noutput\n';
      final sections = sliceJobLog(log);
      expect(sections.single.title, 'Build app');
      expect(sections.single.body.trim(), 'output');
    });

    test('slices start-action/end-action markers using the display attribute', () {
      const log =
          '##[start-action display=Setup Node.js;id=__self.__actions_setup-node]\n'
          'Resolved .nvmrc as 24.15\n'
          'Attempting to download 24.15...\n'
          '##[end-action id=__self.__actions_setup-node;outcome=success;conclusion=success;duration_ms=30818]\n'
          '##[start-action display=Install pnpm dependencies;id=__self.__run]\n'
          'installing\n'
          '##[end-action id=__self.__run;outcome=success]\n';
      final sections = sliceJobLog(log);
      expect(sections.map((s) => s.title), [
        'Setup Node.js',
        'Install pnpm dependencies',
      ]);
      expect(sections.first.body, contains('Resolved .nvmrc as 24.15'));
      expect(sections.first.body, isNot(contains('##[end-action')));
      expect(sections.last.body.trim(), 'installing');
    });

    test('falls back to raw attributes when display is missing', () {
      const log =
          '##[start-action id=__self.__run]\n'
          'body\n'
          '##[end-action id=__self.__run]\n';
      final sections = sliceJobLog(log);
      expect(sections.single.title, 'id=__self.__run');
    });
  });

  group('sliceJobLog (runner command dialect)', () {
    // Mirrors the structure of a real setup-node/pnpm CI log: runner preamble,
    // '##[group]Run <command>' step sections, nested info groups, a composite
    // action emitting start-action/end-action inside a step, and post-job
    // cleanup output after the last 'Post job cleanup.' line.
    const log =
        'Current runner version: 2.329.0\n'
        '##[group]Runner Image Provisioner\n'
        'provisioned\n'
        '##[endgroup]\n'
        '##[group]Run actions/checkout@v4\n'
        'Syncing repository: org/repo\n'
        '##[group]Getting Git version info\n'
        'git version 2.50.1\n'
        '##[endgroup]\n'
        '##[endgroup]\n'
        '##[group]Run ./.github/actions/ci-setup\n'
        '##[start-action display=Setup pnpm;id=__self.__pnpm]\n'
        'installing pnpm\n'
        '##[end-action id=__self.__pnpm;outcome=success]\n'
        '##[endgroup]\n'
        '##[group]Run pnpm deps:validate\n'
        '\$ depcruise src\n'
        '##[endgroup]\n'
        'Post job cleanup.\n'
        'cleanup done\n';

    test('Run-command groups become step sections in order', () {
      final sections = sliceJobLog(log);
      expect(sections.map((s) => s.title), [
        'Set up job',
        'Run actions/checkout@v4',
        'Run ./.github/actions/ci-setup',
        'Run pnpm deps:validate',
        'Post job',
      ]);
    });

    test('the preamble keeps everything before the first Run group', () {
      final setup = sliceJobLog(log).first;
      expect(setup.body, contains('Current runner version'));
      expect(setup.body, contains('Runner Image Provisioner'));
    });

    test(
      'nested info groups and composite actions stay raw inside the step body',
      () {
        final sections = sliceJobLog(log);
        final checkout = sections[1];
        // The raw `Run …` opener/endgroup stays in the body so the display
        // can fold it (GitHub's `▼ Run actions/checkout@v4` row).
        expect(checkout.body, startsWith('##[group]Run actions/checkout@v4'));
        expect(checkout.body, contains('##[group]Getting Git version info'));
        expect(checkout.body, contains('git version 2.50.1'));
        final ciSetup = sections[2];
        expect(ciSetup.body, contains('##[start-action display=Setup pnpm'));
        expect(ciSetup.body, contains('installing pnpm'));
      },
    );

    test('post-step output folds into the synthetic Post job section', () {
      final sections = sliceJobLog(log);
      expect(sections.last.body.trim(), 'cleanup done');
    });
  });

  group('mapStepsToSections (runner command dialect)', () {
    const log =
        'preamble\n'
        '##[group]Run actions/checkout@v4\n'
        'checkout body\n'
        '##[endgroup]\n'
        '##[group]Run ./.github/actions/ci-setup\n'
        'setup body\n'
        '##[endgroup]\n'
        '##[group]Run pnpm deps:validate\n'
        'validate body\n'
        '##[endgroup]\n'
        'Post job cleanup.\n'
        'cleanup body\n';

    final steps = <JobRunStep>[
      JobRunStep(
        number: 1,
        name: 'Set up job',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
      JobRunStep(
        number: 2,
        name: 'Checkout default branch',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
      JobRunStep(
        number: 3,
        name: 'Setup Node.js and pnpm',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
      JobRunStep(
        number: 4,
        name: 'Validate dependencies',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
      JobRunStep(
        number: 5,
        name: 'Post Validate dependencies',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
      JobRunStep(
        number: 6,
        name: 'Complete job',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
    ];

    test('pairs each middle step with its Run section in order', () {
      final result = mapStepsToSections(steps, sliceJobLog(log));
      expect(result[1]!.title, 'Run actions/checkout@v4');
      expect(result[2]!.title, 'Run ./.github/actions/ci-setup');
      expect(result[3]!.title, 'Run pnpm deps:validate');
    });

    test(
      'pseudo-steps map to preamble and Post job; Complete job has no logs',
      () {
        final result = mapStepsToSections(steps, sliceJobLog(log));
        expect(result[0]!.title, 'Set up job');
        expect(result[4]!.title, 'Post job');
        expect(result[5], isNull);
      },
    );

    test('a skipped step keeps the order pairing aligned', () {
      // A skipped step emits no `##[group]Run` section — the log simply has
      // fewer Run sections, and order-pairing stays aligned.
      const skipLog =
          'preamble\n'
          '##[group]Run actions/checkout@v4\n'
          'checkout body\n'
          '##[endgroup]\n'
          '##[group]Run pnpm deps:validate\n'
          'validate body\n'
          '##[endgroup]\n'
          'Post job cleanup.\n'
          'cleanup body\n';
      final skipped = JobRunStep(
        number: steps[2].number,
        name: steps[2].name,
        status: steps[2].status,
        conclusion: CheckRunConclusion.skipped,
      );
      final result = mapStepsToSections([
        steps[0],
        steps[1],
        skipped,
        steps[3],
        steps[4],
        steps[5],
      ], sliceJobLog(skipLog));
      expect(result[1]!.title, 'Run actions/checkout@v4');
      expect(result[2], isNull); // skipped → no section consumed
      expect(result[3]!.title, 'Run pnpm deps:validate');
    });
  });

  group('sectionForStep (classic dialect)', () {
    final sections = sliceJobLog(
      'setup\n'
      '##[group]Build app\n'
      'test body\n'
      '##[endgroup]\n'
      '##[group]Checkout code\n'
      'checkout body\n'
      '##[endgroup]\n'
      'cleanup\n',
    );

    test('exact title match wins', () {
      final s = sectionForStep(sections, 'Build app');
      expect(s, isNotNull);
      expect(s!.body.trim(), 'test body');
    });

    test('pseudo-steps take the preamble and tail', () {
      expect(sectionForStep(sections, 'Set up job')!.body.trim(), 'setup');
      expect(sectionForStep(sections, 'Complete job')!.body.trim(), 'cleanup');
    });

    test('falls back to containment either way', () {
      // Step name is a prefix of the section title.
      final s = sectionForStep(sections, 'Checkout');
      expect(s, isNotNull);
      expect(s!.title, 'Checkout code');
    });

    test('returns null for an unmatched step', () {
      expect(sectionForStep(sections, 'Deploy to prod'), isNull);
    });

    test('a longer step name matches its action section by containment', () {
      // The workflow step is named 'Setup Node.js and pnpm' but the runner
      // logs the action as 'Setup Node.js'.
      final actionSections = sliceJobLog(
        '##[start-action display=Setup Node.js;id=__self.__actions_setup-node]\n'
        'Resolved .nvmrc as 24.15\n'
        '##[end-action id=__self.__actions_setup-node]\n',
      );
      final s = sectionForStep(actionSections, 'Setup Node.js and pnpm');
      expect(s, isNotNull);
      expect(s!.body, contains('Resolved .nvmrc as 24.15'));
    });
  });

  group('parseLogLines', () {
    test('numbers plain lines from 1', () {
      final nodes = parseLogLines('a\nb\nc\n');
      expect(nodes.map((n) => n.number), [1, 2, 3]);
      expect(nodes.every((n) => !n.isGroup), isTrue);
    });

    test('a group becomes a foldable node with numbered children', () {
      final nodes = parseLogLines(
        'before\n'
        '##[group]Getting Git version info\n'
        'git version 2.50.1\n'
        '##[endgroup]\n'
        'after\n',
      );
      expect(nodes, hasLength(3));
      final group = nodes[1];
      expect(group.isGroup, isTrue);
      expect(group.title, 'Getting Git version info');
      expect(group.number, 2);
      expect(group.children.single.number, 3);
      expect(group.children.single.line, 'git version 2.50.1');
      // Hidden marker lines consume no number: `after` is row 4, not 5.
      expect(nodes[2].number, 4);
    });

    test('groups nest', () {
      final nodes = parseLogLines(
        '##[group]Outer\n'
        '##[group]Inner\n'
        'body\n'
        '##[endgroup]\n'
        '##[endgroup]\n',
      );
      final outer = nodes.single;
      expect(outer.title, 'Outer');
      expect(outer.children.single.title, 'Inner');
      expect(outer.children.single.children.single.line, 'body');
    });

    test('a start-action pair folds under its display name', () {
      final nodes = parseLogLines(
        '##[start-action display=Setup pnpm;id=__self.__pnpm]\n'
        'installing\n'
        '##[end-action id=__self.__pnpm]\n',
      );
      expect(nodes.single.isGroup, isTrue);
      expect(nodes.single.title, 'Setup pnpm');
      expect(nodes.single.children.single.line, 'installing');
    });

    test('an unclosed group closes at the end of the slice', () {
      final nodes = parseLogLines('##[group]Open\nbody\n');
      expect(nodes.single.isGroup, isTrue);
      expect(nodes.single.children.single.line, 'body');
    });
  });

  group('composite action steps)', () {
    // Faithful to a PR log. The composite step's own `##[group]Run …` wraps only its (empty) with:
    // block and closes IMMEDIATELY; its children log AFTER that, each inside
    // a `##[start-action]…##[end-action]` block, emitting their own
    // `##[group]Run <action>@<sha>` invocations.
    const log =
        '##[group]Run actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803\n'
        'with:\n'
        '  persist-credentials: false\n'
        '##[endgroup]\n'
        'Syncing repository: UseCtrl/control-center\n'
        '##[group]Getting Git version info\n'
        'git version 2.50.1\n'
        '##[endgroup]\n'
        '##[group]Run ./.github/actions/ci-setup\n'
        '##[endgroup]\n'
        '##[start-action display=Setup pnpm;id=__self.__pnpm_action-setup]\n'
        '##[group]Run pnpm/action-setup@0ebf47130e4866e96fce0953f49152a61190b271\n'
        'installing pnpm\n'
        '##[endgroup]\n'
        '##[group]Running self-installer...\n'
        'self installing\n'
        '##[endgroup]\n'
        '##[end-action id=__self.__pnpm_action-setup;duration_ms=1815]\n'
        '##[start-action display=Setup Node.js;id=__self.__actions_setup-node]\n'
        '##[group]Run actions/setup-node@249970729cb0ef3589644e2896645e5dc5ba9c38\n'
        'with:\n'
        '  node-version-file: .nvmrc\n'
        '##[endgroup]\n'
        'Resolved .nvmrc as 24.15\n'
        '##[end-action id=__self.__actions_setup-node;duration_ms=30264]\n'
        '##[start-action display=Install pnpm dependencies;id=__self.__run]\n'
        '##[group]Run pnpm install --frozen-lockfile\n'
        'installing deps\n'
        '##[endgroup]\n'
        '##[end-action id=__self.__run;duration_ms=26706]\n'
        '##[group]Run /usr/bin/git config --global --add url."***github.com/".insteadOf git@github.com:\n'
        'shell: /usr/bin/bash -e {0}\n'
        '##[endgroup]\n'
        '##[group]Run actions/cache@caa296126883cff596d87d8935842f9db880ef25\n'
        'with:\n'
        '  path: node_modules/.cache/dependency-cruiser\n'
        '##[endgroup]\n'
        'Cache hit for: dependency-cruiser-cache\n'
        '##[group]Run pnpm deps:validate\n'
        '\$ depcruise src\n'
        '##[endgroup]\n';

    final steps = <JobRunStep>[
      JobRunStep(
        number: 1,
        name: 'Set up job',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
      JobRunStep(
        number: 2,
        name: 'Checkout default branch',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
      JobRunStep(
        number: 3,
        name: 'Setup Node.js and pnpm',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
      JobRunStep(
        number: 4,
        name: 'Set GitHub credential for cloning test-backend',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
      JobRunStep(
        number: 5,
        name: 'Cache dependency-cruiser',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
      JobRunStep(
        number: 6,
        name: 'Validate dependencies',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
      JobRunStep(
        number: 7,
        name: 'Complete job',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
    ];

    test('nested action invocations do not open phantom sections', () {
      final titles = sliceJobLog(log).map((s) => s.title).toList();
      expect(titles, [
        'Run actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803',
        'Run ./.github/actions/ci-setup',
        'Run /usr/bin/git config --global --add url."***github.com/".insteadOf git@github.com:',
        'Run actions/cache@caa296126883cff596d87d8935842f9db880ef25',
        'Run pnpm deps:validate',
      ]);
    });

    test(
      'the composite step keeps all three children after its own group closes',
      () {
        final ciSetup = sliceJobLog(log)[1];
        expect(ciSetup.title, 'Run ./.github/actions/ci-setup');
        expect(ciSetup.body, contains('##[start-action display=Setup pnpm'));
        expect(ciSetup.body, contains('##[start-action display=Setup Node.js'));
        expect(
          ciSetup.body,
          contains('##[start-action display=Install pnpm dependencies'),
        );
        expect(ciSetup.body, contains('Resolved .nvmrc as 24.15'));
        expect(ciSetup.body, contains('installing deps'));
      },
    );

    test('order pairing stays aligned across the composite step', () {
      final result = mapStepsToSections(steps, sliceJobLog(log));
      expect(result[1]!.title, startsWith('Run actions/checkout@'));
      expect(result[2]!.title, 'Run ./.github/actions/ci-setup');
      // The regression: the git-config `run:` step pairs with its own
      // section instead of showing "No logs captured for this step."
      expect(result[3]!.title, startsWith('Run /usr/bin/git config'));
      expect(result[4]!.title, startsWith('Run actions/cache@'));
      expect(result[5]!.title, 'Run pnpm deps:validate');
    });

    test('the composite body renders GitHub-shaped rows', () {
      final ciSetup = sliceJobLog(log)[1];
      final nodes = parseLogLines(ciSetup.body);
      // Row 1: the step's own (empty) `▼ Run ./.github/actions/ci-setup`
      // fold; rows 2-4: one fold per composite child.
      expect(nodes[0].isGroup, isTrue);
      expect(nodes[0].title, 'Run ./.github/actions/ci-setup');
      expect(nodes[0].children, isEmpty);
      expect(nodes.sublist(1).map((n) => n.title), [
        'Setup pnpm',
        'Setup Node.js',
        'Install pnpm dependencies',
      ]);
      // The nested `Run pnpm/action-setup@…` invocation folds INSIDE `Setup pnpm`.
      final pnpm = nodes[1];
      expect(pnpm.children[0].title, startsWith('Run pnpm/action-setup@'));
    });
  });
}
