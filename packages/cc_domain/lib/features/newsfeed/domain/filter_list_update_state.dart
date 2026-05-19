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
}
