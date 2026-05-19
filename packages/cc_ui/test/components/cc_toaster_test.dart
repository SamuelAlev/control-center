import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('CcToastScope.show inserts a toast into the overlay', (
    tester,
  ) async {
    late CcToastHandle toaster;

    await tester.pumpWidget(
      ccTestApp(
        CcToastScope(
          child: Builder(
            builder: (context) {
              toaster = CcToastScope.of(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    toaster.show('Workspace created', variant: CcToastVariant.success);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Workspace created'), findsOneWidget);
  });

  testWidgets('CcToast auto-dismisses after its duration', (tester) async {
    late CcToastHandle toaster;

    await tester.pumpWidget(
      ccTestApp(
        CcToastScope(
          duration: const Duration(milliseconds: 500),
          child: Builder(
            builder: (context) {
              toaster = CcToastScope.of(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    toaster.show('Saved');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Saved'), findsOneWidget);

    // Past the lifetime + exit animation.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('CcToast renders an optional semibold title above the message', (
    tester,
  ) async {
    late CcToastHandle toaster;

    await tester.pumpWidget(
      ccTestApp(
        CcToastScope(
          child: Builder(
            builder: (context) {
              toaster = CcToastScope.of(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    toaster.show(
      'The build step exited with code 1',
      title: 'Pipeline failed',
      variant: CcToastVariant.danger,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Pipeline failed'), findsOneWidget);
    expect(find.text('The build step exited with code 1'), findsOneWidget);

    final title = tester.widget<Text>(find.text('Pipeline failed'));
    expect(title.style?.fontWeight, FontWeight.w600);
  });

  testWidgets('CcToast dismisses via its close control', (tester) async {
    late CcToastHandle toaster;

    await tester.pumpWidget(
      ccTestApp(
        CcToastScope(
          duration: const Duration(minutes: 1),
          child: Builder(
            builder: (context) {
              toaster = CcToastScope.of(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    toaster.show('Copied timestamp');
    // Mount, first ticker tick, then past the 180ms entry animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Copied timestamp'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Dismiss'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Copied timestamp'), findsNothing);
  });

  testWidgets('concurrent toasts stack instead of overlapping', (tester) async {
    late CcToastHandle toaster;

    await tester.pumpWidget(
      ccTestApp(
        CcToastScope(
          duration: const Duration(minutes: 1),
          child: Builder(
            builder: (context) {
              toaster = CcToastScope.of(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    toaster.show('First toast');
    toaster.show('Second toast');
    // Mount, first ticker tick, then past the 180ms entry animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('First toast'), findsOneWidget);
    expect(find.text('Second toast'), findsOneWidget);

    // Bottom-anchored: the newest toast sits nearest the edge (below).
    final first = tester.getTopLeft(find.text('First toast'));
    final second = tester.getTopLeft(find.text('Second toast'));
    expect(second.dy, greaterThan(first.dy));
  });

  testWidgets('hover pauses the auto-dismiss countdown', (tester) async {
    late CcToastHandle toaster;

    await tester.pumpWidget(
      ccTestApp(
        CcToastScope(
          duration: const Duration(milliseconds: 500),
          child: Builder(
            builder: (context) {
              toaster = CcToastScope.of(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    toaster.show('Reading this');
    // Mount, first ticker tick, then past the 180ms entry animation —
    // keeping total elapsed time under the 500ms dwell.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 200));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(
      location: tester.getCenter(find.text('Reading this')),
    );
    addTearDown(gesture.removePointer);
    await tester.pump();

    // Well past the dwell time — still visible while hovered.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Reading this'), findsOneWidget);

    // Leaving re-arms a full dwell, after which it dismisses.
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Reading this'), findsNothing);
  });

  testWidgets('toast text overrides an ambient fallback text style '
      '(root-overlay underline regression)', (tester) async {
    late CcToastHandle toaster;

    // Simulate the root overlay: the only ambient DefaultTextStyle is a loud
    // fallback (like WidgetsApp's 48px red double-yellow-underline style).
    await tester.pumpWidget(
      CcTheme(
        data: CcThemeData.light(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontSize: 48,
                color: Color(0xFFFF0000),
                decoration: TextDecoration.underline,
              ),
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (_) => CcToastScope(
                      child: Builder(
                        builder: (context) {
                          toaster = CcToastScope.of(context);
                          return const SizedBox.expand();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    toaster.show('Copied timestamp');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == 'Copied timestamp',
      ),
    );
    expect(richText.text.style?.decoration, TextDecoration.none);
    expect(richText.text.style?.fontSize, 13);
  });

  testWidgets('CcToastScope.maybeOf returns null with no scope ancestor', (
    tester,
  ) async {
    CcToastHandle? handle;

    await tester.pumpWidget(
      ccTestApp(
        Builder(
          builder: (context) {
            handle = CcToastScope.maybeOf(context);
            return const SizedBox.expand();
          },
        ),
      ),
    );

    expect(handle, isNull);
  });
}
