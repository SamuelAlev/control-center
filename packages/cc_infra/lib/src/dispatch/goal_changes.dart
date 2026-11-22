import 'dart:io';

import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_review_prompt.dart'
    show goalReviewTestDiffHeading;
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_start_refs.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_natives/cc_natives.dart' show IsolatedGit;
import 'package:path/path.dart' as p;

/// Runs git (the server's only way: [IsolatedGit.run]); a test seam.
typedef GoalGitRunner =
    Future<ProcessResult> Function(
      List<String> arguments, {
      required String workingDirectory,
    });

/// What changed since a goal started, for its reviewer (plan section 8,
/// "Verification"): the diff stat of each of the conversation's checkouts
/// against the commit its HEAD was at when the goal started
/// ([AgentGoalRun.startRefs], recorded by [startRefs]; the working tree
/// included, and the files git does not track yet), or, without a checkout,
/// the checklist items added or changed since then. A goal whose start was
/// not recorded gets no diff summary: commit dates are no base. The text is
/// the worker's doing and goes into the review prompt inside a data block.
///
/// Ahead of the stat, so no cut drops it, comes the unified diff of every
/// test file ([isTestPath]) and every file a check command names
/// ([namedByChecks]) that was modified or deleted since the start (the
/// best-practice review, G3: changing tests is how agents most often game
/// their checks), at most [maxTestDiffChars] in all; a file cut short says
/// so and how many lines are missing, and a deleted one is listed by name.
class GoalChanges {
  /// Creates the reader.
  GoalChanges({
    required this.conversations,
    required this.filesystem,
    required this.todos,
    GoalGitRunner? git,
  }) : _git = git ?? _isolatedGit;

  /// Finds the conversation's space, scoped to its workspace.
  final ConversationRepository conversations;

  /// Where the space's checkouts are.
  final WorkspaceFilesystemPort filesystem;

  /// The conversation's checklist; null where none is kept.
  final TodoRepository? todos;

  final GoalGitRunner _git;

  /// The most characters of one checkout's summary.
  static const int maxCharsPerCheckout = 4000;

  /// The most untracked files listed for one checkout.
  static const int maxUntracked = 40;

  /// The most characters of the diff of tests and files the checks name,
  /// over all checkouts.
  static const int maxTestDiffChars = 12000;

  /// The most such files diffed (one git command each).
  static const int maxTestDiffFiles = 40;

  /// How long one git command may take.
  static const Duration gitTimeout = Duration(seconds: 20);

  /// git's empty tree: the base of a checkout that had no commit yet when
  /// the goal started.
  static const String emptyTree = '4b825dc642cb6eb9a060e54bf8d69288fbee4904';

  static Future<ProcessResult> _isolatedGit(
    List<String> arguments, {
    required String workingDirectory,
  }) => IsolatedGit.run(arguments, workingDirectory: workingDirectory);

  /// The summary for [goal]; empty when nothing could be read.
  Future<String> of(AgentGoalRun goal) async {
    final checkouts = await _checkouts(goal.workspaceId, goal.conversationId);
    if (checkouts.isNotEmpty) {
      final start = goal.startRefs;
      if (start == null) {
        return '';
      }
      final parts = <String>[];
      final tests = _TestDiffs(maxTestDiffChars);
      final runs = [
        for (final check in goal.contract?.checks ?? const <GoalCheck>[])
          check.run,
      ];
      for (final dir in checkouts) {
        final name = p.basename(dir);
        final base = start.refs[name];
        final stat = base == null
            ? 'added after the goal started'
            : await _diffStat(dir, base);
        if (stat != null) {
          parts.add('repos/$name:\n$stat');
          if (base != null) {
            await _testDiffs(dir, 'repos/$name', base, runs, tests);
          }
        }
      }
      if (parts.isNotEmpty) {
        return [
          if (tests.isNotEmpty) '$goalReviewTestDiffHeading\n$tests',
          ...parts,
        ].join('\n\n');
      }
    }
    return _checklistChanges(goal);
  }

  /// The commit each checkout of [conversationId] is at now
  /// ([GoalStartRefs.noCommit] for one without a commit); null when it has
  /// none, or one could not be read (no summary beats a wrong one).
  Future<GoalStartRefs?> startRefs(
    String workspaceId,
    String conversationId,
  ) async {
    final checkouts = await _checkouts(workspaceId, conversationId);
    if (checkouts.isEmpty) {
      return null;
    }
    final refs = <String, String>{};
    try {
      for (final dir in checkouts) {
        final result = await _git(const [
          'rev-parse',
          '--verify',
          '-q',
          'HEAD^{commit}',
        ], workingDirectory: dir).timeout(gitTimeout);
        final out = result.stdout;
        refs[p.basename(dir)] = switch (result.exitCode) {
          0 when out is String => out.trim(),
          // A repository without a commit yet.
          1 => GoalStartRefs.noCommit,
          _ => throw StateError('git rev-parse exited ${result.exitCode}'),
        };
      }
      return GoalStartRefs(refs);
    } on Object catch (e) {
      CcInfraLog.warning('goal start refs of $conversationId failed: $e');
      return null;
    }
  }

