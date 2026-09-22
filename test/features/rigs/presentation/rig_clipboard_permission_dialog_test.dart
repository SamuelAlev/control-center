import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/rigs/presentation/rig_clipboard_permission_dialog.dart';
import 'package:control_center/features/rigs/presentation/settings/rig_clipboard_settings_section.dart';
import 'package:control_center/features/rigs/providers/rig_clipboard_permissions.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('paste into an enclosure is allowed by default', (tester) async {
    final preferences = AppPreferences.inMemory();
    await tester.pumpWidget(
      _wrap(
        const _PermissionHarness(
          rigId: 'rig-a',
          direction: RigClipboardDirection.hostToRig,
        ),
        preferences,
      ),
    );

    await tester.tap(find.text('Request permission'));
    await tester.pump();

    expect(find.text('Allowed 1'), findsOneWidget);
    expect(find.text('Paste clipboard into this enclosure?'), findsNothing);
    expect(preferences.getBool(rigClipboardHostToRigAlwaysKey), isNull);
  });

  testWidgets('grants one direction for ten minutes after confirmation', (
    tester,
  ) async {
    final preferences = AppPreferences.inMemory();
    await tester.pumpWidget(
      _wrap(
        const _PermissionHarness(
          rigId: 'rig-a',
          direction: RigClipboardDirection.rigToHost,
        ),
        preferences,
      ),
    );

    await tester.tap(find.text('Request permission'));
    await tester.pumpAndSettle();

    expect(find.text('Copy clipboard out of this enclosure?'), findsOneWidget);
    expect(find.text('Allow for 10 minutes'), findsOneWidget);
    expect(find.text('Always allow'), findsOneWidget);

    await tester.tap(find.text('Allow for 10 minutes'));
    await tester.pumpAndSettle();
    expect(find.text('Allowed 1'), findsOneWidget);
    expect(preferences.getBool(rigClipboardRigToHostAlwaysKey), isNull);

    await tester.tap(find.text('Request permission'));
    await tester.pump();
    expect(find.text('Allowed 2'), findsOneWidget);
    expect(find.text('Copy clipboard out of this enclosure?'), findsNothing);
  });

  testWidgets('always allow persists the selected direction', (tester) async {
    final preferences = AppPreferences.inMemory();
    await tester.pumpWidget(
      _wrap(
        const _PermissionHarness(
          rigId: 'rig-a',
          direction: RigClipboardDirection.rigToHost,
        ),
        preferences,
      ),
    );

    await tester.tap(find.text('Request permission'));
    await tester.pumpAndSettle();
    expect(find.text('Copy clipboard out of this enclosure?'), findsOneWidget);

    await tester.tap(find.text('Always allow'));
    await tester.pumpAndSettle();
    expect(find.text('Allowed 1'), findsOneWidget);
    expect(preferences.getBool(rigClipboardRigToHostAlwaysKey), isTrue);
  });

  testWidgets('rig settings show paste on and copy out off by default', (
    tester,
  ) async {
    final preferences = AppPreferences.inMemory();
    await tester.pumpWidget(
      _wrap(const RigClipboardSettingsSection(), preferences),
    );
    await tester.pump();

    expect(find.text('CLIPBOARD ACCESS'), findsOneWidget);
    final switches = tester
        .widgetList<CcSwitch>(find.byType(CcSwitch))
        .toList();
    expect(switches, hasLength(2));
    expect(switches[0].value, isTrue);
    expect(switches[1].value, isFalse);
  });

  testWidgets('cancel denies the clipboard crossing', (tester) async {
    final preferences = AppPreferences.inMemory();
    await tester.pumpWidget(
      _wrap(
        const _PermissionHarness(
          rigId: 'rig-a',
          direction: RigClipboardDirection.rigToHost,
        ),
        preferences,
      ),
    );

    await tester.tap(find.text('Request permission'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Denied 1'), findsOneWidget);
    expect(preferences.getBool(rigClipboardRigToHostAlwaysKey), isNull);
  });
}

Widget _wrap(Widget child, AppPreferences preferences) => ProviderScope(
  overrides: [appPreferencesProvider.overrideWithValue(preferences)],
  child: MaterialApp(
    key: ValueKey(child.runtimeType),
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      GlobalMaterialLocalizations.delegate, // ignore: deprecated_member_use
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate, // ignore: deprecated_member_use
    ],
    supportedLocales: kSupportedAppLocales,
    locale: const Locale('en'),
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: child),
    ),
  ),
);

class _PermissionHarness extends ConsumerStatefulWidget {
  const _PermissionHarness({required this.rigId, required this.direction});

  final String rigId;
  final RigClipboardDirection direction;

  @override
  ConsumerState<_PermissionHarness> createState() => _PermissionHarnessState();
}

class _PermissionHarnessState extends ConsumerState<_PermissionHarness> {
  int _attempts = 0;
  bool? _lastAllowed;

  Future<void> _request() async {
    final allowed = await ensureRigClipboardPermission(
      context: context,
      ref: ref,
      rigId: widget.rigId,
      direction: widget.direction,
    );
    if (mounted) {
      setState(() {
        _attempts++;
        _lastAllowed = allowed;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CcButton(onPressed: _request, child: const Text('Request permission')),
      if (_lastAllowed case final allowed?)
        Text('${allowed ? 'Allowed' : 'Denied'} $_attempts'),
    ],
  );
}
