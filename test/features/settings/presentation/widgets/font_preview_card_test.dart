import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/settings/presentation/widgets/font_preview_card.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

Widget _wrap(Widget child) {
  return FTheme(
    data: FThemes.zinc.light.desktop,
    child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: child)),
  );
}

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('FontPreviewCard', () {
    testWidgets('renders app font preview', (tester) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const font = FontSelection(family: 'Inter');
      await tester.pumpWidget(
        _wrap(
          const FontPreviewCard(font: font, context: FontContext.app),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('The quick brown fox'), findsOneWidget);
    });

    testWidgets('renders code font preview', (tester) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const font = FontSelection(family: 'JetBrains Mono');
      await tester.pumpWidget(
        _wrap(
          const FontPreviewCard(font: font, context: FontContext.code),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('computeLegacy'), findsOneWidget);
      expect(find.textContaining('computeModern'), findsOneWidget);
    });

    testWidgets('renders uppercase and lowercase samples in app preview', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 250);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const font = FontSelection(family: 'Roboto');
      await tester.pumpWidget(
        _wrap(
          const FontPreviewCard(font: font, context: FontContext.app),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('ABCDEFGHIJKLMNOPQRSTUVWXYZ'), findsOneWidget);
      expect(find.text('abcdefghijklmnopqrstuvwxyz'), findsOneWidget);
      expect(find.text('0123456789'), findsOneWidget);
    });

    testWidgets('renders diff lines in code preview', (tester) async {
      tester.view.physicalSize = const Size(400, 250);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const font = FontSelection(family: 'Fira Code');
      await tester.pumpWidget(
        _wrap(
          const FontPreviewCard(font: font, context: FontContext.code),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('-'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);
      expect(find.textContaining('unchanged'), findsWidgets);
    });

    testWidgets('applies custom background and border colors', (tester) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const font = FontSelection(family: 'Inter');
      await tester.pumpWidget(
        _wrap(
          const FontPreviewCard(
            font: font,
            context: FontContext.app,
            backgroundColor: Colors.blue,
            borderColor: Colors.red,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('The quick brown fox'), findsOneWidget);
    });

    testWidgets('renders with system font source', (tester) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const font = FontSelection(
        family: 'System Font',
        source: FontSource.system,
        filePath: '/tmp/nonexistent.ttf',
      );
      await tester.pumpWidget(
        _wrap(
          const FontPreviewCard(font: font, context: FontContext.app),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('The quick brown fox'), findsOneWidget);
    });

    testWidgets('handles null background and border colors', (tester) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const font = FontSelection(family: 'Inter');
      await tester.pumpWidget(
        _wrap(
          const FontPreviewCard(font: font, context: FontContext.app),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('The quick brown fox'), findsOneWidget);
    });

    testWidgets('renders with Google Font source', (tester) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const font = FontSelection(
        family: 'Roboto',
        source: FontSource.google,
      );
      await tester.pumpWidget(
        _wrap(
          const FontPreviewCard(font: font, context: FontContext.app),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('The quick brown fox'), findsOneWidget);
    });
  });

  group('FontContext enum', () {
    test('has two values', () {
      expect(FontContext.values, hasLength(2));
    });

    test('app and code are distinct', () {
      expect(FontContext.app, isNot(FontContext.code));
    });
  });
}
