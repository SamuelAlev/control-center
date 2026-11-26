import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/focusable_bubble.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Its own file: FocusModality's key handler only survives the first test that
// arms it, and the rail's focus reveal is sampled from it.

const Key _after = Key('after-bubble');

void main() {
  testWidgets('Tab onto a message reveals its rail and walks into it', (
    tester,
  ) async {
    var edited = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CcTheme(
              data: CcThemeData.light(),
              child: Column(
                children: [
                  SizedBox(
                    width: 300,
                    child: FocusableBubble(
                      onEdit: () => edited = true,
                      child: const SizedBox(width: 200, height: 40),
                    ),
                  ),
                  // Somewhere for Tab to go once it leaves the message.
                  const Focus(key: _after, child: SizedBox(height: 10)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // Never revealed: nothing to Tab into yet.
    expect(find.byIcon(AppIcons.pencil), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    double railOpacity() => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.byIcon(AppIcons.pencil),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;
    bool focusOnPencil() {
      final focused = FocusManager.instance.primaryFocus?.context;
      return focused != null &&
          find
              .descendant(
                of: find.byElementPredicate((e) => e == focused),
                matching: find.byIcon(AppIcons.pencil),
              )
              .evaluate()
              .isNotEmpty;
    }

    // Focus on the message shows the rail…
    expect(find.byIcon(AppIcons.pencil), findsOneWidget);
    expect(railOpacity(), 1);

    // …the next Tab lands on its first action, and the rail stays up.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focusOnPencil(), isTrue);
    expect(railOpacity(), 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(edited, isTrue);

    // Leaving the message hides it again.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.context?.widget,
      isA<Focus>().having((f) => f.key, 'key', _after),
    );
    expect(railOpacity(), 0);
  });
}
