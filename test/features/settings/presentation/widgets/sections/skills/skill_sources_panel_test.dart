import 'dart:async';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/skills/skill_sources_panel.dart';
import 'package:control_center/features/settings/providers/skill_source_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A RemoteRpcClient stand-in — the fake control below overrides everything.
class _NoopRpcClient implements RemoteRpcClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stand-in for the sources control with canned catalog data.
class FakeSkillSourceControl extends RpcSkillSourceControl {
  FakeSkillSourceControl() : super(_NoopRpcClient());

  List<SkillSourceDto> sources = [];
  Map<String, List<SourceSkillDto>> listingsBySource = {};
  Map<String, SourceSkillDetailDto> detailByPath = {};
  SkillInstallResultDto installResult = const SkillInstallResultDto(
    status: 'installed',
    slug: 'pdf',
  );

  String? lastInstallPath;
  String? lastUninstallSlug;
  bool lastAllowQuarantineOverride = false;

  @override
  Future<List<SkillSourceDto>> listSources() async => sources;

  @override
  Future<(SkillSourceDto, bool)> addSource(String url) async =>
      (sources.first, false);

  @override
  Future<void> removeSource(String sourceId) async {}

  final List<String> listingCalls = [];
  @override
  Future<List<SourceSkillDto>> listings(String sourceId) async {
    listingCalls.add(sourceId);
    return listingsBySource[sourceId] ?? const [];
  }

  @override
  Future<SourceSkillDetailDto> detail(String sourceId, String path) async =>
      detailByPath[path] ??
      const SourceSkillDetailDto(
        ref: 'abc',
        fileCount: 1,
        readme: '# readme',
        scan: SourceSkillScan(
          verdict: SkillScanVerdict.pass,
          llmReviewed: false,
          capabilities: [],
          requiredActionClasses: [],
          findings: [],
        ),
      );

  @override
  Future<SkillInstallResultDto> install(
    String sourceId,
    String path, {
    bool allowQuarantineOverride = false,
  }) async {
    lastInstallPath = path;
    lastAllowQuarantineOverride = allowQuarantineOverride;
    return installResult;
  }

  @override
  Future<void> uninstall(String slug) async {
    lastUninstallSlug = slug;
  }
}

class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _TestActiveWorkspaceNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

late AppPreferences prefs;
late FakeSkillSourceControl control;

const _source = SkillSourceDto(
  id: 'src-1',
  owner: 'octo',
  repo: 'skills',
  url: 'https://github.com/octo/skills',
  description: 'A repo of skills',
  starCount: 12,
  skillCount: 2,
);

