import 'package:control_center/shared/editor/editor_live_close.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

/// The prompt shown when closing a tab whose machine, shell or agent is still
/// working. Two of its three answers are irreversible, so what it does with an
/// ambiguous gesture is the part worth pinning.
void main() {
  Future<LiveTabCloseChoice?> open(WidgetTester tester) async {
    LiveTabCloseChoice? choice;
    await tester.pumpWidget(
      testWrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              choice = await confirmCloseLiveTab(
                context: context,
                title: 'Close WebKit 2?',
                body: 'The machine keeps running in the background.',
                shutDownLabel: 'Shut down',
              );
            },
            child: const Text('close'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    return choice;
  }

  testWidgets('offers keep, shut down and cancel', (tester) async {
    await open(tester);
    expect(find.text('Close WebKit 2?'), findsOneWidget);
    expect(find.text('Keep running'), findsOneWidget);
    // The destructive action is named in the tab's own words: "Shut down", "End
    // shell" and "Stop agent" are three different consequences.
    expect(find.text('Shut down'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('keep running is the answer', (tester) async {
    await open(tester);
    await tester.tap(find.text('Keep running'));
    await tester.pumpAndSettle();
    expect(find.text('Close WebKit 2?'), findsNothing);
  });

  testWidgets('a dismissal is cancel, never a shutdown', (tester) async {
    // Escape and the scrim mean "I did not answer". Closing a tab is undoable;
    // ending a VM or an agent run is not, so an ambiguous gesture must resolve
    // to the answer that changes nothing.
    LiveTabCloseChoice? choice;
    await tester.pumpWidget(
      testWrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              choice = await confirmCloseLiveTab(
                context: context,
                title: 'Close Terminal?',
                body: 'The command keeps running.',
                shutDownLabel: 'End shell',
              );
            },
            child: const Text('close'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(choice, LiveTabCloseChoice.cancel);
  });
}
