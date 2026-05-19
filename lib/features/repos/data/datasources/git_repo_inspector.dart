import 'dart:io';

import 'package:control_center/core/domain/entities/git_repo_info.dart';
import 'package:control_center/core/domain/ports/git_repo_inspector_port.dart';

/// Git repo inspector.
class GitRepoInspector implements GitRepoInspectorPort {
  /// Creates a [GitRepoInspector].
  const GitRepoInspector();

  /// Reads the `origin` remote at [path], parses it into owner/repo, and
  /// returns the current branch.
  ///
  /// Throws [GitRepoInspectionException] if [path] is not a git work tree,
  /// has no `origin` remote, or the remote is not hosted on github.com.
  @override
  Future<GitRepoInfo> inspect(String path) async {
    final inside = await _run(path, ['rev-parse', '--is-inside-work-tree']);
    if (inside.exitCode != 0 || (inside.stdout as String).trim() != 'true') {
      throw const GitRepoInspectionException(
        'Folder is not inside a git work tree.',
      );
    }

    final remote = await _run(path, ['remote', 'get-url', 'origin']);
    if (remote.exitCode != 0) {
      throw const GitRepoInspectionException(
        'No `origin` remote configured for this repository.',
      );
    }

    final parsed = parseGitHubRemote((remote.stdout as String).trim());
    if (parsed == null) {
      throw const GitRepoInspectionException(
        'The `origin` remote is not a github.com URL.',
      );
    }

    final branchResult = await _run(path, [
      'rev-parse',
      '--abbrev-ref',
      'HEAD',
    ]);
    final branch = branchResult.exitCode == 0
        ? (branchResult.stdout as String).trim()
        : '';

    return GitRepoInfo(
      path: path,
      owner: parsed.$1,
      repoName: parsed.$2,
      branch: branch == 'HEAD' ? '' : branch,
    );
  }

  Future<ProcessResult> _run(String cwd, List<String> args) async {
    try {
      return await Process.run('git', args, workingDirectory: cwd);
    } on ProcessException catch (e) {
      return ProcessResult(0, 1, '', e.message);
    }
  }
}

