import 'package:cc_domain/features/focus_mode/domain/focus_mode_state.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/focus_mode/presentation/widgets/focus_config_dialog.dart';
import 'package:control_center/features/focus_mode/presentation/widgets/focus_sidebar_entry.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

class _Focus extends FocusModeNotifier {
  _Focus(this._initial);

  final FocusModeState _initial;
  bool ended = false;
  bool floated = false;

  @override
  FocusModeState build() => _initial;

  @override
  Future<void> deactivate() async => ended = true;

  @override
  Future<void> enterCompactMode() async => floated = true;
}

Widget _wrap(_Focus notifier) => ProviderScope(
  overrides: [focusModeProvider.overrideWith(() => notifier)],
  child: testWrap(
    const Align(
      alignment: Alignment.bottomLeft,
      child: CcSidebarScope(
        collapsed: true,
        child: SizedBox.square(dimension: 32, child: FocusSidebarEntry()),
      ),
    ),
  ),
);

FocusModeState _active() => FocusModeState(
  active: true,
  sessionDurationMinutes: 25,
  sessionStartedAt: DateTime.now(),
);

void main() {
  testWidgets('idle, it starts a session', (tester) async {
    await tester.pumpWidget(_wrap(_Focus(const FocusModeState(active: false))));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.focus));
    await tester.pumpAndSettle();

    expect(find.byType(FocusConfigDialog), findsOneWidget);
  });

  testWidgets('during a session it shows the time left and its actions', (
    tester,
  ) async {
    final notifier = _Focus(_active());
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();

    expect(find.byIcon(AppIcons.focus), findsNothing);
    final countdown = find.textContaining(RegExp(r'^\d+m$'));
    expect(countdown, findsOneWidget);

    await tester.tap(countdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('End focus session'));
    await tester.pumpAndSettle();

    expect(notifier.ended, isTrue);
  });
}
