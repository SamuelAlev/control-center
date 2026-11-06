import 'dart:convert';

/// The generated definition of one repo's lifecycle scripts.
typedef RepoScriptsDefinition = ({String id, String name, String json});

/// The definition replacing [setup] and [archive], or null when neither holds
/// anything to run.
///
/// Part of a schema migration, so this is deliberately frozen as plain JSON
/// instead of built from `EnvironmentDefinition`: what an old file migrates to
/// must not move when the domain model does.
///
/// The role has no anchor, and every task follows the worktree, so the result
/// has no stack and no Start button: a worktree outlives any environment and
/// these scripts must keep running in spaces where nobody presses Start. The
/// id is derived from the repo so a re-entered migration can't duplicate it.
/// Script text is stored unchanged as a shell string, which the runner hands
/// to `bash -lc`, as the scripts always ran.
RepoScriptsDefinition? repoScriptsDefinition({
  required String repoId,
  required String repoName,
  String? setup,
  String? archive,
}) {
  final hasSetup = setup != null && setup.trim().isNotEmpty;
  final hasArchive = archive != null && archive.trim().isNotEmpty;
  if (!hasSetup && !hasArchive) {
    return null;
  }
  final name = repoName.trim().isEmpty ? repoId : repoName;
  return (
    id: 'repo-scripts-$repoId',
    name: name,
    json: jsonEncode({
      'contract': 1,
      'name': name,
      'repos': {
        'app': {'repoId': repoId},
      },
      'components': [
        if (hasSetup)
          {
            'kind': 'task',
            'id': 'setup',
            'when': ['provision'],
            'command': setup,
          },
        if (hasArchive)
          {
            'kind': 'task',
            'id': 'archive',
            'when': ['archive'],
            'command': archive,
          },
      ],
    }),
  );
}
