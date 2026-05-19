import 'package:cc_infra/src/messaging/vision/vision_shapes.dart';
import 'package:test/test.dart';

void main() {
  group('resolveShape', () {
    test('Fable/Mythos Claude → 11on16-bw at 1932px', () {
      final shape = resolveShape('claude-fable-1');
      expect(shape.code, '11on16-bw');
      expect(shape.cellWidth, 11);
      expect(shape.cellHeight, 16);
      expect(shape.frameSize, 1932);
    });

    test('Opus 4.7+ → 11on16-bw at 1932px', () {
      expect(resolveShape('claude-opus-4-7').frameSize, 1932);
      expect(resolveShape('claude-opus-4.8').frameSize, 1932);
      expect(resolveShape('claude-opus-4-9').frameSize, 1932);
    });

    test('Opus 4.6 falls back to plain Claude shape at 1568px', () {
      final shape = resolveShape('claude-opus-4-6');
      expect(shape.code, '11on16-bw');
      expect(shape.frameSize, 1568);
    });

    test('generic Claude → 11on16-bw at 1568px', () {
      final shape = resolveShape('claude-3-5-sonnet');
      expect(shape.code, '11on16-bw');
      expect(shape.cellWidth, 11);
      expect(shape.cellHeight, 16);
      expect(shape.frameSize, 1568);
    });

    test('Gemini → 8on22-bw at 2048px', () {
      final shape = resolveShape('gemini-3.5-flash');
      expect(shape.code, '8on22-bw');
      expect(shape.cellWidth, 8);
      expect(shape.cellHeight, 22);
      expect(shape.frameSize, 2048);
      expect(shape.frameTokenEstimate, 1120);
    });

    test('GPT / Codex → 8on22-bw at 1568px with original detail', () {
      final gpt = resolveShape('gpt-5.5');
      expect(gpt.code, '8on22-bw');
      expect(gpt.frameSize, 1568);
      expect(gpt.imageDetail, 'original');
      expect(resolveShape('codex-mini').code, '8on22-bw');
    });

    test('kimi → 8on16-bw at 1568px', () {
      final shape = resolveShape('kimi-k2');
      expect(shape.code, '8on16-bw');
      expect(shape.cellWidth, 8);
      expect(shape.cellHeight, 16);
      expect(shape.frameSize, 1568);
    });

    test('glm → 8on16-bw', () {
      expect(resolveShape('glm-4.6v').code, '8on16-bw');
    });

    test('matching is case-insensitive', () {
      expect(resolveShape('CLAUDE-OPUS-4-8').frameSize, 1932);
      expect(resolveShape('GEMINI-PRO').code, '8on22-bw');
    });

    test('unknown model falls back to Anthropic 11on16-bw at 1568px', () {
      final shape = resolveShape('some-unknown-model');
      expect(shape.code, '11on16-bw');
      expect(shape.cellWidth, 11);
      expect(shape.cellHeight, 16);
      expect(shape.frameSize, 1568);
    });

    test('first match wins: claude-fable matched before generic claude', () {
      // A model id containing both should resolve to the high-res shape.
      expect(resolveShape('claude-mythos-pro').frameSize, 1932);
    });

    test('all shapes use the 8x8 embedded font and monochrome ink', () {
      for (final id in <String>[
        'claude-opus-4-8',
        'gemini-pro',
        'gpt-5',
        'kimi',
        'unknown',
      ]) {
        final shape = resolveShape(id);
        expect(shape.fontWidth, 8);
        expect(shape.fontHeight, 8);
        expect(shape.stopwordDim, isFalse);
        expect(shape.columns, 1);
      }
    });

    test('derived geometry getters compute capacity', () {
      final shape = resolveShape('claude-3-5-sonnet');
      expect(shape.columnsPerFrame, 1568 ~/ 11);
      expect(shape.rowsPerFrame, 1568 ~/ 16);
      expect(shape.capacity, shape.columnsPerFrame * shape.rowsPerFrame);
    });
  });

  group('VisionShape equality', () {
    test('identical shapes are equal and hash equal', () {
      final a = resolveShape('claude-3-5-sonnet');
      final b = resolveShape('claude-3-5-sonnet');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different shapes are not equal', () {
      expect(resolveShape('claude'), isNot(resolveShape('gemini')));
    });
  });
}
