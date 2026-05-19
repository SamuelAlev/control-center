import 'package:cc_domain/features/fonts/fonts.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/settings/providers/font_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The catalogue is runtime data now (fetched by the host, read over RPC), so
/// these tests feed a fake repository rather than asserting against a
/// compiled-in family list.
class _FakeCatalog implements FontCatalogRepository {
  _FakeCatalog(this.families);

  final List<String> families;
  int calls = 0;

  @override
  Future<List<FontFamilyInfo>> catalog() async {
    calls++;
    return [
      for (final family in families)
        FontFamilyInfo(
          id: family.toLowerCase(),
          family: family,
          category: 'sans-serif',
          weights: const [400, 700],
          styles: const ['normal'],
          subsets: const ['latin'],
          defSubset: 'latin',
        ),
    ];
  }
}

ProviderContainer _containerWith(FontCatalogRepository catalog) {
  final container = ProviderContainer(
    overrides: [fontCatalogRepositoryProvider.overrideWithValue(catalog)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(CcFontRegistry.instance.resetForTests);
  tearDown(CcFontRegistry.instance.resetForTests);

  group('fontCatalogProvider', () {
    test('exposes the families the host catalogues', () async {
      final container = _containerWith(_FakeCatalog(['Inter', 'Roboto']));

      final catalog = await container.read(fontCatalogProvider.future);

      expect(catalog.map((font) => font.family), ['Inter', 'Roboto']);
    });

    test('tells the registry which families are downloadable', () async {
      // Without this the registry would fire a doomed request for every
      // OS-installed family it is asked to render.
      final container = _containerWith(_FakeCatalog(['Inter']));

      await container.read(fontCatalogProvider.future);

      expect(CcFontRegistry.instance.isCatalogued('Inter'), isTrue);
      expect(CcFontRegistry.instance.isCatalogued('Menlo'), isFalse);
    });
  });

  group('googleFontsProvider', () {
    test('is empty until the catalogue resolves', () {
      final container = _containerWith(_FakeCatalog(['Inter']));

      expect(
        container.read(googleFontsProvider),
        isEmpty,
        reason: 'the picker shows bundled + system fonts in the meantime',
      );
    });

    test('lists the catalogued families once loaded', () async {
      final container = _containerWith(_FakeCatalog(['Inter', 'Roboto']));

      await container.read(fontCatalogProvider.future);

      expect(container.read(googleFontsProvider), ['Inter', 'Roboto']);
    });
  });

  group('systemFontsProvider', () {
    test('is a FutureProvider', () {
      expect(
        systemFontsProvider,
        isA<FutureProvider<List<Map<String, String>>>>(),
      );
    });
  });
}
