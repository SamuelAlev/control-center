/// Safe enum lookup by name with a fallback value.
extension SafeEnumByName<T extends Enum> on Iterable<T> {
  /// By name or.
  T byNameOr(String name, T fallback) {
    try {
      return byName(name);
    } catch (_) {
      return fallback;
    }
  }
}

