import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/usage/subscription_usage_strategy.dart';
import 'package:dio/dio.dart';

/// OpenAI Codex (ChatGPT) usage via `GET /backend-api/wham/usage`.
///
/// Same endpoint oh-my-pi uses. The caller supplies an already-refreshed
/// harness OAuth token — this strategy never reads `~/.codex/auth.json` or
/// spawns the Codex CLI.
class CodexUsageStrategy extends SubscriptionUsageStrategy {
  /// Creates a [CodexUsageStrategy].
  CodexUsageStrategy({required Dio dio})
    : _dio = dio,
      super(providerId: 'codex', displayName: 'Codex');

  final Dio _dio;

  @override
  Future<SubscriptionUsage> fetchAccount(SubscriptionUsageAccount account) async {
    final token = account.accessToken?.trim() ?? '';
    if (token.isEmpty) {
      return unconfigured(
        'Sign in to Codex in Settings → Adapters to see usage.',
      );
    }
    try {
      final rawBase = account.baseUrl;
      final base = (rawBase == null || rawBase.trim().isEmpty)
          ? CodexOAuth.backendApi
          : rawBase.trim();
      final parsed = Uri.tryParse(base);
      if (parsed == null ||
          parsed.scheme != 'https' ||
          !CodexOAuth.isChatgptHost(parsed.host)) {
        return error('Invalid Codex base URL.');
      }
      final origin = base.replaceAll(RegExp(r'/+$'), '');
      final chatgptId = account.providerAccountId?.trim();
      final headerId = (chatgptId != null && chatgptId.isNotEmpty)
          ? chatgptId
          : CodexOAuth.accountIdFromToken(token);
      final resp = await _dio.getUri<Map<String, dynamic>>(
        Uri.parse('$origin${CodexOAuth.usagePath}'),
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            if (headerId != null && headerId.isNotEmpty)
              'ChatGPT-Account-Id': headerId,
          },
          sendTimeout: SubscriptionUsageStrategy.requestTimeout,
          receiveTimeout: SubscriptionUsageStrategy.requestTimeout,
        ),
      );
      final windows = parseCodexWhamWindows(resp.data);
      if (windows.isEmpty) {
        return error('Could not read Codex usage.');
      }
      return ok(windows);
    } catch (e) {
      return error(shortError(e));
    }
  }
}

/// Turns a `/wham/usage` JSON body into the two plan windows the pill shows.
///
/// Accepts both the ChatGPT payload (`rate_limit.primary_window`) and the
/// flatter `primary` / `secondary` shape the old CLI handshake used.
List<SubscriptionWindow> parseCodexWhamWindows(Map<String, dynamic>? data) {
  if (data == null) {
    return const [];
  }
  final rate = _asMap(data['rate_limit'] ?? data['rateLimit']);
  final windows = <SubscriptionWindow>[];
  final primary = _asMap(
    rate?['primary_window'] ??
        rate?['primaryWindow'] ??
        data['primary'],
  );
  final secondary = _asMap(
    rate?['secondary_window'] ??
        rate?['secondaryWindow'] ??
        data['secondary'],
  );
  final now = DateTime.now().toUtc();
  final primaryWindow = _windowOf(primary, key: 'primary', now: now);
  final secondaryWindow = _windowOf(secondary, key: 'secondary', now: now);
  if (primaryWindow != null) {
    windows.add(primaryWindow);
  }
  if (secondaryWindow != null) {
    windows.add(secondaryWindow);
  }
  return windows;
}

SubscriptionWindow? _windowOf(
  Map<String, dynamic>? raw, {
  required String key,
  required DateTime now,
}) {
  if (raw == null) {
    return null;
  }
  final used = _num(raw['used_percent'] ?? raw['usedPercent']);
  if (used == null) {
    return null;
  }
  final limitSeconds = _num(
    raw['limit_window_seconds'] ?? raw['limitWindowSeconds'],
  )?.toInt();
  final (:id, :label) = _labelFor(key, limitSeconds);
  return SubscriptionWindow(
    id: id,
    label: label,
    usedFraction: (used / 100).clamp(0.0, 1.0),
    resetsAt: _resetOf(raw, now),
  );
}

({String id, String label}) _labelFor(String key, int? limitSeconds) {
  if (limitSeconds != null && limitSeconds > 0) {
    const daySeconds = 86400;
    if (limitSeconds >= daySeconds) {
      final days = (limitSeconds / daySeconds).round();
      return (id: '${days}d', label: days == 1 ? '1 day' : '$days days');
    }
    final hours = (limitSeconds / 3600).round().clamp(1, 24 * 14);
    return (id: '${hours}h', label: hours == 1 ? '1 hour' : '$hours hours');
  }
  return key == 'primary'
      ? (id: '5h', label: 'Session')
      : (id: '7d', label: 'Weekly');
}

DateTime? _resetOf(Map<String, dynamic> raw, DateTime now) {
  final resetAt = _num(raw['reset_at'] ?? raw['resetAt'] ?? raw['resets_at']);
  if (resetAt != null) {
    final n = resetAt.toInt();
    return DateTime.fromMillisecondsSinceEpoch(
      n > 1000000000000 ? n : n * 1000,
      isUtc: true,
    );
  }
  final after = _num(
    raw['reset_after_seconds'] ??
        raw['resetAfterSeconds'] ??
        raw['resets_in_seconds'],
  );
  if (after != null) {
    return now.add(Duration(seconds: after.toInt()));
  }
  return null;
}

Map<String, dynamic>? _asMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.cast<String, dynamic>();
  }
  return null;
}

num? _num(Object? raw) =>
    raw is num ? raw : (raw is String ? num.tryParse(raw) : null);
