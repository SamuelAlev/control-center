// ignore_for_file: avoid_classes_with_only_static_members

import 'package:cc_domain/features/model_routing/domain/entities/rate_limit.dart';

/// Classifies provider errors into a [RateLimitReason] and the recovery
/// strategy to apply — the brain that decides *"rotate account"* vs.
/// *"wait and retry"*.
abstract final class RateLimitClassifier {
  // Backoffs per reason.
  static const _quotaBackoff = Duration(minutes: 30);
  static const _rateLimitBackoff = Duration(seconds: 30);
  static const _capacityBackoff = Duration(seconds: 45);
  static const _capacityJitter = Duration(seconds: 30);
  static const _serverBackoff = Duration(seconds: 20);

  static final RegExp _accountRateLimit = RegExp(
    r'account.*rate.?limit|rate.?limit.*account',
    caseSensitive: false,
  );

  /// Classifies an error from its HTTP [status] and/or [message] body.
  ///
  /// The decision tree is a priority cascade: quota (longest, rotates) →
  /// model-capacity (medium + jitter) → per-minute rate-limit (short) →
  /// server error (short) → unknown (treated as quota).
  static RateLimitClassification classify({int? status, String? message}) {
    final reason = reasonFor(status: status, message: message);
    return _strategyFor(reason);
  }

  /// The classified reason only (no strategy). The cascade order is:
  /// strong quota literals → model capacity →
  /// account-scoped rate limit → per-minute → server → generic quota (lowest).
  static RateLimitReason reasonFor({int? status, String? message}) {
    final m = (message ?? '').toLowerCase();

    // 1) Strong quota signals. Checked first so "exhausted your capacity"
    //    isn't misread as a temporary overload.
    if (m.contains('quota will reset') ||
        m.contains('exhausted your capacity') ||
        m.contains('usage limit') ||
        m.contains('usage_limit') ||
        m.contains('insufficient balance') ||
        m.contains('insufficient_quota') ||
        m.contains('insufficient quota') ||
        m.contains('billing')) {
      return RateLimitReason.quotaExhausted;
    }

    // 2) Model capacity / overload (temporary) — before the generic checks so a
    //    "model overloaded, quota refreshes later" body reads as capacity.
    if (m.contains('overloaded') ||
        m.contains('capacity') ||
        m.contains('resource exhausted') ||
        m.contains('resource_exhausted') ||
        m.contains('529') ||
        m.contains('503') ||
        status == 529 ||
        status == 503) {
      return RateLimitReason.modelCapacity;
    }

    // 3) Account-scoped rate limit → treat as quota (rotate to a sibling).
    if (_accountRateLimit.hasMatch(m)) {
      return RateLimitReason.quotaExhausted;
    }

    // 4) Per-minute / per-hour transient rate limit.
    if (m.contains('per minute') ||
        m.contains('per-minute') ||
        m.contains('per hour') ||
        m.contains('rate limit') ||
        m.contains('rate_limit') ||
        m.contains('ratelimit') ||
        m.contains('too many requests') ||
        m.contains('presque') ||
        status == 429) {
      return RateLimitReason.rateLimitExceeded;
    }

    // 5) Server error.
    if (m.contains('internal server error') ||
        m.contains('internal error') ||
        m.contains('500') ||
        (status != null && status >= 500 && status < 600)) {
      return RateLimitReason.serverError;
    }

    // 6) Generic quota / exhausted (lowest priority).
    if (m.contains('quota') || m.contains('exhausted')) {
      return RateLimitReason.quotaExhausted;
    }

    return RateLimitReason.unknown;
  }

  /// Whether an outcome should be treated as a *usage limit* (i.e. rotate to a
  /// sibling credential).
  ///
  /// True when the message names a usage/quota/resource-exhaustion condition,
  /// OR the status is 429 with an opaque body (no meaningful prose beyond HTTP
  /// framing), OR the status is 429 and the message classifies as quota.
  static bool isUsageLimitOutcome({int? status, String? message}) {
    final m = (message ?? '').toLowerCase();
    if (RegExp(
      r'usage.?limit|quota.?exhausted|resource.?exhausted|insufficient.?quota',
      caseSensitive: false,
    ).hasMatch(m)) {
      return true;
    }
    if (status == 429 && _isOpaqueBody(m)) {
      return true;
    }
    if (status == 429 &&
        reasonFor(status: status, message: message) ==
            RateLimitReason.quotaExhausted) {
      return true;
    }
    return false;
  }

  /// A 429 body is "opaque" when, after stripping the status code and HTTP
  /// framing words, fewer than 3 alphanumeric characters remain — i.e. it
  /// carries no real reason and should be treated as a usage limit (rotate).
  static bool _isOpaqueBody(String message) {
    var s = message.toLowerCase();
    for (final kw in const [
      '429',
      'http',
      'https',
      'status',
      'error',
      'code',
      'response',
      'message',
    ]) {
      s = s.replaceAll(kw, ' ');
    }
    final alnum = s.replaceAll(RegExp('[^a-z0-9]'), '');
    return alnum.length < 3;
  }

  static RateLimitClassification _strategyFor(RateLimitReason reason) {
    switch (reason) {
      case RateLimitReason.quotaExhausted:
        return const RateLimitClassification(
          reason: RateLimitReason.quotaExhausted,
          baseBackoff: _quotaBackoff,
          shouldRotate: true,
        );
      case RateLimitReason.rateLimitExceeded:
        return const RateLimitClassification(
          reason: RateLimitReason.rateLimitExceeded,
          baseBackoff: _rateLimitBackoff,
          shouldRotate: false,
        );
      case RateLimitReason.modelCapacity:
        return const RateLimitClassification(
          reason: RateLimitReason.modelCapacity,
          baseBackoff: _capacityBackoff,
          shouldRotate: false,
          maxJitter: _capacityJitter,
        );
      case RateLimitReason.serverError:
        return const RateLimitClassification(
          reason: RateLimitReason.serverError,
          baseBackoff: _serverBackoff,
          shouldRotate: false,
        );
      case RateLimitReason.unknown:
        // Conservative: behave like a quota hit (long wait, rotate).
        return const RateLimitClassification(
          reason: RateLimitReason.unknown,
          baseBackoff: _quotaBackoff,
          shouldRotate: true,
        );
    }
  }
}
