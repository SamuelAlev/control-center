import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps every shipped web artifact on the Wasm build path.
///
/// `flutter build web --wasm` emits SkWasm first and a CanvasKit JavaScript
/// fallback. Omitting the flag silently returns one deployment surface to a
/// CanvasKit-only bundle, so CI and every release workflow are pinned here.
void main() {
  test('all web build commands emit SkWasm with a CanvasKit fallback', () {
    final root = Directory.current.path;
    for (final path in const [
      'scripts/build_web.sh',
      '.github/workflows/ci.yml',
      '.github/workflows/deploy-webapp.yml',
      '.github/workflows/deploy-remote.yml',
      '.github/workflows/deploy-design-system.yml',
      '.github/workflows/release.yml',
    ]) {
      // `flutter build web`, or the resolved-SDK form scripts/build_web.sh uses
      // (`$FLUTTER build web`, where FLUTTER comes from resolve_flutter so a
      // local build uses the same fvm-pinned SDK CI does).
      final invocation = RegExp(r'(flutter|\$\{?FLUTTER\}?) build web');
      final commands = File('$root/$path')
          .readAsLinesSync()
          .map((line) => line.trim())
          .where((line) => !line.startsWith('#') && invocation.hasMatch(line))
          .toList();
      expect(commands, isNotEmpty, reason: '$path has no web build command');
      for (final command in commands) {
        expect(
          command,
          contains('--wasm'),
          reason: '$path would emit a CanvasKit-only bundle: $command',
        );
      }
    }
  });

  test('web iframes opt into a credentialless browsing context', () {
    final source = File(
      '${Directory.current.path}/lib/features/messaging/presentation/ide/'
      'editor/browser_webview_web.dart',
    ).readAsStringSync();
    expect(
      source,
      contains("setAttribute('credentialless', '')"),
      reason: 'COEP would otherwise block code-server and browser iframes',
    );
  });
}
