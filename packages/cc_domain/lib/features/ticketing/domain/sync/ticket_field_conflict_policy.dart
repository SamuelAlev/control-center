import 'dart:convert';

/// A ticket field that can diverge between Control Center and a vendor and so
/// needs a conflict winner.
enum TicketSyncField {
  /// The ticket title.
  title,

  /// The ticket description / body.
  description,

  /// The normalized status.
  status,

  /// The priority.
  priority,

  /// The label set.
  labels,

  /// The assignee.
  assignee;

  /// Parses a stored key.
  static TicketSyncField? fromKey(String key) {
    for (final f in values) {
      if (f.name == key) {
        return f;
      }
    }
    return null;
  }
}

/// Which side wins when a field differs between Control Center and a vendor.
enum ConflictWinner {
  /// Keep the Control Center value; do not overwrite it from a vendor pull.
  cc,

  /// Take the vendor value on a pull.
  vendor;

  /// Parses a stored value, defaulting to [cc] for unknown input.
  static ConflictWinner fromStorage(String? value) =>
      value == 'vendor' ? ConflictWinner.vendor : ConflictWinner.cc;

  /// Serializes for storage.
  String toStorageString() => name;
}

/// Per-field conflict-resolution policy for one vendor.
///
/// The default expresses the product rule: a ticket Control Center owns
/// (agent-created / agent-modified) keeps its own fields ([ConflictWinner.cc]);
/// a ticket the vendor owns (vendor-created, mirrored in) takes the vendor's
/// fields ([ConflictWinner.vendor]). [perField] overrides the default for
/// individual fields, so an operator can, say, always let the vendor own
/// `status` while CC keeps `title`.
class TicketFieldConflictPolicy {
  /// Creates a [TicketFieldConflictPolicy].
  const TicketFieldConflictPolicy({
    this.defaultWinner = ConflictWinner.cc,
    this.perField = const {},
  });

  /// Parses a policy from the `field_mapping` JSON stored on a sync config.
  /// Shape: `{"default": "cc|vendor", "fields": {"status": "vendor", ...}}`.
  /// Malformed input degrades to the safe default (CC wins) rather than
  /// throwing — a corrupt mapping must never silently let a vendor clobber CC
  /// data.
  factory TicketFieldConflictPolicy.fromJson(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const TicketFieldConflictPolicy();
    }
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const TicketFieldConflictPolicy();
    }
    if (decoded is! Map) {
      return const TicketFieldConflictPolicy();
    }
    final defaultWinner = ConflictWinner.fromStorage(
      decoded['default'] as String?,
    );
    final perField = <TicketSyncField, ConflictWinner>{};
    final fields = decoded['fields'];
    if (fields is Map) {
      fields.forEach((key, value) {
        final field = TicketSyncField.fromKey('$key');
        if (field != null) {
          perField[field] = ConflictWinner.fromStorage('$value');
        }
      });
    }
    return TicketFieldConflictPolicy(
      defaultWinner: defaultWinner,
      perField: perField,
    );
  }

  /// The policy used for a ticket Control Center created (CC owns its fields).
  static const ccOwned = TicketFieldConflictPolicy();

  /// The policy used for a ticket the vendor created (vendor owns its fields).
  static const vendorOwned = TicketFieldConflictPolicy(
    defaultWinner: ConflictWinner.vendor,
  );

  /// Winner applied to a field not present in [perField].
  final ConflictWinner defaultWinner;

  /// Field-level overrides of [defaultWinner].
  final Map<TicketSyncField, ConflictWinner> perField;

  /// The winner for [field].
  ConflictWinner winnerFor(TicketSyncField field) =>
      perField[field] ?? defaultWinner;

  /// Whether a vendor pull may overwrite [field].
  bool vendorWins(TicketSyncField field) =>
      winnerFor(field) == ConflictWinner.vendor;

  /// Serializes to the `field_mapping` JSON stored on a sync config.
  String toJson() => jsonEncode({
    'default': defaultWinner.toStorageString(),
    'fields': {
      for (final entry in perField.entries)
        entry.key.name: entry.value.toStorageString(),
    },
  });
}
