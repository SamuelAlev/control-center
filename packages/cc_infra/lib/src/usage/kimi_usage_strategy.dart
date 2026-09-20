import 'dart:convert';

import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/usage/subscription_usage_strategy.dart';
import 'package:dio/dio.dart';

/// Kimi Code usage via `GET <base>/usages`.
///
/// Authenticated with the plan's OAuth bearer plus the same `X-Msh-*` device
/// identity every other Kimi call carries. A spent plan answers 429
/// `resource_exhausted` and is reported as [SubscriptionStatus.exhausted].
class KimiUsageStrategy extends SubscriptionUsageStrategy {
  /// Creates a [KimiUsageStrategy].
  KimiUsageStrategy({required this._dio})
    : super(providerId: 'kimi-code', displayName: 'Kimi Code');

  final Dio _dio;

  static const _usagePath = '/usages';

  @override
  Future<SubscriptionUsage> fetchAccount(SubscriptionUsageAccount account) async {
    final token = account.accessToken?.trim() ?? '';
    if (token.isEmpty) {
      return unconfigured(
        'Sign in to Kimi Code in Settings → Adapters to see usage.',
      );
    }
    try {
      final rawBase = account.baseUrl;
      final base = (rawBase == null || rawBase.trim().isEmpty)
          ? KimiOAuth.apiBaseUrl
          : rawBase.trim();
      // Never send the plan token to an arbitrary host: require https and a
      // known Kimi host before attaching the credential.
      final parsed = Uri.tryParse(base);
      if (parsed == null ||
          parsed.scheme != 'https' ||
          !_isKimiHost(parsed.host)) {
        return error('Invalid Kimi Code base URL.');
      }
      final url = '${base.replaceAll(RegExp(r'/+$'), '')}$_usagePath';
      final deviceId = account.deviceId;
      final resp = await _dio.getUri<Map<String, dynamic>>(
        Uri.parse(url),
        options: Options(
          responseType: ResponseType.json,
          headers: {
            if (deviceId != null && deviceId.isNotEmpty)
              ...KimiOAuth.headersFor(deviceId),
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          // A spent plan IS a 429 here (see [_exhaustionReason]), read below
          // into an `exhausted` snapshot — the pill's answer, not a failure to
          // fetch one. Without this the shared error interceptor logs a red
          // `HTTP 429 … | response: {code: resource_exhausted …}` line on every
          // poll for a condition nothing is wrong about.
          extra: expectStatuses(const [429]),
          sendTimeout: SubscriptionUsageStrategy.requestTimeout,
          receiveTimeout: SubscriptionUsageStrategy.requestTimeout,
        ),
      );
      final windows = _parseWindows(resp.data);
      if (windows.isEmpty) {
        return error('Could not read Kimi Code usage.');
      }
      return ok(windows);
    } on DioException catch (e) {
      // A spent plan is an ANSWER, not a failure to read one. Kimi reports it
      // as a 429 carrying `resource_exhausted`, which is indistinguishable from
      // ordinary throttling at the status-code level — and reporting it as
      // "usage unavailable" sent the operator looking for a broken integration
      // when the actual fact was "Credits used up."
      final exhaustedReason = _exhaustionReason(e);
      if (exhaustedReason != null) {
        return exhausted(exhaustedReason);
      }
      return error(shortError(e));
    } catch (e) {
      return error(shortError(e));
    }
  }

  /// The provider's own reason when [e] is a quota/credit-exhaustion refusal,
  /// or null when it is any other failure.
  ///
  /// Recognises the Connect-style envelope Kimi answers with:
  /// `{"code":"resource_exhausted","message":"insufficient balance","details":
  /// [{"debug":{"reason":"REASON_QUOTA_EXCEEDED","localizedMessage":
  /// {"message":"Credits used up."}}}]}`. The localized message is preferred
  /// because it is the sentence written for a person ("Credits used up.")
  /// rather than the one written for a client ("insufficient balance").
  ///
  /// Deliberately narrow: only a 429 whose body SAYS it is exhaustion counts. A
  /// bare 429 is ordinary throttling and stays an [SubscriptionStatus.error],
  /// because guessing "you are out of credits" at a plan that is merely being
  /// rate-limited is a worse answer than admitting the reading failed.
  static String? _exhaustionReason(DioException e) {
    if (e.response?.statusCode != 429) {
      return null;
    }
    final raw = e.response?.data;
    final Map<String, dynamic> body;
    if (raw is Map) {
      body = raw.cast<String, dynamic>();
    } else if (raw is String && raw.trim().isNotEmpty) {
      // A 429 need not come back with a JSON content type, in which case dio
      // hands the body over as text.
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) {
          return null;
        }
        body = decoded.cast<String, dynamic>();
      } on Object {
        return null;
      }
    } else {
      return null;
    }
    if ((body['code'] as String?)?.toLowerCase() != 'resource_exhausted') {
      return null;
    }
    final details = body['details'];
    if (details is List) {
      for (final detail in details) {
        final debug = detail is Map ? detail['debug'] : null;
        final localized = debug is Map ? debug['localizedMessage'] : null;
        final message = localized is Map ? localized['message'] : null;
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    }
    final message = body['message'];
    return message is String && message.trim().isNotEmpty
        ? message.trim()
        // The code alone still carries the fact; the UI has its own localized
        // headline and only uses this as the supporting detail.
        : 'The plan has no quota left.';
  }

