import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the icon-font bundle against the regression that cost every web cold
/// load 2.46 MB: depending on an icon package that declares more font families
/// than we use.
///
/// `phosphoricons_flutter` ships all six Phosphor styles in its pubspec and a
/// dependency's `fonts:` block cannot be opted out of. Flutter's icon
/// tree-shaker only subsets a font that has at least one const `IconData`
/// pointing at it, so the five styles nothing referenced were copied into the
/// bundle whole — and Flutter web downloads every entry in `FontManifest.json`
/// at engine boot, used or not.
///
/// The fix was to vendor the single style we render into cc_ui. These
/// assertions keep it that way: re-adding the package (or a second style)
/// would silently restore the download.
void main() {
  final root = Directory.current.path;

  test('no pubspec depends on a multi-style icon font package', () {
    final offenders = <String>[];
    for (final pubspec in _pubspecs(root)) {
      final content = pubspec.readAsStringSync();
      if (RegExp(
        r'^\s+phosphoricons_flutter\s*:',
        multiLine: true,
      ).hasMatch(content)) {
        offenders.add(pubspec.path.replaceFirst('$root/', ''));
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These pubspecs depend on phosphoricons_flutter, which declares six '
          'Phosphor font families. Five of them are never referenced, so the '
          'icon tree-shaker skips them and Flutter web downloads 2.46 MB of '
          'dead font at engine boot. Use the vendored '
          'packages/cc_ui/fonts/Phosphor-Regular.ttf via the generated icon '
          'seams (tool/gen_icon_seams.py) instead: $offenders',
    );
  });

  test('cc_ui declares exactly one Phosphor family and its file exists', () {
    final pubspec = File(
      '$root/packages/cc_ui/pubspec.yaml',
    ).readAsStringSync();
    final families = RegExp(
      r'^\s+- family:\s*(Phosphor\w*)\s*$',
      multiLine: true,
    ).allMatches(pubspec).map((m) => m.group(1)).toList();

    expect(
      families,
      ['PhosphorRegular'],
      reason:
          'cc_ui must bundle the regular style and nothing else — every extra '
          'family is a full unsubsetted font on the web boot path.',
    );
    expect(
      File('$root/packages/cc_ui/fonts/Phosphor-Regular.ttf').existsSync(),
      isTrue,
    );
  });

  test('every icon seam resolves against the cc_ui-owned font', () {
    const seams = [
      'lib/shared/icons/app_icons.dart',
      'packages/cc_ui/lib/src/components/cc_icons.dart',
      'apps/cc_remote/lib/app_icons.dart',
    ];

    for (final seam in seams) {
      final content = File('$root/$seam').readAsStringSync();
      expect(
        content,
        contains("static const String _family = 'PhosphorRegular';"),
        reason: '$seam must name the vendored family',
      );
      expect(
        content,
        contains("static const String _package = 'cc_ui';"),
        reason:
            '$seam must resolve the font from cc_ui — a stale fontPackage '
            'renders every glyph as tofu. Re-run tool/gen_icon_seams.py.',
      );
    }
  });
}

Iterable<File> _pubspecs(String root) sync* {
  for (final entity in Directory(root).listSync()) {
    if (entity is File && entity.path.endsWith('pubspec.yaml')) {
      yield entity;
    }
  }
  for (final dir in ['apps', 'packages']) {
    final parent = Directory('$root/$dir');
    if (!parent.existsSync()) {
      continue;
    }
    for (final member in parent.listSync().whereType<Directory>()) {
      final pubspec = File('${member.path}/pubspec.yaml');
      if (pubspec.existsSync()) {
        yield pubspec;
      }
    }
  }
}
