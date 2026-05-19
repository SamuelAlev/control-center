/// Permission level granted to an agent for accessing workspace memory.
enum MemoryPermission {
/// No access to memory.
  none('none'),
/// Read-only access to memory.
  read('read'),
/// Read and write access to memory.
  write('write');

  const MemoryPermission(this.label);

/// Serialized label for this permission level.
  final String label;

/// Parses a string value (case-insensitive) into a [MemoryPermission], or
/// `null` if no match is found.
  static MemoryPermission? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    return MemoryPermission.values.where(
      (p) => p.label.toLowerCase() == value.toLowerCase(),
    ).firstOrNull;
  }
}
