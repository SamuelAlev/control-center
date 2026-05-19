import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/reader_address_field.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  // A focusable strip above the field so tests can blur the address input
  // by tapping outside it.
  final outsideNode = FocusNode();
  return CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Column(
          children: [
            GestureDetector(
              key: const ValueKey('blur_strip'),
              behavior: HitTestBehavior.opaque,
              onTap: outsideNode.requestFocus,
              child: Focus(
                focusNode: outsideNode,
                child: const SizedBox(width: 200, height: 24),
              ),
            ),
            SizedBox(width: 400, child: child),
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('parseReaderAddress', () {
    test('defaults the https scheme when missing', () {
      expect(
        parseReaderAddress('example.com'),
        Uri.parse('https://example.com'),
      );
      expect(
        parseReaderAddress('example.com/article?utm_source=x'),
        Uri.parse('https://example.com/article?utm_source=x'),
      );
    });

    test('host:port is not mistaken for a scheme', () {
      expect(
        parseReaderAddress('example.com:8080/path'),
        Uri.parse('https://example.com:8080/path'),
      );
    });

    test('keeps an explicit scheme', () {
      expect(
        parseReaderAddress('http://insecure.example/page'),
        Uri.parse('http://insecure.example/page'),
      );
    });

    test('accepts localhost', () {
      expect(
        parseReaderAddress('localhost:5173'),
        Uri.parse('https://localhost:5173'),
      );
    });

    test('rejects input without a host-shaped destination', () {
      expect(parseReaderAddress(''), isNull);
      expect(parseReaderAddress('   '), isNull);
      expect(parseReaderAddress('hello'), isNull);
      expect(parseReaderAddress('not a url'), isNull);
      expect(parseReaderAddress('https://'), isNull);
    });
  });

  group('ReaderAddressField', () {
    testWidgets('shows the current URL', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReaderAddressField(
            url: 'https://example.com/article',
            onNavigate: (_) {},
          ),
        ),
      );

      expect(find.text('https://example.com/article'), findsOneWidget);
    });

    testWidgets('focusing selects the whole address', (tester) async {
      const url = 'https://example.com/article';
      await tester.pumpWidget(
        _wrap(ReaderAddressField(url: url, onNavigate: (_) {})),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pump();

      final state = tester.state<EditableTextState>(find.byType(EditableText));
      final selection = state.textEditingValue.selection;
      expect(selection.baseOffset, 0);
      expect(selection.extentOffset, url.length);
    });

    testWidgets('Enter navigates to the submitted address', (tester) async {
      final navigated = <Uri>[];
      await tester.pumpWidget(
        _wrap(
          ReaderAddressField(
            url: 'https://example.com/article',
            onNavigate: navigated.add,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText), 'other.example.org/x');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();

      expect(navigated, [Uri.parse('https://other.example.org/x')]);
      // The field normalizes to the navigated URL and drops focus.
      expect(find.text('https://other.example.org/x'), findsOneWidget);
      expect(
        tester
            .state<EditableTextState>(find.byType(EditableText))
            .widget
            .focusNode
            .hasFocus,
        isFalse,
      );
    });

    testWidgets('invalid input does not navigate', (tester) async {
      final navigated = <Uri>[];
      await tester.pumpWidget(
        _wrap(
          ReaderAddressField(
            url: 'https://example.com/article',
            onNavigate: navigated.add,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText), 'not a url');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();

      expect(navigated, isEmpty);
    });

    testWidgets('Escape restores the live URL and drops focus', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ReaderAddressField(
            url: 'https://example.com/article',
            onNavigate: (_) {},
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText), 'https://other.com');
      expect(find.text('https://other.com'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('https://example.com/article'), findsOneWidget);
      expect(
        tester
            .state<EditableTextState>(find.byType(EditableText))
            .widget
            .focusNode
            .hasFocus,
        isFalse,
      );
    });

    testWidgets('blurring an unsubmitted edit restores the live URL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ReaderAddressField(
            url: 'https://example.com/article',
            onNavigate: (_) {},
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText), 'https://other.com');
      // Tap the focusable strip above the field to move focus away.
      await tester.tap(find.byKey(const ValueKey('blur_strip')));
      await tester.pump();

      expect(find.text('https://example.com/article'), findsOneWidget);
    });

    testWidgets('follows external URL changes while not editing', (
      tester,
    ) async {
      late StateSetter setStateOuter;
      var url = 'https://example.com/a';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setStateOuter = setState;
            return _wrap(ReaderAddressField(url: url, onNavigate: (_) {}));
          },
        ),
      );
      expect(find.text('https://example.com/a'), findsOneWidget);

      // Navigation from inside the page moves the field along.
      setStateOuter(() => url = 'https://example.com/b');
      await tester.pump();
      expect(find.text('https://example.com/b'), findsOneWidget);

      // While the user is editing, an external change must not clobber the
      // text they are typing.
      await tester.enterText(find.byType(EditableText), 'https://edit.me');
      setStateOuter(() => url = 'https://example.com/c');
      await tester.pump();
      expect(find.text('https://edit.me'), findsOneWidget);
    });

    testWidgets('copy button copies the address and flashes a check', (
      tester,
    ) async {
      final clipboardCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboardCalls.add(call);
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(
        _wrap(
          ReaderAddressField(
            url: 'https://example.com/article',
            onNavigate: (_) {},
          ),
        ),
      );

      await tester.tap(find.byIcon(AppIcons.copy));
      await tester.pump();

      expect(find.byIcon(AppIcons.check), findsOneWidget);
      expect(clipboardCalls, hasLength(1));
      expect(
        (clipboardCalls.single.arguments as Map<String, dynamic>)['text'],
        'https://example.com/article',
      );
    });
  });
}
