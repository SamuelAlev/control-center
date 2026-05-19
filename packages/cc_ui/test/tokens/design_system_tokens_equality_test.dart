import 'dart:io';

import 'package:cc_ui/cc_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// [DesignSystemTokens] carries ~117 fields and implements `==`/`hashCode`
/// over a `_props` list rather than 117 hand-written comparisons.
///
/// That is only safe if `_props` stays COMPLETE: a field left out of it makes
/// two token sets that differ in exactly that field compare EQUAL, which is
/// strictly worse than having no equality at all — `CcThemeData ==` would then
/// report "unchanged" for a real theme change and every token-dependent widget
/// would keep painting the old value.
///
/// So this re-parses the source and pins the correspondence. It is a ratchet,
/// not a unit test: adding a token makes it fail until `_props` is updated.
void main() {
  group('DesignSystemTokens equality', () {
    late String source;

    setUpAll(() {
      // Resolved relative to the package root, which is the CWD for
      // `flutter test` in this package.
      final file = File('lib/src/tokens/design_system_tokens.dart');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'expected to run from the cc_ui package root',
      );
      source = file.readAsStringSync();
    });

    test('every declared field participates in _props', () {
      // Fields are declared before `_props`; anything after it is derived.
      final classBody = source.substring(
        0,
        source.indexOf('  List<Object?> get _props'),
      );
      final declared = RegExp(
        r'^\s+final\s+[\w<>?, ]+?\s+(\w+);\s*$',
        multiLine: true,
      ).allMatches(classBody).map((m) => m.group(1)!).toSet();
      expect(
        declared,
        isNotEmpty,
        reason:
            'the field-declaration regex stopped matching — fix it, do '
            'not delete this test',
      );

      final propsBlock = source.substring(
        source.indexOf('  List<Object?> get _props'),
        source.indexOf('  /// Value equality.'),
      );
      final listed = RegExp(
        r'^\s+(\w+),\s*$',
        multiLine: true,
      ).allMatches(propsBlock).map((m) => m.group(1)!).toSet();

      expect(
        declared.difference(listed),
        isEmpty,
        reason:
            'these tokens are missing from _props, so two token sets '
            'differing only in them would compare EQUAL',
      );
    });

    test('identical values compare equal and hash equal', () {
      final a = DesignSystemTokens.light();
      final b = DesignSystemTokens.light();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('light and dark do not compare equal', () {
      expect(
        DesignSystemTokens.light(),
        isNot(equals(DesignSystemTokens.dark())),
      );
    });

    test('a single changed token breaks equality', () {
      final base = DesignSystemTokens.light();
      final changed = base.lerp(DesignSystemTokens.dark(), 0.5);
      expect(changed, isNot(equals(base)));
    });

    test('the chartCategorical list is compared by value, not identity', () {
      final a = DesignSystemTokens.light();
      // `lerp` at t=0 rebuilds every field — including a fresh list — from
      // values equal to the original, so a by-identity comparison of the list
      // would report a difference that does not exist.
      final rebuilt = a.lerp(a, 0);
      expect(rebuilt, equals(a));
      expect(rebuilt.hashCode, equals(a.hashCode));
    });
  });
}
