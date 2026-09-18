import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/l10n/phone_widgets_localizations.dart';
import 'package:cc_remote/l10n/remote_locales.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({required Locale locale, required Widget child}) {
    return WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: kSupportedRemoteLocales,
      localeResolutionCallback: resolveRemoteLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        PhoneWidgetsLocalizationsDelegate(),
      ],
      pageRouteBuilder: <T>(settings, builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        );
      },
      home: child,
    );
  }

  testWidgets('Arabic locale sets RTL and serves translated strings', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        locale: const Locale('ar', 'SA'),
        child: Builder(
          builder: (context) {
            expect(Directionality.of(context), TextDirection.rtl);
            expect(Localizations.localeOf(context), const Locale('ar', 'SA'));
            expect(AppLocalizations.of(context).localeName, 'ar');
            return Text(AppLocalizations.of(context).tabInbox);
          },
        ),
      ),
    );

    expect(find.text('الوارد'), findsOneWidget);
  });

  testWidgets('Hebrew locale sets RTL and serves translated strings', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        locale: const Locale('he', 'IL'),
        child: Builder(
          builder: (context) {
            expect(Directionality.of(context), TextDirection.rtl);
            expect(Localizations.localeOf(context), const Locale('he', 'IL'));
            expect(AppLocalizations.of(context).localeName, 'he');
            return Text(AppLocalizations.of(context).tabInbox);
          },
        ),
      ),
    );

    expect(find.text('דואר נכנס'), findsOneWidget);
  });

  testWidgets('Persian locale sets RTL and serves translated strings', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        locale: const Locale('fa', 'IR'),
        child: Builder(
          builder: (context) {
            expect(Directionality.of(context), TextDirection.rtl);
            expect(Localizations.localeOf(context), const Locale('fa', 'IR'));
            return Text(AppLocalizations.of(context).tabInbox);
          },
        ),
      ),
    );

    expect(find.text('صندوق ورودی'), findsOneWidget);
  });

  testWidgets('Urdu locale sets RTL and serves translated strings', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        locale: const Locale('ur', 'PK'),
        child: Builder(
          builder: (context) {
            expect(Directionality.of(context), TextDirection.rtl);
            expect(Localizations.localeOf(context), const Locale('ur', 'PK'));
            return Text(AppLocalizations.of(context).tabInbox);
          },
        ),
      ),
    );

    expect(find.text('ان باکس'), findsOneWidget);
  });

  testWidgets('English locale stays LTR', (tester) async {
    await tester.pumpWidget(
      host(
        locale: const Locale('en', 'US'),
        child: Builder(
          builder: (context) {
            expect(Directionality.of(context), TextDirection.ltr);
            expect(Localizations.localeOf(context), const Locale('en', 'US'));
            return Text(AppLocalizations.of(context).tabInbox);
          },
        ),
      ),
    );

    expect(find.text('Inbox'), findsOneWidget);
  });

  test('region-qualified RTL languages still count as RTL', () {
    expect(
      PhoneWidgetsLocalizationsDelegate.rtlLanguageCodes,
      containsAll(['ar', 'he', 'fa', 'ur']),
    );
  });
}
