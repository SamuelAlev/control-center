import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_channel_auto_open.dart';
import 'package:flutter_test/flutter_test.dart';

Channel _channel(
  String id, {
  ChannelOrigin origin = ChannelOrigin.user,
  DateTime? updatedAt,
}) => Channel(
  id: id,
  name: id,
  createdAt: DateTime(2024),
  updatedAt: updatedAt ?? DateTime(2024),
  origin: origin,
);

void main() {
  group('chatBridgeChannelToAutoOpen', () {
    test('ignores new channels while the app is foregrounded', () {
      expect(
        chatBridgeChannelToAutoOpen(
          previouslyKnownIds: {'old'},
          current: [
            _channel('slack-1', origin: ChannelOrigin.slack),
            _channel('old'),
          ],
          isForeground: true,
        ),
        isNull,
      );
    });

    test('opens the newest bridged channel that was not already known', () {
      final slackNew = _channel(
        'slack-new',
        origin: ChannelOrigin.slack,
        updatedAt: DateTime(2024, 2),
      );
      expect(
        chatBridgeChannelToAutoOpen(
          previouslyKnownIds: {'old', 'slack-old'},
          current: [
            slackNew,
            _channel('user-new', updatedAt: DateTime(2024, 2)),
            _channel('slack-old', origin: ChannelOrigin.slack),
            _channel('old'),
          ],
          isForeground: false,
        ),
        slackNew,
      );
    });

    test('does not open a human-created channel', () {
      expect(
        chatBridgeChannelToAutoOpen(
          previouslyKnownIds: const {},
          current: [_channel('user-new')],
          isForeground: false,
        ),
        isNull,
      );
    });

    test('does not reopen a bridged channel that was already in the list', () {
      expect(
        chatBridgeChannelToAutoOpen(
          previouslyKnownIds: {'slack-1'},
          current: [_channel('slack-1', origin: ChannelOrigin.slack)],
          isForeground: false,
        ),
        isNull,
      );
    });
  });
}
