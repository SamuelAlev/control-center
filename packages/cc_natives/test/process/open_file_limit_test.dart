import 'dart:io';

import 'package:cc_natives/cc_natives.dart' show raiseOpenFileLimit;
import 'package:test/test.dart';

void main() {
  test('raises the soft limit once and is a no-op after', () async {
    final first = raiseOpenFileLimit();
    if (Platform.isWindows) {
      expect(first, isNull);
      return;
    }
    expect(first, isNotNull);
    expect(first!.after, greaterThanOrEqualTo(first.before));
    // At least the macOS default, whatever the hard limit allows.
    expect(first.after, greaterThanOrEqualTo(256));

    final second = raiseOpenFileLimit()!;
    expect(second.before, first.after);
    expect(second.after, first.after);

    // A child inherits the raised limit.
    final child = await Process.run('/bin/sh', ['-c', 'ulimit -n']);
    final reported = (child.stdout as String).trim();
    expect(
      reported == 'unlimited' || int.parse(reported) >= first.after,
      isTrue,
      reason: 'child reported $reported',
    );
  });
}
