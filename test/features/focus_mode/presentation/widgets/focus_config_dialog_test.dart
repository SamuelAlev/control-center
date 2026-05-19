import 'package:cc_domain/features/focus_mode/domain/focus_mode_state.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/focus_mode/presentation/widgets/focus_config_dialog.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

/// A [FocusModeNotifier] that never actually opens a window.
class _TestFocusModeNotifier extends FocusModeNotifier {
  @override
  Future<void> activateAndFloat({
    int durationMinutes = 50,
    String? goal,
    bool blockNotifications = false,
  }) async {
    // No-op: do not try to open a real window.
  }

  @override
  FocusModeState build() => const FocusModeState(active: false);

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> exitCompactMode() async {}
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      focusModeProvider.overrideWith(_TestFocusModeNotifier.new),
    ],
    child: testWrap(child),
  );
}

void main() {
  group('FocusConfigDialog', () {
    testWidgets('renders and shows title', (tester) async {
      await tester.pumpWidget(_wrap(const FocusConfigDialog()));
      await tester.pumpAndSettle();

      // The dialog frame should be mounted.
      expect(find.byType(FocusConfigDialog), findsOneWidget);
      // The title text should be visible.
      expect(find.text('Start focus session'), findsOneWidget);
    });

    testWidgets('renders duration chip values', (tester) async {
      await tester.pumpWidget(_wrap(const FocusConfigDialog()));
      await tester.pumpAndSettle();

      // Duration chips use _durationLabel: 25m, 50m, 1h, 1h 30m, 2h
      expect(find.text('25m'), findsOneWidget);
      expect(find.text('50m'), findsOneWidget);
    });

    testWidgets('renders block notifications toggle', (tester) async {
      await tester.pumpWidget(_wrap(const FocusConfigDialog()));
      await tester.pumpAndSettle();

      expect(find.text('Block notifications'), findsOneWidget);
    });

    testWidgets('renders start button', (tester) async {
      await tester.pumpWidget(_wrap(const FocusConfigDialog()));
      await tester.pumpAndSettle();

      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('has text input field for goal', (tester) async {
      await tester.pumpWidget(_wrap(const FocusConfigDialog()));
      await tester.pumpAndSettle();

      // The CcTextField is present for entering the focus goal.
      expect(find.byType(CcTextField), findsOneWidget);
    });

    testWidgets('can type into goal field', (tester) async {
      await tester.pumpWidget(_wrap(const FocusConfigDialog()));
      await tester.pumpAndSettle();

      final textField = find.byType(CcTextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Ship the feature');
      await tester.pumpAndSettle();

      expect(find.text('Ship the feature'), findsOneWidget);
    });
  });
}
