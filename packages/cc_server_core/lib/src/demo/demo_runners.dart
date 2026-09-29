import 'dart:io';

import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_domain/features/settings/domain/repositories/adapter_repository.dart';
import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_infra/cc_infra.dart' show ClaudeAccountStore;

/// Answers `adapter.detectOne` / `adapter.detectAll` without looking at the host.
///
/// The real detector short-circuits the built-in harness, then shells out to
/// `<cli> --version` for everything else. A public demo must not spawn a
/// process to decorate Settings, and it must not report a binary that happens
/// to be on the box. Both catalogued runners are reported installed so the
/// agent form can offer them; any other id is not found, including one whose
/// `cliName` a caller tried to point at a local executable.
class DemoAdapterRepository implements AdapterRepository {
  /// Creates the repository.
  const DemoAdapterRepository();

  @override
  Future<DetectedAdapter> detectOne(Adapter adapter) async {
    if (adapter.id != builtInAdapter.id && adapter.id != 'claude-code') {
      return DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.notFound,
      );
    }
    return DetectedAdapter(
      adapter: adapter,
      status: DetectionStatus.found,
      capabilities: capabilitiesForAdapter(adapter.id),
      // The harness has no binary. Claude Code is reported without a path so
      // the pane does not imply a CLI the host was probed for.
      version: adapter.id == builtInAdapter.id ? 'built-in' : '2.1.0',
    );
  }

  @override
  Future<List<DetectedAdapter>> detectAll(List<Adapter> adapters) async => [
    for (final adapter in adapters) await detectOne(adapter),
  ];
}

/// The Claude Code logins a demo visitor sees on the runner.
///
/// Helix's cast, signed in, with no credential behind them. Ids stay inside
/// `[a-z0-9-]` because a real account id is also a directory name; these never
/// become directories.
const List<ClaudeAccount> kDemoClaudeAccounts = [
  ClaudeAccount(
    id: 'maya',
    label: 'Maya Okonkwo',
    email: 'maya.okonkwo@helix.example',
    orgName: 'Helix',
    subscriptionType: 'max',
    loggedIn: true,
    isDefault: true,
  ),
  ClaudeAccount(
    id: 'diego',
    label: 'Diego Ferrer',
    email: 'diego.ferrer@helix.example',
    orgName: 'Helix',
    subscriptionType: 'max',
    loggedIn: true,
  ),
  ClaudeAccount(
    id: 'priya',
    label: 'Priya Raman',
    email: 'priya.raman@helix.example',
    orgName: 'Helix',
    subscriptionType: 'pro',
    loggedIn: true,
  ),
];

/// A [ClaudeAccountStore] that never touches disk, the keychain, or `claude`.
///
/// The catalog's `claude_accounts.list` calls `listWithStatus`, which on the
/// real store syncs the macOS keychain and runs `claude auth status`. Both are
/// wrong on a public demo: the first can surface the operator's own login, the
/// second is a process spawn. Mutations stay denied at the op layer; if one
/// is reached anyway, the process seam throws rather than executing.
class DemoClaudeAccountStore extends ClaudeAccountStore {
  /// Creates the store.
  DemoClaudeAccountStore()
    : super(dataDir: '', claudeHome: _noHome, runProcess: _refuse);

  static String? _noHome() => null;

  static Future<ProcessResult> _refuse(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  }) => Future<ProcessResult>.error(
    StateError(
      'The demo must not spawn a runner CLI. Claude Code accounts are fictional.',
    ),
  );

  @override
  Future<List<ClaudeAccount>> list() async => kDemoClaudeAccounts;

  @override
  Future<List<ClaudeAccount>> listWithStatus() async => kDemoClaudeAccounts;

  @override
  String configDirFor(String accountId) => 'demo-claude/$accountId';
}

/// Fictional plan usage for one demo Claude Code account.
///
/// [configDir] is the value [DemoClaudeAccountStore.configDirFor] returns.
/// An unknown directory answers null, the same as a probe that found nothing,
/// and never opens a socket.
Future<Map<String, dynamic>?> demoClaudeAccountUsage(String configDir) async {
  final id = configDir.split('/').last;
  final session = switch (id) {
    'maya' => 0.38,
    'diego' => 0.71,
    'priya' => 0.22,
    _ => null,
  };
  if (session == null) {
    return null;
  }
  final now = DateTime.now().toUtc();
  return SubscriptionUsage(
    providerId: 'claude',
    displayName: 'Claude Code (demo)',
    status: SubscriptionStatus.ok,
    fetchedAt: now,
    accountId: id,
    windows: [
      SubscriptionWindow(
        id: '5h',
        label: 'Session',
        usedFraction: session,
        resetsAt: now.add(const Duration(hours: 3)),
      ),
      SubscriptionWindow(
        id: '7d',
        label: 'Weekly',
        usedFraction: (session * 0.6).clamp(0.05, 0.9),
        resetsAt: now.add(const Duration(days: 4)),
      ),
    ],
  ).toJson();
}
