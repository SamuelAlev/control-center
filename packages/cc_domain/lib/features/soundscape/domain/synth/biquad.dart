import 'dart:math' as math;

/// A second-order IIR (biquad) filter in Direct Form II Transposed.
///
/// Coefficients follow the RBJ audio-EQ cookbook. The filter keeps its sample
/// rate so its cutoff can be retuned in place (`setLowPass`/`setHighPass`/
/// `setBandPass`) without reallocating — used to glide the noise bed's
/// brightness as the weather changes.
class Biquad {
  Biquad._(this._sampleRate);

  /// A low-pass filter at [cutoffHz] with resonance [q].
  factory Biquad.lowPass(double sampleRate, double cutoffHz, double q) {
    final filter = Biquad._(sampleRate);
    filter.setLowPass(cutoffHz, q);
    return filter;
  }

  /// A high-pass filter at [cutoffHz] with resonance [q].
  factory Biquad.highPass(double sampleRate, double cutoffHz, double q) {
    final filter = Biquad._(sampleRate);
    filter.setHighPass(cutoffHz, q);
    return filter;
  }

  /// A (constant-0-dB-peak) band-pass filter centred at [cutoffHz] with [q].
  factory Biquad.bandPass(double sampleRate, double cutoffHz, double q) {
    final filter = Biquad._(sampleRate);
    filter.setBandPass(cutoffHz, q);
    return filter;
  }

  final double _sampleRate;

  double _b0 = 1.0;
  double _b1 = 0.0;
  double _b2 = 0.0;
  double _a1 = 0.0;
  double _a2 = 0.0;

  double _z1 = 0.0;
  double _z2 = 0.0;

  /// Clamps [cutoffHz] to a safe open interval below Nyquist.
  double _safeCutoff(double cutoffHz) {
    final nyquist = _sampleRate * 0.5;
    return cutoffHz.clamp(10.0, nyquist * 0.99);
  }

  /// Retunes this filter as a low-pass at [cutoffHz] with resonance [q].
  void setLowPass(double cutoffHz, double q) {
    final w0 = 2 * math.pi * _safeCutoff(cutoffHz) / _sampleRate;
    final cosW0 = math.cos(w0);
    final alpha = math.sin(w0) / (2 * (q <= 0 ? 0.0001 : q));
    final a0 = 1 + alpha;
    _b0 = ((1 - cosW0) / 2) / a0;
    _b1 = (1 - cosW0) / a0;
    _b2 = ((1 - cosW0) / 2) / a0;
    _a1 = (-2 * cosW0) / a0;
    _a2 = (1 - alpha) / a0;
  }

  /// Retunes this filter as a high-pass at [cutoffHz] with resonance [q].
  void setHighPass(double cutoffHz, double q) {
    final w0 = 2 * math.pi * _safeCutoff(cutoffHz) / _sampleRate;
    final cosW0 = math.cos(w0);
    final alpha = math.sin(w0) / (2 * (q <= 0 ? 0.0001 : q));
    final a0 = 1 + alpha;
    _b0 = ((1 + cosW0) / 2) / a0;
    _b1 = (-(1 + cosW0)) / a0;
    _b2 = ((1 + cosW0) / 2) / a0;
    _a1 = (-2 * cosW0) / a0;
    _a2 = (1 - alpha) / a0;
  }

  /// Retunes this filter as a band-pass centred at [cutoffHz] with [q].
  void setBandPass(double cutoffHz, double q) {
    final w0 = 2 * math.pi * _safeCutoff(cutoffHz) / _sampleRate;
    final cosW0 = math.cos(w0);
    final alpha = math.sin(w0) / (2 * (q <= 0 ? 0.0001 : q));
    final a0 = 1 + alpha;
    _b0 = alpha / a0;
    _b1 = 0.0;
    _b2 = (-alpha) / a0;
    _a1 = (-2 * cosW0) / a0;
    _a2 = (1 - alpha) / a0;
  }

  /// Processes a single input sample and returns the filtered output.
  double process(double x) {
    final y = _b0 * x + _z1;
    _z1 = _b1 * x - _a1 * y + _z2;
    _z2 = _b2 * x - _a2 * y;
    return y;
  }

  /// Clears the filter's internal delay state.
  void reset() {
    _z1 = 0.0;
    _z2 = 0.0;
  }
}
