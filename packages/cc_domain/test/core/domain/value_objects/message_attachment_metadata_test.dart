import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:test/test.dart';

/// The tolerant read of `metadata['attachments']`.
///
/// Both ends go through this: the transcript draws the strip from it and the
/// dispatch path decides what an agent is handed. It is also what the server op
/// narrows a client's metadata down to, so what it IGNORES is a security
/// property, not a formatting one.
void main() {
  final blob = 'blob:sha256:${'a' * 64}';

  Map<String, dynamic> meta(List<Object?> attachments) => {
    'attachments': attachments,
  };

  group('attachmentsFromMetadata', () {
    test('reads entries in send order, not list order', () {
      final found = MessageAttachment.attachmentsFromMetadata(
        meta([
          {'path': blob, 'name': 'b.png', 'kind': 'image', 'order': 1},
          {'path': blob, 'name': 'a.png', 'kind': 'image', 'order': 0},
        ]),
      );
      expect(found.map((a) => a.name), ['a.png', 'b.png']);
    });

    test('falls back to list position when no order was written', () {
      final found = MessageAttachment.attachmentsFromMetadata(
        meta([
          {'path': blob, 'name': 'first.png'},
          {'path': blob, 'name': 'second.png'},
        ]),
      );
      expect(found.map((a) => a.name), ['first.png', 'second.png']);
    });

    test('skips malformed entries instead of throwing', () {
      // A transcript build walks this; one bad row must not blank the
      // conversation.
      final found = MessageAttachment.attachmentsFromMetadata(
        meta(['not a map', {'kind': 'image'}, {'path': blob}]),
      );
      expect(found, hasLength(1));
      expect(found.single.name, 'attachment');
    });

    test('is empty for a message that carried none', () {
      expect(MessageAttachment.attachmentsFromMetadata(null), isEmpty);
      expect(MessageAttachment.attachmentsFromMetadata({'other': 1}), isEmpty);
      expect(
        MessageAttachment.attachmentsFromMetadata({'attachments': 'nope'}),
        isEmpty,
      );
    });

    test('reads nothing but attachments from the map', () {
      // What the server relies on when it narrows a client's metadata: a caller
      // cannot smuggle mentions, entity refs or chat provenance through this
      // door, because nothing else is read.
      final found = MessageAttachment.attachmentsFromMetadata({
        'attachments': [
          {'path': blob, 'name': 'a.png', 'kind': 'image'},
        ],
        'mentions': [
          {'agentId': 'a-1', 'raw': '@architect'},
        ],
        'chat': {'provider': 'slack'},
      });
      expect(found.single.toJson().keys, isNot(contains('mentions')));
      expect(found.single.name, 'a.png');
    });
  });

  group('blobHash', () {
    test('separates an uploaded reference from a path on somebody disk', () {
      expect(
        MessageAttachment.tryFromJson({'path': blob, 'name': 'a'})!.isUploaded,
        isTrue,
      );
      expect(
        MessageAttachment.tryFromJson({
          'path': '/tmp/a.png',
          'name': 'a',
        })!.isUploaded,
        isFalse,
      );
    });

    test('refuses a hash that is not 64 lowercase hex characters', () {
      // The hash becomes a filename on the server, so anything else is a
      // traversal attempt rather than a reference.
      for (final bad in [
        'blob:sha256:short',
        'blob:sha256:${'A' * 64}',
        'blob:sha256:../../etc/passwd',
      ]) {
        expect(
          MessageAttachment.tryFromJson({'path': bad, 'name': 'a'})!.blobHash,
          isNull,
          reason: bad,
        );
      }
    });
  });

  test('mediaType and localPath round-trip, and stay out when unset', () {
    const full = MessageAttachment(
      id: 'i',
      path: '/p',
      name: 'n',
      kind: AttachmentKind.file,
      mediaType: 'application/pdf',
      localPath: '/home/me/spec.pdf',
    );
    expect(MessageAttachment.fromJson(full.toJson()), full);
    const bare = MessageAttachment(
      id: 'i',
      path: '/p',
      name: 'n',
      kind: AttachmentKind.file,
    );
    expect(bare.toJson().containsKey('mediaType'), isFalse);
    expect(bare.toJson().containsKey('localPath'), isFalse);
  });
}
