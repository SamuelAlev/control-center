import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_space_auto_open.dart';
import 'package:flutter_test/flutter_test.dart';

Space _space(
  String id, {
  SpaceKind kind = SpaceKind.topic,
  DateTime? updatedAt,
}) => Space(
  id: id,
  name: id,
  createdAt: DateTime(2024),
  updatedAt: updatedAt ?? DateTime(2024),
  kind: kind,
);

void main() {
  group('chatBridgeSpaceToAutoOpen', () {
    test('ignores new spaces while the app is foregrounded', () {
      expect(
        chatBridgeSpaceToAutoOpen(
          previouslyKnownIds: {'old'},
          current: [
            _space('slack-1', kind: SpaceKind.slack),
            _space('old'),
          ],
          isForeground: true,
        ),
        isNull,
      );
    });

    test('opens the newest bridged space that was not already known', () {
      final slackNew = _space(
        'slack-new',
        kind: SpaceKind.slack,
        updatedAt: DateTime(2024, 2),
      );
      expect(
        chatBridgeSpaceToAutoOpen(
          previouslyKnownIds: {'old', 'slack-old'},
          current: [
            slackNew,
            _space('user-new', updatedAt: DateTime(2024, 2)),
            _space('slack-old', kind: SpaceKind.slack),
            _space('old'),
          ],
          isForeground: false,
        ),
        slackNew,
      );
    });

    test('does not open a human-created space', () {
      expect(
        chatBridgeSpaceToAutoOpen(
          previouslyKnownIds: const {},
          current: [_space('user-new')],
          isForeground: false,
        ),
        isNull,
      );
    });

    test('does not reopen a bridged space that was already in the list', () {
      expect(
        chatBridgeSpaceToAutoOpen(
          previouslyKnownIds: {'slack-1'},
          current: [_space('slack-1', kind: SpaceKind.slack)],
          isForeground: false,
        ),
        isNull,
      );
    });
  });
}
