import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/review_code_pane.dart';
import 'package:control_center/features/messaging/providers/repo_changes_provider.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A patch tall enough that the next file starts below a short viewport.
String _tallPatch() {
  final lines = StringBuffer('@@ -1,80 +1,80 @@\n');
  for (var i = 0; i < 80; i++) {
    lines.writeln('+line $i');
  }
  return lines.toString();
}

PrFile _file(String filename) {
  return PrFile(
    filename: filename,
    status: PrFileStatus.modified,
    additions: 80,
    deletions: 0,
    patch: _tallPatch(),
  );
}

final _files = <PrFile>[];

Widget _pane(String anchor) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('monospace'),
      codeFontLigaturesProvider.overrideWithValue(false),
      repoChangesProvider.overrideWith((ref, args) async => _files),
    ],
    child: MaterialApp(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate, // ignore: deprecated_member_use
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // ignore: deprecated_member_use
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(
          body: ReviewCodePane(
            workspaceId: 'ws',
            repoId: 'repo',
            spaceId: 'space',
            anchorPath: anchor,
          ),
        ),
      ),
    ),
  );
}

double _verticalOffset(WidgetTester tester) {
  var max = 0.0;
  for (final state in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    final position = state.position;
    if (position.axis == Axis.vertical &&
        position.hasPixels &&
        position.pixels > max) {
      max = position.pixels;
    }
  }
  return max;
}

/// Pumps long enough for the changeset to arrive and the anchor animation
/// (240ms) to finish, including a few frames of "scroll view not ready" retries.
Future<double> _settledOffset(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return _verticalOffset(tester);
}

void main() {
  final files = [_file('first.dart'), _file('second.dart')];

  setUpAll(() => DiffWorkerPool.debugForceInline = true);
  tearDownAll(() => DiffWorkerPool.debugForceInline = false);

  setUp(() {
    _files
      ..clear()
      ..addAll(files);
  });

  Future<void> runOnDesktop(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    // Desktop scroll views do not inherit the route PrimaryScrollController.
    // That is the bug: the jump used to no-op because nothing was attached.
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    tester.view.physicalSize = const Size(800, 480);
    tester.view.devicePixelRatio = 1;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  }

  testWidgets('opens scrolled to the clicked file', (tester) async {
    await runOnDesktop(tester, () async {
      await tester.pumpWidget(_pane('second.dart'));
      final offset = await _settledOffset(tester);

      expect(offset, greaterThan(400));
      expect(find.text('second.dart'), findsOneWidget);
    });
  });

  testWidgets('scrolling follows a later click on another file', (
    tester,
  ) async {
    await runOnDesktop(tester, () async {
      await tester.pumpWidget(_pane('first.dart'));
      final atFirst = await _settledOffset(tester);

      await tester.pumpWidget(_pane('second.dart'));
      final atSecond = await _settledOffset(tester);

      expect(atSecond, greaterThan(atFirst + 400));
      expect(find.text('second.dart'), findsOneWidget);
    });
  });
}
