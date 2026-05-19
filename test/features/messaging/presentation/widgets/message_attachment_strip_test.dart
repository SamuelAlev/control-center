import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/message_attachment_refs.dart';
import 'package:flutter_test/flutter_test.dart';

final String _blob = 'blob:sha256:${'a' * 64}';
final String _blob2 = 'blob:sha256:${'b' * 64}';

Message _message(Map<String, dynamic>? metadata) => Message(
  id: 'm1',
  spaceId: 's1',
  conversationId: 'c1',
  senderId: 'u1',
  senderType: SenderType.user,
  content: 'look at this',
  messageType: MessageType.text,
  createdAt: DateTime.utc(2026),
  metadata: metadata,
);

void main() {
  group('messageAttachmentsOf', () {
    test('reads attachments in send order', () {
      final message = _message({
        'attachments': [
          {'kind': 'image', 'path': _blob2, 'name': 'b.png', 'order': 1},
          {
            'kind': 'image',
            'path': _blob,
            'name': 'a.png',
            'order': 0,
            'size': 2048,
          },
        ],
      });
      final found = messageAttachmentsOf(message);
      expect(found.map((a) => a.name), ['a.png', 'b.png']);
      expect(found.first.size, 2048);
      expect(found.first.path, _blob);
      expect(found.first.isImage, isTrue);
    });

    // The regression this guards: a dropped FILE used to leave no record on the
    // message at all, so a sent message showed a bare expanded path and there
    // was nothing left to click.
    test('keeps non-picture files, by path', () {
      final message = _message({
        'attachments': [
          {
            'kind': 'file',
            'path': '/repo/spec.pdf',
            'name': 'spec.pdf',
            'mediaType': 'application/pdf',
            'size': 4096,
            'order': 0,
          },
        ],
      });
      final file = messageAttachmentsOf(message).single;
      expect(file.isImage, isFalse);
      expect(file.path, '/repo/spec.pdf');
      expect(file.mediaType, 'application/pdf');
      expect(file.size, 4096);
    });

    test('is empty when the message carries none', () {
      expect(messageAttachmentsOf(_message(null)), isEmpty);
      expect(messageAttachmentsOf(_message({'other': 1})), isEmpty);
    });

    test('skips malformed entries instead of throwing', () {
      final message = _message({
        'attachments': [
          'not a map',
          {'kind': 'image'},
          {'kind': 'image', 'path': _blob},
        ],
      });
      final found = messageAttachmentsOf(message);
      expect(found, hasLength(1));
      expect(found.single.path, _blob);
      expect(found.single.name, 'attachment');
    });

    // The degraded case: an attachment too large to carry, or whose upload
    // failed, is still recorded — by path. `isUploaded` is what separates a
    // reference every reader can resolve from one that only works on the
    // machine that sent it.
    test('distinguishes an uploaded reference from a local path', () {
      final message = _message({
        'attachments': [
          {'kind': 'image', 'path': _blob, 'name': 'sent.png'},
          {'kind': 'image', 'path': '/tmp/huge.png', 'name': 'huge.png'},
          {'kind': 'file', 'path': '/tmp/notes.md', 'name': 'notes.md'},
        ],
      });
      final found = messageAttachmentsOf(message);
      expect(found.map((a) => a.name), ['sent.png', 'huge.png', 'notes.md']);
      expect(found[0].isUploaded, isTrue);
      expect(found[1].isUploaded, isFalse);
      expect(found[2].isUploaded, isFalse);
    });

    test('falls back to list position when order is missing', () {
      final message = _message({
        'attachments': [
          {'kind': 'image', 'path': _blob, 'name': 'first.png'},
          {'kind': 'image', 'path': _blob2, 'name': 'second.png'},
        ],
      });
      expect(messageAttachmentsOf(message).map((a) => a.name), [
        'first.png',
        'second.png',
      ]);
    });
  });
}
