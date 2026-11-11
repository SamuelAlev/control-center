/// A git name and email.
typedef GitPerson = ({String name, String email});

/// Who a run's commits name, whom they credit and whether they are signed.
///
/// One rule, decided by who started the work:
///
/// * **A person did** (a chat in a space, a pipeline they started, a commit
///   they make in the IDE): the commits are theirs ([AgentCommitIdentity.person]).
///   They are author and committer under an address their forge verified
///   for their own sign-in, the commits are signed with their signing key
///   when they set one up, and a `Co-Authored-By:` trailer credits
///   [controlCenter] when attribution is on.
/// * **Nobody did** (a schedule, a webhook): the commits are the agent's
///   ([AgentCommitIdentity.automation]). On GitHub the agent is the
///   workspace's GitHub App bot ([githubAppBot]), anywhere else
///   [controlCenter]. They are never signed (no key vouches for work nobody
///   asked for), and a `Co-Authored-By:` trailer credits each person
///   accountable for the automation when attribution is on.
///
/// Author and committer are always the same identity, and names and emails
/// are kept as git writes them ([asGitWrites]). The agent run gateway holds
/// every commit a run pushes to this, and so does a stack an agent run
/// publishes; what a person pushes themselves is theirs to vouch for.
final class AgentCommitIdentity {
  AgentCommitIdentity._({
    required GitPerson author,
    required this.isPerson,
    List<GitPerson> coAuthors = const [],
    this.signingKey,
  }) : author = _asGitWrites(author),
       coAuthors = List.unmodifiable(coAuthors.map(_asGitWrites)) {
    for (final (field, value) in [
      ('author name', this.author.name),
      ('author email', this.author.email),
      for (final coAuthor in this.coAuthors) ...[
        ('co-author name', coAuthor.name),
        ('co-author email', coAuthor.email),
      ],
    ]) {
      if (value.isEmpty || value.contains(_notIdentity)) {
        throw ArgumentError.value(value, field, 'not a git identity');
      }
    }
    final key = signingKey;
    if (key != null && !_sshEd25519Key.hasMatch(key)) {
      throw ArgumentError.value(key, 'signingKey', 'not an ssh-ed25519 key');
    }
  }

  /// [person] started the work: their commits, signed with [signingKey] (an
  /// `ssh-ed25519 <base64>` public key, no comment) when they have one, and
  /// crediting [controlCenter] when [creditAgent].
  factory AgentCommitIdentity.person(
    GitPerson person, {
    bool creditAgent = false,
    String? signingKey,
  }) => AgentCommitIdentity._(
    author: person,
    isPerson: true,
    coAuthors: [if (creditAgent) controlCenter],
    signingKey: signingKey,
  );

  /// Nobody started the work: [agent]'s commits, unsigned, crediting each of
  /// [accountable] (the people answerable for the automation).
  factory AgentCommitIdentity.automation({
    GitPerson agent = controlCenter,
    List<GitPerson> accountable = const [],
  }) => AgentCommitIdentity._(
    author: agent,
    isPerson: false,
    coAuthors: accountable,
  );

  static final RegExp _notIdentity = RegExp('[<>\r\n\x00]');

  /// [text] as every git writes a name or an email into a commit: without
  /// the leading and trailing characters git strips (everything up to a
  /// space, and `"',:;<>\`), and without a leading or trailing `.`, which git
  /// before 2.46 strips too. A name given as `"Ada"` is committed as `Ada`;
  /// an identity that kept the quotes would never match its own commits, and
  /// one that kept a final dot would match only under a newer git.
  static String asGitWrites(String text) {
    var start = 0;
    var end = text.length;
    while (start < end && _stripped(text.codeUnitAt(start))) {
      start++;
    }
    while (end > start && _stripped(text.codeUnitAt(end - 1))) {
      end--;
    }
    return text.substring(start, end);
  }

  /// `"`, `'`, `,`, `.`, `:`, `;`, `<`, `>` and `\`.
  static const List<int> _strippedMarks = [
    0x22,
    0x27,
    0x2c,
    0x2e,
    0x3a,
    0x3b,
    0x3c,
    0x3e,
    0x5c,
  ];

