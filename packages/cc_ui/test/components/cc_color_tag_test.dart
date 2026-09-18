import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../cc_test_app.dart';

void main() {
  group('CcColorTag.parseHex', () {
    test('reads 6-digit hex with or without a hash', () {
      expect(CcColorTag.parseHex('d73a4a'), const Color(0xFFD73A4A));
      expect(CcColorTag.parseHex('#0366d6'), const Color(0xFF0366D6));
    });

    test('expands 3-digit hex', () {
      expect(CcColorTag.parseHex('#abc'), const Color(0xFFAABBCC));
    });

    test('returns null for empty or unparseable input', () {
      expect(CcColorTag.parseHex(''), isNull);
      expect(CcColorTag.parseHex('zz'), isNull);
      expect(CcColorTag.parseHex('12345'), isNull);
    });
  });

  group('CcColorTag.inkOn', () {
    test('picks dark ink on a light yellow fill', () {
      expect(
        CcColorTag.inkOn(const Color(0xFFFFFF00)),
        const Color(0xFF0D0D0D),
      );
    });

    test('picks white ink on a dark blue fill', () {
      expect(
        CcColorTag.inkOn(const Color(0xFF0366D6)),
        const Color(0xFFFFFFFF),
      );
    });
  });

  testWidgets('renders the label text', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcColorTag(label: 'dependencies', color: '0366d6')),
    );
    expect(find.text('dependencies'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty color still shows the name', (tester) async {
    await tester.pumpWidget(ccTestApp(const CcColorTag(label: 'needs-review')));
    expect(find.text('needs-review'), findsOneWidget);
  });
}
