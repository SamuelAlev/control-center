import 'dart:convert';

import 'package:cc_infra/src/dispatch/render_media_image_refs.dart';
import 'package:test/test.dart';

void main() {
  test('should extract all four saved refs from builtin result text', () {
    final text = jsonEncode({
      'source': 'video',
      'images': [
        for (var i = 0; i < 4; i++)
          {
            'ref': 'blob:sha256:$i',
            'mediaType': 'image/jpeg',
            'bytes': 123,
            'width': 320,
            'height': 180,
          },
      ],
    });
    final refs = renderMediaImageRefs('render_media', text);
    expect(refs.map((image) => image.ref), [
      for (var i = 0; i < 4; i++) 'blob:sha256:$i',
    ]);
    expect(refs.every((image) => image.mediaType == 'image/jpeg'), true);
    expect(refs.every((image) => image.width == 320), true);
    expect(renderMediaImageRefs('unrelated_tool', text), isEmpty);
  });

  test('should ignore image data blocks and malformed metadata', () {
    final refs = renderMediaImageRefs('mcp__control-center__render_media', [
      {
        'type': 'text',
        'text': jsonEncode({
          'images': [
            {'ref': 'blob:sha256:one', 'mediaType': 'image/png'},
            {'ref': 'blob:sha256:two', 'mediaType': 'image/png'},
          ],
        }),
      },
      {'type': 'image', 'data': 'base64-not-persisted'},
    ]);
    expect(refs.map((image) => image.ref), [
      'blob:sha256:one',
      'blob:sha256:two',
    ]);
    expect(renderMediaImageRefs('render_media', 'not JSON'), isEmpty);
    expect(
      renderMediaImageRefs(
        'render_media',
        jsonEncode({
          'images': [
            {'ref': 42, 'mediaType': 'image/png'},
          ],
        }),
      ),
      isEmpty,
    );
  });
}
