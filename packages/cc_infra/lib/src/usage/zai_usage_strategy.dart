import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_infra/src/usage/subscription_usage_strategy.dart';
import 'package:dio/dio.dart';

/// z.ai (Zhipu) GLM Coding Plan usage via
/// `GET <base>/api/monitor/usage/quota/limit`.
///
/// The credential is supplied by the caller — the RPC op resolves it from the
/// harness provider credential store. The key is only ever sent to a recognised
/// z.ai / Zhipu host.
class ZaiUsageStrategy extends SubscriptionUsageStrategy {
  /// Creates a [ZaiUsageStrategy].
  ZaiUsageStrategy({required Dio dio})
    : _dio = dio,
      super(providerId: 'zai', displayName: 'z.ai');

  final Dio _dio;

  static const _defaultBaseUrl = 'https://api.z.ai';
  static const _usagePath = '/api/monitor/usage/quota/limit';

  @override
  Future<SubscriptionUsage> fetchAccount(SubscriptionUsageAccount account) async {
    final key = account.apiKey?.trim() ?? '';
    if (key.isEmpty) {
      return unconfigured('Sign in to z.ai to see usage.');
    }
    try {
      final rawBase = account.baseUrl;
      final base = (rawBase == null || rawBase.trim().isEmpty)
          ? _defaultBaseUrl
          : rawBase.trim();
      // Never send the operator's key to an arbitrary host: require https and a
      // known z.ai/Zhipu host before attaching the credential.
      final parsed = Uri.tryParse(base);
      if (parsed == null ||
          parsed.scheme != 'https' ||
          !_isZaiHost(parsed.host)) {
        return error('Invalid z.ai base URL.');
      }
      final url = '${base.replaceAll(RegExp(r'/+$'), '')}$_usagePath';
      final resp = await _get(url, key);
      final windows = _parseWindows(resp.data);
      if (windows.isEmpty) {
        return error('Could not read z.ai usage.');
      }
      return ok(windows);
    } catch (e) {
      return error(shortError(e));
    }
  }

  /// z.ai installs disagree on the auth scheme — some want the raw key in the
  /// `Authorization` header, others want `Bearer <key>`. Try raw first (the
  /// dominant convention) and fall back to Bearer on a 401/403.
  Future<Response<Map<String, dynamic>>> _get(String url, String key) async {
    Options opts(String auth) => Options(
      responseType: ResponseType.json,
      headers: {
        'Authorization': auth,
        'Accept': 'application/json',
        'Accept-Language': 'en-US,en',
      },
      sendTimeout: SubscriptionUsageStrategy.requestTimeout,
      receiveTimeout: SubscriptionUsageStrategy.requestTimeout,
    );
    try {
      return await _dio.getUri<Map<String, dynamic>>(
        Uri.parse(url),
        options: opts(key),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        return _dio.getUri<Map<String, dynamic>>(
          Uri.parse(url),
          options: opts('Bearer $key'),
        );
      }
      rethrow;
    }
  }

  /// Parses the z.ai quota response: `{ data: { limits: [ { type, percentage,
  /// nextResetTime, unit } ] } }`. We surface the `TOKENS_LIMIT` entries (the
  /// coding token quota). The window is keyed off the entry's `unit`
  /// discriminator (3 = 5-hour session, 6 = weekly) rather than array order, so
  /// reordering or a single-window response still labels correctly; array
  /// position is the fallback when `unit` is absent/unrecognised.
  List<SubscriptionWindow> _parseWindows(Map<String, dynamic>? data) {
    if (data == null) {
      return const [];
    }
    final inner = data['data'];
    final limits = inner is Map ? inner['limits'] : null;
    if (limits is! List) {
      return const [];
    }
    final tokenLimits = [
      for (final l in limits)
        if (l is Map && l['type'] == 'TOKENS_LIMIT') l,
    ];
    final windows = <SubscriptionWindow>[];
    for (var i = 0; i < tokenLimits.length; i++) {
      final l = tokenLimits[i];
      final pct = (l['percentage'] as num?)?.toDouble();
      if (pct == null) {
        continue;
      }
      final resetMs = (l['nextResetTime'] as num?)?.toInt();
      final (wid, label) = switch ((l['unit'] as num?)?.toInt()) {
        3 => ('5h', 'Session'),
        6 => ('7d', 'Weekly'),
        _ => switch (i) {
          0 => ('5h', 'Session'),
          1 => ('7d', 'Weekly'),
          _ => ('w$i', 'Window ${i + 1}'),
        },
      };
      windows.add(
        SubscriptionWindow(
          id: wid,
          label: label,
          usedFraction: (pct / 100).clamp(0.0, 1.0),
          resetsAt: resetMs == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(resetMs, isUtc: true),
        ),
      );
    }
    return windows;
  }

  /// Whether [host] is a recognised z.ai / Zhipu endpoint (global `z.ai` or the
  /// China `bigmodel.cn`), so the operator's key is only ever sent there.
  bool _isZaiHost(String host) {
    final h = host.toLowerCase();
    return h == 'z.ai' ||
        h.endsWith('.z.ai') ||
        h == 'bigmodel.cn' ||
        h.endsWith('.bigmodel.cn');
  }
}
