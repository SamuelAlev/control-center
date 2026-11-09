import 'dart:io';

import 'package:test/test.dart';

/// cc_connect_core is the one contract shared by Connect and every server, so
/// it must stay pure Dart: the same bytes sign on a desktop server, verify on
/// Cloud Run and run embedded. Any of these imports would tie it to one host.
void main() {
  test('lib/ imports no IO, FFI, Flutter or infrastructure package', () {
    const forbidden = [
      "'dart:io'",
      "'dart:ffi'",
      "'dart:isolate'",
      "'dart:html'",
      'package:flutter',
      'package:cc_infra',
      'package:cc_persistence',
      'package:cc_server_core',
      'package:drift',
      'package:rhttp',
    ];
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      for (final line in entity.readAsLinesSync()) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) {
          continue;
        }
        for (final needle in forbidden) {
          if (trimmed.contains(needle)) {
            offenders.add('${entity.path}: $trimmed');
          }
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
