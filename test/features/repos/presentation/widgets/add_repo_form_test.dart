import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/git_repo_info.dart';
import 'package:control_center/core/domain/ports/git_repo_inspector_port.dart';
import 'package:control_center/core/domain/repositories/repo_repository.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/repos/presentation/widgets/add_repo_form.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGitRepoInspector implements GitRepoInspectorPort {
  @override
  Future<GitRepoInfo> inspect(String path) async {
    throw UnimplementedError();
  }
}

class _FakeRepoRepo extends Fake implements RepoRepository {}

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('AddRepoForm rendering', () {
    testWidgets('renders choose folder button', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitRepoInspectorPortProvider.overrideWithValue(
              _FakeGitRepoInspector(),
            ),
            repoRepositoryProvider.overrideWithValue(_FakeRepoRepo()),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AddRepoForm(onCreated: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Choose repository folder'), findsOneWidget);
    });

    testWidgets('renders submit button', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitRepoInspectorPortProvider.overrideWithValue(
              _FakeGitRepoInspector(),
            ),
            repoRepositoryProvider.overrideWithValue(_FakeRepoRepo()),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AddRepoForm(
                  onCreated: (_) {},
                  submitLabel: 'Add repository',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Add repository'), findsOneWidget);
    });

    testWidgets('renders cancel button when onCancel provided', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitRepoInspectorPortProvider.overrideWithValue(
              _FakeGitRepoInspector(),
            ),
            repoRepositoryProvider.overrideWithValue(_FakeRepoRepo()),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AddRepoForm(
                  onCreated: (_) {},
                  onCancel: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('does not render cancel when not provided', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitRepoInspectorPortProvider.overrideWithValue(
              _FakeGitRepoInspector(),
            ),
            repoRepositoryProvider.overrideWithValue(_FakeRepoRepo()),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AddRepoForm(onCreated: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('uses custom submitLabel', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitRepoInspectorPortProvider.overrideWithValue(
              _FakeGitRepoInspector(),
            ),
            repoRepositoryProvider.overrideWithValue(_FakeRepoRepo()),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AddRepoForm(
                  onCreated: (_) {},
                  submitLabel: 'Save repo',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Save repo'), findsOneWidget);
    });

    testWidgets('renders with default submitLabel', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitRepoInspectorPortProvider.overrideWithValue(_FakeGitRepoInspector()),
            repoRepositoryProvider.overrideWithValue(_FakeRepoRepo()),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: AddRepoForm(onCreated: (_) {})),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Add repository'), findsOneWidget);
    });

    testWidgets('submit button uses CcButton', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitRepoInspectorPortProvider.overrideWithValue(_FakeGitRepoInspector()),
            repoRepositoryProvider.overrideWithValue(_FakeRepoRepo()),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: AddRepoForm(onCreated: (_) {})),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(CcButton), findsWidgets);
    });

    testWidgets('onCancel button calls callback', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var cancelled = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitRepoInspectorPortProvider.overrideWithValue(_FakeGitRepoInspector()),
            repoRepositoryProvider.overrideWithValue(_FakeRepoRepo()),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AddRepoForm(
                  onCreated: (_) {},
                  onCancel: () => cancelled = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Cancel'));
      expect(cancelled, isTrue);

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });

  group('showAddRepoDialog', () {
    testWidgets('dialog shows title', (tester) async {
      tester.view.physicalSize = const Size(600, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitRepoInspectorPortProvider.overrideWithValue(_FakeGitRepoInspector()),
            repoRepositoryProvider.overrideWithValue(_FakeRepoRepo()),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  builder: (context) => CcButton(
                    onPressed: () => showAddRepoDialog(context),
                    child: const Text('Open dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Open dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Add repository'), findsWidgets);
      expect(find.text('Choose repository folder'), findsOneWidget);
    });

    testWidgets('dialog cancel button dismisses dialog', (tester) async {
      tester.view.physicalSize = const Size(600, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitRepoInspectorPortProvider.overrideWithValue(_FakeGitRepoInspector()),
            repoRepositoryProvider.overrideWithValue(_FakeRepoRepo()),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  builder: (context) => CcButton(
                    onPressed: () => showAddRepoDialog(context),
                    child: const Text('Open dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Open dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The dialog cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('dialog returns null when cancelled', (tester) async {
      tester.view.physicalSize = const Size(600, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? result = 'not-null';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gitRepoInspectorPortProvider.overrideWithValue(_FakeGitRepoInspector()),
            repoRepositoryProvider.overrideWithValue(_FakeRepoRepo()),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  builder: (context) => CcButton(
                    onPressed: () async {
                      result = await showAddRepoDialog(context);
                    },
                    child: const Text('Open dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Open dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The dialog cancel pops with null
      expect(result, isNull);
    });
  });
}
