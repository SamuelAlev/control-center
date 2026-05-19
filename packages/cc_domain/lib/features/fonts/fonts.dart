/// Selectable font families.
///
/// The host catalogues which families exist and resolves one variant to a file;
/// clients list them, preview them and ask the host for bytes. Pure Dart — no
/// `dart:io` / `dio` / Flutter — so the catalogue type is shared verbatim by the
/// server that fetches it and the clients that render it.
library;

export 'domain/entities/font_family_info.dart';
export 'domain/repositories/font_catalog_repository.dart';