  Future<List<String>> _checkouts(
    String workspaceId,
    String conversationId,
  ) async {
    try {
      final conversation = await conversations.getById(
        workspaceId: workspaceId,
        conversationId: conversationId,
      );
      if (conversation == null) {
        return const [];
      }
      final reposDir = Directory(
        p.join(
          await filesystem.spaceDir(workspaceId, conversation.spaceId),
          'repos',
        ),
      );
      if (!reposDir.existsSync()) {
        return const [];
      }
      return [
        for (final entry in reposDir.listSync(followLinks: false))
          if (entry is Directory) entry.path,
      ]..sort();
    } on Object catch (e) {
      CcInfraLog.warning('listing checkouts of $conversationId failed: $e');
      return const [];
    }
  }

  Future<String?> _diffStat(String dir, String base) async {
    try {
      final from = base == GoalStartRefs.noCommit ? emptyTree : base;
      final stat = await _run(dir, ['diff', '--stat', from]);
      if (stat == null) {
        // The start commit is gone (the checkout was replaced): no base.
        return null;
      }
      final status = await _run(dir, [
        'status',
        '--porcelain',
        '--untracked-files=all',
      ]);
      final untracked = [
        for (final line in (status ?? '').split('\n'))
          if (line.startsWith('?? ')) line.substring(3).trim(),
      ];
      final out = StringBuffer(stat.trimRight());
      if (untracked.isNotEmpty) {
        if (out.isNotEmpty) {
          out.writeln();
        }
        out.write('Not tracked by git yet: ');
        out.write(untracked.take(maxUntracked).join(', '));
        if (untracked.length > maxUntracked) {
          out.write(' (and ${untracked.length - maxUntracked} more)');
        }
      }
      final text = out.isEmpty ? 'no changes' : out.toString();
      return text.length > maxCharsPerCheckout
          ? '${text.substring(0, maxCharsPerCheckout)}\n(cut)'
          : text;
    } on Object catch (e) {
      CcInfraLog.warning('goal diff stat in $dir failed: $e');
      return null;
    }
  }

  /// Adds to [into] the diff since [base] of each test file and file named
  /// by [runs] that [dir] (shown as [label]) modified or deleted. A failure
  /// leaves the section as it is: the stat still says what changed.
  Future<void> _testDiffs(
    String dir,
    String label,
    String base,
    List<String> runs,
    _TestDiffs into,
  ) async {
    try {
      final from = base == GoalStartRefs.noCommit ? emptyTree : base;
      final names = await _run(dir, [
        'diff',
        '--name-status',
        '--no-renames',
        '-z',
        from,
      ]);
      if (names == null) {
        return;
      }
      final fields = names.split('\x00');
      for (var i = 0; i + 1 < fields.length; i += 2) {
        final status = fields[i];
        final path = fields[i + 1];
        if (status.isEmpty ||
            !(status.startsWith('M') ||
                status.startsWith('D') ||
                status.startsWith('T')) ||
            !(isTestPath(path) || namedByChecks(path, runs))) {
          continue;
        }
        if (status.startsWith('D')) {
          into.deleted('$label/$path');
          continue;
        }
        if (into.files >= maxTestDiffFiles || into.full) {
          into.notShown('$label/$path');
          continue;
        }
        final diff = await _run(dir, [
          'diff',
          '--no-color',
          '--no-textconv',
          from,
          '--',
          path,
        ]);
        if (diff != null && diff.trim().isNotEmpty) {
          into.diff('$label/$path', diff.trimRight());
        }
      }
    } on Object catch (e) {
      CcInfraLog.warning('goal test diffs in $dir failed: $e');
    }
  }

  static final RegExp _testDir = RegExp(
    r'(^|/)(tests?|__tests__|specs?|testing|testdata|test_data|fixtures|'
    r'goldens?|__snapshots__|integration_test|e2e|androidTest)/',
  );
  static final RegExp _testName = RegExp(
    r'(^|/)(test_[^/]+|[^/]+_test\.[^/]+|[^/]+_spec\.[^/]+|'
    r'[^/]+\.(test|spec)\.[^/]+|'
    r'[^/]+(Test|Tests|Spec|IT)\.(java|kt|kts|scala|cs|swift|groovy|php|m)|'
    r'conftest\.py|[^/]+\.snap)$',
  );

  /// Whether [path] is a test by the usual directory and name patterns
  /// across languages (`test/`, `__tests__/`, `*_test.go`, `test_*.py`,
  /// `*.spec.ts`, `FooTest.java`, snapshots and fixtures).
  static bool isTestPath(String path) =>
      _testDir.hasMatch(path) || _testName.hasMatch(path);

