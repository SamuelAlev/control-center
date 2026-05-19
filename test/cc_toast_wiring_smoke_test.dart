import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies that the production wiring — a [CcToastScope] installed in
/// `MaterialApp.builder` (above the router/navigator overlay) — can actually
/// surface a toast. The app has never called `.show()` before, so this proves
/// the overlay resolves before we migrate every SnackBar onto it.
void main() {
  testWidgets('CcToastScope.show resolves an overlay from MaterialApp.builder',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => CcToastScope(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        home: Builder(
          builder: (context) => Center(
            child: GestureDetector(
              onTap: () => CcToastScope.of(context).show(
                'hello toast',
                variant: CcToastVariant.success,
              ),
              child: const Text('trigger'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await tester.pump(); // insert overlay entry
    await tester.pump(const Duration(milliseconds: 50)); // play-in frame

    expect(tester.takeException(), isNull);
    expect(find.text('hello toast'), findsOneWidget);
  });
}
