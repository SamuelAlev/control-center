import 'package:flutter_test/flutter_test.dart';

import '../../helpers/source_files.dart';

/// `HardwareKeyboard.clearState()` is a test-hermeticity API: besides clearing
/// pressed-key state it detaches EVERY registered key handler (the keybinding
/// dispatcher, the diff view's search keys, push-to-talk, focus-ring modality
/// tracking, Material's menu shortcuts). A single production call permanently
/// kills every shortcut in the app — each later press falls through unhandled
/// and rings the macOS system alert. This happened three times before being
/// caught; production code must use `releaseStuckKeys()`
/// (`lib/core/keybindings/stuck_keys.dart`) instead, which synthesises
/// key-ups through the public event path and leaves handlers attached.
void main() {
  test('HardwareKeyboard.clearState() is never called from production code', () {
    final offenders = <String>[];
    // `dartSourceFiles` enumerates via git, so generated/vendored/runtime
    // trees are excluded without a hand-maintained skip list — and without
    // walking them. Package test/tooling dirs may legitimately use the API,
    // hence production-only (the helper's default).
    for (final entity in dartSourceFiles()) {
      final path = entity.path;
      if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
        continue;
      }
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        // Comments may (and do) reference the API by name to explain the ban.
        if (line.startsWith('//') || line.startsWith('*')) {
          continue;
        }
        if (line.contains('.clearState(')) {
          offenders.add('$path:${i + 1}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'HardwareKeyboard.clearState() detaches every registered key handler '
          'and permanently kills all keyboard shortcuts (each press then rings '
          'the macOS system alert). Use releaseStuckKeys() from '
          'lib/core/keybindings/stuck_keys.dart instead. Offenders:\n'
          '${offenders.join('\n')}',
    );
  });
}
