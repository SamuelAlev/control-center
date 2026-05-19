import 'package:cc_infra/src/messaging/vision/png_encoder.dart';
import 'package:cc_infra/src/messaging/vision/vision_compactor.dart';
import 'package:cc_infra/src/messaging/vision/vision_serialize.dart';
import 'package:cc_infra/src/messaging/vision/vision_shapes.dart';
import 'package:test/test.dart';

const VisionCompactor _compactor = VisionCompactor();

List<VisionEntry> _sampleEntries() => <VisionEntry>[
      const VisionEntry(role: 'user', text: 'Please refactor the parser.'),
      const VisionEntry(role: 'reasoning', text: 'I should read it first.'),
      const VisionEntry(
        role: 'tool',
        toolName: 'Read',
        toolArgs: <String, dynamic>{'path': 'lib/parser.dart'},
        text: 'class Parser { /* ... */ }',
      ),
      const VisionEntry(role: 'assistant', text: 'Done, refactored.'),
    ];

void main() {
  group('VisionCompactor.compact', () {
    test('produces non-empty PNG frames from entries', () {
      final archive = _compactor.compact(
        newEntries: _sampleEntries(),
        shape: resolveShape('claude-3-5-sonnet'),
      );
      expect(archive.frames, isNotEmpty);
      for (final frame in archive.frames) {
        expect(frame, isNotEmpty);
        // Each frame is a real PNG.
        expect(frame.sublist(0, 8), pngSignature);
      }
      expect(archive.totalChars, greaterThan(0));
      expect(archive.fullSourceText, contains('# User'));
    });

    test('summary reports the char and frame counts', () {
      final archive = _compactor.compact(
        newEntries: _sampleEntries(),
        shape: resolveShape('claude-3-5-sonnet'),
      );
      expect(archive.summary, contains('Vision-compacted'));
      expect(archive.summary, contains('${archive.totalChars} chars'));
      expect(archive.summary, contains('${archive.frames.length}'));
    });

    test('is deterministic: identical inputs produce identical frames', () {
      final shape = resolveShape('claude-3-5-sonnet');
      final a = _compactor.compact(newEntries: _sampleEntries(), shape: shape);
      final b = _compactor.compact(newEntries: _sampleEntries(), shape: shape);
      expect(a.frames.length, b.frames.length);
      for (var i = 0; i < a.frames.length; i++) {
        expect(a.frames[i], b.frames[i], reason: 'frame $i differs');
      }
      expect(a.fullSourceText, b.fullSourceText);
      expect(a.summary, b.summary);
    });

    test('accumulates the previous archive source text', () {
      final shape = resolveShape('claude-3-5-sonnet');
      final first = _compactor.compact(
        newEntries: <VisionEntry>[
          const VisionEntry(role: 'user', text: 'first message'),
        ],
        shape: shape,
      );
      final second = _compactor.compact(
        newEntries: <VisionEntry>[
          const VisionEntry(role: 'user', text: 'second message'),
        ],
        previous: first,
        shape: shape,
      );
      expect(second.fullSourceText, contains('first message'));
      expect(second.fullSourceText, contains('second message'));
      expect(second.totalChars, greaterThan(first.totalChars));
    });

    test('empty entries yield no frames and an empty source', () {
      final archive = _compactor.compact(
        newEntries: const <VisionEntry>[],
        shape: resolveShape('claude-3-5-sonnet'),
      );
      expect(archive.frames, isEmpty);
      expect(archive.fullSourceText, isEmpty);
      expect(archive.totalChars, 0);
    });

    test('low-quality middle frames are emitted for large histories', () {
      // A small frame shape forces foveation on modest input.
      const tiny = VisionShape(
        code: 'test',
        fontWidth: 8,
        fontHeight: 8,
        cellWidth: 8,
        cellHeight: 8,
        stopwordDim: false,
        columns: 1,
        frameSize: 16,
        frameTokenEstimate: 1,
        imageDetail: '',
      );
      final bigText = 'word ' * 200;
      final archive = _compactor.compact(
        newEntries: <VisionEntry>[
          VisionEntry(role: 'user', text: bigText),
        ],
        shape: tiny,
        maxFrames: 5,
      );
      expect(archive.frames, isNotEmpty);
      expect(archive.truncatedRegions, greaterThan(0));
      // Every frame is still a valid PNG of the right size.
      for (final frame in archive.frames) {
        expect(frame.sublist(0, 8), pngSignature);
      }
    });

    test('frames render at the shape frame size', () {
      final shape = resolveShape('gemini-pro'); // 2048px
      final archive = _compactor.compact(
        newEntries: _sampleEntries(),
        shape: shape,
      );
      // Decode IHDR width/height from the first frame.
      final png = archive.frames.first;
      int be32(int o) =>
          (png[o] << 24) | (png[o + 1] << 16) | (png[o + 2] << 8) | png[o + 3];
      // IHDR data begins at offset 16 (8 sig + 4 len + 4 type).
      expect(be32(16), shape.frameSize);
      expect(be32(20), shape.frameSize);
    });
  });
}
