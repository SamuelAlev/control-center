import 'package:cc_domain/features/subscriptions/domain/entities/subscription_usage.dart';

/// One connected account whose plan usage can be read.
///
/// Shared input to every usage strategy (Claude, Codex, Cursor, z.ai, Kimi
/// Code). The coordinator fans out N accounts per provider through this shape
/// so a new plan is a new strategy class, not another parameter on the
/// coordinator — and so pinned / round-robin / serial rotation can show the
/// same per-account quota Claude Code already does.
class SubscriptionUsageAccount {
  /// Creates a [SubscriptionUsageAccount].
  const SubscriptionUsageAccount({
    required this.providerId,
    this.accountId,
    this.accountLabel,
    this.accessToken,
    this.apiKey,
    this.baseUrl,
    this.deviceId,
    this.providerAccountId,
    this.configDir,
    this.knownStatus,
    this.knownReason,
  });

  /// Strategy id (`claude`, `codex`, `cursor`, `zai`, `kimi-code`).
  final String providerId;

  /// Our address for this account — a Claude Code id or a harness
  /// `credentialId`. Stamped onto the snapshot so the rotation editor and the
  /// usage pill can page accounts without guessing from labels.
  final String? accountId;

  /// How to name it in one line (email, plan, org, or a key hint).
  final String? accountLabel;

  /// OAuth bearer the caller has already refreshed.
  final String? accessToken;

  /// API key (z.ai GLM Coding Plan, a pasted Cursor session).
  final String? apiKey;

  /// Optional origin override. Each strategy still refuses to send the secret
  /// to a host it does not recognise.
  final String? baseUrl;

  /// Kimi device id (`X-Msh-Device-Id`).
  final String? deviceId;

  /// The vendor's own account id when it differs from [accountId] — Codex's
  /// `chatgpt_account_id` on the usage request.
  final String? providerAccountId;

  /// Exclusive Claude Code config dir for one named login.
  final String? configDir;

  /// When set, skip the network and report this status (signed-out / expired
  /// Claude logins, whose credential already says they cannot answer).
  final SubscriptionStatus? knownStatus;

  /// Why [knownStatus] is set, carried verbatim onto the snapshot.
  final String? knownReason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionUsageAccount &&
          providerId == other.providerId &&
          accountId == other.accountId &&
          accountLabel == other.accountLabel &&
          accessToken == other.accessToken &&
          apiKey == other.apiKey &&
          baseUrl == other.baseUrl &&
          deviceId == other.deviceId &&
          providerAccountId == other.providerAccountId &&
          configDir == other.configDir &&
          knownStatus == other.knownStatus &&
          knownReason == other.knownReason;

  @override
  int get hashCode => Object.hash(
    providerId,
    accountId,
    accountLabel,
    accessToken,
    apiKey,
    baseUrl,
    deviceId,
    providerAccountId,
    configDir,
    knownStatus,
    knownReason,
  );
}
