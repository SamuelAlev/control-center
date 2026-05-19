import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/markdown/file_reference_chip.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The reference is claimed at PARSE time, so the assertions here are about the
/// AST: the chip is a real node the builder registry can style and make
/// clickable, not a rewrite of the text into inline code (which is what it
/// replaced, and which could be neither).
void main() {
  final plugins = CcPluginSet(const [FileRefInlinePlugin()]);

  List<CcInlineNode> inlinesOf(String source) {
    final first = CcParser(plugins: plugins).parse(source).first;
    return first is CcParagraph ? first.children : const [];
  }

  group('FileRefInlinePlugin', () {
    test('claims a reference as its own node', () {
      final inlines = inlinesOf('look at @[file:shot.png] please');
      expect(
        inlines.whereType<CcFileRefInline>().map((n) => n.name),
        ['shot.png'],
      );
      expect(inlines.first, const CcText('look at '));
      expect(inlines.last, const CcText(' please'));
    });

    test('claims every reference on the line', () {
      expect(
        inlinesOf(
          'compare @[file:before.png] with @[file:after.png]',
        ).whereType<CcFileRefInline>().map((n) => n.name),
        ['before.png', 'after.png'],
      );
    });

    test('keeps a name with spaces and an ellipsis intact', () {
      // What the composer actually writes: an ellipsized screenshot name.
      expect(
        inlinesOf(
          '@[file:Screenshot 202… 17.55.49.png]',
        ).whereType<CcFileRefInline>().single.name,
        'Screenshot 202… 17.55.49.png',
      );
    });

    test('leaves other `@` text alone', () {
      // An agent mention, an address and a version pin all start with the
      // trigger character and none of them are references.
      for (final source in ['@engineer look', 'sam@host.com', 'node@20']) {
        expect(
          inlinesOf(source).whereType<CcFileRefInline>(),
          isEmpty,
          reason: source,
        );
      }
    });

    test('leaves an unclosed token as text', () {
      expect(inlinesOf('@[file:oops').whereType<CcFileRefInline>(), isEmpty);
    });

    test('the node type matches the builder registration key', () {
      expect(const CcFileRefInline('a.png').nodeType, kFileRefNodeType);
    });
  });

  group('rendering', () {
    Widget app(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CcTheme(
          data: CcThemeData.light(),
          child: Scaffold(body: SizedBox(width: 600, child: child)),
        ),
      ),
    );

    Widget body(BuildContext context, {required bool resolved}) => FileRefScope(
      attachments: resolved
          ? const {
              'shot.png': ComposerAttachment(
                id: 'sent:blob',
                kind: 'image',
                label: 'shot.png',
                refName: 'shot.png',
              ),
            }
          : const {},
      child: CcMarkdown(
        data: 'look at @[file:shot.png] please',
        style: appMarkdownStyle(context),
        plugins: chatMarkdownPlugins,
        options: chatMarkdownOptions,
        builders: chatMarkdownBuilders,
      ),
    );

    setUp(CcMarkdownCache.clearCache);

    testWidgets('draws the name, never the bracket syntax', (tester) async {
      await tester.pumpWidget(
        app(Builder(builder: (c) => body(c, resolved: true))),
      );
      await tester.pump();
      expect(find.text('shot.png'), findsOneWidget);
      expect(find.textContaining('@[file:'), findsNothing);
    });

    testWidgets('a resolved reference is a button', (tester) async {
      await tester.pumpWidget(
        app(Builder(builder: (c) => body(c, resolved: true))),
      );
      await tester.pump();
      expect(
        find.ancestor(
          of: find.text('shot.png'),
          matching: find.byType(GestureDetector),
        ),
        findsWidgets,
      );
    });

    testWidgets('an unresolved reference promises no click', (tester) async {
      // Somebody typed the token by hand, or the message predates the
      // metadata: plain words beat an affordance that opens nothing.
      await tester.pumpWidget(
        app(Builder(builder: (c) => body(c, resolved: false))),
      );
      await tester.pump();
      expect(find.text('shot.png'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('shot.png'),
          matching: find.byType(MouseRegion),
        ),
        findsNothing,
      );
    });
  });
}
