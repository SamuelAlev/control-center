import 'package:control_center/core/config/env_config.dart';
import 'package:control_center/core/domain/events/calendar_events.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/data/repositories/google_credentials_repository.dart';
import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The public (iOS-type) Google OAuth client id (from env / `.env`). There is
/// no client secret — the iOS client is a public client and the PKCE flow needs
/// none, which is what lets the binary ship without embedding a secret.
final googleClientIdProvider = Provider<String>(
  (ref) => EnvConfig.googleOAuthClientId,
);

/// Builds the deterministic account id for a workspace + Google account email.
/// Embedding the workspace keeps the keychain key (and thus the tokens)
/// workspace-isolated; embedding the email lets a workspace hold many accounts.
String googleAccountId(String workspaceId, String email) =>
    'google:$workspaceId:$email';

/// Recovers the workspace id embedded in a [googleAccountId], or null if
/// [accountId] is not a well-formed Google account id. Safe to split on `:`:
/// workspace ids are UUIDs and an email's local-part/domain contain no `:`, so
/// the workspace id is always the second `:`-separated segment. Fails closed
/// (returns null) rather than throwing so a future id-format change is caught.
String? googleAccountWorkspaceId(String accountId) {
  final parts = accountId.split(':');
  if (parts.length < 3 || parts[0] != 'google' || parts[1].isEmpty) {
    return null;
  }
  return parts[1];
}

/// Per-account Google token store + refresh. Loads/refreshes OAuth tokens keyed
/// by `accountId`, single-flighting refreshes per account so concurrent API
/// calls for the same account share one refresh.
///
/// This is the multi-account replacement for the old per-workspace
/// `GoogleCredentialsNotifier`: there is no longer a single "active" Google
/// account — every API request names the account it is for (see the dio
/// interceptor), and this manager hands back a valid token for it.
class GoogleTokenManager {
  /// Creates a [GoogleTokenManager].
  GoogleTokenManager(
    this._repository,
    this._oauthRefresh, {
    Future<void> Function(String accountId)? onRefreshTokenInvalid,
  }) : _onRefreshTokenInvalid = onRefreshTokenInvalid;

  final GoogleCredentialsRepository _repository;

  /// Refreshes a token given the stored refresh token. Injected so tests don't
  /// need the full OAuth service.
  final Future<({String accessToken, DateTime expiresAt})?> Function(
    String refreshToken,
  ) _oauthRefresh;

  /// Invoked once a refresh fails *terminally* (Google `invalid_grant` — the
  /// refresh token is revoked/expired and can never recover without
  /// re-consent). Wired by the provider to flag the account + notify the user.
  /// Not called for transient failures, which the next sync retries.
  final Future<void> Function(String accountId)? _onRefreshTokenInvalid;

  final Map<String, Future<GoogleCredentials?>> _inFlight = {};

  /// A valid access token for [accountId], refreshing first if it is expired.
  /// Returns null when the account has no usable credentials.
  Future<String?> accessTokenFor(String accountId) async {
    var creds = await _repository.load(accountId);
    if (creds == null) {
      return null;
    }
    if (creds.isExpired()) {
      creds = await _refresh(accountId) ?? creds;
    }
    return creds.accessToken.isEmpty ? null : creds.accessToken;
  }

  /// Forces a refresh (used after a 401) and returns the new access token.
  Future<String?> forceRefresh(String accountId) async =>
      (await _refresh(accountId))?.accessToken;

  Future<GoogleCredentials?> _refresh(String accountId) {
    // NB: the cleanup MUST be a block body. `whenComplete` awaits any Future its
    // action returns, and `Map.remove` returns the stored future (this very
    // future), so an arrow body `() => _inFlight.remove(accountId)` makes the
    // refresh future wait on itself — a permanent deadlock that hangs every
    // token refresh (and thus all calendar syncing).
    return _inFlight[accountId] ??= _doRefresh(accountId).whenComplete(() {
      _inFlight.remove(accountId);
    });
  }

  Future<GoogleCredentials?> _doRefresh(String accountId) async {
    final current = await _repository.load(accountId);
    if (current == null || current.refreshToken.isEmpty) {
      return null;
    }
    try {
      final refreshed = await _oauthRefresh(current.refreshToken);
      if (refreshed == null) {
        return null;
      }
      await _repository.updateAccessToken(
        accountId,
        accessToken: refreshed.accessToken,
        expiresAt: refreshed.expiresAt,
      );
      return current.copyWithAccessToken(
        accessToken: refreshed.accessToken,
        expiresAt: refreshed.expiresAt,
      );
    } on GoogleOAuthException catch (e) {
      AppLog.w('GoogleAuth', 'Token refresh failed for $accountId: ${e.message}');
      if (e.kind == GoogleOAuthFailureKind.invalidGrant) {
        // Terminal: the refresh token is dead. Notify so the account is flagged
        // for reconnect. Guard it — this runs inside the single-flighted refresh
        // future, so a throw here must not escape and poison that future.
        try {
          await _onRefreshTokenInvalid?.call(accountId);
        } on Object catch (e, st) {
          AppLog.e('GoogleAuth', 'onRefreshTokenInvalid handler failed', e, st);
        }
      }
      return null;
    }
  }
}

/// Provides the [GoogleTokenManager], wired to the OAuth refresh endpoint.
final googleTokenManagerProvider = Provider<GoogleTokenManager>((ref) {
  final oauth = ref.watch(googleOAuthServiceProvider);
  return GoogleTokenManager(
    ref.watch(googleCredentialsRepositoryProvider),
    (refreshToken) async {
      final refreshed = await oauth.refresh(refreshToken);
      return (accessToken: refreshed.accessToken, expiresAt: refreshed.expiresAt);
    },
    // On a terminal refresh failure, flag the account for reconnect and — only
    // on the first transition — publish [CalendarAuthExpired] so the user is
    // notified once. Uses `ref.read` (this fires asynchronously, long after the
    // provider built; watching here would rebuild the manager).
    onRefreshTokenInvalid: (accountId) async {
      final workspaceId = googleAccountWorkspaceId(accountId);
      if (workspaceId == null) {
        AppLog.w('GoogleAuth', 'Cannot flag reauth: malformed accountId $accountId');
        return;
      }
      final repo = ref.read(calendarRepositoryProvider);
      final now = DateTime.now();
      final transitioned = await repo.markNeedsReauth(workspaceId, accountId, now);
      if (!transitioned) {
        return; // already flagged — don't notify again this episode
      }
      final email = (await repo.getAccounts(workspaceId))
              .where((a) => a.id == accountId)
              .map((a) => a.accountEmail)
              .firstOrNull ??
          '';
      ref.read(domainEventBusProvider).publish(
            CalendarAuthExpired(
              workspaceId: workspaceId,
              accountEmail: email,
              occurredAt: now,
            ),
          );
    },
  );
});

/// The connected Google accounts for the active workspace (empty when none).
/// Backed by the DB, so connecting/disconnecting updates it reactively.
final googleAccountsProvider =
    StreamProvider<List<CalendarAccount>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(const <CalendarAccount>[]);
  }
  return ref.watch(calendarRepositoryProvider).watchAccounts(workspaceId);
});

/// Connected accounts whose OAuth token died and need the user to reconnect.
/// Drives the calendar "reconnect" banner. Empty while every account is healthy.
final accountsNeedingReauthProvider = Provider<List<CalendarAccount>>((ref) {
  final accounts = ref.watch(googleAccountsProvider).asData?.value ?? const [];
  return accounts.where((a) => a.needsReauth).toList(growable: false);
});
