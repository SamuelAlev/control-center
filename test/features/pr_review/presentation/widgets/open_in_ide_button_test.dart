import 'dart:async';
import 'package:control_center/core/domain/entities/ide_editor.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/ports/editor_launcher_port.dart';
import 'package:control_center/core/domain/ports/pr_worktree_port.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/widgets/open_in_ide_button.dart';
import 'package:control_center/features/pr_review/providers/ide_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/test_wrap.dart';

// ── Test fixtures ──────────────────────────────────────────────────────────

PullRequest _pr([int number = 42]) {
  return PullRequest(
    id: number,
    number: number,
    title: 'Test PR',
    body: 'PR body',
    state: PrState.open,
    isDraft: false,
    author: const PrUser(login: 'author', avatarUrl: ''),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 6, 10),
    repoFullName: 'owner/repo',
    htmlUrl: 'https://github.com/owner/repo/pull/$number',
    headRef: 'feature/test-branch',
  );
}

Repo _repo() {
  return Repo(
    id: 'repo-1',
    name: 'owner/repo',
    path: '/tmp/test-repo',
    githubOwner: 'owner',
    githubRepoName: 'repo',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

const _installedEditor1 = IdeEditor(
  id: 'vscode',
  displayName: 'VS Code',
  installed: true,
);

const _installedEditor2 = IdeEditor(
  id: 'cursor',
  displayName: 'Cursor',
  installed: true,
);

const _notInstalledEditor = IdeEditor(
  id: 'sublime',
  displayName: 'Sublime Text',
  installed: false,
);

// ── Fake ports (capture calls for verification) ────────────────────────────

class _FakeEditorLauncher implements EditorLauncherPort {
  String? lastOpenedEditorId;
  String? lastOpenedPath;
  bool shouldThrow = false;

  @override
  Future<List<IdeEditor>> detectEditors() async {
    return const [];
  }

  @override
  Future<void> openDirectory({
    required String editorId,
    required String directoryPath,
  }) async {
    lastOpenedEditorId = editorId;
    lastOpenedPath = directoryPath;
    if (shouldThrow) {
      throw const EditorLaunchException('Launch failed');
    }
  }
}

class _FakePrWorktreePort implements PrWorktreePort {
  bool shouldThrow = false;
  int ensureWorktreeCalls = 0;

  /// When non-null, [ensureWorktree] returns this future instead of completing
  /// synchronously. Set to a [Completer] to hold the async operation open long
  /// enough for the test to observe the loading state.
  Future<String>? _pendingWorktree;

  @override
  Future<String> ensureWorktree({
    required String workspaceId,
    required Repo repo,
    required int prNumber,
    required String prHeadRef,
  }) async {
    ensureWorktreeCalls++;
    if (shouldThrow) {
      throw const PrWorktreeException('Worktree failed');
    }
    if (_pendingWorktree != null) {
      return _pendingWorktree!;
    }
    return '/tmp/worktrees/pr-$prNumber';
  }

  @override
  Future<void> release({
    required String repoFullName,
    required int prNumber,
  }) async {
    // No-op for tests.
  }
}

// ── Wrapper helpers ────────────────────────────────────────────────────────

/// Wraps [child] in [testWrap] plus [DesignSystemTokens.light] as a theme
/// extension so `context.designSystem!` works.
// testWrap now provides a CcTheme(CcThemeData.light()) ancestor, so
// `context.designSystem` resolves the light tokens directly.
Widget _wrap(Widget child) => testWrap(child);

/// A minimal notifier that returns a fixed selected editor id.
class _FixedSelectedIdeNotifier extends SelectedIdeNotifier {
  _FixedSelectedIdeNotifier(this._id);
  final String? _id;

  @override
  String? build() => _id;
}

/// Wraps the button with overrides for the IDE providers and fake ports.
///
/// [editors] drives `installedEditorsProvider`; [selectedId] drives
/// `selectedIdeProvider`; the fake launcher and worktree ports are exposed
/// for assertion.
Widget _wrapWithEditors({
  required List<IdeEditor> editors,
  String? selectedId,
  required _FakeEditorLauncher fakeLauncher,
  required _FakePrWorktreePort fakeWorktree,
  PullRequest? pr,
  Repo? repo,
  String workspaceId = 'ws-1',
}) {
  final button = OpenInIdeButton(
    pr: pr ?? _pr(),
    repo: repo ?? _repo(),
    workspaceId: workspaceId,
  );

  return _wrap(
    ProviderScope(
      overrides: [
        installedEditorsProvider.overrideWith((ref) => editors),
        ideLogoAssetsProvider.overrideWith((ref) => const <String>{}),
        editorLauncherProvider.overrideWithValue(fakeLauncher),
        prWorktreePortProvider.overrideWithValue(fakeWorktree),
        selectedIdeProvider.overrideWith(
          () => _FixedSelectedIdeNotifier(selectedId),
        ),
      ],
      child: button,
    ),
  );
}

/// Pumps enough time to clear any Overlay animation timers.
Future<void> _settleTimers(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  // ── Rendering ──────────────────────────────────────────────────────────

  group('rendering', () {
    testWidgets('renders nothing when no editors are installed', (tester) async {
      await tester.pumpWidget(_wrapWithEditors(
        editors: const [],
        fakeLauncher: _FakeEditorLauncher(),
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);
      // When no editors are installed, the build returns SizedBox.shrink() —
      // so no button UI (chevron, logo) is rendered.
      expect(find.byIcon(LucideIcons.chevronDown), findsNothing);
    });

    testWidgets('renders split button when editors are installed', (tester) async {
      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1],
        fakeLauncher: _FakeEditorLauncher(),
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);
      // The chevron icon is always present.
      expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
    });

    testWidgets('renders most installed editors when some are not installed',
        (tester) async {
      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_notInstalledEditor, _installedEditor1],
        fakeLauncher: _FakeEditorLauncher(),
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);
      // The button is visible because at least one editor is installed.
      expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
    });

    testWidgets('shows fallback icon when no bundled logos are loaded',
        (tester) async {
      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1],
        fakeLauncher: _FakeEditorLauncher(),
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);
      // With no bundled logos (ideLogoAssetsProvider empty), _buildLogo falls
      // back to LucideIcons.code for VS Code.
      expect(find.byIcon(LucideIcons.code), findsOneWidget);
    });
  });

  // ── IDE options (menu) ──────────────────────────────────────────────────

  group('menu', () {
    testWidgets('tapping chevron opens menu with installed editors',
        (tester) async {
      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1, _installedEditor2],
        fakeLauncher: _FakeEditorLauncher(),
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);

      // Tap the chevron icon to open the menu.
      await tester.tap(find.byIcon(LucideIcons.chevronDown));
      await _settleTimers(tester);

      // The menu header uses l10n.openInEditorPrompt.
      expect(find.text('Open in which editor?'), findsOneWidget);
      expect(find.text('VS Code'), findsOneWidget);
      expect(find.text('Cursor'), findsOneWidget);
    });

    testWidgets('menu shows not-installed editors under separator',
        (tester) async {
      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1, _notInstalledEditor],
        fakeLauncher: _FakeEditorLauncher(),
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);

      await tester.tap(find.byIcon(LucideIcons.chevronDown));
      await _settleTimers(tester);

      // The not-installed section header uses .toUpperCase() of the l10n key.
      expect(find.text('VS Code'), findsOneWidget);
      expect(find.text('Sublime Text'), findsOneWidget);
      // The "NOT INSTALLED" header appears (uppercased from l10n.ideNotInstalled).
      expect(
        find.textContaining('NOT INSTALLED', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('selected editor shows checkmark in menu', (tester) async {
      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1, _installedEditor2],
        selectedId: 'cursor',
        fakeLauncher: _FakeEditorLauncher(),
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);

      await tester.tap(find.byIcon(LucideIcons.chevronDown));
      await _settleTimers(tester);

      // The selected "Cursor" row has a check icon.
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
    });

    testWidgets('closing menu removes overlay', (tester) async {
      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1],
        fakeLauncher: _FakeEditorLauncher(),
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);

      await tester.tap(find.byIcon(LucideIcons.chevronDown));
      await _settleTimers(tester);
      expect(find.text('VS Code'), findsOneWidget);

      // Tap the scrim (the GestureDetector fills the Positioned.fill area).
      // Close by tapping the chevron again.
      await tester.tap(find.byIcon(LucideIcons.chevronDown));
      await _settleTimers(tester);
      expect(find.text('VS Code'), findsNothing);
    });

    testWidgets('no not-installed section when all editors are installed',
        (tester) async {
      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1, _installedEditor2],
        fakeLauncher: _FakeEditorLauncher(),
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);

      await tester.tap(find.byIcon(LucideIcons.chevronDown));
      await _settleTimers(tester);

      // Should not render the not-installed section header.
      expect(
        find.textContaining('NOT INSTALLED', findRichText: true),
        findsNothing,
      );
    });
  });

  // ── Effective editor selection ──────────────────────────────────────────

  group('effective editor', () {
    testWidgets('selects selectedId when installed', (tester) async {
      final fakeLauncher = _FakeEditorLauncher();
      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1, _installedEditor2],
        selectedId: 'cursor',
        fakeLauncher: fakeLauncher,
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);

      // Tap the main button (the first _HoverSegment). It should open cursor.
      await tester.tap(find.byIcon(LucideIcons.chevronDown));
      await _settleTimers(tester);

      // Tap on "Cursor" in the menu.
      await tester.tap(find.text('Cursor'));
      await tester.pump();
      await _settleTimers(tester);

      expect(fakeLauncher.lastOpenedEditorId, 'cursor');
    });

    testWidgets('falls back to priority when selectedId is not installed',
        (tester) async {
      final fakeLauncher = _FakeEditorLauncher();
      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1], // only VS Code
        selectedId: 'cursor', // not installed
        fakeLauncher: fakeLauncher,
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);

      // Tap the main button — should use VS Code (only installed, highest
      // priority) as the effective editor, not the uninstalled 'cursor'.
      final chevron = find.byIcon(LucideIcons.chevronDown);
      final buttonCenter = tester.getCenter(chevron);
      await tester.tapAt(Offset(buttonCenter.dx - 20, buttonCenter.dy));
      await tester.pump();
      await _settleTimers(tester);

      expect(fakeLauncher.lastOpenedEditorId, 'vscode');
    });

    testWidgets('falls back to first installed when no priority match',
        (tester) async {
      final fakeLauncher = _FakeEditorLauncher();
      const unknownEditor = IdeEditor(
        id: 'unknown-editor',
        displayName: 'Unknown',
        installed: true,
      );

      await tester.pumpWidget(_wrapWithEditors(
        editors: const [unknownEditor],
        fakeLauncher: fakeLauncher,
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);
      // The widget renders — the unknown editor is used as fallback.
      expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
    });
  });

  // ── Tap actions ─────────────────────────────────────────────────────────

  group('tap', () {
    testWidgets('tapping main button opens worktree then launches editor',
        (tester) async {
      final fakeLauncher = _FakeEditorLauncher();
      final fakeWorktree = _FakePrWorktreePort();

      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1],
        fakeLauncher: fakeLauncher,
        fakeWorktree: fakeWorktree,
      ));
      await _settleTimers(tester);

      // Tap the main button — the logo-containing _HoverSegment, left half of
      // the split button. Find it by looking for the Row children: first child
      // is the main button area. The logo falls back to a Lucide icon.
      // Tap the first clickable area (before the chevron).
      final chevron = find.byIcon(LucideIcons.chevronDown);
      // The main button is positioned before the chevron in the widget tree.
      // We can tap the area that surrounds the logo. Use a tap at the left
      // portion of the button.
      final buttonCenter = tester.getCenter(chevron);
      await tester.tapAt(Offset(buttonCenter.dx - 20, buttonCenter.dy));
      await tester.pump();
      await _settleTimers(tester);

      expect(fakeWorktree.ensureWorktreeCalls, 1);
      expect(fakeLauncher.lastOpenedEditorId, 'vscode');
      expect(fakeLauncher.lastOpenedPath, '/tmp/worktrees/pr-42');
    });

    testWidgets('tapping installed menu item selects and opens editor',
        (tester) async {
      final fakeLauncher = _FakeEditorLauncher();
      final fakeWorktree = _FakePrWorktreePort();

      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1, _installedEditor2],
        fakeLauncher: fakeLauncher,
        fakeWorktree: fakeWorktree,
      ));
      await _settleTimers(tester);

      // Open menu.
      await tester.tap(find.byIcon(LucideIcons.chevronDown));
      await _settleTimers(tester);

      // Tap "Cursor" in the menu.
      await tester.tap(find.text('Cursor'));
      await tester.pump();
      await _settleTimers(tester);

      expect(fakeWorktree.ensureWorktreeCalls, 1);
      expect(fakeLauncher.lastOpenedEditorId, 'cursor');
      expect(fakeLauncher.lastOpenedPath, '/tmp/worktrees/pr-42');
    });

    testWidgets('tapping not-installed menu item does nothing',
        (tester) async {
      final fakeLauncher = _FakeEditorLauncher();
      final fakeWorktree = _FakePrWorktreePort();

      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1, _notInstalledEditor],
        fakeLauncher: fakeLauncher,
        fakeWorktree: fakeWorktree,
      ));
      await _settleTimers(tester);

      await tester.tap(find.byIcon(LucideIcons.chevronDown));
      await _settleTimers(tester);

      // Tap "Sublime Text" — it's disabled, should not trigger anything.
      await tester.tap(find.text('Sublime Text'));
      await tester.pump();
      await _settleTimers(tester);

      // Worktree should NOT have been called.
      expect(fakeWorktree.ensureWorktreeCalls, 0);
      expect(fakeLauncher.lastOpenedEditorId, isNull);
    });

    testWidgets('shows CircularProgressIndicator while preparing',
        (tester) async {
      final fakeLauncher = _FakeEditorLauncher();
      final fakeWorktree = _FakePrWorktreePort();

      // Hold the worktree operation open so _preparing stays true.
      final completer = Completer<String>();
      fakeWorktree._pendingWorktree = completer.future;

      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1],
        fakeLauncher: fakeLauncher,
        fakeWorktree: fakeWorktree,
      ));
      await _settleTimers(tester);

      // Tap main button.
      final chevron = find.byIcon(LucideIcons.chevronDown);
      final buttonCenter = tester.getCenter(chevron);
      await tester.tapAt(Offset(buttonCenter.dx - 20, buttonCenter.dy));

      // Pump a frame — _preparing should be true, showing spinner.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the worktree, let async ops finish.
      completer.complete('/tmp/worktrees/pr-42');
      await tester.pump();
      await _settleTimers(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error snackbar on launch failure', (tester) async {
      final fakeLauncher = _FakeEditorLauncher()..shouldThrow = true;
      final fakeWorktree = _FakePrWorktreePort();

      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1],
        fakeLauncher: fakeLauncher,
        fakeWorktree: fakeWorktree,
      ));
      await _settleTimers(tester);

      final chevron = find.byIcon(LucideIcons.chevronDown);
      final buttonCenter = tester.getCenter(chevron);
      await tester.tapAt(Offset(buttonCenter.dx - 20, buttonCenter.dy));
      await tester.pump();
      await _settleTimers(tester);

      // Toast should appear with error message.
      expect(find.textContaining("Couldn't open"), findsOneWidget);
      // After error, _preparing should be false again.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error snackbar on worktree failure', (tester) async {
      final fakeLauncher = _FakeEditorLauncher();
      final fakeWorktree = _FakePrWorktreePort()..shouldThrow = true;

      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1],
        fakeLauncher: fakeLauncher,
        fakeWorktree: fakeWorktree,
      ));
      await _settleTimers(tester);

      final chevron = find.byIcon(LucideIcons.chevronDown);
      final buttonCenter = tester.getCenter(chevron);
      await tester.tapAt(Offset(buttonCenter.dx - 20, buttonCenter.dy));
      await tester.pump();
      await _settleTimers(tester);

      // Toast should appear with error message.
      expect(find.textContaining("Couldn't open"), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Editor should NOT have been opened after worktree failure.
      expect(fakeLauncher.lastOpenedEditorId, isNull);
    });
  });

  // ── Multiple editors ────────────────────────────────────────────────────

  group('multiple editors', () {
    testWidgets('all installed editors appear as menu items', (tester) async {
      const extraEditor = IdeEditor(
        id: 'zed',
        displayName: 'Zed',
        installed: true,
      );

      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1, _installedEditor2, extraEditor],
        fakeLauncher: _FakeEditorLauncher(),
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);

      await tester.tap(find.byIcon(LucideIcons.chevronDown));
      await _settleTimers(tester);

      expect(find.text('VS Code'), findsOneWidget);
      expect(find.text('Cursor'), findsOneWidget);
      expect(find.text('Zed'), findsOneWidget);
    });
  });

  // ── Effective editor edge cases ─────────────────────────────────────────

  group('effective editor edge cases', () {
    testWidgets(
        'effective selects first installed when no priority match and no selectedId',
        (tester) async {
      final fakeLauncher = _FakeEditorLauncher();
      const unknownEditor = IdeEditor(
        id: 'unknown-editor',
        displayName: 'Unknown',
        installed: true,
      );

      await tester.pumpWidget(_wrapWithEditors(
        editors: const [unknownEditor],
        fakeLauncher: fakeLauncher,
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);

      // Tap the main button — the unknown editor should be used as effective
      // since no priority match exists and no selectedId is set.
      final chevron = find.byIcon(LucideIcons.chevronDown);
      final buttonCenter = tester.getCenter(chevron);
      await tester.tapAt(Offset(buttonCenter.dx - 20, buttonCenter.dy));
      await tester.pump();
      await _settleTimers(tester);

      expect(fakeLauncher.lastOpenedEditorId, 'unknown-editor');
    });
  });

  // ── Chevron icon ─────────────────────────────────────────────────────────

  group('chevrondown icon', () {
    testWidgets('split button renders logo area for installed editor',
        (tester) async {
      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1],
        fakeLauncher: _FakeEditorLauncher(),
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);

      // The main button area renders the logo — with no bundled logos, VS Code
      // falls back to the LucideIcons.code glyph.
      expect(find.byIcon(LucideIcons.code), findsOneWidget);
    });
  });

  // ── Hover states ─────────────────────────────────────────────────────────

  group('hover states', () {
    testWidgets('chevrondown icon is visible', (tester) async {
      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor1],
        fakeLauncher: _FakeEditorLauncher(),
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);

      expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
    });
  });

  // ── Menu icon display ────────────────────────────────────────────────────

  group('menu icon display', () {
    testWidgets('cursor editor renders with chevron visible', (tester) async {
      await tester.pumpWidget(_wrapWithEditors(
        editors: const [_installedEditor2], // cursor
        fakeLauncher: _FakeEditorLauncher(),
        fakeWorktree: _FakePrWorktreePort(),
      ));
      await _settleTimers(tester);

      // Button renders (chevron visible means editor detected and rendered).
      expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
    });
  });
}
