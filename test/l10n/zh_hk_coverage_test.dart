import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _keys(String file) => {
  for (final key in (jsonDecode(File(file).readAsStringSync()) as Map).keys)
    if (key is String && !key.startsWith('@')) key,
};

void main() {
  test('Hong Kong carries every key, or it falls back to Simplified', () {
    // gen-l10n bases zh_HK on zh, so a missing key renders Simplified Chinese
    // to a Traditional reader instead of failing anywhere visible.
    expect(
      _keys('lib/l10n/app_en.arb').difference(_keys('lib/l10n/app_zh_HK.arb')),
      isEmpty,
    );
  });
}
