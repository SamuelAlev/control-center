import 'package:control_center/shared/utils/video_embed_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoomEmbedAdapter', () {
    const adapter = LoomEmbedAdapter();

    String? embed(String url) =>
        adapter.embedUrlFor(Uri.parse(url))?.toString();

    test('rewrites share → embed', () {
      expect(
        embed('https://www.loom.com/share/abc123'),
        'https://www.loom.com/embed/abc123',
      );
    });

    test('keeps embed as embed', () {
      expect(
        embed('https://www.loom.com/embed/abc123'),
        'https://www.loom.com/embed/abc123',
      );
    });

    test('handles the bare (no-www) host', () {
      expect(
        embed('https://loom.com/share/abc123'),
        'https://www.loom.com/embed/abc123',
      );
    });

    test('drops query string and fragment', () {
      expect(
        embed('https://www.loom.com/share/abc123?sid=xyz&t=10#foo'),
        'https://www.loom.com/embed/abc123',
      );
    });

    test('tolerates a trailing slash', () {
      expect(
        embed('https://www.loom.com/share/abc123/'),
        'https://www.loom.com/embed/abc123',
      );
    });

    test('strips trailing punctuation from the id', () {
      expect(
        embed('https://www.loom.com/share/abc123.'),
        'https://www.loom.com/embed/abc123',
      );
    });

    test('returns null for non-loom hosts', () {
      expect(embed('https://example.com/share/abc123'), isNull);
      expect(embed('https://youtube.com/watch?v=abc'), isNull);
    });

    test('returns null for unrecognised loom paths', () {
      expect(embed('https://www.loom.com/'), isNull);
      expect(embed('https://www.loom.com/looms/folders'), isNull);
      expect(embed('https://www.loom.com/share'), isNull);
    });

    test('exposes provider metadata', () {
      expect(adapter.providerName, 'Loom');
      expect(adapter.aspectRatio, closeTo(16 / 9, 0.001));
    });
  });

  group('VideoEmbedRegistry', () {
    test('default instance resolves Loom links', () {
      final match = VideoEmbedRegistry.instance.resolve(
        Uri.parse('https://www.loom.com/share/abc123'),
      );
      expect(match, isNotNull);
      expect(match!.adapter, isA<LoomEmbedAdapter>());
      expect(match.embedUrl.toString(), 'https://www.loom.com/embed/abc123');
    });

    test('returns null when no adapter matches', () {
      expect(
        VideoEmbedRegistry.instance.resolve(Uri.parse('https://example.com')),
        isNull,
      );
    });
  });
}
