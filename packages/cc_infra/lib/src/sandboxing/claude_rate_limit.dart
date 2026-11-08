import 'package:cc_domain/features/subscriptions/subscriptions.dart';

/// One rolling window from a [ClaudeRateLimitInfo].
class ClaudeRateLimitWindow {
  /// Creates a [ClaudeRateLimitWindow].
  const ClaudeRateLimitWindow({required this.usedFraction, this.resetsAt});

  /// How much of the window is spent, `0` to `1`. Unlike `get_usage`, which
  /// reports percent, the stream reports a fraction.
  final double usedFraction;

  /// When the window reopens.
  final DateTime? resetsAt;
}

/// The plan's limit state, from `rate_limit_event.rate_limit_info`.
class ClaudeRateLimitInfo {
  /// Creates a [ClaudeRateLimitInfo].
  const ClaudeRateLimitInfo({
    required this.status,
    this.rateLimitType,
    this.resetsAt,
    this.overageStatus,
    this.isUsingOverage = false,
    this.windows = const {},
  });

  /// Reads a `rate_limit_info` body, or null when it is not one.
  static ClaudeRateLimitInfo? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final status = raw['status'];
    if (status is! String || status.isEmpty) {
      return null;
    }
    final windows = <String, ClaudeRateLimitWindow>{};
    final unified = raw['unifiedWindows'];
    if (unified is Map) {
      for (final MapEntry(:key, :value) in unified.entries) {
        final used = value is Map ? value['utilization'] : null;
        if (key is String && used is num) {
          windows[key] = ClaudeRateLimitWindow(
            usedFraction: used.toDouble().clamp(0.0, 1.0),
            resetsAt: _epochSeconds((value as Map)['resetsAt']),
          );
        }
      }
    }
    final type = raw['rateLimitType'];
    final overage = raw['overageStatus'];
    return ClaudeRateLimitInfo(
      status: status,
      rateLimitType: type is String && type.isNotEmpty ? type : null,
      resetsAt: _epochSeconds(raw['resetsAt']),
      overageStatus: overage is String ? overage : null,
      isUsingOverage:
          raw['isUsingOverage'] == true || raw['overageInUse'] == true,
      windows: windows,
    );
  }

  static DateTime? _epochSeconds(Object? raw) => raw is num && raw > 0
      ? DateTime.fromMillisecondsSinceEpoch((raw * 1000).toInt(), isUtc: true)
      : null;

  /// `allowed`, `allowed_warning` or `rejected`.
  final String status;

  /// The limit this report is about, such as `five_hour`.
  final String? rateLimitType;

  /// When that limit reopens.
  final DateTime? resetsAt;

  /// Whether extra usage may carry on past the limit.
  final String? overageStatus;

  /// Whether extra usage is already paying for this response.
  final bool isUsingOverage;

  /// Each rolling window's current state, keyed `five_hour`, `seven_day`.
  final Map<String, ClaudeRateLimitWindow> windows;

  /// Whether extra usage keeps the account running past a closed window.
  bool get overageAllowed =>
      isUsingOverage ||
      overageStatus == 'allowed' ||
      overageStatus == 'allowed_warning';

  /// Whether this account can answer nothing more until [resetsAt].
  bool get blocked => status == 'rejected' && !overageAllowed;

  /// Whether the account is close to a limit but still running.
  bool get warning => status == 'allowed_warning';

  /// Identifies this limit crossing: the CLI repeats a report on every blocked
  /// response, and one crossing is one thing to act on.
  String get crossingKey =>
      '${rateLimitType ?? 'unknown'}:${resetsAt?.toIso8601String() ?? ''}';

  /// The usage windows this report updates.
  List<SubscriptionWindow> get usageWindows => [
    for (final (key, id, label) in const [
      ('five_hour', '5h', 'Session'),
      ('seven_day', '7d', 'Weekly'),
    ])
      if (windows[key] case final window?)
        SubscriptionWindow(
          id: id,
          label: label,
          usedFraction: window.usedFraction,
          resetsAt: window.resetsAt,
        ),
  ];
}

/// The answer to one control request, from a `control_response` frame.
class ClaudeControlResponse {
  /// Creates a [ClaudeControlResponse].
  const ClaudeControlResponse({
    required this.requestId,
    required this.success,
    this.error,
    this.body = const {},
  });

  /// Reads a `control_response` frame, or null when it names no request.
  static ClaudeControlResponse? tryParse(Map<String, dynamic> obj) {
    final response = obj['response'];
    final id = response is Map ? response['request_id'] : null;
    if (id is! String || id.isEmpty) {
      return null;
    }
    final body = (response as Map)['response'];
    final error = response['error'];
    return ClaudeControlResponse(
      requestId: id,
      success: response['subtype'] == 'success',
      error: error is String ? error : null,
      body: body is Map ? Map<String, dynamic>.from(body) : const {},
    );
  }

  /// The `request_id` this answers.
  final String requestId;

  /// Whether the CLI accepted the request.
  final bool success;

  /// Why it did not.
  final String? error;

  /// The answer's payload.
  final Map<String, dynamic> body;
}
