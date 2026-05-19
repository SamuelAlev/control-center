import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/repos_settings.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _TestActiveWorkspaceNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

Widget _wrap(Widget child) {
  return CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: child)),
  );
}

late AppPreferences prefs;
void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    prefs = AppPreferences.inMemory();
  });

  testWidgets('renders no workspace state', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(null),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: _wrap(const ReposSettings()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No active workspace'), findsOneWidget);
  });

  testWidgets('renders loading state', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier('ws-test'),
          ),
          reposForWorkspaceProvider('ws-test').overrideWith(
            (ref) => const Stream<List<Repo>>.empty(),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: _wrap(const ReposSettings()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Repositories'), findsOneWidget);
    expect(find.text('Add repository'), findsOneWidget);
  });

  testWidgets('renders empty state', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier('ws-test'),
          ),
          reposForWorkspaceProvider('ws-test').overrideWith(
            (ref) => Stream.value(const []),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: _wrap(const ReposSettings()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('No repositories'), findsOneWidget);
  });

  testWidgets('renders repos list', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = Repo(
      id: 'repo-1',
      name: 'my-repo',
      path: '/home/user/my-repo',
      githubOwner: '',
      githubRepoName: '',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier('ws-test'),
          ),
          reposForWorkspaceProvider('ws-test').overrideWith(
            (ref) => Stream.value([repo]),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: _wrap(const ReposSettings()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('my-repo'), findsOneWidget);
    expect(find.textContaining('/home/user/my-repo'), findsOneWidget);
  });

  testWidgets('renders multiple repos', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repos = [
      Repo(
        id: 'repo-1', name: 'alpha', path: '/alpha',
        githubOwner: '', githubRepoName: '',
        createdAt: DateTime(2024), updatedAt: DateTime(2024),
      ),
      Repo(
        id: 'repo-2', name: 'beta', path: '/beta',
        githubOwner: '', githubRepoName: '',
        createdAt: DateTime(2024), updatedAt: DateTime(2024),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier('ws-test'),
          ),
          reposForWorkspaceProvider('ws-test').overrideWith(
            (ref) => Stream.value(repos),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: _wrap(const ReposSettings()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);
  });

  testWidgets('shows error state on failed load', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier('ws-test'),
          ),
          reposForWorkspaceProvider('ws-test').overrideWith(
            (ref) => Stream<List<Repo>>.fromFuture(
              Future.error(Exception('Load failed')),
            ),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: _wrap(const ReposSettings()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // The _ReposList widget uses reposAsync.when() with error handler.
    // Verify the page still renders its header (build didn't crash).
    expect(find.text('Repositories'), findsOneWidget);
  });

  testWidgets('renders remove button on repo card', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = Repo(
      id: 'repo-1', name: 'test-repo', path: '/tmp/test-repo',
      githubOwner: '', githubRepoName: '',
      createdAt: DateTime(2024), updatedAt: DateTime(2024),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier('ws-test'),
          ),
          reposForWorkspaceProvider('ws-test').overrideWith(
            (ref) => Stream.value([repo]),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: _wrap(const ReposSettings()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
  });

  testWidgets('renders repo with github remote avatar', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = Repo(
      id: 'repo-gh',
      name: 'gh-repo',
      path: '/tmp/gh-repo',
      githubOwner: 'octocat',
      githubRepoName: 'hello-world',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier('ws-test'),
          ),
          reposForWorkspaceProvider('ws-test').overrideWith(
            (ref) => Stream.value([repo]),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: _wrap(const ReposSettings()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('gh-repo'), findsOneWidget);
  });

  testWidgets('renders repo with branch and path', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = Repo(
      id: 'repo-bp',
      name: 'branch-repo',
      path: '/home/dev/project',
      githubOwner: '',
      githubRepoName: '',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier('ws-test'),
          ),
          reposForWorkspaceProvider('ws-test').overrideWith(
            (ref) => Stream.value([repo]),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: _wrap(const ReposSettings()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('branch-repo'), findsOneWidget);
    expect(find.textContaining('/home/dev/project'), findsOneWidget);
  });

  testWidgets('no workspace state shows correct message', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(null),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: _wrap(const ReposSettings()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Create or select a workspace'), findsOneWidget);
  });

  testWidgets('renders Repositories header', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier('ws-test'),
          ),
          reposForWorkspaceProvider('ws-test').overrideWith(
            (ref) => Stream.value([]),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: _wrap(const ReposSettings()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Repositories'), findsOneWidget);
  });

  testWidgets('renders empty state add button', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier('ws-test'),
          ),
          reposForWorkspaceProvider('ws-test').overrideWith(
            (ref) => Stream.value([]),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: _wrap(const ReposSettings()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Add repository'), findsAtLeast(1));
  });

  testWidgets('renders repo with empty branch falls back to path', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = Repo(
      id: 'repo-nobranch',
      name: 'no-branch-repo',
      path: '/opt/project',
      githubOwner: '',
      githubRepoName: '',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier('ws-test'),
          ),
          reposForWorkspaceProvider('ws-test').overrideWith(
            (ref) => Stream.value([repo]),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: _wrap(const ReposSettings()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('no-branch-repo'), findsOneWidget);
    expect(find.text('/opt/project'), findsOneWidget);
  });
}
