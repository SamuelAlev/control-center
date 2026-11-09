/// Who an agent run's commits name, and whether the host may sign them.
///
/// One rule for every run (the "honest attribution" rule):
///
/// * **Owner-requested**: the owner is author and committer, and the host's
///   signing key (the owner's) may sign.
/// * **Requested by another member**: the member is author (their GitHub
///   noreply address when they are signed in to GitHub), Control Center is
///   committer, and nothing is signed: the host key is not theirs.
/// * **Unrequested** (a schedule, a reconciler): Control Center is author and
///   committer, unsigned.
///
/// The agent run gateway checks every pushed commit against this.
final class AgentCommitIdentity {
  /// Creates an identity. Prefer the named constructors.
  AgentCommitIdentity({
    required this.authorName,
    required this.authorEmail,
    required this.committerName,
    required this.committerEmail,
    required this.mayHostSign,
  }) {
    for (final (field, value) in [
      ('authorName', authorName),
      ('authorEmail', authorEmail),
      ('committerName', committerName),
      ('committerEmail', committerEmail),
    ]) {
      if (value.trim().isEmpty || value.contains(RegExp('[<>\n]'))) {
        throw ArgumentError.value(value, field, 'not a git identity');
      }
    }
  }

  /// The run acts for the machine owner.
  factory AgentCommitIdentity.owner({
    required String name,
    required String email,
  }) => AgentCommitIdentity(
    authorName: name,
    authorEmail: email,
    committerName: name,
    committerEmail: email,
    mayHostSign: true,
  );

  /// The run acts for a member other than the owner.
  factory AgentCommitIdentity.member({
    required String name,
    required String email,
  }) => AgentCommitIdentity(
    authorName: name,
    authorEmail: email,
    committerName: controlCenterName,
    committerEmail: controlCenterEmail,
    mayHostSign: false,
  );

  /// Nobody asked for the run.
  factory AgentCommitIdentity.unrequested() => AgentCommitIdentity(
    authorName: controlCenterName,
    authorEmail: controlCenterEmail,
    committerName: controlCenterName,
    committerEmail: controlCenterEmail,
    mayHostSign: false,
  );

  /// Control Center's own git name.
  static const String controlCenterName = 'Control Center';

  /// Control Center's own git email.
  static const String controlCenterEmail = 'hi@usectrl.dev';

  /// A GitHub account's noreply address, which GitHub attributes to it. The
  /// `<id>+<login>` form survives a rename; the bare `<login>` form is used
  /// only when the account id is unknown (0).
  static String githubNoreply({
    required int accountId,
    required String login,
  }) => accountId > 0
      ? '$accountId+$login@users.noreply.github.com'
      : '$login@users.noreply.github.com';

  /// `GIT_AUTHOR_NAME`.
  final String authorName;

  /// `GIT_AUTHOR_EMAIL`.
  final String authorEmail;

  /// `GIT_COMMITTER_NAME`.
  final String committerName;

  /// `GIT_COMMITTER_EMAIL`.
  final String committerEmail;

  /// Whether the host's signing key may sign this run's commits.
  final bool mayHostSign;

  /// The four `GIT_AUTHOR_*` / `GIT_COMMITTER_*` variables.
  Map<String, String> get environment => {
    'GIT_AUTHOR_NAME': authorName,
    'GIT_AUTHOR_EMAIL': authorEmail,
    'GIT_COMMITTER_NAME': committerName,
    'GIT_COMMITTER_EMAIL': committerEmail,
  };

  @override
  bool operator ==(Object other) =>
      other is AgentCommitIdentity &&
      other.authorName == authorName &&
      other.authorEmail == authorEmail &&
      other.committerName == committerName &&
      other.committerEmail == committerEmail &&
      other.mayHostSign == mayHostSign;

  @override
  int get hashCode => Object.hash(
    authorName,
    authorEmail,
    committerName,
    committerEmail,
    mayHostSign,
  );

  @override
  String toString() =>
      'AgentCommitIdentity(author: $authorName <$authorEmail>, '
      'committer: $committerName <$committerEmail>, '
      'mayHostSign: $mayHostSign)';
}
