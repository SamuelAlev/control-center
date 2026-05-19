import 'package:cc_domain/features/subscriptions/subscriptions.dart';

/// One Claude Code login Control Center can run the `claude-code` adapter on.
///
/// ## Why accounts exist at all
///
/// Claude Code's credential lives wherever `CLAUDE_CONFIG_DIR` points, and when
/// that variable is set the macOS Keychain is never consulted. Control Center
/// needs its own directory for two independent reasons and they happen to have
/// the same answer:
///
///  1. **The sandbox.** Every Seatbelt profile denies reads under
///     `~/Library/Keychains` (see `SandboxPolicyResolver.secretsDenyReadRels`),
///     and a denied keychain lookup does not fail loudly — it returns "item not
///     found", which Claude Code reports as `Not logged in · Please run
///     /login`. Pointing the CLI at a directory it can actually read is the fix
///     that does not also hand every sandboxed agent the whole login keychain.
///  2. **Multiple logins.** One directory per account is the only isolation the
///     CLI offers, and it is a complete one: credential, identity, settings and
///     session history all move with it.
///
/// ## What is authoritative
///
/// Only [id] and [label] are Control Center's. Everything else —
/// [email], [orgName], [subscriptionType], [loggedIn] — is **read back from
/// `claude auth status --json`** run against this account's directory, never
/// written by us. That matters: the CLI owns the login (the operator runs
/// `claude auth login` in a terminal), so any identity we cached would be a
/// guess that goes stale the moment they sign in as someone else.
class ClaudeAccount {
  /// Creates a [ClaudeAccount].
  const ClaudeAccount({
    required this.id,
    required this.label,
    this.email,
    this.orgName,
    this.subscriptionType,
    this.loggedIn = false,
    this.isDefault = false,
    this.statusError,
    this.rateLimitedUntil,
    this.authFailedAt,
    this.authFailedReason,
    this.credentialExpiresAt,
    this.tracksDefaultLogin = false,
  });

  /// Reads the RPC wire shape.
  factory ClaudeAccount.fromJson(Map<String, dynamic> json) => ClaudeAccount(
    id: json['id'] as String? ?? '',
    label: json['label'] as String? ?? '',
    email: json['email'] as String?,
    orgName: json['org_name'] as String?,
    subscriptionType: json['subscription_type'] as String?,
    loggedIn: json['logged_in'] as bool? ?? false,
    isDefault: json['is_default'] as bool? ?? false,
    statusError: json['status_error'] as String?,
    rateLimitedUntil: DateTime.tryParse(
      json['rate_limited_until'] as String? ?? '',
    ),
    authFailedAt: DateTime.tryParse(json['auth_failed_at'] as String? ?? ''),
    authFailedReason: json['auth_failed_reason'] as String?,
    credentialExpiresAt: DateTime.tryParse(
      json['credential_expires_at'] as String? ?? '',
    ),
    tracksDefaultLogin: json['tracks_default_login'] as bool? ?? false,
  );

  /// Stable opaque id. Also the directory name under the accounts root, so it
  /// is constrained to `[a-z0-9-]` — see `ClaudeAccountStore`.
  final String id;

  /// Operator-facing name. Defaults to the account's email once the CLI
  /// reports one, but stays editable: two logins on the same address (personal
  /// vs. a workspace invite) are indistinguishable otherwise.
  final String label;

  /// Signed-in email, as reported by the CLI. Null until a login completes.
  final String? email;

  /// Organization the login belongs to, as reported by the CLI.
  final String? orgName;

  /// Plan tier (`max`, `pro`, …), as reported by the CLI. Null for a Console
  /// (API-billing) login, which has no subscription.
  final String? subscriptionType;

  /// Whether the CLI reports a usable credential in this directory.
  ///
  /// False is not an error state — a freshly created account is legitimately
  /// logged out until the operator finishes `claude auth login`.
  final bool loggedIn;

  /// Whether dispatches with no explicit account selection fall back to this
  /// one. Exactly one account carries it — see `ClaudeAccountStore.setDefault`.
  final bool isDefault;

  /// Why the status probe failed, when it did. Distinct from `loggedIn: false`:
  /// that is a known-logged-out account, this is an account whose state we
  /// could not determine (the CLI is missing, or it timed out).
  final String? statusError;

  /// When this account stops being rate-limited, if it currently is.
  ///
  /// Set from a REAL capacity response — Claude Code reporting a usage limit on
  /// a terminal `result` — not from the usage endpoint, which is a cached
  /// reading that can lag a plan by minutes. It is the accurate half of the
  /// headroom check: the usage percentage decides in advance, this decides
  /// after the fact, and the second one is never wrong.
  final DateTime? rateLimitedUntil;

