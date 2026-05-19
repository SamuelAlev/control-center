import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

/// Renders [child] at a fixed logical size so the width-dependent branches
/// (`SettingsFieldLayout.auto`) are exercised deterministically rather than at
/// whatever the default test surface happens to be.
Future<void> _pumpAt(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(900, 700),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(testWrap(SingleChildScrollView(child: child)));
  await tester.pump();
}

void main() {
  group('SettingsField', () {
    testWidgets('renders label, description, control and hint', (tester) async {
      await _pumpAt(
        tester,
        const SettingsField(
          label: 'Issuer URL',
          description: 'Where discovery lives',
          hint: 'https://idp.example.com',
          child: SizedBox(height: 40),
        ),
      );

      expect(find.text('Issuer URL'), findsOneWidget);
      expect(find.text('Where discovery lives'), findsOneWidget);
      expect(find.text('https://idp.example.com'), findsOneWidget);
    });

    testWidgets('an error replaces the hint rather than stacking with it', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        const SettingsField(
          label: 'Issuer URL',
          hint: 'a hint',
          error: 'must be an absolute URL',
          child: SizedBox(height: 40),
        ),
      );

      expect(find.text('must be an absolute URL'), findsOneWidget);
      expect(find.text('a hint'), findsNothing);
    });

    testWidgets('optional fields say so', (tester) async {
      await _pumpAt(
        tester,
        const SettingsField(
          label: 'Client secret',
          optional: true,
          child: SizedBox(height: 40),
        ),
      );

      expect(find.text('Optional'), findsOneWidget);
    });

    testWidgets('auto layout goes inline when there is room and stacks when '
        'there is not', (tester) async {
      // Wide: the label sits in the fixed left column, so the control's left
      // edge is pushed past it.
      await _pumpAt(
        tester,
        const SettingsField(
          label: 'Default role',
          child: SizedBox(key: Key('control'), height: 40),
        ),
      );
      final wideControlLeft = tester.getTopLeft(
        find.byKey(const Key('control')),
      );
      final wideLabelLeft = tester.getTopLeft(find.text('Default role'));
      expect(wideControlLeft.dx, greaterThan(wideLabelLeft.dx + 100));

      // Narrow (the phone remote): label above, control below at full width.
      await _pumpAt(
        tester,
        const SettingsField(
          label: 'Default role',
          child: SizedBox(key: Key('control'), height: 40),
        ),
        size: const Size(420, 700),
      );
      final narrowControl = tester.getTopLeft(find.byKey(const Key('control')));
      final narrowLabel = tester.getTopLeft(find.text('Default role'));
      expect(narrowControl.dx, equals(narrowLabel.dx));
      expect(narrowControl.dy, greaterThan(narrowLabel.dy));
    });
  });

  group('SettingsToggle', () {
    testWidgets('tapping anywhere on the row flips the switch', (tester) async {
      var value = false;
      await _pumpAt(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SettingsToggle(
            title: 'Provision unknown users',
            description: 'Turn off to reject users without an account',
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      );

      // The description is nowhere near the switch — the point of the test.
      await tester.tap(
        find.text('Turn off to reject users without an account'),
      );
      await tester.pump();
      expect(value, isTrue);
    });

    testWidgets('a null handler disables the row', (tester) async {
      await _pumpAt(
        tester,
        const SettingsToggle(
          title: 'Provision unknown users',
          value: false,
          onChanged: null,
        ),
      );

      await tester.tap(find.text('Provision unknown users'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.widget<CcSwitch>(find.byType(CcSwitch)).onChanged, isNull);
    });
  });

  group('SettingsDisclosure', () {
    testWidgets('hides its child until opened, and states what is inside', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        const SettingsDisclosure(
          title: 'Advanced',
          summary: 'Clock skew, signature policy',
          child: Text('the detail'),
        ),
      );

      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('Clock skew, signature policy'), findsOneWidget);
      expect(find.text('the detail'), findsNothing);

      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();
      expect(find.text('the detail'), findsOneWidget);
    });

    testWidgets('a collapsed section still reports a non-default value', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        const SettingsDisclosure(
          title: 'Generation defaults',
          badge: SettingsModifiedBadge(label: 'Overridden'),
          child: Text('the detail'),
        ),
      );

      expect(find.text('Overridden'), findsOneWidget);
      expect(find.text('the detail'), findsNothing);
    });
  });

  group('SettingsEntityRow', () {
    testWidgets('collapsed row carries name, status, subtitle and meta', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        const SettingsEntityRow(
          title: 'Anthropic',
          tone: CcStatusTone.positive,
          statusLabel: 'Connected',
          icon: AppIcons.circleCheck,
          subtitle: 'sam@example.com',
          meta: [SettingsMetaFact(label: 'Models', value: '12')],
          detail: Text('the detail'),
        ),
      );

      expect(find.text('Anthropic'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('sam@example.com'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('detail stays unbuilt until the row is expanded', (
      tester,
    ) async {
      var expanded = false;
      await _pumpAt(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SettingsEntityRow(
            title: 'Anthropic',
            expanded: expanded,
            onExpandedChanged: (v) => setState(() => expanded = v),
            detail: const Text('the detail'),
          ),
        ),
      );

      expect(find.text('the detail'), findsNothing);
      await tester.tap(find.text('Anthropic'));
      await tester.pumpAndSettle();
      expect(find.text('the detail'), findsOneWidget);
    });

    testWidgets('a row with no detail is not a button', (tester) async {
      await _pumpAt(
        tester,
        const SettingsEntityRow(title: 'Anthropic', subtitle: 'no detail'),
      );

      // No chevron: nothing to open, so nothing that looks openable.
      expect(find.byIcon(AppIcons.chevronRight), findsNothing);
    });
  });

  group('SettingsSummary', () {
    testWidgets('renders each fact as a label over its value', (tester) async {
      await _pumpAt(
        tester,
        const SettingsSummary(
          facts: [
            SettingsFact(
              label: 'Connected',
              value: '2 of 18',
              tone: CcStatusTone.positive,
            ),
            SettingsFact(label: 'Models', value: '214'),
          ],
          note: 'agents fall back to the workspace default',
        ),
      );

      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('2 of 18'), findsOneWidget);
      expect(find.text('214'), findsOneWidget);
      expect(
        find.text('agents fall back to the workspace default'),
        findsOneWidget,
      );
      final label = tester.getTopLeft(find.text('Connected'));
      final value = tester.getTopLeft(find.text('2 of 18'));
      expect(value.dy, greaterThan(label.dy));
      expect(value.dx, greaterThanOrEqualTo(label.dx));
    });
  });

  group('SettingsSaveBar', () {
    testWidgets('is invisible with nothing to commit', (tester) async {
      await _pumpAt(tester, SettingsSaveBar(dirty: false, onSave: () {}));

      expect(find.text('Save'), findsNothing);
      expect(find.text('Discard'), findsNothing);
    });

    testWidgets('appears when dirty and says so', (tester) async {
      var saved = false;
      await _pumpAt(
        tester,
        SettingsSaveBar(dirty: true, onSave: () => saved = true),
      );

      expect(find.textContaining('Unsaved'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(saved, isTrue);
    });

    testWidgets('secondary actions stay available while clean', (tester) async {
      await _pumpAt(
        tester,
        SettingsSaveBar(
          dirty: false,
          onSave: () {},
          secondaryActions: [
            CcButton(onPressed: () {}, child: const Text('Test connection')),
          ],
        ),
      );

      expect(find.text('Test connection'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });
  });

  group('SettingsKeyValueEditor', () {
    testWidgets('emits pairs and drops rows with an empty key', (tester) async {
      List<SettingsKeyValuePair>? emitted;
      await _pumpAt(
        tester,
        SettingsKeyValueEditor(
          entries: const [SettingsKeyValuePair('platform-leads', 'admin')],
          addLabel: 'Add mapping',
          onChanged: (v) => emitted = v,
        ),
      );

      expect(find.text('platform-leads'), findsOneWidget);

      // A freshly added, still-blank row must not turn into a `"": ""` entry.
      await tester.tap(find.text('Add mapping'));
      await tester.pump();
      final keyFields = find.byType(CcTextField);
      await tester.enterText(keyFields.at(2), 'designers');
      await tester.pump();

      expect(emitted, isNotNull);
      expect(emitted!.map((e) => e.key), contains('designers'));
      expect(emitted!.map((e) => e.key), isNot(contains('')));
    });

    testWidgets('says so when there is nothing mapped', (tester) async {
      await _pumpAt(
        tester,
        SettingsKeyValueEditor(
          entries: const [],
          emptyLabel: 'No mappings yet',
          onChanged: (_) {},
        ),
      );

      expect(find.text('No mappings yet'), findsOneWidget);
    });
  });

  group('SettingsFilterBar', () {
    testWidgets('reports the query, the facets and the live count', (
      tester,
    ) async {
      String? query;
      String? facet;
      await _pumpAt(
        tester,
        SettingsFilterBar<String>(
          query: '',
          onQueryChanged: (q) => query = q,
          searchHint: 'Filter providers',
          selectedFacet: 'all',
          onFacetChanged: (f) => facet = f,
          resultLabel: '6 of 18',
          facets: const [
            SettingsFacet(value: 'all', label: 'All', count: 18),
            SettingsFacet(value: 'connected', label: 'Connected', count: 6),
          ],
        ),
      );

      expect(find.text('6 of 18'), findsOneWidget);
      expect(find.text('All  18'), findsOneWidget);

      await tester.enterText(find.byType(CcTextField), 'ollama');
      await tester.pump();
      expect(query, 'ollama');

      await tester.tap(find.text('Connected  6'));
      await tester.pump();
      expect(facet, 'connected');
    });
  });

  group('SettingsGroup', () {
    testWidgets('renders its heading and children without nesting a card', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        const SettingsGroup(
          title: 'Attribute mapping',
          description: 'Which claim carries each field',
          children: [Text('one'), Text('two')],
        ),
      );

      expect(find.text('Attribute mapping'), findsOneWidget);
      expect(find.text('Which claim carries each field'), findsOneWidget);
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
    });
  });

  group('SettingsCopyField', () {
    testWidgets('shows the value and an explanation when there is none', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        const SettingsCopyField(value: 'https://cc.example.com/saml/acs'),
      );
      expect(find.text('https://cc.example.com/saml/acs'), findsOneWidget);

      await _pumpAt(
        tester,
        const SettingsCopyField(
          value: null,
          emptyLabel: 'Set a public URL first',
        ),
      );
      expect(find.text('Set a public URL first'), findsOneWidget);
    });
  });
}
