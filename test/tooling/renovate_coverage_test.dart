import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet over Renovate's custom managers.
///
/// Built-in managers already cover pubspec.yaml, Cargo.toml, docs/package.json,
/// GitHub Actions `uses:` pins and Docker `FROM` lines. Everything else is a
/// regex manager in renovate.json — and a manager that is missing is silent:
/// the pin just never updates. This test is the list of those pins.
void main() {
  final root = Directory.current.path;
  final renovateJson = File('$root/renovate.json').readAsStringSync();
  final renovate = jsonDecode(renovateJson) as Map<String, dynamic>;
  final managers = (renovate['customManagers'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final depNames = {
    for (final manager in managers)
      if (manager['depNameTemplate'] is String)
        manager['depNameTemplate'] as String,
  };

  test('renovate.json is valid and names every custom manager', () {
    expect(managers, isNotEmpty);
    for (final manager in managers) {
      expect(manager['customType'], 'regex', reason: '${manager['description']}');
      expect(manager['depNameTemplate'], isNotEmpty);
      expect(manager['datasourceTemplate'], isNotEmpty);
      expect(manager['matchStrings'], isNotEmpty);
      expect(manager['managerFilePatterns'], isNotEmpty);
    }
  });

  test('git-refs managers use a fully-qualified git URL', () {
    // git-refs runs `git ls-remote <packageName>`. An owner/repo slug is not a
    // repository — that is the lookup error that takes the whole Renovate run
    // down. Keep depName as the short slug (grouping, PR titles); put the URL
    // in packageNameTemplate.
    for (final manager in managers) {
      if (manager['datasourceTemplate'] != 'git-refs') {
        continue;
      }
      final url = manager['packageNameTemplate'] as String?;
      expect(
        url,
        anyOf(startsWith('https://'), startsWith('git@')),
        reason:
            '${manager['depNameTemplate']} uses git-refs but '
            'packageNameTemplate is ${url ?? "missing"}',
      );
    }
  });

  test('every native_pins.env version pin has a custom manager', () {
    // `_REF` keys are already ratcheted in native_pins_test.dart. This covers
    // the version-only pins that live in the same file.
    final pins = File('$root/scripts/lib/native_pins.env').readAsLinesSync();
    final keys = <String>{
      for (final line in pins)
        if (line.trim().isNotEmpty && !line.trimLeft().startsWith('#'))
          line.split('=').first.trim(),
    };

    expect(
      renovateJson,
      contains('SHERPA_ONNX_VERSION'),
      reason: 'SHERPA_ONNX_VERSION has no renovate.json custom manager',
    );
    expect(
      depNames,
      contains('k2-fsa/sherpa-onnx'),
      reason: 'sherpa-onnx archive pin is not a custom manager',
    );
    expect(keys, contains('SHERPA_ONNX_VERSION'));

    expect(
      renovateJson,
      contains('APPIMAGETOOL_URL'),
      reason: 'APPIMAGETOOL_URL has no renovate.json custom manager',
    );
    expect(depNames, contains('AppImage/appimagetool'));
    expect(keys, contains('APPIMAGETOOL_URL'));

    // LAME 3.100 (October 2017) is the last upstream release. A manager that
    // never fires is worse than an explicit freeze.
    expect(keys, contains('LAME_VERSION'));
    expect(
      File('$root/scripts/lib/native_pins.env').readAsStringSync(),
      contains('NOT Renovate-tracked'),
      reason: 'LAME must stay an explicit freeze, not an omitted manager',
    );
    expect(depNames, isNot(contains('lame')));
  });

  test('every non-native regex pin has a custom manager', () {
    const required = <String, String>{
      'coder/code-server':
          'packages/cc_infra/lib/src/ide/code_server_service.dart',
      'Dart-Code/Dart-Code':
          'packages/cc_infra/lib/src/ide/code_server_service.dart',
      'appium/WebDriverAgent':
          'packages/cc_infra/lib/src/rigs/ios_automation_store.dart',
      'phosphor-icons/core': 'packages/cc_ui/fonts/Phosphor-LICENSE.txt',
      'sharanda/manrope': 'packages/cc_ui/fonts/Manrope-LICENSE.txt',
      'tonsky/FiraCode': 'packages/cc_ui/fonts/FiraCode-LICENSE.txt',
      'cadsondemak/Sarabun':
          'packages/cc_ui/fonts/scripts/Sarabun-LICENSE.txt',
      'googlefonts/rubik': 'packages/cc_ui/fonts/scripts/Rubik-LICENSE.txt',
      'flutter_pty': 'packages/cc_natives/native/pty/PROVENANCE.md',
      'flutter/flutter': '.fvmrc',
      'ubuntu':
          'packages/cc_infra/lib/src/rigs/smolvm_enclosure_backend.dart',
      'debian':
          'packages/cc_infra/lib/src/rigs/smolvm_enclosure_backend.dart',
      'dart': 'apps/cc_signaling_server/Dockerfile',
    };

    for (final MapEntry(:key, :value) in required.entries) {
      expect(
        depNames,
        contains(key),
        reason: '$key ($value) has no renovate.json custom manager',
      );
      expect(
        File('$root/$value').existsSync(),
        isTrue,
        reason: '$value (pin file for $key) is missing',
      );
    }
  });

  test('regex managers point at files that exist and match their pins', () {
    for (final manager in managers) {
      final description = manager['description'] as String;
      final depName = manager['depNameTemplate'] as String;
      final patterns = (manager['managerFilePatterns'] as List<dynamic>)
          .cast<String>();
      for (final pattern in patterns) {
        final path = _fileFromManagerPattern(pattern);
        expect(
          File('$root/$path').existsSync(),
          isTrue,
          reason:
              '$depName ($description) targets $path, which does not exist',
        );
      }
    }
  });

  test('code-server and WebDriverAgent pins still match the managers', () {
    final codeServer = File(
      '$root/packages/cc_infra/lib/src/ide/code_server_service.dart',
    ).readAsStringSync();
    expect(
      codeServer,
      contains("const String codeServerVersion = '"),
    );
    expect(
      codeServer,
      contains("publisher: 'Dart-Code', name: 'dart-code', version: '"),
    );

    final wda = File(
      '$root/packages/cc_infra/lib/src/rigs/ios_automation_store.dart',
    ).readAsStringSync();
    expect(wda, contains("kIosAutomationVersion = '"));
    // URLs must interpolate the const — a hardcoded tag next to it is how a
    // Renovate bump would download a different zip than the one checksummed.
    expect(wda, contains(r'$kIosAutomationVersion'));
    expect(
      wda.contains("releases/download/v"),
      isFalse,
      reason:
          'WebDriverAgent URLs hardcode a tag instead of interpolating '
          'kIosAutomationVersion',
    );
  });

  test('IBM Plex Sans Arabic stays an explicit untracked pin', () {
    // The Arabic font's name-table version (1.101) is not the IBM/plex GitHub
    // tag (v6.x). A github-releases manager would propose a false major bump.
    expect(depNames, isNot(contains('IBM/plex')));
    expect(
      File(
        '$root/packages/cc_ui/fonts/scripts/IBMPlexSansArabic-LICENSE.txt',
      ).readAsStringSync(),
      contains('1.101'),
    );
  });
}

/// Turns a renovate `managerFilePatterns` regex into a repo-relative path.
///
/// Patterns here are anchored filenames (`/path/to/file\\.ext$/`), not globs.
String _fileFromManagerPattern(String pattern) {
  var path = pattern;
  if (path.startsWith('/') && path.endsWith(r'$/')) {
    path = path.substring(1, path.length - 2);
  }
  return path.replaceAll(r'\.', '.');
}
