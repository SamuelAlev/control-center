import 'dart:math' as math;

/// The small-sample statistics the evaluation gate needs: Student's t, the
/// exact sign-flip test and Holm's step-down correction. Pure Dart, no
/// dependency.
// ignore: avoid_classes_with_only_static_members
abstract final class TaskClusterStatistics {
  /// The standard normal quantile (Wichura, AS241 `PPND16`), accurate to
  /// about 1e-16 over (0, 1).
  static double normalQuantile(double p) {
    if (!(p > 0 && p < 1)) {
      throw ArgumentError.value(p, 'p', 'must be in (0, 1)');
    }
    final q = p - 0.5;
    if (q.abs() <= 0.425) {
      final r = 0.180625 - q * q;
      return q *
          (((((((r * 2509.0809287301226727 + 33430.575583588128105) * r +
                                                      67265.770927008700853) *
                                                  r +
                                              45921.953931549871457) *
                                          r +
                                      13731.693765509461125) *
                                  r +
                              1971.5909503065514427) *
                          r +
                      133.14166789178437745) *
                  r +
              3.387132872796366608) /
          (((((((r * 5226.495278852545925 + 28729.085735721942674) * r +
                                                      39307.89580009271061) *
                                                  r +
                                              21213.794301586595867) *
                                          r +
                                      5394.1960214247511077) *
                                  r +
                              687.1870074920579083) *
                          r +
                      42.313330701600911252) *
                  r +
              1.0);
    }
    var r = q < 0 ? p : 1 - p;
    r = math.sqrt(-math.log(r));
    double value;
    if (r <= 5) {
      r -= 1.6;
      value =
          (((((((r * 7.7454501427834140764e-4 + 0.0227238449892691845833) * r +
                                                      0.24178072517745061177) *
                                                  r +
                                              1.27045825245236838258) *
                                          r +
                                      3.64784832476320460504) *
                                  r +
                              5.7694972214606914055) *
                          r +
                      4.6303378461565452959) *
                  r +
              1.42343711074968357734) /
          (((((((r * 1.05075007164441684324e-9 + 5.475938084995344946e-4) * r +
                                                      0.0151986665636164571966) *
                                                  r +
                                              0.14810397642748007459) *
                                          r +
                                      0.68976733498510000455) *
                                  r +
                              1.6763848301838038494) *
                          r +
                      2.05319162663775882187) *
                  r +
              1.0);
    } else {
      r -= 5;
      value =
          (((((((r * 2.01033439929228813265e-7 + 2.71155556874348757815e-5) *
                                                          r +
                                                      0.0012426609473880784386) *
                                                  r +
                                              0.026532189526576123093) *
                                          r +
                                      0.29656057182850489123) *
                                  r +
                              1.7848265399172913358) *
                          r +
                      5.4637849111641143699) *
                  r +
              6.6579046435011037772) /
          (((((((r * 2.04426310338993978564e-15 + 1.4215117583164458887e-7) *
                                                          r +
                                                      1.8463183175100546818e-5) *
                                                  r +
                                              7.868691311456132591e-4) *
                                          r +
                                      0.0148753612908506148525) *
                                  r +
                              0.13692988092273580531) *
                          r +
                      0.59983220655588793769) *
                  r +
              1.0);
    }
    return q < 0 ? -value : value;
  }

  /// P(T ≤ [t]) for Student's t with [df] degrees of freedom, through the
  /// regularized incomplete beta function.
  static double studentTCdf(double t, int df) {
    if (df < 1) {
      throw ArgumentError.value(df, 'df', 'must be at least 1');
    }
    if (t.isNaN) {
      return double.nan;
    }
    if (t == double.infinity) {
      return 1;
    }
    if (t == double.negativeInfinity) {
      return 0;
    }
    final x = df / (df + t * t);
    final tail = 0.5 * _regularizedBeta(x, df / 2, 0.5);
    return t > 0 ? 1 - tail : tail;
  }

  /// The [p] quantile of Student's t with [df] degrees of freedom: the
  /// Cornish-Fisher expansion (Abramowitz and Stegun 26.7.5) over the normal
  /// quantile, refined by Newton steps on the exact distribution (the
  /// expansion alone is off by 5 % at one degree of freedom).
  static double studentTQuantile(double p, int df) {
    if (!(p > 0 && p < 1)) {
      throw ArgumentError.value(p, 'p', 'must be in (0, 1)');
    }
    if (df < 1) {
      throw ArgumentError.value(df, 'df', 'must be at least 1');
    }
    final x = normalQuantile(p);
    final n = df.toDouble();
    final x2 = x * x;
    final g1 = (x2 * x + x) / 4;
    final g2 = (5 * x2 * x2 * x + 16 * x2 * x + 3 * x) / 96;
    final g3 =
        (3 * math.pow(x, 7) + 19 * math.pow(x, 5) + 17 * x2 * x - 15 * x) / 384;
    final g4 =
        (79 * math.pow(x, 9) +
            776 * math.pow(x, 7) +
            1482 * math.pow(x, 5) -
            1920 * x2 * x -
            945 * x) /
        92160;
    var t = x + g1 / n + g2 / (n * n) + g3 / (n * n * n) + g4 / (n * n * n * n);
    for (var i = 0; i < 50; i++) {
      final error = studentTCdf(t, df) - p;
      final density = _studentTDensity(t, df);
      if (density <= 0) {
        break;
      }
      final step = error / density;
      t -= step;
      if (step.abs() < 1e-12 * math.max(1, t.abs())) {
        break;
      }
    }
    return t;
  }

