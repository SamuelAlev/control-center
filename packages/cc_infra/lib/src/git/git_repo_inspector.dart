import 'dart:io';

import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// Git repo inspector.
class GitRepoInspector implements GitRepoInspectorPort {
  /// Creates a [GitRepoInspector].
  const GitRepoInspector();

  /// Reads the `origin` remote at [path], resolves it to a forge and
  /// `owner/name`, and returns the current branch.
  ///
  /// Throws [GitRepoInspectionException] if [path] is not a git work tree,
  /// has no `origin` remote, or the remote is not on a supported forge.
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

    final parsed = parseForgeRemote((remote.stdout as String).trim());
    if (parsed == null) {
      throw GitRepoInspectionException(
        'The `origin` remote is not hosted on a supported forge '
        '(${ForgeHost.supported.map((f) => f.gitHost).join(', ')}).',
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
      forge: parsed.forge,
      owner: parsed.owner,
      repoName: parsed.name,
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