const _pdf = SourceSkillDto(
  slug: 'pdf',
  name: 'PDF skills',
  description: 'Work with PDFs',
  path: 'skills/pdf/SKILL.md',
  installed: false,
  slugTaken: false,
  updateAvailable: false,
);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    prefs = AppPreferences.inMemory();
    control = FakeSkillSourceControl();
    control.sources = const [_source];
    control.listingsBySource = {
      'src-1': const [
        _pdf,
        SourceSkillDto(
          slug: 'xlsx',
          name: 'XLSX skills',
          description: 'Spreadsheets',
          path: 'skills/xlsx/SKILL.md',
          installed: true,
          slugTaken: false,
          updateAvailable: true,
        ),
      ],
    };
  });

  /// The read families resolve to completed futures, pre-warmed BEFORE the
  /// panel mounts: under fake-async an immediately-completing FutureProvider
  /// first watched from a subtree that mounts mid-test never delivers its
  /// completion notification (a real host's GitHub round trips take real time,
  /// so production is unaffected). [detailPaths] pre-warms the record-keyed
  /// detail family for tests that open a skill.
  Future<void> pumpPanel(
    WidgetTester tester, {
    List<String> detailPaths = const [],
  }) async {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(prefs),
        workspacesProvider.overrideWith(
          (ref) => Stream.value(const <Workspace>[]),
        ),
        skillSourceControlProvider.overrideWithValue(control),
        skillSourcesProvider.overrideWith(
          (ref, workspaceId) => Future.value(control.sources),
        ),
        skillSourceListingsProvider.overrideWith(
          (ref, sourceId) =>
              Future.value(control.listingsBySource[sourceId] ?? const []),
        ),
        skillSourceDetailProvider.overrideWith(
          (ref, key) => Future.value(
            control.detailByPath[key.path] ??
                const SourceSkillDetailDto(
                  ref: 'abc',
                  fileCount: 1,
                  readme: '# readme',
                  scan: SourceSkillScan(
                    verdict: SkillScanVerdict.pass,
                    llmReviewed: false,
                    capabilities: [],
                    requiredActionClasses: [],
                    findings: [],
                  ),
                ),
          ),
        ),
        activeWorkspaceIdProvider.overrideWith(
          () => _TestActiveWorkspaceNotifier('ws-1'),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Warm the read providers so their futures are already resolved when
    // the panel's first build subscribes (see the doc comment above).
    await Future.wait([
      container.read(skillSourcesProvider('ws-1').future),
      container.read(skillSourceListingsProvider('src-1').future),
      for (final path in detailPaths)
        container.read(
          skillSourceDetailProvider((sourceId: 'src-1', path: path)).future,
        ),
    ]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: CcTheme(
          data: CcThemeData.light(),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CcToastScope(
              child: Scaffold(body: SkillSourcesPanel(workspaceId: 'ws-1')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('rail lists sources, grid lists their skills', (tester) async {
    await pumpPanel(tester);

    // The rail row and the selected source's header both carry the name.
    expect(find.text('octo/skills'), findsNWidgets(2));

    expect(find.text('PDF skills'), findsOneWidget);
    expect(find.text('XLSX skills'), findsOneWidget);
    // Install-state badges surface on the grid cards.
    expect(find.text('Update available'), findsOneWidget);
  });

  testWidgets('the filter narrows the grid by name, description and slug', (
    tester,
  ) async {
    await pumpPanel(tester);

    expect(find.text('PDF skills'), findsOneWidget);
    expect(find.text('XLSX skills'), findsOneWidget);

    // Filter by name fragment.
    await tester.enterText(find.byType(CcTextField), 'xls');
    await tester.pump();
    expect(find.text('PDF skills'), findsNothing);
    expect(find.text('XLSX skills'), findsOneWidget);

    // Filter by description fragment ('Work with PDFs').
    await tester.enterText(find.byType(CcTextField), 'spreadsheets');
    await tester.pump();
    expect(find.text('XLSX skills'), findsOneWidget);

    // A filter matching nothing shows the no-matches state.
    await tester.enterText(find.byType(CcTextField), 'nope');
    await tester.pump();
    expect(find.text('No skills match your filter.'), findsOneWidget);
  });

  testWidgets('clicking a skill renders the README and install action', (
    tester,
  ) async {
    control.detailByPath = {
      'skills/pdf/SKILL.md': const SourceSkillDetailDto(
        ref: 'abc123',
        fileCount: 3,
        readme: '# The PDF skill\n\nIt does PDF things.',
        scan: SourceSkillScan(
          verdict: SkillScanVerdict.warn,
          llmReviewed: true,
          capabilities: ['writes files'],
          requiredActionClasses: ['fileWriteOutsideWorktree'],
          findings: [],
        ),
      ),
    };
    await pumpPanel(tester, detailPaths: const ['skills/pdf/SKILL.md']);

    await tester.tap(find.text('PDF skills'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The README renders as markdown (a heading + body text).
    expect(find.text('The PDF skill'), findsOneWidget);
    expect(find.text('It does PDF things.'), findsOneWidget);
    // The scan preview + capabilities surface.
    expect(find.text('Warning'), findsOneWidget);
    expect(find.text('writes files'), findsOneWidget);

    await tester.tap(find.text('Install'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(control.lastInstallPath, 'skills/pdf/SKILL.md');
    expect(control.lastAllowQuarantineOverride, isFalse);
    // Success toast names the installed skill.
    expect(find.text('Skill "pdf" installed.'), findsOneWidget);
  });

  testWidgets('a quarantine verdict requires the override tick to install', (
    tester,
  ) async {
    control.detailByPath = {
      'skills/pdf/SKILL.md': const SourceSkillDetailDto(
        ref: 'abc123',
        fileCount: 1,
        readme: '# risky',
        scan: SourceSkillScan(
          verdict: SkillScanVerdict.quarantine,
          llmReviewed: false,
          capabilities: [],
          requiredActionClasses: [],
          findings: [
            SkillScanFinding(
              ruleId: 'curl_pipe_shell',
              verdict: SkillScanVerdict.quarantine,
              message: 'curl piped into sh',
              file: 'SKILL.md',
              line: 3,
            ),
          ],
        ),
      ),
    };
    await pumpPanel(tester, detailPaths: const ['skills/pdf/SKILL.md']);
    await tester.tap(find.text('PDF skills'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Quarantined'), findsOneWidget);
    expect(find.text('curl piped into sh'), findsOneWidget);
    // Install is disabled until the override checkbox is ticked.
    final installButton = tester.widget<CcButton>(
      find.ancestor(
        of: find.text('Install'),
        matching: find.byType(CcButton),
      ),
    );
    expect(installButton.onPressed, isNull);

    await tester.tap(find.text('I understand the risk — install anyway'));
    await tester.pump();
    final armedButton = tester.widget<CcButton>(
      find.ancestor(
        of: find.text('Install'),
        matching: find.byType(CcButton),
      ),
    );
    expect(armedButton.onPressed, isNotNull);
  });

  testWidgets('installed skill offers update + uninstall', (tester) async {
    await pumpPanel(tester, detailPaths: const ['skills/xlsx/SKILL.md']);
    await tester.tap(find.text('XLSX skills'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Uninstall'), findsOneWidget);

    await tester.tap(find.text('Uninstall'));
    await tester.pump();
    // Confirm dialog → destructive confirm.
    await tester.tap(find.text('Uninstall').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(control.lastUninstallSlug, 'xlsx');
    expect(find.text('Skill "xlsx" uninstalled.'), findsOneWidget);
  });
}