  /// When a run last failed on this account because its credential no longer
  /// authenticates (a `401` from an expired OAuth token, a signed-out
  /// directory), if it has.
  ///
  /// Deliberately NOT folded into [rateLimitedUntil]. The two heal differently:
  /// a spent plan comes back by itself at a known time, an expired credential
  /// comes back only when a human runs `claude auth login`. Parking a
  /// signed-out account on a timer would hand it back to the rotation every
  /// half hour to fail again, and would tell the operator "rate limited" about
  /// an account that is simply logged out.
  ///
  /// It self-clears rather than needing to be cleared: the account is usable
  /// again as soon as a NEWER credential appears in its directory — which is
  /// exactly what a re-login (or an in-sandbox refresh) writes. See
  /// `ClaudeAccountStore.availability`.
  final DateTime? authFailedAt;

  /// What the failing run reported, so the operator is told which account to
  /// sign back in and why, rather than just seeing it skipped.
  final String? authFailedReason;

  /// When the OAuth access token in this account's directory stops being
  /// accepted, read from the credential itself. Null when the directory holds
  /// no credential, or one that carries no expiry.
  ///
  /// This is the signal `claude auth status` does not give: it reports the
  /// credential's SHAPE, so a directory whose token expired hours ago still
  /// answers `loggedIn: true`. Before this was read, an expired account showed
  /// as a healthy row while its usage probe 401'd every ten minutes forever and
  /// every run dispatched to it failed to authenticate — the roster and reality
  /// disagreeing with nothing on screen to explain it.
  ///
  /// Nothing here renews it. Claude Code's own CLI refreshes the token when it
  /// runs against that directory (and Control Center mirrors the newer
  /// credential in); Control Center never mints one itself, which is the same
  /// line the harness's Anthropic provider holds. So an expired account is
  /// reported, never repaired: the fix is `claude auth login`.
  final DateTime? credentialExpiresAt;

  /// Whether this account IS the operator's own `~/.claude` login, seeded from
  /// the unsuffixed keychain item rather than signed in through its own
  /// directory.
  ///
  /// It matters for refresh. A directory the CLI logged into owns a keychain
  /// item named after it, and the CLI renews that item — so mirroring keeps the
  /// account fresh. A SEEDED directory has no such item: nothing renews it, and
  /// the snapshot silently expires (measured: expired at 21:57 while the
  /// default item was good until 05:54, and every run on it then 401s). So this
  /// one account follows the default item instead, which is what it is a copy
  /// of.
  final bool tracksDefaultLogin;

  /// Whether the account is cooling off at [now] (defaults to the wall clock).
  bool isRateLimited([DateTime? now]) {
    final until = rateLimitedUntil;
    return until != null && until.isAfter(now ?? DateTime.now());
  }

  /// Whether this account's credential has expired at [now] (defaults to the
  /// wall clock), so it can only fail until someone signs in again.
  bool isCredentialExpired([DateTime? now]) {
    final at = credentialExpiresAt;
    return at != null && !at.isAfter(now ?? DateTime.now());
  }

  /// A one-line description for a picker row: the plan and the org, when known.
  ///
  /// Deliberately not localized — every part of it is a value the CLI handed
  /// back verbatim, and translating around an unknown-shaped string produces
  /// worse output than showing it plainly.
  String get subtitle {
    final parts = [
      if (subscriptionType != null && subscriptionType!.isNotEmpty)
        subscriptionType!,
      if (orgName != null && orgName!.isNotEmpty) orgName!,
    ];
    return parts.join(' · ');
  }

  /// Returns a copy with the given overrides.
  ClaudeAccount copyWith({
    String? label,
    String? email,
    String? orgName,
    String? subscriptionType,
    bool? loggedIn,
    bool? isDefault,
    String? statusError,
    bool clearStatusError = false,
    DateTime? rateLimitedUntil,
    bool clearRateLimitedUntil = false,
    DateTime? authFailedAt,
    String? authFailedReason,
    bool clearAuthFailure = false,
    DateTime? credentialExpiresAt,
    bool clearCredentialExpiresAt = false,
    bool? tracksDefaultLogin,
  }) => ClaudeAccount(
    id: id,
    label: label ?? this.label,
    email: email ?? this.email,
    orgName: orgName ?? this.orgName,
    subscriptionType: subscriptionType ?? this.subscriptionType,
    loggedIn: loggedIn ?? this.loggedIn,
    isDefault: isDefault ?? this.isDefault,
    statusError: clearStatusError ? null : (statusError ?? this.statusError),
    rateLimitedUntil: clearRateLimitedUntil
        ? null
        : (rateLimitedUntil ?? this.rateLimitedUntil),
    authFailedAt: clearAuthFailure ? null : (authFailedAt ?? this.authFailedAt),
    authFailedReason: clearAuthFailure
        ? null
        : (authFailedReason ?? this.authFailedReason),
    credentialExpiresAt: clearCredentialExpiresAt
        ? null
        : (credentialExpiresAt ?? this.credentialExpiresAt),
    tracksDefaultLogin: tracksDefaultLogin ?? this.tracksDefaultLogin,
  );

