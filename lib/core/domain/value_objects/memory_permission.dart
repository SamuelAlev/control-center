enum MemoryPermission {
  none('none'),
  read('read'),
  write('write');

  const MemoryPermission(this.label);

  final String label;

  static MemoryPermission? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    return MemoryPermission.values.where(
      (p) => p.label.toLowerCase() == value.toLowerCase(),
    ).firstOrNull;
  }
}
