import 'package:cc_domain/core/domain/value_objects/money.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fmtMicros', () {
    test('formats micro-dollars in US English', () {
      expect(fmtMicros(0, locale: 'en_US'), r'$0.00');
      expect(fmtMicros(4200000, locale: 'en_US'), r'$4.20');
      expect(fmtMicros(4000, locale: 'en_US'), r'$0.004');
      expect(
        fmtMicros(centsToMicros(5), decimals: 2, locale: 'en_US'),
        r'$0.05',
      );
    });

    test('formats micro-dollars in German', () {
      expect(fmtMicros(4200000, locale: 'de'), '4,20 \$');
      expect(fmtMicros(4000, locale: 'de'), '0,004 \$');
    });

    test('a positive amount below the last digit is not shown as zero', () {
      expect(fmtMicros(400, locale: 'en_US'), r'<$0.001');
      expect(fmtMicros(4000, decimals: 2, locale: 'en_US'), r'<$0.01');
    });
  });
}
