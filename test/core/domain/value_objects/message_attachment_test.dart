
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttachmentKind', () {
    test('has image and file values', () {
      expect(AttachmentKind.values, containsAll([AttachmentKind.image, AttachmentKind.file]));
      expect(AttachmentKind.values.length, 2);
    });
  });

  group('MessageAttachment', () {
    group('constructor', () {
      test('creates instance with all fields', () {
        const a = MessageAttachment(
          id: 'a1',
          path: '/tmp/img.png',
          name: 'img.png',
          kind: AttachmentKind.image,
          size: 1024,
          order: 3,
        );
        expect(a.id, 'a1');
        expect(a.path, '/tmp/img.png');
        expect(a.name, 'img.png');
        expect(a.kind, AttachmentKind.image);
        expect(a.size, 1024);
        expect(a.order, 3);
      });

      test('default order is 0', () {
        const a = MessageAttachment(
          id: 'a1',
          path: '/tmp/f.txt',
          name: 'f.txt',
          kind: AttachmentKind.file,
        );
        expect(a.order, 0);
        expect(a.size, isNull);
      });
    });

    group('fromJson', () {
      test('parses image kind', () {
        final a = MessageAttachment.fromJson({
          'id': 'a1',
          'path': '/tmp/img.png',
          'name': 'img.png',
          'kind': 'image',
          'size': 2048,
          'order': 1,
        });
        expect(a.kind, AttachmentKind.image);
        expect(a.size, 2048);
        expect(a.order, 1);
      });

      test('parses file kind for any non-image string', () {
        for (final kindStr in ['file', 'video', '']) {
          final a = MessageAttachment.fromJson({
            'id': 'a1',
            'path': '/tmp/f',
            'name': 'f',
            'kind': kindStr,
          });
          expect(a.kind, AttachmentKind.file, reason: 'kind="$kindStr" should parse as file');
        }
      });

      test('handles null size', () {
        final a = MessageAttachment.fromJson({
          'id': 'a1',
          'path': '/tmp/f',
          'name': 'f',
          'kind': 'file',
        });
        expect(a.size, isNull);
      });

      test('null order defaults to 0', () {
        final a = MessageAttachment.fromJson({
          'id': 'a1',
          'path': '/tmp/f',
          'name': 'f',
          'kind': 'file',
        });
        expect(a.order, 0);
      });
    });

    group('toJson', () {
      test('includes size when non-null', () {
        const a = MessageAttachment(
          id: 'a1',
          path: '/tmp/img.png',
          name: 'img.png',
          kind: AttachmentKind.image,
          size: 512,
          order: 2,
        );
        final json = a.toJson();
        expect(json, containsPair('size', 512));
      });

      test('omits size when null', () {
        const a = MessageAttachment(
          id: 'a1',
          path: '/tmp/f.txt',
          name: 'f.txt',
          kind: AttachmentKind.file,
        );
        final json = a.toJson();
        expect(json, isNot(contains('size')));
      });

      test('round-trips through fromJson', () {
        const original = MessageAttachment(
          id: 'a1',
          path: '/tmp/img.png',
          name: 'img.png',
          kind: AttachmentKind.image,
          size: 4096,
          order: 5,
        );
        final roundTripped = MessageAttachment.fromJson(original.toJson());
        expect(roundTripped, original);
      });
    });

    group('== and hashCode', () {
      test('equal when all fields match', () {
        const a = MessageAttachment(
          id: 'a1',
          path: '/tmp/f',
          name: 'f',
          kind: AttachmentKind.file,
          size: 100,
          order: 1,
        );
        const b = MessageAttachment(
          id: 'a1',
          path: '/tmp/f',
          name: 'f',
          kind: AttachmentKind.file,
          size: 100,
          order: 1,
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('not equal when id differs', () {
        const a = MessageAttachment(
          id: 'a1',
          path: '/tmp/f',
          name: 'f',
          kind: AttachmentKind.file,
        );
        const b = MessageAttachment(
          id: 'a2',
          path: '/tmp/f',
          name: 'f',
          kind: AttachmentKind.file,
        );
        expect(a, isNot(b));
      });

      test('equal objects have same hashCode', () {
        const a = MessageAttachment(
          id: 'x',
          path: '/p',
          name: 'n',
          kind: AttachmentKind.image,
          size: null,
          order: 0,
        );
        const b = MessageAttachment(
          id: 'x',
          path: '/p',
          name: 'n',
          kind: AttachmentKind.image,
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });
    });
  });
}
