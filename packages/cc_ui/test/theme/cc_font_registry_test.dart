import 'dart:typed_data';

import 'package:cc_ui/src/theme/cc_font_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final registry = CcFontRegistry.instance;

  setUp(registry.resetForTests);
  tearDown(registry.resetForTests);

  group('apply', () {
    test('an empty family is a no-op', () {
      const base = TextStyle(fontSize: 12);
      expect(registry.apply('', base), base);
    });

    test('applies the unified family and preserves weight and size', () {
      final style = registry.apply(
        'Inter',
        const TextStyle(fontWeight: FontWeight.w300, fontSize: 11),
      );
      expect(style.fontFamily, 'Inter');
      expect(style.fontWeight, FontWeight.w300);
      expect(style.fontSize, 11, reason: 'other fields survive');
    });

    test('preserves an existing fallback chain after its own', () {
      final style = registry.apply(
        'Inter',
        const TextStyle(fontFamilyFallback: ['Apple Color Emoji']),
        fallbackFamily: 'Manrope',
      );
      expect(style.fontFamily, 'Inter');
      expect(style.fontFamilyFallback, ['Manrope', 'Apple Color Emoji']);
    });

    test('extraFallbacks slot in ahead of the caller list', () {
      final style = registry.apply(
        'Inter',
        const TextStyle(fontFamilyFallback: ['Apple Color Emoji']),
        fallbackFamily: 'Manrope',
        extraFallbacks: const ['PingFang SC', 'Noto Sans CJK SC'],
      );
      expect(style.fontFamily, 'Inter');
      expect(style.fontFamilyFallback, [
        'Manrope',
        'PingFang SC',
        'Noto Sans CJK SC',
        'Apple Color Emoji',
      ]);
    });
  });

  group('loading', () {
    test('fetches a cut once, however many times it is applied', () async {
      final requested = <String>[];
      registry.install(
        loader: ({required family, required weight, required italic}) async {
          requested.add('$family/$weight/$italic');
          return null;
        },
      );

      registry.apply('Inter', const TextStyle());
      registry.apply('Inter', const TextStyle(fontSize: 20));
      registry.apply('Inter', const TextStyle(fontWeight: FontWeight.w700));
      await pumpEventQueue();

      expect(requested, ['Inter/400/false', 'Inter/700/false']);
    });

    test('does not fetch before a loader is installed', () async {
      // An unconnected client must still render: bundled and OS-installed
      // families work, downloadable ones simply fall back.
      final style = registry.apply('Inter', null);
      await pumpEventQueue();
      expect(style.fontFamily, 'Inter');
    });

    test('skips families the host does not catalogue', () async {
      final requested = <String>[];
      registry
        ..install(
          loader: ({required family, required weight, required italic}) async {
            requested.add(family);
            return null;
          },
        )
        ..setCatalogue(['Inter']);

      registry.apply('Inter', null);
      registry.apply('Menlo', null);
      await pumpEventQueue();

      expect(
        requested,
        ['Inter'],
        reason: 'an OS-installed family would only 404',
      );
    });

    test('attempts optimistically while the catalogue is unknown', () async {
      // The catalogue loads with the picker, so a font selected at boot has to
      // be fetchable before it arrives.
      final requested = <String>[];
      registry.install(
        loader: ({required family, required weight, required italic}) async {
          requested.add(family);
          return null;
        },
      );

      registry.apply('Menlo', null);
      await pumpEventQueue();

      expect(requested, ['Menlo']);
    });

    test('a throwing loader does not escape', () async {
      registry.install(
        loader: ({required family, required weight, required italic}) async =>
            throw Exception('host went away'),
      );

      expect(() => registry.apply('Inter', null), returnsNormally);
      await pumpEventQueue();
    });

    test('corrupt bytes do not escape', () async {
      // FontLoader.load throws on a non-font payload; a font is cosmetic, so it
      // must never take a build down.
      registry.install(
        loader: ({required family, required weight, required italic}) async =>
            Uint8List.fromList([1, 2, 3]),
      );

      expect(() => registry.apply('Broken', null), returnsNormally);
      await pumpEventQueue();
    });

    test('a new connection retries a family that failed', () async {
      var calls = 0;
      Future<Uint8List?> loader({
        required String family,
        required int weight,
        required bool italic,
      }) async {
        calls++;
        return null;
      }

      registry.install(loader: loader);
      registry.apply('Inter', null);
      await pumpEventQueue();

      registry.install(loader: loader);
      registry.apply('Inter', null);
      await pumpEventQueue();

      expect(calls, 2);
    });
  });

  group('preloadFamily', () {
    test('requests all standard cuts under the unified family', () async {
      final requested = <(int, bool)>[];
      registry.install(
        loader: ({required family, required weight, required italic}) async {
          requested.add((weight, italic));
          return null;
        },
      );

      registry.preloadFamily('Inter');
      await pumpEventQueue();

      expect(requested, CcFontRegistry.standardCuts);
    });

    test('retries after install when called before loader is ready', () async {
      final requested = <(int, bool)>[];
      registry.preloadFamily('Inter');
      await pumpEventQueue();
      expect(requested, isEmpty);

      registry.install(
        loader: ({required family, required weight, required italic}) async {
          requested.add((weight, italic));
          return null;
        },
      );
      await pumpEventQueue();

      expect(requested, CcFontRegistry.standardCuts);
    });

    test('skips families the host does not catalogue', () async {
      final requested = <String>[];
      registry
        ..install(
          loader: ({required family, required weight, required italic}) async {
            requested.add(family);
            return null;
          },
        )
        ..setCatalogue(['Inter']);

      registry.preloadFamily('Menlo');
      await pumpEventQueue();

      expect(requested, isEmpty);
    });

    test('deduplicates identical byte payloads without throwing', () async {
      final sameBytes = Uint8List.fromList([1, 2, 3, 4]);
      registry.install(
        loader: ({required family, required weight, required italic}) async =>
            sameBytes,
      );

      expect(() => registry.preloadFamily('Broken'), returnsNormally);
      await pumpEventQueue();
    });
  });
}
