import 'package:cc_domain/features/fonts/fonts.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/system_font_service.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The downloadable font families the host can serve, sorted by display name.
///
/// Fetched at runtime rather than compiled in: `package:google_fonts` shipped a
/// manifest of every family, which measured 14 MB of the web bundle — more than
/// half of `main.dart.js`. The host caches the catalogue on disk, so this is one
/// cheap call per client.
///
/// Loading it also tells [CcFontRegistry] which families are downloadable, so it
/// does not go asking the host for an OS-installed font.
final fontCatalogProvider = FutureProvider<List<FontFamilyInfo>>((ref) async {
  final catalog = await ref.watch(fontCatalogRepositoryProvider).catalog();
  CcFontRegistry.instance.setCatalogue(catalog.map((font) => font.family));
  return catalog;
});

/// Sorted list of selectable downloadable font family names. Empty while the
/// catalogue loads and on a host that has never reached it — the picker then
/// shows bundled + system fonts, which need no network.
final googleFontsProvider = Provider<List<String>>((ref) {
  final catalog = ref.watch(fontCatalogProvider).value ?? const [];
  return [for (final font in catalog) font.family];
});

/// List of system-installed fonts as `{family, path}` maps.
final systemFontsProvider = FutureProvider<List<Map<String, String>>>((ref) {
  return SystemFontService().getInstalledFonts();
});