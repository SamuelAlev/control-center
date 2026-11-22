import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:test/test.dart';

void main() {
  // 'a', then U+1F600 (a surrogate pair at units 1 and 2), then 'b'.
  const text = 'a😀b';

  test('a cut inside a surrogate pair moves before it or after it', () {
    expect(safeCutBefore(text, 2), 1);
    expect(safeCutAfter(text, 2), 3);
    expect(text.substring(0, safeCutBefore(text, 2)), 'a');
    expect(text.substring(safeCutAfter(text, 2)), 'b');
  });

  test('a cut on a boundary, or past either end, is kept (clamped)', () {
    for (final at in [0, 1, 3, 4]) {
      expect(safeCutBefore(text, at), at);
      expect(safeCutAfter(text, at), at);
    }
    expect(safeCutBefore(text, -5), 0);
    expect(safeCutAfter(text, 99), text.length);
  });

  test('a lone surrogate is no pair: the cut stays', () {
    final lone = String.fromCharCodes([0x61, 0xD83D, 0x62]);
    expect(safeCutBefore(lone, 2), 2);
    expect(safeCutAfter(lone, 2), 2);
  });
}