  /// The files a command's first word reads its targets from.
  static const Map<String, List<String>> _runnerFiles = {
    'make': ['Makefile', 'makefile', 'GNUmakefile'],
    'npm': ['package.json'],
    'npx': ['package.json'],
    'pnpm': ['package.json'],
    'yarn': ['package.json'],
    'bun': ['package.json'],
    'just': ['justfile', 'Justfile'],
  };

  /// Whether one of the check commands [runs] names [path]: a word of the
  /// command that is the path (or ends with it, or it ends with the word),
  /// or the file a runner reads (`make` its Makefile, `npm` its
  /// package.json).
  static bool namedByChecks(String path, List<String> runs) {
    final base = p.posix.basename(path);
    for (final run in runs) {
      for (final command in run.split(RegExp(r'&&|\|\||[;|\n]'))) {
        final words = command
            .split(RegExp(r'''[\s&()<>'"`=]+'''))
            .where((w) => w.isNotEmpty)
            .map((w) => w.startsWith('./') ? w.substring(2) : w)
            .toList();
        if (words.isNotEmpty &&
            (_runnerFiles[words.first]?.contains(base) ?? false)) {
          return true;
        }
        for (final word in words) {
          if ((word.contains('/') || word.contains('.')) &&
              (path == word ||
                  path.endsWith('/$word') ||
                  word.endsWith('/$path'))) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<String?> _run(String dir, List<String> args) async {
    final result = await _git(args, workingDirectory: dir).timeout(gitTimeout);
    if (result.exitCode != 0) {
      return null;
    }
    final out = result.stdout;
    return out is String ? out : '';
  }

  Future<String> _checklistChanges(AgentGoalRun goal) async {
    final repo = todos;
    if (repo == null) {
      return '';
    }
    try {
      final items = await repo.list(goal.workspaceId, goal.conversationId);
      final changed = [
        for (final item in items)
          if (!item.updatedAt.isBefore(goal.createdAt) ||
              !item.createdAt.isBefore(goal.createdAt))
            '- [${item.status.name}] ${item.content}',
      ];
      if (changed.isEmpty) {
        return '';
      }
      return 'Checklist items added or changed since the goal started:\n'
          '${changed.join('\n')}';
    } on Object catch (e) {
      CcInfraLog.warning('goal ${goal.id}: checklist read failed: $e');
      return '';
    }
  }
}

/// The section of the change summary with the diff of tests and files the
/// checks name, held to a character budget: a file's diff stops where the
/// budget does, with a line that says how many lines are missing, and the
/// files that no longer fit are counted at the end.
class _TestDiffs {
  _TestDiffs(this._budget);

  int _budget;
  final StringBuffer _out = StringBuffer();
  int _unlisted = 0;

  /// Room kept for the line that says a file was cut.
  static const int _markerRoom = 80;

  /// Room kept for the closing line that counts the files left out, so the
  /// section stays within the limit with it.
  static const int _trailerRoom = 120;

  /// Files whose diff was added.
  int files = 0;

  /// Whether the budget is spent.
  bool get full => _budget <= _markerRoom + _trailerRoom;

  bool get isNotEmpty => _out.isNotEmpty || _unlisted > 0;

  /// Writes [line] when it fits in what is left past [keep].
  bool _line(String line, {int keep = 0}) {
    if (line.length + 1 > _budget - keep) {
      return false;
    }
    if (_out.isNotEmpty) {
      _out.writeln();
    }
    _out.write(line);
    _budget -= line.length + 1;
    return true;
  }

  void deleted(String path) {
    if (!_line('$path: deleted', keep: _markerRoom + _trailerRoom)) {
      _unlisted++;
    }
  }

  void notShown(String path) {
    if (!_line(
      '$path: modified; diff not shown (the '
      '${GoalChanges.maxTestDiffChars}-character limit was reached)',
      keep: _markerRoom + _trailerRoom,
    )) {
      _unlisted++;
    }
  }

  void diff(String path, String diff) {
    if (!_line('$path:', keep: _markerRoom + _trailerRoom)) {
      _unlisted++;
      return;
    }
    files++;
    final lines = diff.split('\n');
    var kept = 0;
    for (final line in lines) {
      if (!_line(line, keep: _markerRoom + _trailerRoom)) {
        break;
      }
      kept++;
    }
    final missing = lines.length - kept;
    if (missing > 0) {
      _line(
        '[cut: $missing more lines of this file\'s diff not shown]',
        keep: _trailerRoom,
      );
    }
  }

  @override
  String toString() {
    if (_unlisted == 0) {
      return _out.toString();
    }
    final more =
        '(and $_unlisted more modified or deleted test or check '
        'file${_unlisted == 1 ? '' : 's'} not listed: the limit was reached)';
    return _out.isEmpty ? more : '$_out\n$more';
  }
}
