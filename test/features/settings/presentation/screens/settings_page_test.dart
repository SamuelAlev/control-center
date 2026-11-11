import 'package:control_center/di/settings_registry.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_page_heading.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

/// Whether the middle card has anything to show.
class _Shown extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final _shownProvider = NotifierProvider<_Shown, bool>(_Shown.new);

bool _middleVisible(WidgetRef ref) => ref.watch(_shownProvider);

/// A contributed card whose predicate answers false is left out of the page
/// entirely: never built, and no gap of its own between its neighbours. A
/// heading over the contributed cards goes with them.
void main() {
  late int middleBuilds;

  setUp(() => middleBuilds = 0);

  Widget card(String id) =>
      SizedBox(key: ValueKey(id), height: 40, child: Text(id));

  SettingsRegistry registry({required bool predicate}) => SettingsRegistry(
    sections: [
      SettingsSectionContribution(
        id: 'test.first',
        slot: SettingsSlot.userAccounts,
        order: 10,
        builder: (_) => card('test.first'),
      ),
      SettingsSectionContribution(
        id: 'test.middle',
        slot: SettingsSlot.userAccounts,
        order: 20,
        builder: (_) {
          middleBuilds++;
          // What a card with nothing to show used to render.
          return const SizedBox.shrink();
        },
        visible: predicate ? _middleVisible : null,
      ),
      SettingsSectionContribution(
        id: 'test.last',
        slot: SettingsSlot.userAccounts,
        order: 30,
        builder: (_) => card('test.last'),
      ),
    ],
  );

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required bool predicate,
  }) async {
    tester.view
      ..physicalSize = const Size(1200, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        settingsRegistryProvider.overrideWithValue(
          registry(predicate: predicate),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testWrap(
          const SettingsPage(
            title: 'Page',
            sections: [],
            slot: SettingsSlot.userAccounts,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  double gap(WidgetTester tester) =>
      tester.getTopLeft(find.byKey(const ValueKey('test.last'))).dy -
      tester.getBottomLeft(find.byKey(const ValueKey('test.first'))).dy;

  testWidgets('a card whose predicate answers false is not built and leaves '
      'no gap', (tester) async {
    await pump(tester, predicate: true);
    expect(middleBuilds, 0);
    // One separator between the neighbours, as if the card did not exist.
    expect(gap(tester), 16);
  });

  testWidgets('without a predicate, an empty card still costs a gap', (
    tester,
  ) async {
    await pump(tester, predicate: false);
    expect(middleBuilds, greaterThan(0));
    expect(gap(tester), 32);
  });

  testWidgets('a heading sits between the page\'s own cards and the '
      'contributed ones, and is left out when nothing is contributed', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1200, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Future<void> pumpWith(SettingsRegistry registry) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsRegistryProvider.overrideWithValue(registry)],
          child: testWrap(
            SettingsPage(
              title: 'Page',
              sections: [card('own')],
              slot: SettingsSlot.userAccounts,
              slotHeading: const SettingsPageHeading(title: 'Contributed'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpWith(registry(predicate: true));
    final own = tester.getBottomLeft(find.byKey(const ValueKey('own'))).dy;
    final heading = tester.getRect(find.text('Contributed'));
    final first = tester.getTopLeft(find.byKey(const ValueKey('test.first')));
    expect(heading.top - own, 32, reason: 'more room above than below');
    expect(first.dy - heading.bottom, 16);

    await pumpWith(const SettingsRegistry());
    expect(find.text('Contributed'), findsNothing);
    expect(find.byKey(const ValueKey('own')), findsOneWidget);
  });

  testWidgets('the page follows the predicate as its answer changes', (
    tester,
  ) async {
    final container = await pump(tester, predicate: true);
    expect(middleBuilds, 0);

    container.read(_shownProvider.notifier).set(true);
    await tester.pumpAndSettle();
    expect(middleBuilds, greaterThan(0));
    expect(gap(tester), 32);

    container.read(_shownProvider.notifier).set(false);
    await tester.pumpAndSettle();
    expect(gap(tester), 16);
  });
}
