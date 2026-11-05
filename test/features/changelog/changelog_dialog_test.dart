import 'package:cc_domain/cc_domain.dart' show BuildInfo;
import 'package:cc_domain/features/changelog/domain/entities/changelog_release.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/changelog/presentation/widgets/changelog_after_update.dart';
import 'package:control_center/features/changelog/presentation/widgets/changelog_dialog.dart';
import 'package:control_center/features/changelog/providers/changelog_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

final _releases = ChangelogRelease.parseMarkdown('''
## v${BuildInfo.buildVersion} — Oct 27, 2026 — The phone app grows up

The phone app can now manage spaces.

- [new] Phone conversations.
- [fixed] Copying a link works.

## v0.0.1 — Oct 1, 2026 — First

The first one.
''');

Widget _wrap(
  Widget child, {
  required Future<List<ChangelogRelease>> Function() load,
  AppPreferences? prefs,
}) => ProviderScope(
  overrides: [
    changelogProvider.overrideWith((ref) => load()),
    if (prefs != null) appPreferencesProvider.overrideWithValue(prefs),
  ],
  child: testWrap(child),
);

void main() {
  group('ChangelogDialog', () {
    testWidgets('lists releases and marks the running build', (tester) async {
      await tester.pumpWidget(
        _wrap(const ChangelogDialog(), load: () async => _releases),
      );
      await tester.pumpAndSettle();

      expect(find.text(BuildInfo.buildVersion), findsOneWidget);
      expect(find.text('0.0.1'), findsOneWidget);
      expect(find.text('Installed'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Fixed'), findsOneWidget);
      expect(find.text('Phone conversations.'), findsOneWidget);
    });

    testWidgets('offers a retry when the changelog cannot be read', (
      tester,
    ) async {
      var attempts = 0;
      await tester.pumpWidget(
        _wrap(
          const ChangelogDialog(),
          load: () async {
            attempts++;
            if (attempts == 1) {
              throw const ChangelogUnavailable();
            }
            return _releases;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load the release notes."), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Phone conversations.'), findsOneWidget);
    });
  });

  group('ChangelogAfterUpdate', () {
    Future<void> launch(
      WidgetTester tester,
      AppPreferences prefs, {
      Future<List<ChangelogRelease>> Function()? load,
    }) async {
      await tester.pumpWidget(
        _wrap(
          const ChangelogAfterUpdate(version: '2.0.0'),
          load: load ?? () async => _releases,
          prefs: prefs,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a fresh install records its version silently', (
      tester,
    ) async {
      final prefs = AppPreferences.inMemory();
      await launch(tester, prefs);

      expect(find.byType(ChangelogDialog), findsNothing);
      expect(prefs.getString(changelogLastSeenVersionKey), '2.0.0');
    });

    testWidgets('a new version opens the dialog once', (tester) async {
      final prefs = AppPreferences.inMemory({
        changelogLastSeenVersionKey: '1.0.0',
      });
      await launch(tester, prefs);

      expect(find.byType(ChangelogDialog), findsOneWidget);
      expect(prefs.getString(changelogLastSeenVersionKey), '2.0.0');
    });

    testWidgets('the same version stays quiet', (tester) async {
      final prefs = AppPreferences.inMemory({
        changelogLastSeenVersionKey: '2.0.0',
      });
      await launch(tester, prefs);

      expect(find.byType(ChangelogDialog), findsNothing);
    });

    testWidgets('an unreachable changelog waits for the next launch', (
      tester,
    ) async {
      final prefs = AppPreferences.inMemory({
        changelogLastSeenVersionKey: '1.0.0',
      });
      await launch(
        tester,
        prefs,
        load: () async => throw const ChangelogUnavailable(),
      );

      expect(find.byType(ChangelogDialog), findsNothing);
      expect(prefs.getString(changelogLastSeenVersionKey), '1.0.0');
    });
  });
}
