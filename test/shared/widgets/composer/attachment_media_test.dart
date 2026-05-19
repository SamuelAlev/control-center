import 'package:control_center/shared/widgets/composer/attachments/attachment_media.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mediaTypeForFileName', () {
    test('maps the common types', () {
      expect(mediaTypeForFileName('shot.PNG'), 'image/png');
      expect(mediaTypeForFileName('clip.mov'), 'video/quicktime');
      expect(mediaTypeForFileName('notes.md'), 'text/markdown');
      expect(mediaTypeForFileName('spec.pdf'), 'application/pdf');
    });

    test('is null for something it does not know', () {
      expect(mediaTypeForFileName('thing.qqq'), isNull);
      expect(mediaTypeForFileName('noextension'), isNull);
    });
  });

  group('attachmentMediaKind', () {
    test('classifies from a reported mime type', () {
      expect(
        attachmentMediaKind(mimeType: 'image/webp'),
        AttachmentMediaKind.image,
      );
      expect(
        attachmentMediaKind(mimeType: 'application/pdf'),
        AttachmentMediaKind.pdf,
      );
    });

    // The common desktop case: macOS hands over a file URL and leaves the type
    // to the receiver, so the extension is the only signal there is.
    test('classifies from the name when no type was reported', () {
      expect(
        attachmentMediaKind(name: 'diagram.svg'),
        AttachmentMediaKind.image,
      );
      expect(attachmentMediaKind(name: 'talk.mp4'), AttachmentMediaKind.video);
      expect(attachmentMediaKind(name: 'song.flac'), AttachmentMediaKind.audio);
    });

    test('ignores an unhelpfully generic reported type', () {
      expect(
        attachmentMediaKind(
          mimeType: 'application/octet-stream',
          name: 'photo.jpg',
        ),
        AttachmentMediaKind.image,
      );
    });

    // A source file dragged out of an editor commonly arrives as text/plain;
    // "plain text" and "highlight this as Dart" are the same renderer.
    test('prefers the extension for source files reported as text', () {
      expect(
        attachmentMediaKind(mimeType: 'text/plain', name: 'composer.dart'),
        AttachmentMediaKind.text,
      );
      expect(
        attachmentMediaKind(mimeType: 'text/plain', name: 'README.md'),
        AttachmentMediaKind.markdown,
      );
    });

    test('names office documents and archives rather than lumping them', () {
      expect(
        attachmentMediaKind(name: 'report.docx'),
        AttachmentMediaKind.document,
      );
      expect(
        attachmentMediaKind(name: 'bundle.zip'),
        AttachmentMediaKind.archive,
      );
      expect(
        attachmentMediaKind(name: 'mystery.qqq'),
        AttachmentMediaKind.other,
      );
    });

    test('classifies extensionless code filenames', () {
      expect(attachmentMediaKind(name: 'Dockerfile'), AttachmentMediaKind.text);
    });

    test('is other when nothing is known', () {
      expect(attachmentMediaKind(), AttachmentMediaKind.other);
    });
  });

  group('formatAttachmentSize', () {
    test('scales the unit', () {
      expect(formatAttachmentSize(512), '512 B');
      expect(formatAttachmentSize(2048), '2.0 KB');
      expect(formatAttachmentSize(1024 * 1024 * 3), '3.0 MB');
      expect(formatAttachmentSize(1024 * 1024 * 1024 * 2), '2.0 GB');
    });

    test('is null when the size is unknown', () {
      expect(formatAttachmentSize(null), isNull);
      expect(formatAttachmentSize(-1), isNull);
    });
  });
}
