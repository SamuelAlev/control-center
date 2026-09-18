import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_wrap.dart';

void main() {
  testWidgets('Arabic locale resolves RTL and serves translated strings', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        locale: const Locale('ar'),
        Builder(
          builder: (context) {
            expect(Directionality.of(context), TextDirection.rtl);
            expect(AppLocalizations.of(context).localeName, 'ar');
            return Text(AppLocalizations.of(context).cancel);
          },
        ),
      ),
    );

    expect(find.text('إلغاء'), findsOneWidget);
  });

  testWidgets('Hebrew locale resolves RTL and serves translated strings', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        locale: const Locale('he'),
        Builder(
          builder: (context) {
            expect(Directionality.of(context), TextDirection.rtl);
            expect(AppLocalizations.of(context).localeName, 'he');
            return Text(AppLocalizations.of(context).cancel);
          },
        ),
      ),
    );

    expect(find.text('ביטול'), findsOneWidget);
  });

  testWidgets('region-qualified Persian resolves RTL', (tester) async {
    await tester.pumpWidget(
      testWrap(
        locale: const Locale('fa', 'IR'),
        Builder(
          builder: (context) {
            expect(Directionality.of(context), TextDirection.rtl);
            expect(Localizations.localeOf(context), const Locale('fa', 'IR'));
            return Text(AppLocalizations.of(context).cancel);
          },
        ),
      ),
    );

    expect(find.text('لغو'), findsOneWidget);
  });

  testWidgets('region-qualified Urdu resolves RTL', (tester) async {
    await tester.pumpWidget(
      testWrap(
        locale: const Locale('ur', 'PK'),
        Builder(
          builder: (context) {
            expect(Directionality.of(context), TextDirection.rtl);
            expect(Localizations.localeOf(context), const Locale('ur', 'PK'));
            return Text(AppLocalizations.of(context).cancel);
          },
        ),
      ),
    );

    expect(find.text('منسوخ'), findsOneWidget);
  });
}
