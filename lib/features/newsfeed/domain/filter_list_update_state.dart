class FilterListUpdateState {
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

  final DateTime? lastCheck;
  final DateTime? lastSuccess;
  final bool isUpdating;
  final List<String> errors;
  final int cookieHidingRules;
  final int adHidingRules;
  final int networkBlockRules;
  final int removeParamsCount;

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
