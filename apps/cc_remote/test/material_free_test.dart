import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// cc_remote's first tests.
///
/// The phone client is a Flutter web PWA — the most bandwidth-sensitive tier
/// in the product — and it is Material-free by construction: a
/// `WidgetsApp.router`, `package:flutter/widgets.dart` only, every glyph from
/// cc_ui's vendored Phosphor. Nothing checked either half, and both are one
/// import away from being lost:
///
/// * `uses-material-design: true` was set with zero Material icons in the app.
///   That bundles `MaterialIcons-Regular.otf` (~1.6 MB), and Flutter web
///   downloads every `FontManifest.json` entry at engine boot — so it was a
///   cold-load tax paid for a font nothing rendered. Verified after the fix:
///   the built manifest lists Manrope, Fira Code and Phosphor, and nothing
///   else.
/// * The first `import 'package:flutter/material.dart'` would silently
///   re-introduce a Material text theme, ink splashes and a second icon font.
void main() {
  test('the app does not ask for the Material icon font', () {
    final pubspec = _appFile('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      contains('uses-material-design: false'),
      reason:
          'Setting this to true bundles MaterialIcons-Regular.otf (~1.6 MB) '
          'into a phone web build. If a Material icon is genuinely needed, '
          'flip it deliberately and update this test with the reason.',
    );
  });

  test('nothing imports Material or Cupertino', () {
    final offenders = <String>[];
    for (final file in _dartSources()) {
      final src = file.readAsStringSync();
      if (src.contains('package:flutter/material.dart') ||
          src.contains('package:flutter/cupertino.dart')) {
        offenders.add(_short(file));
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'cc_remote renders on flutter/widgets.dart + cc_ui. A Material '
          'import brings an ambient theme this app does not install and a '
          'second icon font it does not need:\n  ${offenders.join('\n  ')}',
    );
  });

  test('no Material icon is referenced', () {
    final iconsUse = RegExp(r'(?<![\w.])Icons\.\w');
    final offenders = <String>[];
    for (final file in _dartSources()) {
      if (iconsUse.hasMatch(file.readAsStringSync())) {
        offenders.add(_short(file));
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use cc_ui\'s AppIcons (vendored Phosphor). A single `Icons.*` '
          'reference is what would force uses-material-design back on:\n  '
          '${offenders.join('\n  ')}',
    );
  });

  test('icon-only controls go through the 44px touch target', () {
    // DESIGN.md's accessibility bar is ">=44px targets on phone". Every
    // icon-only control here was hand-rolled as a CcTappable wrapping an
    // 8pt-padded 18-20pt icon — a 34-36pt target, in the back button of five
    // screens. `PhoneIconButton` is the one place that number lives.
    final offenders = <String>[];
    // A CcTappable whose builder paints a bare padded Icon: the exact shape
    // that produced an under-sized target.
    // Deliberately two cheap steps rather than one clever regex: find each
    // `CcTappable(` and look at the next 400 characters for a padded bare
    // Icon. A single pattern spanning a nested widget tree is the kind that
    // silently stops matching — this one was verified to FIRE by planting the
    // old shape back in and watching it fail.
    final padded = RegExp(
      r'padding: const EdgeInsets\.all\(\d+\),\s*\n\s*child: Icon\(',
    );
    for (final file in _dartSources()) {
      if (_short(file).endsWith('widgets/touch_target.dart')) {
        continue;
      }
      final src = file.readAsStringSync();
      for (final m in RegExp('CcTappable\\(').allMatches(src)) {
        final window = src.substring(
          m.end,
          m.end + 400 > src.length ? src.length : m.end + 400,
        );
        if (padded.hasMatch(window)) {
          offenders.add(
            '${_short(file)}:${'\n'.allMatches(src.substring(0, m.start)).length + 1}',
          );
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use PhoneIconButton (lib/widgets/touch_target.dart), which keeps '
          'the icon its visual size and grows the HIT AREA to '
          '44x44:\n  ${offenders.join('\n  ')}',
    );
  });
}

Directory _appRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/lib/app_router.dart').existsSync() &&
        File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir;
    }
    final nested = Directory('${dir.path}/apps/cc_remote');
    if (nested.existsSync()) {
      return nested;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('Could not locate apps/cc_remote from ${Directory.current.path}');
    }
    dir = parent;
  }
}

File _appFile(String rel) => File('${_appRoot().path}/$rel');

Iterable<File> _dartSources() {
  final lib = Directory('${_appRoot().path}/lib');
  expect(lib.existsSync(), isTrue, reason: 'cc_remote/lib not found');
  return lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));
}

String _short(File f) {
  final parts = f.uri.pathSegments;
  final i = parts.lastIndexOf('lib');
  return i < 0 ? parts.last : parts.sublist(i).join('/');
}