  /// What the on-disk registry stores: only the fields Control Center owns.
  ///
  /// Deliberately narrower than [toJson]. [loggedIn], [email], [orgName] and
  /// [subscriptionType] are answers from `claude auth status`, and a persisted
  /// copy of an answer goes stale the moment the operator signs in, signs out,
  /// or switches accounts — leaving a file that confidently disagrees with the
  /// CLI. Storing only what we decide (the id, the operator's label, which one
  /// is default) means the registry cannot be wrong about the login.
  Map<String, dynamic> toRegistryJson() => {
    'id': id,
    'label': label,
    'is_default': isDefault,
    // The cooldown IS ours — we observed the rate-limit response — and it has
    // to outlive a server restart, or a bounced process would send the next
    // run straight back into the account that just refused it.
    if (rateLimitedUntil != null)
      'rate_limited_until': rateLimitedUntil!.toIso8601String(),
    // Ours for the same reason the cooldown is — we observed the 401 — and it
    // has to outlive a restart, or a bounced server sends the next run straight
    // back into the account that just refused it.
    if (authFailedAt != null) 'auth_failed_at': authFailedAt!.toIso8601String(),
    if (authFailedReason != null) 'auth_failed_reason': authFailedReason,
    if (tracksDefaultLogin) 'tracks_default_login': true,
  };

  /// The RPC wire shape.
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    if (email != null) 'email': email,
    if (orgName != null) 'org_name': orgName,
    if (subscriptionType != null) 'subscription_type': subscriptionType,
    'logged_in': loggedIn,
    'is_default': isDefault,
    if (statusError != null) 'status_error': statusError,
    if (rateLimitedUntil != null)
      'rate_limited_until': rateLimitedUntil!.toIso8601String(),
    if (authFailedAt != null) 'auth_failed_at': authFailedAt!.toIso8601String(),
    if (authFailedReason != null) 'auth_failed_reason': authFailedReason,
    // Read back from the credential on every list, never stored — a persisted
    // expiry would outlive the login it describes, exactly like a cached
    // `logged_in` would.
    if (credentialExpiresAt != null)
      'credential_expires_at': credentialExpiresAt!.toIso8601String(),
    if (tracksDefaultLogin) 'tracks_default_login': true,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaudeAccount &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          email == other.email &&
          orgName == other.orgName &&
          subscriptionType == other.subscriptionType &&
          loggedIn == other.loggedIn &&
          isDefault == other.isDefault &&
          statusError == other.statusError &&
          rateLimitedUntil == other.rateLimitedUntil &&
          authFailedAt == other.authFailedAt &&
          authFailedReason == other.authFailedReason &&
          credentialExpiresAt == other.credentialExpiresAt &&
          tracksDefaultLogin == other.tracksDefaultLogin;

  @override
  int get hashCode => Object.hash(
    id,
    label,
    email,
    orgName,
    subscriptionType,
    loggedIn,
    isDefault,
    statusError,
    rateLimitedUntil,
    authFailedAt,
    authFailedReason,
    credentialExpiresAt,
    tracksDefaultLogin,
  );
}

/// A [ClaudeAccount] joined with its live plan usage.
///
/// The join exists for the composer's picker, where the question is not "which
/// accounts are there" but "which one should this run use" — and the honest
/// answer depends on how much of each plan's 5-hour and weekly window is
/// already spent. [usage] is null when the account is signed out, when the host
/// wires no usage fetcher, or when the probe failed; the row still renders, it
/// just cannot say how much headroom is left.
class ClaudeAccountView {
  /// Creates a [ClaudeAccountView].
  const ClaudeAccountView({required this.account, this.usage});

  /// Reads the `claude_accounts.list` wire shape.
  factory ClaudeAccountView.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'];
    return ClaudeAccountView(
      account: ClaudeAccount.fromJson(json),
      usage: usage is Map<String, dynamic>
          ? SubscriptionUsage.fromJson(usage)
          : null,
    );
  }

  /// The account.
  final ClaudeAccount account;

  /// Its live plan usage, when known.
  final SubscriptionUsage? usage;

  /// The window closest to being exhausted, which is the one that will stop a
  /// run first and therefore the one worth showing in a one-line row.
  SubscriptionWindow? get tightestWindow {
    final windows = usage?.windows ?? const <SubscriptionWindow>[];
    if (windows.isEmpty) {
      return null;
    }
    return windows.reduce((a, b) => b.usedFraction > a.usedFraction ? b : a);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaudeAccountView &&
          runtimeType == other.runtimeType &&
          account == other.account &&
          usage == other.usage;

  @override
  int get hashCode => Object.hash(account, usage);
}
