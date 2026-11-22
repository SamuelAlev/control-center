import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// Records how a person's park ended on its row (a `LimitParkRowStamper`):
/// the `limit_park` system row whose `wakeId` is the settled wake gets the
/// outcome fields merged into its metadata, once. The row's text is never
/// rewritten; a row that already has an outcome is left as it is.
class LimitParkRowStamp {
  /// Creates the stamp over [_messaging].
  LimitParkRowStamp(this._messaging);

  final MessagingRepository _messaging;

  /// Merges [fields] into the park row of [wakeId]. True when it changed.
  Future<bool> call({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String wakeId,
    required Map<String, Object?> fields,
  }) async {
    final rows = await _messaging.getMessages(
      workspaceId,
      spaceId,
      conversationId: conversationId,
    );
    for (final row in rows) {
      final metadata = row.metadata;
      if (row.conversationId != conversationId ||
          metadata == null ||
          metadata['kind'] != LimitPark.rowKind ||
          metadata['wakeId'] != wakeId) {
        continue;
      }
      if (metadata[LimitPark.rowOutcomeKey] != null) {
        return false;
      }
      await _messaging.updateMessage(
        workspaceId,
        row.id,
        metadata: {...metadata, ...fields},
      );
      return true;
    }
    return false;
  }
}
