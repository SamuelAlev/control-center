import 'package:control_center/features/memory/presentation/screens/memory_screen.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

/// Test-only [ActiveWorkspaceIdNotifier] that reports no active workspace.
class _NoActiveWorkspace extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

void main() {
  testWidgets('memory screen shows empty state when no workspace is active', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_NoActiveWorkspace.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const Scaffold(body: MemoryScreen()),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('Select a workspace to view its memory.'),
      findsOneWidget,
    );
  });
}
