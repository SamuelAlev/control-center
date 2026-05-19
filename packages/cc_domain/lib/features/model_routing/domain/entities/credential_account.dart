/// A single credential (API key or OAuth account) for a provider. Multiple
/// accounts per provider are ranked by remaining headroom (feature #4).
class CredentialAccount {
  /// Creates a [CredentialAccount].
  const CredentialAccount({
    required this.id,
    required this.providerId,
    this.label,
    this.email,
    this.isApiKey = false,
    this.priorityBoost = false,
    this.order = 0,
  });

  /// Stable account id (used as the rank/block key).
  final String id;

  /// Owning provider id.
  final String providerId;

  /// Display label.
  final String? label;

  /// Account email, if OAuth.
  final String? email;

  /// Whether this is a raw API key (vs. an OAuth account).
  final bool isApiKey;

  /// A provider-specific priority boost (e.g. a Pro plan).
  final bool priorityBoost;

  /// The account's original configured position (tiebreak of last resort).
  final int order;

  /// A stable identity for usage history (email if present, else id).
  String get accountKey => email ?? id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CredentialAccount &&
          id == other.id &&
          providerId == other.providerId;

  @override
  int get hashCode => Object.hash(id, providerId);

  @override
  String toString() => 'CredentialAccount($providerId/$id)';
}

/// Records that a credential is blocked (e.g. quota exhausted) until a time,
/// optionally scoped to a model family.
class AccountBlockState {
  /// Creates an [AccountBlockState].
  const AccountBlockState({
    required this.accountId,
    required this.blockedUntil,
    this.scope,
  });

  /// The blocked account.
  final String accountId;

  /// When the block lifts.
  final DateTime blockedUntil;

  /// Model-family scope (block-all-or-nothing within a scope), if any.
  final String? scope;

  /// Whether the block is still active at [now].
  bool isActiveAt(DateTime now) => now.isBefore(blockedUntil);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountBlockState &&
          accountId == other.accountId &&
          blockedUntil == other.blockedUntil &&
          scope == other.scope;

  @override
  int get hashCode => Object.hash(accountId, blockedUntil, scope);
}
