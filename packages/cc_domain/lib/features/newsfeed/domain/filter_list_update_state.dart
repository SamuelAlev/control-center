/// State for the filter list auto-update process.
class FilterListUpdateState {
  /// Creates a [FilterListUpdateState].
  const FilterListUpdateState({
    this.lastCheck,
    this.lastSuccess,
    required this.isUpdating,
    required this.errors,
    required this.cookieHidingRules,
    required this.adHidingRules,
    required this.networkBlockRules,
    required this.removeParamsCount,
  });

  /// Parses the wire shape produced by [toJson].
  factory FilterListUpdateState.fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? raw) {
      if (raw is String && raw.isNotEmpty) {
        return DateTime.tryParse(raw);
      }
      return null;
    }

    final errorsRaw = json['errors'];
    return FilterListUpdateState(
      lastCheck: parse(json['lastCheck']),
      lastSuccess: parse(json['lastSuccess']),
      isUpdating: json['isUpdating'] == true,
      errors: [
        if (errorsRaw is List)
          for (final e in errorsRaw)
            if (e is String) e,
      ],
      cookieHidingRules: (json['cookieHidingRules'] as num?)?.toInt() ?? 0,
      adHidingRules: (json['adHidingRules'] as num?)?.toInt() ?? 0,
      networkBlockRules: (json['networkBlockRules'] as num?)?.toInt() ?? 0,
      removeParamsCount: (json['removeParamsCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Empty state before the first successful fetch.
  static const empty = FilterListUpdateState(
    isUpdating: false,
    errors: [],
    cookieHidingRules: 0,
    adHidingRules: 0,
    networkBlockRules: 0,
    removeParamsCount: 0,
  );

  /// The last time an update check was performed.
  final DateTime? lastCheck;

  /// The last time an update succeeded.
  final DateTime? lastSuccess;

  /// Whether an update is currently running.
  final bool isUpdating;

  /// Recent error messages from update attempts.
  final List<String> errors;

  /// Number of active cookie hiding rules.
  final int cookieHidingRules;

  /// Number of active ad hiding rules.
  final int adHidingRules;

  /// Number of active network block rules.
  final int networkBlockRules;

  /// Number of active URL parameter removal rules.
  final int removeParamsCount;

  /// Wire shape for `newsfeed.filterLists.state` / `refresh`.
  Map<String, dynamic> toJson() => {
    'lastCheck': lastCheck?.toIso8601String(),
    'lastSuccess': lastSuccess?.toIso8601String(),
    'isUpdating': isUpdating,
    'errors': errors,
    'cookieHidingRules': cookieHidingRules,
    'adHidingRules': adHidingRules,
    'networkBlockRules': networkBlockRules,
    'removeParamsCount': removeParamsCount,
  };

  /// Creates a copy with optionally overridden fields.
  FilterListUpdateState copyWith({
    DateTime? lastCheck,
    DateTime? lastSuccess,
    bool? isUpdating,
    List<String>? errors,
    int? cookieHidingRules,
    int? adHidingRules,
    int? networkBlockRules,
    int? removeParamsCount,
  }) {
    return FilterListUpdateState(
      lastCheck: lastCheck ?? this.lastCheck,
      lastSuccess: lastSuccess ?? this.lastSuccess,
      isUpdating: isUpdating ?? this.isUpdating,
      errors: errors ?? this.errors,
      cookieHidingRules: cookieHidingRules ?? this.cookieHidingRules,
      adHidingRules: adHidingRules ?? this.adHidingRules,
      networkBlockRules: networkBlockRules ?? this.networkBlockRules,
      removeParamsCount: removeParamsCount ?? this.removeParamsCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterListUpdateState &&
          lastCheck == other.lastCheck &&
          lastSuccess == other.lastSuccess &&
          isUpdating == other.isUpdating &&
          _listEquals(errors, other.errors) &&
          cookieHidingRules == other.cookieHidingRules &&
          adHidingRules == other.adHidingRules &&
          networkBlockRules == other.networkBlockRules &&
          removeParamsCount == other.removeParamsCount;

  @override
  int get hashCode => Object.hash(
    lastCheck,
    lastSuccess,
    isUpdating,
    Object.hashAll(errors),
    cookieHidingRules,
    adHidingRules,
    networkBlockRules,
    removeParamsCount,
  );
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