  /// The one-sided p of the exact sign-flip (randomization) test that the
  /// mean of [values] is above zero: the share of the 2^N sign patterns whose
  /// sum is at least the observed one. Enumerated exactly up to 20 values;
  /// above that, 100,000 random patterns from [seed] (deterministic), with
  /// the observed pattern counted.
  static double signFlipPValue(List<double> values, {required int seed}) {
    final n = values.length;
    if (n == 0) {
      return 1;
    }
    final observed = values.fold<double>(0, (a, b) => a + b);
    final magnitudes = [for (final v in values) v.abs()];
    final total = magnitudes.fold<double>(0, (a, b) => a + b);
    const tolerance = 1e-9;
    if (n <= 20) {
      var atLeast = 0;
      final patterns = 1 << n;
      for (var mask = 0; mask < patterns; mask++) {
        var negative = 0.0;
        for (var i = 0; i < n; i++) {
          if (mask & (1 << i) != 0) {
            negative += magnitudes[i];
          }
        }
        if (total - 2 * negative >= observed - tolerance) {
          atLeast++;
        }
      }
      return atLeast / patterns;
    }
    const draws = 100000;
    final random = math.Random(seed);
    var atLeast = 1;
    for (var d = 0; d < draws; d++) {
      var sum = 0.0;
      for (final m in magnitudes) {
        sum += random.nextBool() ? m : -m;
      }
      if (sum >= observed - tolerance) {
        atLeast++;
      }
    }
    return atLeast / (draws + 1);
  }

  /// Holm's step-down correction: which of [pValues] are rejected at family
  /// level [alpha]. The smallest p is held to alpha/m, the next to
  /// alpha/(m−1), and the first that fails stops every larger one.
  static List<bool> holm(List<double> pValues, double alpha) {
    final m = pValues.length;
    final order = List<int>.generate(m, (i) => i)
      ..sort((a, b) => pValues[a].compareTo(pValues[b]));
    final rejected = List<bool>.filled(m, false);
    for (var rank = 0; rank < m; rank++) {
      final index = order[rank];
      if (pValues[index] > alpha / (m - rank)) {
        break;
      }
      rejected[index] = true;
    }
    return rejected;
  }

  static double _studentTDensity(double t, int df) {
    final n = df.toDouble();
    final logDensity =
        _logGamma((n + 1) / 2) -
        _logGamma(n / 2) -
        0.5 * math.log(n * math.pi) -
        (n + 1) / 2 * math.log(1 + t * t / n);
    return math.exp(logDensity);
  }

  /// I_x(a, b) by the continued fraction (Lentz), using the symmetry
  /// I_x(a, b) = 1 − I_{1−x}(b, a) where it converges faster.
  static double _regularizedBeta(double x, double a, double b) {
    if (x <= 0) {
      return 0;
    }
    if (x >= 1) {
      return 1;
    }
    final front = math.exp(
      _logGamma(a + b) -
          _logGamma(a) -
          _logGamma(b) +
          a * math.log(x) +
          b * math.log(1 - x),
    );
    if (x < (a + 1) / (a + b + 2)) {
      return front * _betaFraction(x, a, b) / a;
    }
    return 1 - front * _betaFraction(1 - x, b, a) / b;
  }

  static double _betaFraction(double x, double a, double b) {
    const tiny = 1e-300;
    const epsilon = 1e-15;
    final qab = a + b;
    final qap = a + 1;
    final qam = a - 1;
    var c = 1.0;
    var d = 1 - qab * x / qap;
    if (d.abs() < tiny) {
      d = tiny;
    }
    d = 1 / d;
    var h = d;
    for (var m = 1; m <= 300; m++) {
      final m2 = 2 * m;
      var aa = m * (b - m) * x / ((qam + m2) * (a + m2));
      d = 1 + aa * d;
      if (d.abs() < tiny) {
        d = tiny;
      }
      c = 1 + aa / c;
      if (c.abs() < tiny) {
        c = tiny;
      }
      d = 1 / d;
      h *= d * c;
      aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
      d = 1 + aa * d;
      if (d.abs() < tiny) {
        d = tiny;
      }
      c = 1 + aa / c;
      if (c.abs() < tiny) {
        c = tiny;
      }
      d = 1 / d;
      final delta = d * c;
      h *= delta;
      if ((delta - 1).abs() < epsilon) {
        break;
      }
    }
    return h;
  }

  /// ln Γ(x) for x > 0 (Lanczos, g = 7, nine coefficients).
  static double _logGamma(double x) {
    const coefficients = [
      0.99999999999980993,
      676.5203681218851,
      -1259.1392167224028,
      771.32342877765313,
      -176.61502916214059,
      12.507343278686905,
      -0.13857109526572012,
      9.9843695780195716e-6,
      1.5056327351493116e-7,
    ];
    if (x < 0.5) {
      return math.log(math.pi / math.sin(math.pi * x)) - _logGamma(1 - x);
    }
    final z = x - 1;
    var sum = coefficients[0];
    for (var i = 1; i < coefficients.length; i++) {
      sum += coefficients[i] / (z + i);
    }
    final t = z + 7.5;
    return 0.5 * math.log(2 * math.pi) +
        (z + 0.5) * math.log(t) -
        t +
        math.log(sum);
  }
}
