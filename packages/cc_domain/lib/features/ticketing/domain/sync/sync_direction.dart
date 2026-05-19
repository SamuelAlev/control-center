/// The direction(s) a vendor sync is allowed to flow.
enum SyncDirection {
  /// Control Center → vendor only (push CC changes out; ignore vendor changes).
  push,

  /// Vendor → Control Center only (mirror vendor changes in; never push).
  pull,

  /// Both directions.
  bidirectional;

  /// Whether pushing CC changes to the vendor is allowed.
  bool get allowsPush =>
      this == SyncDirection.push || this == SyncDirection.bidirectional;

  /// Whether pulling vendor changes into CC is allowed.
  bool get allowsPull =>
      this == SyncDirection.pull || this == SyncDirection.bidirectional;

  /// Parses a stored value, defaulting to [bidirectional] for unknown input.
  static SyncDirection fromStorage(String? value) => switch (value) {
    'push' => SyncDirection.push,
    'pull' => SyncDirection.pull,
    'bidirectional' => SyncDirection.bidirectional,
    _ => SyncDirection.bidirectional,
  };

  /// Serializes for storage.
  String toStorageString() => name;
}
