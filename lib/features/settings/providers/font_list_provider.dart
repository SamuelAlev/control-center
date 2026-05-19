import 'package:control_center/core/theme/system_font_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sorted list of available Google Font family names.
final googleFontsProvider = Provider<List<String>>((ref) {
  return GoogleFonts.asMap().keys.toList()..sort();
});

/// List of system-installed fonts as `{family, path}` maps.
final systemFontsProvider = FutureProvider<List<Map<String, String>>>((ref) {
  return SystemFontService().getInstalledFonts();
});

/// Whether a given family name is a Google Font.
bool isGoogleFont(String family) => GoogleFonts.asMap().containsKey(family);
