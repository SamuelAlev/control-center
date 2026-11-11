/// Whether one Claude Code account holds a credential a run could use, as the
/// server reads it WITHOUT probing the CLI.
///
/// `claude auth login` runs in a terminal, outside Control Center, so nothing
/// reports that it finished. A surface waiting on one reads this before and
/// after and compares the two: see [signedInSince].
class ClaudeSignInState {
  /// Creates a [ClaudeSignInState].
  const ClaudeSignInState({
    required this.accountId,
    required this.signedIn,
    this.credentialExpiresAt,
  });

  /// Reads the `claude_accounts.signInStates` wire shape.
  factory ClaudeSignInState.fromJson(Map<String, dynamic> json) =>
      ClaudeSignInState(
        accountId: json['id'] as String? ?? '',
        signedIn: json['signed_in'] as bool? ?? false,
        credentialExpiresAt: DateTime.tryParse(
          json['credential_expires_at'] as String? ?? '',
        ),
      );

  /// The account this is about.
  final String accountId;

  /// Whether a run would find a working credential in the account's
  /// directory. The same answer dispatch gets, so an access token that lapsed
  /// but can renew itself still counts.
  final bool signedIn;

  /// When the credential's access token lapses, if the credential states it.
  /// It names the credential: a login, like a renewal, always writes a later
  /// one.
  final DateTime? credentialExpiresAt;

  /// Whether a sign-in finished between [before] and this reading.
  ///
  /// [before] is the same account read earlier, or null when it did not exist
  /// yet. The account has to be signed in now, and either was not before or
  /// holds another credential than it did. Being signed in is not enough on
  /// its own: signing a working account in again is a sign-in to wait for too.
  bool signedInSince(ClaudeSignInState? before) =>
      signedIn &&
      (before == null ||
          !before.signedIn ||
          !_sameInstant(credentialExpiresAt, before.credentialExpiresAt));

  /// Compared as instants: a UTC and a local [DateTime] of the same moment
  /// are not `==`.
  static bool _sameInstant(DateTime? a, DateTime? b) =>
      a == null || b == null ? a == b : a.isAtSameMomentAs(b);

  /// The RPC wire shape. The instant is sent in UTC, so it reads the same on a
  /// client in another time zone.
  Map<String, dynamic> toJson() => {
    'id': accountId,
    'signed_in': signedIn,
    if (credentialExpiresAt != null)
      'credential_expires_at': credentialExpiresAt!.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaudeSignInState &&
          runtimeType == other.runtimeType &&
          accountId == other.accountId &&
          signedIn == other.signedIn &&
          credentialExpiresAt == other.credentialExpiresAt;

  @override
  int get hashCode => Object.hash(accountId, signedIn, credentialExpiresAt);
}
