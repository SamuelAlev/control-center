import 'package:cc_domain/features/fonts/domain/entities/font_family_info.dart';

/// Reads the catalogue of selectable font families.
///
/// Host-side this is answered from an upstream catalogue behind a disk cache;
/// client-side it is answered over RPC. Either way it never returns an error for
/// "offline": a catalogue that cannot be reached is an empty list and the
/// picker still offers the bundled and system fonts.
abstract class FontCatalogRepository {
  /// Every selectable family, sorted by display name.
  Future<List<FontFamilyInfo>> catalog();
}
