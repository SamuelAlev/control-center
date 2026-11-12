/// The one money unit: integer micro-dollars (1 USD = 1,000,000).
///
/// Every stored column, entity, wire field and comparison carries money in
/// micro-dollars. A priced call that costs a fraction of a cent is real spend:
/// a coarser unit rounds it to zero, and hundreds of such calls then add up to
/// nothing against a budget or a cap. Cents exist only where money becomes
/// text ([formatUsdMicros]) and at the few inputs whose copy asks for cents
/// ([centsToMicros]).
library;

/// Micro-dollars per US dollar.
const int microsPerDollar = 1000000;

/// Micro-dollars per US cent.
const int microsPerCent = 10000;

/// Converts a whole number of US cents typed by a person into micro-dollars.
///
/// Only for inputs whose copy asks for cents; everything else is micros
/// already.
int centsToMicros(int cents) => cents * microsPerCent;

/// Converts a dollar amount typed by a person (`25`, `25.5`) into
/// micro-dollars, rounded to the nearest micro.
int dollarsToMicros(num dollars) => (dollars * microsPerDollar).round();

/// Parses a dollar amount as a person types it (`25`, `25.50`, `$25`) into
/// micro-dollars, or null when it is not a finite number.
int? parseDollarsToMicros(String raw) {
  final dollars = double.tryParse(raw.trim().replaceFirst(r'$', ''));
  if (dollars == null || !dollars.isFinite) {
    return null;
  }
  return dollarsToMicros(dollars);
}

/// Server-rendered money text (`$12.34`): cents precision, rounded to the
/// nearest cent, the way logs, audit details, agent-facing messages and
/// reports show money.
String formatUsdMicros(int micros) {
  final cents = (micros / microsPerCent).round();
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  return '$sign\$${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
}
