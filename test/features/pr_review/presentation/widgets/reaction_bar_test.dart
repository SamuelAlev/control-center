import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/reaction_bar.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: CcTheme(
    data: CcThemeData.light(),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('renders the reacted chip count and the add-reaction pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ReactionBar(
          reactions: const [
            ReactionGroup(
              content: '+1',
              emoji: '👍',
              count: 2,
              userReacted: true,
              usernames: ['kenny'],
            ),
          ],
          onToggle: (content, {required add}) async {},
        ),
      ),
    );

    expect(find.text('👍'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(AppIcons.smile), findsOneWidget);
    expect(find.text('React'), findsNothing);

    final chipTip = tester.widget<CcTooltip>(
      find.ancestor(of: find.text('👍'), matching: find.byType(CcTooltip)),
    );
    expect(chipTip.message, 'Thumbs up · kenny');
    final addTip = tester.widget<CcTooltip>(
      find.ancestor(
        of: find.byIcon(AppIcons.smile),
        matching: find.byType(CcTooltip),
      ),
    );
    expect(addTip.message, 'Add reaction');
  });

  testWidgets('tapping a reacted chip toggles it off and drops the count', (
    tester,
  ) async {
    final toggles = <({String content, bool add})>[];
    await tester.pumpWidget(
      _host(
        ReactionBar(
          reactions: const [
            ReactionGroup(
              content: '+1',
              emoji: '👍',
              count: 2,
              userReacted: true,
            ),
          ],
          onToggle: (content, {required add}) async {
            toggles.add((content: content, add: add));
          },
        ),
      ),
    );

    await tester.tap(find.text('2'));
    await tester.pump();

    expect(toggles, [(content: '+1', add: false)]);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
  });

  AnimatedContainer pillContainer(WidgetTester tester) =>
      tester.widget<AnimatedContainer>(
        find.ancestor(
          of: find.byIcon(AppIcons.smile),
          matching: find.byType(AnimatedContainer),
        ),
      );

  BoxDecoration pillDecoration(WidgetTester tester) =>
      pillContainer(tester).decoration! as BoxDecoration;

  testWidgets('the add-reaction pill paints a hover wash and strong border', (
    tester,
  ) async {
    final tokens = DesignSystemTokens.light();
    await tester.pumpWidget(
      _host(
        ReactionBar(
          reactions: const [],
          onToggle: (c, {required add}) async {},
        ),
      ),
    );

    final rest = pillDecoration(tester);
    expect(
      tester.getSize(find.byWidget(pillContainer(tester))).width,
      lessThan(48),
    );
    expect(rest.color, const Color(0x00000000));
    expect(
      rest.border!.top.color,
      tokens.borderSecondary.withValues(alpha: 0.5),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byIcon(AppIcons.smile)));
    await tester.pump();

    final hovered = pillDecoration(tester);
    expect(hovered.color, tokens.hover);
    expect(hovered.border!.top.color, tokens.lineStrong);
  });

  testWidgets('the pill stays lit while the popover is open, without hover', (
    tester,
  ) async {
    final tokens = DesignSystemTokens.light();
    await tester.pumpWidget(
      _host(
        ReactionBar(
          reactions: const [],
          onToggle: (c, {required add}) async {},
        ),
      ),
    );

    // Touch tap: no pointer hover, so any highlight must come from `open`.
    await tester.tap(find.byIcon(AppIcons.smile));
    await tester.pump();

    // The emoji grid opened, with a name tooltip and no content-key label.
    expect(find.text('👍'), findsOneWidget);
    expect(find.text('+1'), findsNothing);
    expect(
      tester
          .widget<CcTooltip>(
            find.ancestor(
              of: find.text('👍'),
              matching: find.byType(CcTooltip),
            ),
          )
          .message,
      'Thumbs up',
    );
    expect(
      tester
          .widget<CcTooltip>(
            find.ancestor(
              of: find.text('👀'),
              matching: find.byType(CcTooltip),
            ),
          )
          .message,
      'Eyes',
    );

    final decoration = pillDecoration(tester);
    expect(decoration.color, tokens.hover);
    expect(decoration.border!.top.color, tokens.lineStrong);
  });
}
