import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/eager_locales_io.dart';
import 'package:flutter_test/flutter_test.dart';

/// Native builds look every locale up in this table instead of the deferred
/// libraries, so a locale missing from it would never load on the desktop.
void main() {
  test('every shipped locale is in the native table, and nothing else', () {
    expect(
      eagerLocales.keys.toSet(),
      AppLocalizations.supportedLocales.toSet(),
    );
  });

  test('each entry builds the localizations of its own locale', () {
    for (final entry in eagerLocales.entries) {
      expect(
        entry.value().localeName,
        entry.key.toString(),
        reason: '${entry.key}',
      );
    }
  });
}
