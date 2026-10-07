import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:control_center/shared/widgets/window_caption_buttons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_wrap.dart';

final _l10n = AppLocalizationsEn();

class _FakeWindow extends ChangeNotifier implements WindowCaptionActions {
  final List<String> calls = [];

  @override
  bool isMaximized = false;

  @override
  bool isActive = true;

  @override
  void minimize() => calls.add('minimize');

  @override
  void toggleMaximize() {
    calls.add('toggleMaximize');
    isMaximized = !isMaximized;
    notifyListeners();
  }

  @override
  void close() => calls.add('close');
}

Finder get _buttons => find.descendant(
  of: find.byType(WindowCaptionButtons),
  matching: find.byType(CcTappable),
);

void main() {
  testWidgets('renders nothing where the window keeps native controls', (
    tester,
  ) async {
    await tester.pumpWidget(testWrap(const WindowCaptionButtons()));

    expect(_buttons, findsNothing);
  });

  testWidgets('drives the window and tracks its maximized state', (
    tester,
  ) async {
    final window = _FakeWindow();
    await tester.pumpWidget(
      testWrap(
        WindowCaptionScope(
          actions: window,
          child: const Align(
            alignment: AlignmentDirectional.topEnd,
            child: WindowCaptionButtons(),
          ),
        ),
      ),
    );

    expect(_buttons, findsNWidgets(3));
    expect(find.bySemanticsLabel(_l10n.windowMaximize), findsOneWidget);

    await tester.tap(_buttons.at(0));
    await tester.tap(_buttons.at(1));
    await tester.pump();
    // The window is maximized now: the middle button offers to restore it.
    expect(find.bySemanticsLabel(_l10n.windowRestore), findsOneWidget);
    expect(find.bySemanticsLabel(_l10n.windowMaximize), findsNothing);

    await tester.tap(_buttons.at(2));
    expect(window.calls, ['minimize', 'toggleMaximize', 'close']);
  });

  group('room for the caption', () {
    Future<Rect> pumpCorner(
      WidgetTester tester, {
      required bool withCaption,
      TextDirection? textDirection,
    }) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      const corner = SizedBox(key: Key('corner'), width: 40, height: 40);
      const stack = Stack(
        children: [
          Positioned.fill(child: SizedBox()),
          WindowCaptionCorner(child: corner),
        ],
      );
      await tester.pumpWidget(
        testWrap(
          withCaption
              ? WindowCaptionScope(actions: _FakeWindow(), child: stack)
              : stack,
          textDirection: textDirection,
        ),
      );
      return tester.getRect(find.byKey(const Key('corner')));
    }

    testWidgets('reserves nothing without app-drawn controls', (tester) async {
      final rect = await pumpCorner(tester, withCaption: false);

      expect(rect.topRight, const Offset(800 - 16, 16));
    });

    testWidgets('stays clear of the macOS traffic lights under RTL', (
      tester,
    ) async {
      final rect = await pumpCorner(
        tester,
        withCaption: false,
        textDirection: TextDirection.rtl,
      );

      expect(rect.topRight, const Offset(800 - 16, 16));
    });

    testWidgets('sits level with and just inside the caption buttons', (
      tester,
    ) async {
      final rect = await pumpCorner(tester, withCaption: true);
      const reserved = 3 * 46.0;

      expect(rect.right, 800 - reserved);
      expect(rect.center.dy, kWindowCaptionHeight / 2);
    });

    testWidgets('mirrors under RTL, where the caption leads the window', (
      tester,
    ) async {
      final rect = await pumpCorner(
        tester,
        withCaption: true,
        textDirection: TextDirection.rtl,
      );

      expect(rect.left, 3 * 46.0);
      expect(rect.center.dy, kWindowCaptionHeight / 2);
    });
  });
}
