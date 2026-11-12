import 'package:cc_domain/core/domain/value_objects/money.dart';
import 'package:intl/intl.dart';

/// The app's money formatter: [micros] (1 USD = 1,000,000) as a US dollar
/// amount in [locale], or the app locale when it is omitted.
///
/// Without [decimals], amounts under one dollar show three decimals ($0.004)
/// so small per-run costs stay legible, and larger ones two ($4.20). A
/// positive amount smaller than the last shown digit reads as less than that
/// digit (`<$0.01`) instead of a zero that is not true.
String fmtMicros(int micros, {int? decimals, String? locale}) {
  final digits =
      decimals ?? (micros != 0 && micros.abs() < microsPerDollar ? 3 : 2);
  final format = NumberFormat.simpleCurrency(
    locale: locale,
    name: 'USD',
    decimalDigits: digits,
  );
  var unit = microsPerDollar;
  for (var i = 0; i < digits; i++) {
    unit ~/= 10;
  }
  if (micros > 0 && micros < unit) {
    return '<${format.format(unit / microsPerDollar)}';
  }
  return format.format(micros / microsPerDollar);
}
