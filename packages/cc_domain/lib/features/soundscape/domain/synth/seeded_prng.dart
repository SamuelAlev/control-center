/// A small, fast, fully deterministic pseudo-random number generator.
///
/// Implements Marsaglia's xorshift128 over four 32-bit lanes. Deliberately
/// does NOT use `dart:math`'s `Random` so that a given `seed` always produces
/// the exact same sequence — soundscape renders must be sample-identical for a
/// given `SoundscapeContext`. All arithmetic stays within 2^53 (shifts are
/// masked to 32 bits) so the sequence is identical on the native VM and on the
/// web.
class SeededPrng {
  /// Creates a PRNG whose sequence is fully determined by [seed].
  SeededPrng(int seed) {
    final s = seed & _mask;
    _x = (s ^ 0x9E3779B9) & _mask;
    _y = (_rotl(_x, 13) ^ 0x243F6A88) & _mask;
    _z = (_rotl(_y, 7) ^ 0xB7E15162) & _mask;
    _w = (_rotl(_z, 17) ^ 0xDEADBEEF) & _mask;
    if (_x == 0 && _y == 0 && _z == 0 && _w == 0) {
      _x = 0x1;
    }
    // Warm up so low-entropy seeds diverge before the first draw.
    for (var i = 0; i < 16; i++) {
      _step();
    }
  }

  static const int _mask = 0xFFFFFFFF;
  static const double _twoPow32 = 4294967296.0;

  late int _x;
  late int _y;
  late int _z;
  late int _w;

  int _rotl(int v, int n) => ((v << n) | (v >>> (32 - n))) & _mask;

  /// Advances the state one step and returns a fresh 32-bit unsigned integer.
  int _step() {
    final t = (_x ^ ((_x << 11) & _mask)) & _mask;
    _x = _y;
    _y = _z;
    _z = _w;
    _w = (_w ^ (_w >>> 19) ^ (t ^ (t >>> 8))) & _mask;
    return _w;
  }

  /// Returns the next value in `[0, 1)`.
  double nextDouble() => _step() / _twoPow32;

  /// Returns the next value uniformly in `[lo, hi)`.
  double nextRange(double lo, double hi) => lo + nextDouble() * (hi - lo);

  /// Returns the next integer in `[0, max)`.
  ///
  /// Throws an [ArgumentError] if [max] is not positive.
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be greater than 0');
    }
    return _step() % max;
  }

  /// Returns `true` with probability [p] (clamped to `[0, 1]`).
  bool nextBool(double p) => nextDouble() < p;
}
