import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('regular and medium weights compensate only on web', () {
    expect(
      CcTypography.regularWeight,
      kIsWeb ? FontWeight.w500 : FontWeight.w400,
    );
    expect(
      CcTypography.mediumWeight,
      kIsWeb ? FontWeight.w600 : FontWeight.w500,
    );
    expect(CcTypography.semiboldWeight, FontWeight.w600);
  });

  test('semantic type styles use the centralized weight seams', () {
    for (final style in [
      CcTypography.body,
      CcTypography.bodySm,
      CcTypography.caption,
      CcTypography.monoNum,
    ]) {
      expect(style.fontWeight, CcTypography.regularWeight);
    }

    for (final style in [
      CcTypography.displayHero,
      CcTypography.display,
      CcTypography.title,
      CcTypography.label,
    ]) {
      expect(style.fontWeight, CcTypography.semiboldWeight);
    }
  });
}
