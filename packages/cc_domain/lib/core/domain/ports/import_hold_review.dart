import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:collection/collection.dart';

/// The grants a restored workspace file carried, as the server owner reviews
/// them from a client (`workspace.importHolds.list` / `.resolve`).
///
/// The server keeps each grant out of its live table until the server owner
/// accepts or dismisses it; this port only reads them and forwards the
/// decision.
abstract interface class ImportHoldReview {
  /// The holds waiting in [workspaceId], oldest first.
  Future<List<ImportHoldView>> list(String workspaceId);

  /// Accepts ([accept] true) or dismisses hold [holdId] of [workspaceId].
  /// Returns whether a grant was applied: accepting a hold whose subject is
  /// gone (a member who left, a deleted repository) applies nothing.
  Future<bool> resolve({
    required String workspaceId,
    required String holdId,
    required bool accept,
  });
}

/// One held grant as the client sees it.
///
/// Unlike [ImportedAuthorityHold], [kind] may be null: a newer server can
/// hold a kind this build does not know, and that hold must still be
/// listable (and dismissable) rather than dropped or misread.
final class ImportHoldView {
  /// Creates a view of one hold. Throws [ArgumentError] on an empty [id] or
  /// [wireKind].
  ImportHoldView({
    required this.id,
    required this.wireKind,
    required this.payload,
    required this.importedAt,
    required this.sourceInstallId,
  }) : kind = ImportHoldKind.fromWire(wireKind) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (wireKind.isEmpty) {
      throw ArgumentError.value(wireKind, 'wireKind', 'must not be empty');
    }
  }

  /// Hold id, what `resolve` names.
  final String id;

  /// The kind as the server sent it.
  final String wireKind;

  /// The kind, or null when this build does not know [wireKind].
  final ImportHoldKind? kind;

  /// The held row as the file held it, by column name (`user_id`, `role`,
  /// `decision`, `path`, ...).
  final Map<String, Object?> payload;

  /// When the import that held it ran.
  final DateTime importedAt;

  /// The install the file says it came from.
  final String sourceInstallId;

  /// [payload]`[column]` when it is a non-empty string, else null.
  String? text(String column) {
    final value = payload[column];
    return value is String && value.isNotEmpty ? value : null;
  }

  static const _payloadEquality = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      other is ImportHoldView &&
      other.id == id &&
      other.wireKind == wireKind &&
      other.importedAt == importedAt &&
      other.sourceInstallId == sourceInstallId &&
      _payloadEquality.equals(other.payload, payload);

  @override
  int get hashCode => Object.hash(
    id,
    wireKind,
    importedAt,
    sourceInstallId,
    _payloadEquality.hash(payload),
  );
}
