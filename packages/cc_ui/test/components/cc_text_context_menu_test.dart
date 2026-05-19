import 'package:cc_ui/src/components/cc_text_area.dart';
import 'package:cc_ui/src/components/cc_text_field.dart';
import 'package:cc_ui/src/foundation/cc_native_text_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

const MethodChannel _nativeMenu = MethodChannel(
  'com.controlcenter/text_context_menu',
);

/// Right-clicks the first glyph of [finder] with a real mouse pointer — the
/// selection gesture detector only reads a secondary button off one, and the
/// framework only selects a word when the pointer is actually over one (the
/// centre of a full-width field is past the end of the text).
Future<void> _secondaryTap(WidgetTester tester, Finder finder) async {
  final rect = tester.getRect(finder);
  final gesture = await tester.startGesture(
    Offset(rect.left + 4, rect.center.dy),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await gesture.removePointer();
  // Twice: asking the host is a channel round-trip, so the drawn fallback is
  // only inserted a microtask after the gesture settles.
  await tester.pumpAndSettle();
  await tester.pumpAndSettle();
}

/// The menu is a desktop affordance; pin the platform so the framework takes
/// its macOS secondary-tap path rather than the host's.
final _desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

/// Installs the answer a runner with no bridge gives — what the real binary
/// messenger raises for an unregistered channel. It has to be explicit:
/// leaving the channel unmocked in a test never replies AT ALL, so the future
/// would hang rather than fail.
void _installHostWithoutBridge(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _nativeMenu,
    (call) async => throw MissingPluginException('no bridge on this host'),
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _nativeMenu,
      null,
    ),
  );
}

void main() {
  // Every test starts with the "this host has no bridge" latch cleared, since
  // it is process-wide and one test flipping it would decide the next.
  setUp(CcNativeTextMenu.debugReset);

  group('the host menu', () {
    /// Installs a fake native bridge that answers with [chosen].
    List<Map<Object?, Object?>> installHost(
      WidgetTester tester, {
      String? chosen,
    }) {
      final calls = <Map<Object?, Object?>>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _nativeMenu,
        (call) async {
          calls.add(call.arguments as Map<Object?, Object?>);
          return chosen;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _nativeMenu,
          null,
        ),
      );
      return calls;
    }

    testWidgets('right-click asks the OS, and draws nothing itself', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      final calls = installHost(tester);

      await tester.pumpWidget(
        ccTestApp(Center(child: CcTextField(controller: controller))),
      );
      await _secondaryTap(tester, find.byType(EditableText));

      expect(calls, hasLength(1));
      // Cut/copy are offered because macOS selects the word under the pointer.
      expect(calls.single['actions'], ['cut', 'copy', 'paste', 'selectAll']);
      expect(calls.single['x'], isA<double>());
      // No drawn menu: the OS is showing its own.
      expect(find.text('Paste'), findsNothing);
    }, variant: _desktop);

    testWidgets('choosing Paste in the OS menu pastes', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => switch (call.method) {
          'Clipboard.getData' => <String, dynamic>{'text': 'from clipboard'},
          'Clipboard.hasStrings' => <String, dynamic>{'value': true},
          _ => null,
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final controller = TextEditingController();
      addTearDown(controller.dispose);
      installHost(tester, chosen: 'paste');

      await tester.pumpWidget(
        ccTestApp(Center(child: CcTextField(controller: controller))),
      );
      await _secondaryTap(tester, find.byType(EditableText));

      expect(controller.text, 'from clipboard');
    }, variant: _desktop);

    testWidgets('dismissing the OS menu does nothing at all', (tester) async {
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      installHost(tester);

      await tester.pumpWidget(
        ccTestApp(Center(child: CcTextField(controller: controller))),
      );
      await _secondaryTap(tester, find.byType(EditableText));

      expect(controller.text, 'hello world');
      expect(find.text('Paste'), findsNothing);
    }, variant: _desktop);

    testWidgets('a host with no bridge falls back to the drawn menu', (
      tester,
    ) async {
      _installHostWithoutBridge(tester);
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ccTestApp(Center(child: CcTextField(controller: controller))),
      );
      await _secondaryTap(tester, find.byType(EditableText));

      expect(find.text('Paste'), findsOneWidget);
    }, variant: _desktop);
  });

  group('CcTextContextMenu (drawn fallback)', () {
    // Everything below is what a host WITHOUT a native bridge renders —
    // Windows, Linux, the widget catalogue's runner. Each test says so
    // explicitly, since a mock handler needs the tester to install it on.
    testWidgets('renders in the design system style, not the error fallback', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      _installHostWithoutBridge(tester);

      await tester.pumpWidget(
        ccTestApp(Center(child: CcTextField(controller: controller))),
      );
      await _secondaryTap(tester, find.byType(EditableText));

      // A selection toolbar is presented into the ROOT overlay, where the only
      // ambient DefaultTextStyle is WidgetsApp's 48px double-yellow-underline
      // error fallback. Every row must carry a real style instead.
      final style = DefaultTextStyle.of(
        tester.element(find.text('Paste')),
      ).style;
      expect(style.decoration, TextDecoration.none);
      expect(style.fontSize, lessThan(20));
    }, variant: _desktop);

    testWidgets('Paste inserts the clipboard and closes the menu', (
      tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => switch (call.method) {
          'Clipboard.getData' => <String, dynamic>{'text': 'from clipboard'},
          'Clipboard.hasStrings' => <String, dynamic>{'value': true},
          _ => null,
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final controller = TextEditingController();
      addTearDown(controller.dispose);

      _installHostWithoutBridge(tester);

      await tester.pumpWidget(
        ccTestApp(Center(child: CcTextField(controller: controller))),
      );
      await _secondaryTap(tester, find.byType(EditableText));
      expect(find.text('Paste'), findsOneWidget);

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(controller.text, 'from clipboard');
      expect(find.text('Paste'), findsNothing);
    }, variant: _desktop);

    testWidgets('a text area gets the same menu', (tester) async {
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      _installHostWithoutBridge(tester);

      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 300,
              child: CcTextArea(controller: controller),
            ),
          ),
        ),
      );
      await _secondaryTap(tester, find.byType(EditableText));

      expect(find.text('Paste'), findsOneWidget);
    }, variant: _desktop);

    testWidgets('an empty field offers only Paste', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      _installHostWithoutBridge(tester);

      await tester.pumpWidget(
        ccTestApp(Center(child: CcTextField(controller: controller))),
      );
      await _secondaryTap(tester, find.byType(EditableText));

      // Nothing to cut, copy or select — but the clipboard may still hold
      // something worth pasting, which is the whole point of the menu.
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Select all'), findsNothing);
    }, variant: _desktop);

    testWidgets('a read-only field never offers Paste or Cut', (tester) async {
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      _installHostWithoutBridge(tester);

      await tester.pumpWidget(
        ccTestApp(
          Center(child: CcTextField(controller: controller, readOnly: true)),
        ),
      );
      await _secondaryTap(tester, find.byType(EditableText));

      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsNothing);
      expect(find.text('Cut'), findsNothing);
    }, variant: _desktop);

    testWidgets('an obscured field never offers Cut or Copy', (tester) async {
      final controller = TextEditingController(text: 'hunter2');
      addTearDown(controller.dispose);
      _installHostWithoutBridge(tester);

      await tester.pumpWidget(
        ccTestApp(
          Center(child: CcTextField(controller: controller, obscureText: true)),
        ),
      );
      await _secondaryTap(tester, find.byType(EditableText));

      expect(find.text('Cut'), findsNothing);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Paste'), findsOneWidget);
    }, variant: _desktop);
  });
}