  static bool _stripped(int unit) =>
      unit <= 0x20 || _strippedMarks.contains(unit);

  static GitPerson _asGitWrites(GitPerson person) =>
      (name: asGitWrites(person.name), email: asGitWrites(person.email));

  static final RegExp _sshEd25519Key = RegExp(
    r'^ssh-ed25519 [A-Za-z0-9+/]+=*$',
  );

  /// Control Center's git name.
  static const String controlCenterName = 'Control Center';

  /// Control Center's git email: the address its forge accounts verify, so a
  /// co-author line links to the product.
  static const String controlCenterEmail = 'hi@usectrl.dev';

  /// Control Center as a git identity: the agent where no GitHub App names
  /// it, and the co-author credited on a person's commits.
  static const GitPerson controlCenter = (
    name: controlCenterName,
    email: controlCenterEmail,
  );

  /// A GitHub App's bot as a git identity: `<slug>[bot]` at the bot
  /// account's noreply address, which GitHub attributes to the App.
  static GitPerson githubAppBot({
    required int botUserId,
    required String slug,
  }) => (
    name: '$slug[bot]',
    email: githubNoreply(accountId: botUserId, login: '$slug[bot]'),
  );

  /// A GitHub account's noreply address, which GitHub attributes to it. The
  /// `<id>+<login>` form survives a rename; the bare `<login>` form is used
  /// only when the account id is unknown (0).
  static String githubNoreply({
    required int accountId,
    required String login,
  }) => accountId > 0
      ? '$accountId+$login@users.noreply.github.com'
      : '$login@users.noreply.github.com';

  /// The author, who is also the committer.
  final GitPerson author;

  /// Whether a person started the work ([AgentCommitIdentity.person]), so
  /// the commits are theirs rather than the agent's.
  final bool isPerson;

  /// Everyone credited in a `Co-Authored-By:` trailer, in order. Every
  /// commit carries exactly these co-author lines and no other.
  final List<GitPerson> coAuthors;

  /// The `ssh-ed25519 <base64>` public key every commit is signed with, or
  /// null when the commits are unsigned. Only a person's commits are signed.
  final String? signingKey;

  /// This identity, unsigned: for a run that has no way to reach the signer.
  AgentCommitIdentity get unsigned => signingKey == null
      ? this
      : AgentCommitIdentity._(
          author: author,
          isPerson: isPerson,
          coAuthors: coAuthors,
        );

  /// One `Co-Authored-By:` line per co-author, in order.
  List<String> get coAuthorTrailers => [
    for (final coAuthor in coAuthors)
      'Co-Authored-By: ${coAuthor.name} <${coAuthor.email}>',
  ];

  /// The four `GIT_AUTHOR_*` / `GIT_COMMITTER_*` variables.
  Map<String, String> get environment => {
    'GIT_AUTHOR_NAME': author.name,
    'GIT_AUTHOR_EMAIL': author.email,
    'GIT_COMMITTER_NAME': author.name,
    'GIT_COMMITTER_EMAIL': author.email,
  };

  @override
  bool operator ==(Object other) =>
      other is AgentCommitIdentity &&
      other.author == author &&
      other.isPerson == isPerson &&
      other.signingKey == signingKey &&
      other.coAuthors.length == coAuthors.length &&
      [
        for (var i = 0; i < coAuthors.length; i++)
          other.coAuthors[i] == coAuthors[i],
      ].every((same) => same);

  @override
  int get hashCode =>
      Object.hash(author, isPerson, signingKey, Object.hashAll(coAuthors));

  @override
  String toString() =>
      'AgentCommitIdentity(${isPerson ? 'person' : 'automation'}: '
      '${author.name} <${author.email}>'
      '${coAuthors.isEmpty ? '' : ', coAuthors: ${coAuthors.map((c) => '${c.name} <${c.email}>').join(', ')}'}'
      '${signingKey == null ? '' : ', signed'})';
}
