/// Lifecycle shell scripts configured per registered repo and executed by the
/// server against a space's isolated worktree of that repo (the checkout under
/// `<dataDir>/<workspaceId>/spaces/<spaceId>/repos/<repo>/`).
///
/// Two kinds, modelled on Conductor's per-workspace scripts:
///
/// - [setup] runs in the worktree immediately after the provisioner
///   materializes it (install dependencies, generate files, copy `.env`,
///   symlink). A non-zero exit FAILS the space provisioning; the worktree is
///   kept so a retry resumes a half-finished install.
/// - [archive] runs just before that worktree is destroyed or garbage
///   collected (stop services, clean up resources outside the worktree).
///   It is best-effort: a failure is recorded but never blocks deletion.
///
/// Both run via `bash -lc` with the worktree as the working directory and the
/// environment variables `CC_WORKSPACE_PATH` (the worktree), `CC_ROOT_PATH`
/// (the registered source repo root), `CC_SPACE_ID`, `CC_SPACE_NAME` and
/// `CC_REPO_NAME` set.
///
/// ## Test runs
///
/// A draft of either script can be TESTED from the settings dialog
/// (`RepoScriptPort.runTest`): the server materializes a throwaway
/// copy-on-write clone of the registered repo (pristine — a clean tree, the
/// same state a freshly provisioned worktree is in) and runs the draft there,
/// so nothing in the operator's checkout is touched. A test run exports the
/// same variables minus the space ones (`CC_SPACE_ID`/`CC_SPACE_NAME`) plus
/// `CC_SCRIPT_TEST=1` — the flag an archive script checks to skip the steps
/// that are only safe against a worktree that is really going away. Test
/// outcomes are recorded like any other run and never fail anything.
///
/// Scripts are edited by a workspace admin in Settings → Repositories and are
/// deliberately NOT part of the `Repo` entity/DTO: they are server-executed
/// code, so they travel on their own admin-gated RPC op instead of riding the
/// member-level `repos.upsert`.
class RepoScripts {
  /// Creates [RepoScripts]. Whitespace-only scripts are normalized to null.
  factory RepoScripts({String? setup, String? archive}) => RepoScripts._(
    setup: _normalize(setup),
    archive: _normalize(archive),
  );

  const RepoScripts._({this.setup, this.archive});

  /// No scripts configured — the common case; all lifecycle hooks no-op.
  const RepoScripts.empty()
    : setup = null,
      archive = null;

  /// The setup script body, or null when unset.
  final String? setup;

  /// The archive script body, or null when unset.
  final String? archive;

  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  /// True when neither script is configured.
  bool get isEmpty => setup == null && archive == null;

  /// Copy with. Pass an empty string to clear a script.
  RepoScripts copyWith({String? setup, String? archive}) {
    return RepoScripts(
      setup: setup ?? this.setup,
      archive: archive ?? this.archive,
    );
  }

  /// Wire codec. Absent/blank members decode to null so older payloads and
  /// hand-written JSON behave like "unset".
  Map<String, dynamic> toJson() => {
    if (setup != null) 'setup': setup,
    if (archive != null) 'archive': archive,
  };

  /// Decodes a wire payload defensively: a non-map or non-string members
  /// decode to "unset" rather than throwing.
  static RepoScripts fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RepoScripts.empty();
    }
    dynamic setup;
    dynamic archive;
    try {
      setup = json['setup'];
      archive = json['archive'];
    } on Object {
      return const RepoScripts.empty();
    }
    return RepoScripts(
      setup: setup is String ? setup : null,
      archive: archive is String ? archive : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepoScripts &&
          runtimeType == other.runtimeType &&
          setup == other.setup &&
          archive == other.archive;

  @override
  int get hashCode => Object.hash(setup, archive);
}

/// Which lifecycle moment a script run belongs to.
enum RepoScriptKind {
  /// Runs right after a worktree is provisioned for a space.
  setup('setup'),

  /// Runs just before a worktree is destroyed or garbage collected.
  archive('archive'),

  /// A manual test of a script DRAFT, executed by an admin from the settings
  /// dialog in a throwaway clone of the repo. Recorded like any other run so
  /// the dialog's run list streams its output; never part of provisioning.
  test('test');

  const RepoScriptKind(this.wireName);

  /// Stable wire/storage name.
  final String wireName;

  /// Parses the wire/storage name; null for unknown values.
  static RepoScriptKind? fromName(String? name) {
    if (name == null) {
      return null;
    }
    for (final kind in RepoScriptKind.values) {
      if (kind.wireName == name) {
        return kind;
      }
    }
    return null;
  }
}

/// Outcome state of a script run.
enum RepoScriptRunStatus {
  running('running'),
  succeeded('succeeded'),
  failed('failed'),

  /// The run exceeded its timeout and was killed.
  timedOut('timed_out');

  const RepoScriptRunStatus(this.wireName);

  /// Stable wire/storage name.
  final String wireName;

  /// Parses the wire/storage name; null for unknown values.
  static RepoScriptRunStatus? fromName(String? name) {
    if (name == null) {
      return null;
    }
    for (final status in RepoScriptRunStatus.values) {
      if (status.wireName == name) {
        return status;
      }
    }
    return null;
  }
}