  /// Parses Kimi's `/usages` payload: an optional `usage` summary plus a
  /// `limits` array, each entry pairing a `detail` (used/limit/remaining) with
  /// a `window` (duration + timeUnit).
  List<SubscriptionWindow> _parseWindows(Map<String, dynamic>? data) {
    if (data == null) {
      return const [];
    }
    final windows = <SubscriptionWindow>[];

    /// Kimi reports absolute counts, not percentages and spells "how much is
    /// left" either way round — derive the used fraction from whichever pair is
    /// present.
    double? fraction(Map<String, dynamic> row) {
      final limit = asNum(row['limit']);
      if (limit == null || limit <= 0) {
        return null;
      }
      final remaining = asNum(row['remaining']);
      final used =
          asNum(row['used']) ?? (remaining == null ? null : limit - remaining);
      if (used == null) {
        return null;
      }
      return (used / limit).clamp(0.0, 1.0);
    }

    void add(
      String id,
      String label,
      Map<String, dynamic> row,
      DateTime? reset,
    ) {
      final f = fraction(row);
      if (f == null) {
        return;
      }
      windows.add(
        SubscriptionWindow(
          id: id,
          label: label,
          usedFraction: f,
          resetsAt: reset,
        ),
      );
    }

    final summary = data['usage'];
    if (summary is Map<String, dynamic>) {
      add('total', 'Total', summary, _resetOf(summary));
    }
    final limits = data['limits'];
    if (limits is List) {
      for (var i = 0; i < limits.length; i++) {
        final entry = limits[i];
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final detail = entry['detail'] is Map<String, dynamic>
            ? entry['detail'] as Map<String, dynamic>
            : entry;
        final window = entry['window'] is Map<String, dynamic>
            ? entry['window'] as Map<String, dynamic>
            : const <String, dynamic>{};
        final windowLabel = _windowLabel(window);
        add(
          windowLabel ?? 'limit-$i',
          (entry['name'] as String?) ??
              (entry['title'] as String?) ??
              windowLabel ??
              'Window ${i + 1}',
          detail,
          // Kimi puts the reset on the limit detail, not on the window.
          _resetOf(detail) ?? _resetOf(window),
        );
      }
    }
    return windows;
  }

  /// A window's human label from its `duration` + `timeUnit` pair
  /// (e.g. `{duration: 5, timeUnit: HOURS}` → `5h`).
  String? _windowLabel(Map<String, dynamic> window) {
    final duration = asNum(window['duration'])?.toInt();
    final unit = (window['timeUnit'] as String?)?.toUpperCase() ?? '';
    if (duration == null || unit.isEmpty) {
      return null;
    }
    if (unit.startsWith('MINUTE')) {
      return duration % 60 == 0 ? '${duration ~/ 60}h' : '${duration}m';
    }
    if (unit.startsWith('HOUR')) {
      return '${duration}h';
    }
    if (unit.startsWith('DAY')) {
      return '${duration}d';
    }
    if (unit.startsWith('SECOND')) {
      return '${duration}s';
    }
    return null;
  }

  /// A reset instant from any of the spellings Kimi uses — an ISO string, epoch
  /// seconds or millis, or a relative "resets in N seconds".
  DateTime? _resetOf(Map<String, dynamic> row) {
    for (final key in ['reset_at', 'resetAt', 'reset_time', 'resetTime']) {
      final value = row[key];
      if (value is String && value.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed.toUtc();
        }
      }
      final n = asNum(value)?.toInt();
      if (n != null && n > 0) {
        // Epoch seconds and epoch millis are told apart by magnitude.
        return DateTime.fromMillisecondsSinceEpoch(
          n > 1000000000000 ? n : n * 1000,
          isUtc: true,
        );
      }
    }
    for (final key in ['reset_in', 'resetIn', 'ttl']) {
      final seconds = asNum(row[key])?.toInt();
      if (seconds != null && seconds > 0) {
        return DateTime.now().toUtc().add(Duration(seconds: seconds));
      }
    }
    return null;
  }

  /// Whether [host] is a recognised Kimi endpoint, so the plan token is only
  /// ever sent there.
  bool _isKimiHost(String host) {
    final h = host.toLowerCase();
    return h == 'kimi.com' ||
        h.endsWith('.kimi.com') ||
        h == 'moonshot.ai' ||
        h.endsWith('.moonshot.ai');
  }
}
