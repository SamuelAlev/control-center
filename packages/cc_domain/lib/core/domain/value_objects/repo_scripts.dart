/// Lifecycle shell scripts per registered repo, run by the server against a
/// space's isolated worktree
/// (`…/spaces/<spaceId>/repos/<repo>/`).
/// [setup] runs right after the worktree is materialized (deps, `.env`,
/// symlink). Non-zero exit fails provisioning; the worktree is kept for retry.
/// [archive] runs just before destroy/GC (stop services, clean external
/// resources). Best-effort — failure is recorded, never blocks deletion.
/// Both via `bash -lc` in the worktree with `CC_WORKSPACE_PATH`,
/// `CC_ROOT_PATH`, `CC_SPACE_ID`, `CC_SPACE_NAME`, `CC_REPO_NAME`.
/// Drafts can be tested via `RepoScriptPort.runTest` on a throwaway pristine
/// CoW clone (same vars minus space ones, plus `CC_SCRIPT_TEST=1` so archive
/// scripts skip irreversible steps). Outcomes are recorded; never fail a run.
/// Admin-only in Settings → Repositories — not on the `Repo` DTO (server-
/// executed code rides its own admin-gated RPC, not member `repos.upsert`).
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
