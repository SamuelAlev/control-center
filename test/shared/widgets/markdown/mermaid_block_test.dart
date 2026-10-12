import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// App-side diagram behavior: token-aware styling, source inspection and an
/// expanded viewer whose controls actually move and restore the canvas.
Widget _app(Widget child, {Brightness brightness = Brightness.light}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: brightness),
      home: CcTheme(
        data: brightness == Brightness.dark
            ? CcThemeData.dark()
            : CcThemeData.light(),
        child: Scaffold(
          body: SizedBox(
            width: 700,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    ),
  );
}

const String _flowchart = '''
```mermaid
flowchart TD
  A[Fetch PR] --> B{Has conflicts?}
  B -->|no| C[Merge]
  B -->|yes| D[Notify author]
```
''';

void main() {
  setUp(() {
    clearMermaidParseCache();
    clearMermaidSceneCache();
    CcMarkdownCache.clearCache();
  });

  group('appMermaidStyle', () {
    testWidgets('is built from design tokens and follows brightness', (
      tester,
    ) async {
      CcMermaidStyle? light;
      CcMermaidStyle? dark;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              light = appMermaidStyle(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              dark = appMermaidStyle(context);
              return const SizedBox.shrink();
            },
          ),
          brightness: Brightness.dark,
        ),
      );
      expect(light, isNotNull);
      expect(dark, isNotNull);
      expect(light!.nodeFill, isNot(dark!.nodeFill));
      expect(light!.label.color, isNot(dark!.label.color));
    });
  });

  group('diagram block', () {
    testWidgets('renders a diagram with its kind label and actions', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const StyledMarkdownBody(data: _flowchart)));
      await tester.pumpAndSettle();

      expect(find.byType(CcMermaidView), findsOneWidget);
      expect(find.text('flowchart'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('view source swaps the diagram for its mermaid text', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const StyledMarkdownBody(data: _flowchart)));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is CcIconButton &&
              widget.tooltip == l10n.diagramViewSource,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CcMermaidView), findsNothing);
      expect(find.textContaining('flowchart TD'), findsOneWidget);

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is CcIconButton &&
              widget.tooltip == l10n.diagramHideSource,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CcMermaidView), findsOneWidget);
    });

    testWidgets('expanded viewer zooms and restores the fitted diagram', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const StyledMarkdownBody(data: _flowchart)));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is CcIconButton && widget.tooltip == l10n.expand,
        ),
      );
      await tester.pumpAndSettle();

      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final controller = viewer.transformationController!;
      final fitted = controller.value.clone();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is CcIconButton && widget.tooltip == l10n.zoomIn,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        controller.value.getMaxScaleOnAxis(),
        greaterThan(fitted.getMaxScaleOnAxis()),
      );
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is CcIconButton && widget.tooltip == l10n.fitToView,
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.value, fitted);
    });

    testWidgets(
      'an unsupported dialect falls back to the code block with a reason',
      (tester) async {
        await tester.pumpWidget(
          _app(
            const StyledMarkdownBody(
              data: '```mermaid\ngantt\n  title Roadmap\n```',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CcMermaidView), findsNothing);
        // The code block keeps the source (with its language label) and the
        // caption explains why there is no picture.
        expect(find.text('mermaid'), findsOneWidget);
        expect(find.textContaining('gantt'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a very tall diagram collapses behind show more', (
      tester,
    ) async {
      final source = StringBuffer('```mermaid\nflowchart TD\n');
      for (var i = 0; i < 24; i++) {
        source.writeln('  n$i[Step $i] --> n${i + 1}[Step ${i + 1}]');
      }
      source.writeln('```');
      await tester.pumpWidget(
        _app(StyledMarkdownBody(data: source.toString())),
      );
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.showMore), findsOneWidget);
      await tester.tap(find.text(l10n.showMore));
      await tester.pumpAndSettle();
      expect(find.text(l10n.showLess), findsOneWidget);
    });
  });
}
