import 'package:control_center/features/settings/providers/font_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('googleFontsProvider', () {
    test('is a Provider', () {
      expect(googleFontsProvider, isA<Provider<List<String>>>());
    });

    test('returns sorted list of fonts', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final fonts = container.read(googleFontsProvider);
      expect(fonts, isNotEmpty);
      for (var i = 1; i < fonts.length; i++) {
        expect(
          fonts[i - 1].compareTo(fonts[i]),
          lessThanOrEqualTo(0),
          reason: '${fonts[i - 1]} should come before ${fonts[i]}',
        );
      }
    });

    test('contains common Google fonts', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final fonts = container.read(googleFontsProvider);
      expect(fonts, contains('Inter'));
      expect(fonts, contains('Roboto'));
    });
  });

  group('systemFontsProvider', () {
    test('is a FutureProvider', () {
      expect(systemFontsProvider, isA<FutureProvider<List<Map<String, String>>>>());
    });
  });

  group('isGoogleFont', () {
    test('returns true for known Google font', () {
      expect(isGoogleFont('Inter'), isTrue);
    });

    test('returns true for Roboto', () {
      expect(isGoogleFont('Roboto'), isTrue);
    });

    test('returns false for unknown font', () {
      expect(isGoogleFont('DefinitelyNotARealFontName12345'), isFalse);
    });

    test('returns false for empty string', () {
      expect(isGoogleFont(''), isFalse);
    });
  });
}
