import 'dart:async';
import 'dart:io';

import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:dio/dio.dart';

/// Fetches live subscription usage for ONE AI coding plan.
///
/// Shared interface for Claude, Codex, Cursor, z.ai and Kimi Code. Each
/// provider is its own class in its own file; the only thing they share is
/// this contract plus [SubscriptionUsageAccount], so multi-account rotation
/// (pinned / round-robin / serial) can page the same snapshots the title-bar
/// pill shows.
///
/// Strategies degrade independently and never throw out of [guarded]: missing
/// credentials → [SubscriptionStatus.unconfigured], a spent plan →
/// [SubscriptionStatus.exhausted], a failed fetch → [SubscriptionStatus.error].
abstract class SubscriptionUsageStrategy {
  /// Creates a strategy for [providerId] / [displayName].
  const SubscriptionUsageStrategy({
    required this.providerId,
    required this.displayName,
  });

  /// Stable provider id (`claude`, `codex`, `cursor`, `zai`, `kimi-code`).
  final String providerId;

  /// Human display name (`Claude`, `Codex`, `Cursor`, `z.ai`, `Kimi Code`).
  final String displayName;

  /// Bound on every outbound usage request.
  static const Duration requestTimeout = Duration(seconds: 10);

  /// Reads [account]'s usage. May throw; callers use [guarded].
  Future<SubscriptionUsage> fetchAccount(SubscriptionUsageAccount account);

  /// [fetchAccount] for a nameless account of this provider — the single-
  /// account / unconfigured path.
  Future<SubscriptionUsage> fetch() =>
      fetchAccount(SubscriptionUsageAccount(providerId: providerId));

  /// [fetchAccount] with the degrade contract: a stray throw (including
  /// pre-`try` work like file-existence checks) becomes an
  /// [SubscriptionStatus.error] snapshot instead of rejecting the whole batch.
  Future<SubscriptionUsage> guarded([SubscriptionUsageAccount? account]) =>
      (account == null ? fetch() : fetchAccount(account)).catchError(
        (Object e) => error(shortError(e)),
      );

  /// A successful reading.
  SubscriptionUsage ok(
    List<SubscriptionWindow> windows, {
    SubscriptionSpend? spend,
  }) => SubscriptionUsage(
    providerId: providerId,
    displayName: displayName,
    status: SubscriptionStatus.ok,
    windows: windows,
    spend: spend,
    fetchedAt: DateTime.now().toUtc(),
  );

  /// No credentials / the provider isn't set up on this machine.
  SubscriptionUsage unconfigured(String reason) => SubscriptionUsage(
    providerId: providerId,
    displayName: displayName,
    status: SubscriptionStatus.unconfigured,
    error: reason,
    fetchedAt: DateTime.now().toUtc(),
  );

  /// A fetch was attempted but failed.
  SubscriptionUsage error(String reason) => SubscriptionUsage(
    providerId: providerId,
    displayName: displayName,
    status: SubscriptionStatus.error,
    error: reason,
    fetchedAt: DateTime.now().toUtc(),
  );

  /// The plan answered and has nothing left. [reason] is the provider's own
  /// sentence, carried verbatim so the popover can show what it actually said.
  SubscriptionUsage exhausted(String reason) => SubscriptionUsage(
    providerId: providerId,
    displayName: displayName,
    status: SubscriptionStatus.exhausted,
    error: reason,
    fetchedAt: DateTime.now().toUtc(),
  );

  /// A number from a JSON value that may be numeric or a numeric string.
  num? asNum(Object? raw) =>
      raw is num ? raw : (raw is String ? num.tryParse(raw) : null);

  /// An ISO-8601 instant, or null when [raw] isn't a parseable string.
  DateTime? parseIso(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;

  /// A short, credential-free reason for a failed fetch.
  String shortError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code != null) {
        return 'HTTP $code';
      }
      return switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => 'Timed out',
        DioExceptionType.connectionError => 'Network error',
        _ => 'Request failed',
      };
    }
    if (e is TimeoutException) {
      return 'Timed out';
    }
    if (e is ProcessException) {
      return 'CLI unavailable';
    }
    return 'Unavailable';
  }
}
