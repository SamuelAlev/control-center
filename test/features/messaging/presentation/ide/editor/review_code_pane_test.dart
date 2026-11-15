import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/cache_for.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/review_code_pane.dart';
import 'package:control_center/features/messaging/providers/repo_changes_provider.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

/// When set, the changeset load fails with it instead of answering [_files].
Object? _failure;

/// How many times the changeset was loaded.
var _loads = 0;

/// When set, a load waits for it before answering.
Completer<void>? _hold;

Widget _pane(String anchor, {bool shown = true}) {
  return ProviderScope(
    retry: (_, _) => null,
    overrides: [
      codeFontFamilyProvider.overrideWithValue('monospace'),
      codeFontLigaturesProvider.overrideWithValue(false),
      repoChangesProvider.overrideWith((ref, args) async {
        // As the real provider does: the diff outlives the tab for a while.
        ref.cacheFor(kPanelCacheTtl);
        _loads++;
        await _hold?.future;
        final failure = _failure;
        if (failure != null) {
          throw failure;
        }
        return _files;
      }),
    ],
    child: MaterialApp(
      localizationsDelegates: [
        ...appLocalizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(
          body: shown
              ? ReviewCodePane(
                  workspaceId: 'ws',
                  repoId: 'repo',
                  spaceId: 'space',
                  anchorPath: anchor,
                )
              : const SizedBox.shrink(),
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
    _failure = null;
    _loads = 0;
    _hold = null;
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

  testWidgets('a diff refused by the forge says so, not "no changes"', (
    tester,
  ) async {
    _failure = RemoteRpcException(RpcErrorCodes.unauthorized, 'refused', {
      'kind': 'forge_cannot_read',
      'forge': 'github',
    });
    await tester.pumpWidget(_pane('first.dart'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text("Your GitHub account can't read this repository."),
      findsOneWidget,
    );
    expect(find.text('No changes to review'), findsNothing);
  });

  testWidgets('a diff that fails otherwise offers a retry', (tester) async {
    _failure = StateError('boom');
    await tester.pumpWidget(_pane('first.dart'));
    await tester.pump();
    await tester.pump();

    expect(find.text("Couldn't load the changes"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('coming back paints the held diff and refetches it', (
    tester,
  ) async {
    await runOnDesktop(tester, () async {
      await tester.pumpWidget(_pane('first.dart'));
      await _settledOffset(tester);
      expect(find.text('first.dart'), findsOneWidget);
      expect(_loads, 1);

      await tester.pumpWidget(_pane('first.dart', shown: false));
      await tester.pump();

      // The refetch stays in flight: the held diff must paint meanwhile.
      _hold = Completer<void>();
      await tester.pumpWidget(_pane('first.dart'));
      await tester.pump();
      expect(find.byType(CcSpinner), findsNothing);
      expect(find.text('first.dart'), findsOneWidget);
      expect(_loads, 2);

      _hold!.complete();
      await _settledOffset(tester);
      expect(find.text('first.dart'), findsOneWidget);
    });
  });
}
