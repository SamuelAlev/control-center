import 'package:cc_ui/src/components/cc_toaster.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('CcToastScope.show inserts a toast into the overlay',
      (tester) async {
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

  testWidgets('CcToastScope.maybeOf returns null with no scope ancestor',
      (tester) async {
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
