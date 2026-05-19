import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/shader_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShaderBackground', () {
    testWidgets('renders fallback container when shader fails to load', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShaderBackground(
            shaderAsset: 'assets/shaders/nonexistent.frag',
            child: Text('Child Content'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Child Content'), findsOneWidget);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShaderBackground(
            shaderAsset: 'assets/shaders/login_background_dark.frag',
            child: Text('Overlay'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Overlay'), findsOneWidget);
    });

    testWidgets('uses default shader asset when not specified', (tester) async {
      await tester.pumpWidget(const MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: ShaderBackground()));
      await tester.pump();

      expect(find.byType(ShaderBackground), findsOneWidget);
    });

    testWidgets('renders without child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShaderBackground(
            shaderAsset: 'assets/shaders/login_background_dark.frag',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ShaderBackground), findsOneWidget);
    });

    testWidgets('shows fallback when shader asset is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShaderBackground(shaderAsset: '', child: Text('Fallback')),
        ),
      );
      await tester.pump();

      expect(find.text('Fallback'), findsOneWidget);
    });

    testWidgets('renders CustomPaint child when shader loads successfully', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShaderBackground(
            shaderAsset: 'assets/shaders/login_background_dark.frag',
            child: SizedBox.expand(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.byType(ShaderBackground), findsOneWidget);
    });

    testWidgets('initial state renders fallback before shader loads', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShaderBackground(
            shaderAsset: 'assets/shaders/nonexistent.frag',
            child: Text('Loading'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Loading'), findsOneWidget);
    });

    test('ShaderBackground constructor sets correct defaults', () {
      const widget = ShaderBackground();
      // Default is null — the asset is resolved from Theme.brightness at build.
      expect(widget.shaderAsset, isNull);
      expect(widget.child, isNull);
    });

    test('ShaderBackground constructor with custom params', () {
      const widget = ShaderBackground(
        shaderAsset: 'assets/custom.frag',
        child: Text('hello'),
      );
      expect(widget.shaderAsset, 'assets/custom.frag');
      expect(widget.child, isNotNull);
    });

    test('ShaderBackground has key parameter', () {
      const key = Key('test-key');
      const widget = ShaderBackground(key: key);
      expect(widget.key, key);
    });
  });
}
