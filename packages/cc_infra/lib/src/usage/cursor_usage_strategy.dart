import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/usage/subscription_usage_strategy.dart';
import 'package:dio/dio.dart';

/// Cursor usage via Connect RPC `DashboardService/GetCurrentPeriodUsage`
/// (Pro/Ultra spend + Auto/API percentages). Request-based enterprise seats
/// have no `planUsage` there and answer instead at `GET /auth/usage`.
class CursorUsageStrategy extends SubscriptionUsageStrategy {
  /// Creates a [CursorUsageStrategy].
  CursorUsageStrategy({required Dio dio})
    : _dio = dio,
      super(providerId: 'cursor', displayName: 'Cursor');

  final Dio _dio;

  static const _periodUsagePath =
      '/aiserver.v1.DashboardService/GetCurrentPeriodUsage';
  static const _authUsagePath = '/auth/usage';

  @override
  Future<SubscriptionUsage> fetchAccount(SubscriptionUsageAccount account) async {
    final token =
        account.accessToken?.trim().isNotEmpty == true
        ? account.accessToken!.trim()
        : (account.apiKey?.trim() ?? '');
    if (token.isEmpty) {
      return unconfigured(
        'Sign in to Cursor in Settings → Adapters to see usage.',
      );
    }
    try {
      final rawBase = account.baseUrl;
      final base = (rawBase == null || rawBase.trim().isEmpty)
          ? CursorOAuth.defaultApiBase
          : rawBase.trim();
      // Never send the session token to an arbitrary host: require https and a
      // known Cursor host before attaching the credential.
      final parsed = Uri.tryParse(base);
      if (parsed == null ||
          parsed.scheme != 'https' ||
          !_isCursorHost(parsed.host)) {
        return error('Invalid Cursor base URL.');
      }
      final origin = base.replaceAll(RegExp(r'/+$'), '');
      try {
        final period = await _periodUsage(origin, token);
        if (period != null && period.hasReading) {
          return period;
        }
      } on DioException catch (e) {
        // Auth failure is the same on both endpoints — don't spend a second
        // round-trip to re-learn it. Anything else (404, 5xx, empty body) is
        // "this seat is not period-billed" and we fall through to requests.
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          return error(shortError(e));
        }
      }
      final requests = await _requestUsage(origin, token);
      if (requests != null && requests.hasReading) {
        return requests;
      }
      return error('Could not read Cursor usage.');
    } catch (e) {
      return error(shortError(e));
    }
  }

  Future<SubscriptionUsage?> _periodUsage(String origin, String token) async {
    final resp = await _dio.postUri<Map<String, dynamic>>(
      Uri.parse('$origin$_periodUsagePath'),
      data: const <String, dynamic>{},
      options: Options(
        responseType: ResponseType.json,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Connect-Protocol-Version': '1',
          'x-cursor-client-version': kCursorClientVersion,
          'x-cursor-client-type': 'cli',
        },
        sendTimeout: SubscriptionUsageStrategy.requestTimeout,
        receiveTimeout: SubscriptionUsageStrategy.requestTimeout,
        extra: expectStatuses(const [404, 405]),
      ),
    );
    return _parsePeriod(resp.data);
  }

  Future<SubscriptionUsage?> _requestUsage(String origin, String token) async {
    try {
      final resp = await _dio.getUri<Map<String, dynamic>>(
        Uri.parse('$origin$_authUsagePath'),
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          sendTimeout: SubscriptionUsageStrategy.requestTimeout,
          receiveTimeout: SubscriptionUsageStrategy.requestTimeout,
          extra: expectStatuses(const [404, 405]),
        ),
      );
      return _parseRequests(resp.data);
    } on DioException catch (e) {
      // A missing request-quota endpoint is not a failure of the period
      // reading we already tried — only a hard error (auth, network) should
      // surface. 404/405 mean this seat is not request-billed.
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) {
        return null;
      }
      rethrow;
    }
  }

  SubscriptionUsage? _parsePeriod(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final plan = _planMap(data);
    final reset = _cycleReset(data);
    final windows = <SubscriptionWindow>[];
    void addPercent(String key, String wid, String label) {
      final raw = asNum(plan?[key] ?? data[key]);
      if (raw == null) {
        return;
      }
      windows.add(
        SubscriptionWindow(
          id: wid,
          label: label,
          usedFraction: (raw / 100).clamp(0.0, 1.0),
          resetsAt: reset,
        ),
      );
    }

    addPercent('totalPercentUsed', 'total', 'Total');
    addPercent('autoPercentUsed', 'auto', 'Cursor models');
    addPercent('apiPercentUsed', 'api', 'API');
    // snake_case aliases some Connect JSON encodings emit.
    if (windows.isEmpty) {
      addPercent('total_percent_used', 'total', 'Total');
      addPercent('auto_percent_used', 'auto', 'Cursor models');
      addPercent('api_percent_used', 'api', 'API');
    }

    final spend = _spendOf(plan);
    if (windows.isEmpty && spend != null) {
      // A seat billed in dollars with no percentage fields still has a
      // reading — inventing "no usage reported" would hide the one number
      // the dashboard shows. The flyout also renders [spend] as dollars.
      windows.add(
        SubscriptionWindow(
          id: 'spend',
          label: 'Included',
          usedFraction: spend.usedFraction,
          resetsAt: reset,
        ),
      );
    }
    if (windows.isEmpty && spend == null) {
      return null;
    }
    return ok(windows, spend: spend);
  }

  /// The plan object: `planUsage` on Pro/Ultra, or `individualUsage.plan` on
  /// the usage-summary shape some seats return from the same RPC.
  Map<String, dynamic>? _planMap(Map<String, dynamic> data) {
    final direct = data['planUsage'] ?? data['plan_usage'];
    if (direct is Map<String, dynamic>) {
      return direct;
    }
    if (direct is Map) {
      return direct.cast<String, dynamic>();
    }
    final individual = data['individualUsage'] ?? data['individual_usage'];
    if (individual is Map) {
      final plan = individual['plan'];
      if (plan is Map<String, dynamic>) {
        return plan;
      }
      if (plan is Map) {
        return plan.cast<String, dynamic>();
      }
    }
    return null;
  }

  DateTime? _cycleReset(Map<String, dynamic> data) {
    final raw = data['billingCycleEnd'] ?? data['billing_cycle_end'];
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw)?.toUtc();
    }
    final n = asNum(raw)?.toInt();
    if (n != null && n > 0) {
      return DateTime.fromMillisecondsSinceEpoch(
        n > 1000000000000 ? n : n * 1000,
        isUtc: true,
      );
    }
    return null;
  }

  /// Dollar spend against the included allowance. Amounts are integer cents.
  SubscriptionSpend? _spendOf(Map<String, dynamic>? plan) {
    if (plan == null) {
      return null;
    }
    final used =
        asNum(plan['includedSpend'] ?? plan['included_spend'])?.toInt() ??
        asNum(plan['totalSpend'] ?? plan['total_spend'])?.toInt();
    final limit = asNum(plan['limit'])?.toInt();
    if (used == null || limit == null) {
      return null;
    }
    return SubscriptionSpend(
      usedMinor: used,
      limitMinor: limit,
      currency: 'USD',
    );
  }

  /// Request-based enterprise quota: `{ "gpt-4": { numRequests, maxRequestUsage },
  /// startOfMonth }`.
  SubscriptionUsage? _parseRequests(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final start =
        parseIso(data['startOfMonth'] ?? data['start_of_month']) ??
        _cycleReset(data);
    final reset = start == null
        ? null
        : DateTime.utc(start.year, start.month + 1, start.day);
    final windows = <SubscriptionWindow>[];
    data.forEach((key, value) {
      if (value is! Map) {
        return;
      }
      final used = asNum(value['numRequests'] ?? value['num_requests']);
      final limit = asNum(
        value['maxRequestUsage'] ?? value['max_request_usage'],
      );
      if (used == null || limit == null || limit <= 0) {
        return;
      }
      windows.add(
        SubscriptionWindow(
          id: key,
          label: key,
          usedFraction: (used / limit).clamp(0.0, 1.0),
          resetsAt: reset,
        ),
      );
    });
    if (windows.isEmpty) {
      return null;
    }
    return ok(windows);
  }

  /// Whether [host] is a recognised Cursor endpoint, so the session token is
  /// only ever sent there.
  bool _isCursorHost(String host) {
    final h = host.toLowerCase();
    return h == 'cursor.sh' ||
        h.endsWith('.cursor.sh') ||
        h == 'cursor.com' ||
        h.endsWith('.cursor.com');
  }
}
