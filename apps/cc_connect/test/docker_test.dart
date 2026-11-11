import 'dart:io';

import 'package:test/test.dart';

/// `name -> (version, sha256)` for every package of a pubspec.lock.
Map<String, (String, String?)> _lock(String path) {
  final packages = <String, (String, String?)>{};
  String? name;
  String? sha;
  for (final line in File(path).readAsLinesSync()) {
    final package = RegExp(r'^  ([a-z0-9_]+):$').firstMatch(line);
    if (package != null) {
      name = package.group(1);
      sha = null;
      continue;
    }
    final hash = RegExp(r'^      sha256: "?([0-9a-f]{64})"?$').firstMatch(line);
    if (hash != null) {
      sha = hash.group(1);
      continue;
    }
    final version = RegExp(r'^    version: "([^"]+)"$').firstMatch(line);
    if (version != null && name != null) {
      packages[name] = (version.group(1)!, sha);
    }
  }
  return packages;
}

void main() {
  final dockerfile = File('Dockerfile').readAsStringSync();
  final docker = _lock('docker/pubspec.lock');
  final workspace = _lock('../../pubspec.lock');

  test('the image resolves against a lockfile', () {
    expect(dockerfile, contains('COPY docker/pubspec.lock '));
    expect(dockerfile, contains('dart pub get --enforce-lockfile'));
  });

  test('the image lockfile pins what the workspace tests ran', () {
    expect(docker, contains('dart_jsonwebtoken'));
    docker.forEach((name, pin) {
      if (name == 'cc_connect_core') {
        return;
      }
      expect(pin.$2, isNotNull, reason: '$name has no content hash');
      expect(workspace[name], pin, reason: '$name differs from pubspec.lock');
    });
  });

  test('the synthesized manifests pin the lockfile versions', () {
    final pins = RegExp(
      r"'  ([a-z0-9_]+): (\d+\.\d+\.\d+)'",
    ).allMatches(dockerfile).toList();
    expect(pins, isNotEmpty);
    for (final pin in pins) {
      expect(
        docker[pin.group(1)]?.$1,
        pin.group(2),
        reason: '${pin.group(1)} in the Dockerfile',
      );
    }
  });

  test('base images are pinned by digest', () {
    final froms = RegExp(
      r'^FROM (\S+)',
      multiLine: true,
    ).allMatches(dockerfile).toList();
    expect(froms, hasLength(2));
    for (final from in froms) {
      expect(from.group(1), matches(RegExp(r'@sha256:[0-9a-f]{64}$')));
    }
  });
}
