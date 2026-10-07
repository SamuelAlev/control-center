import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/conversation_pane.dart'
    show SpaceProvisioningBanner;
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/recent_files_provider.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_quick_open.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/active_workspace.dart';
import '../../../../../helpers/fake_rpc_client.dart';
import '../../../../../helpers/test_wrap.dart';

const _ws = kTestWorkspaceId;
const _spaceId = 'pr-space-412';

PullRequest _pr() => PullRequest(
  id: 412,
  number: 412,
  title: 'Cap eval-run token budget per model family',
  body: '',
  state: PrState.open,
  isDraft: false,
  author: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  repoFullName: 'helix/evalkit',
  htmlUrl: 'https://example.invalid/helix/evalkit/pull/412',
);

Space _space(SpaceProvisioningStatus status) => Space(
  id: _spaceId,
  name: 'Review: PR #412',
  workspaceId: _ws,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  provisioningStatus: status,
);

/// The PR page's ⌘P picker waits out the PR worktree's checkout: the field is
/// disabled under the provisioning strip until the space is ready, then it
/// enables and takes focus. Recents are the PR space's own.
void main() {
  late FakeRpcHost host;
  late Completer<String> spaceId;
  late StreamController<List<Space>> spaces;
  late List<String?> searchedSpaces;

  setUp(() {
    host = FakeRpcHost();
    searchedSpaces = [];
    host.onCall = (op, args) {
      if (op == 'repos.searchFiles') {
        searchedSpaces.add(args['space_id'] as String?);
        return {
          'hits': [
            {
              'absolutePath': '/w/lib/main.dart',
              'relativePath': 'lib/main.dart',
              'rootPath': '/w',
              'isDirectory': false,
              'score': 1.0,
              'repoId': 'r1',
            },
          ],
          'has_more': false,
        };
      }
      return const {};
    };
  });

  // Not awaited: a single-subscription controller nobody listened to never
  // completes its close.
  tearDown(() => unawaited(spaces.close()));

  Future<void> pump(WidgetTester tester, {AppPreferences? prefs}) async {
    // Made here, inside the test's fake-async zone, so `pump` flushes their
    // callbacks; made in setUp they would complete in a zone nothing drives.
    spaceId = Completer<String>();
    // Buffered: the space list is only watched once the space id resolves.
    spaces = StreamController<List<Space>>();
    // Outside testWrap's own scope: a provider this scope does not override
    // (the recent-files list) resolves in the root, so its preferences must be
    // overridden there too.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          rpcClientProvider.overrideWithValue(host.client()),
          appPreferencesProvider.overrideWithValue(
            prefs ?? AppPreferences.inMemory({}),
          ),
          prSpaceProvider.overrideWith((ref, _) => spaceId.future),
          workspaceSpacesProvider.overrideWith((ref, _) => spaces.stream),
        ],
        child: testWrap(PrQuickOpenPanel(workspaceId: _ws, pr: _pr())),
      ),
    );
    await tester.pump();
  }

  // The spinner never settles, so step a few frames instead: the space id
  // resolves, the space list subscribes, its event lands, the panel rebuilds.
  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  CcTextField field(WidgetTester tester) =>
      tester.widget<CcTextField>(find.byType(CcTextField));

  testWidgets('is disabled with a preparing line while the space resolves', (
    tester,
  ) async {
    await pump(tester);

    expect(field(tester).enabled, isFalse);
    expect(find.text('Preparing workspace…'), findsOneWidget);
    // Nothing to list over a worktree that does not exist yet.
    expect(find.text('No recently opened files'), findsNothing);
  });

  testWidgets('shows the provisioning strip while the checkout runs, then '
      'enables and focuses the field', (tester) async {
    await pump(tester);
    spaceId.complete(_spaceId);
    spaces.add([_space(SpaceProvisioningStatus.provisioning)]);
    await frames(tester);

    expect(find.byType(SpaceProvisioningBanner), findsOneWidget);
    expect(field(tester).enabled, isFalse);

    spaces.add([_space(SpaceProvisioningStatus.ready)]);
    await frames(tester);

    expect(find.byType(SpaceProvisioningBanner), findsNothing);
    expect(find.text('Preparing workspace…'), findsNothing);
    expect(field(tester).enabled, isTrue);
    expect(field(tester).focusNode!.hasFocus, isTrue);
    expect(find.text('No recently opened files'), findsOneWidget);
  });

  testWidgets('stays disabled for a space the stream has not delivered', (
    tester,
  ) async {
    // `pr.ensureSpace` answered, but the space list has no row for it yet —
    // the moment `spaceProvisioningStatusProvider` would call ready.
    await pump(tester);
    spaceId.complete(_spaceId);
    spaces.add(const []);
    await frames(tester);

    expect(field(tester).enabled, isFalse);
    expect(find.text('Preparing workspace…'), findsOneWidget);
  });

  testWidgets('lists this PR space recents and searches its worktree only', (
    tester,
  ) async {
    final prefs = AppPreferences.inMemory({
      '$recentFilesKeyPrefix$_ws': jsonEncode({
        _spaceId: [
          {'r': 'r1', 'p': 'README.md'},
        ],
        'another-space': [
          {'r': 'r1', 'p': 'other.dart'},
        ],
      }),
    });
    await pump(tester, prefs: prefs);
    spaceId.complete(_spaceId);
    spaces.add([_space(SpaceProvisioningStatus.ready)]);
    await frames(tester);

    expect(find.text('README.md'), findsOneWidget);
    expect(find.text('other.dart'), findsNothing);

    await tester.enterText(find.byType(CcTextField), 'main');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(searchedSpaces, [_spaceId]);
    expect(find.text('main.dart'), findsOneWidget);
  });
}
