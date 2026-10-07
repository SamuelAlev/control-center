import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_infra/src/claude_accounts/claude_long_lived_token.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// The host operator's home, the default source of managed-settings consent.
String? _hostClaudeHome() => Platform.environment['HOME'];

/// Owns Claude Code account dirs under `<dataDir>/claude-accounts/` plus
/// sidecar `accounts.json` (dir IS the account — one place to delete).
///
/// Never performs login: operator runs `claude auth login` with
/// `CLAUDE_CONFIG_DIR` set, or pastes the token `claude setup-token` printed
/// (see [setLongLivedToken]). Does not mint Claude Code tokens from another
/// app, and never copies the operator's own `~/.claude` login: two copies of
/// one rotating refresh token sign each other out.
class ClaudeAccountStore {
  /// Creates a store rooted at [dataDir].
  ///
  /// [claudeExecutable] is resolved on the host at probe time; tests override
  /// it. [runProcess] is the process seam — the default shells out for real.
  ClaudeAccountStore({
    required String dataDir,
    this.claudeExecutable = 'claude',
    Future<ProcessResult> Function(
      String executable,
      List<String> arguments, {
      Map<String, String>? environment,
    })?
    runProcess,
    this.probeUsage,
    this.now = DateTime.now,
    this.claudeHome = _hostClaudeHome,
  }) : _root = p.join(dataDir, 'claude-accounts'),
       _runProcess = runProcess ?? _defaultRunProcess;

  /// Reads one account's tightest plan window, by config dir.
  ///
  /// Injected rather than constructed so the store stays free of an HTTP
  /// client, and so tests decide what "spent" means without a network. Null
  /// (no probe wired) makes every signed-in account look available and leaves
  /// the observed-429 cooldown as the only headroom signal — degraded, but
  /// never wrong in the direction that matters.
  final Future<({double usedFraction, DateTime? resetsAt})?> Function(
    String configDir,
  )?
  probeUsage;

  /// Clock seam, so cooldown expiry is testable.
  final DateTime Function() now;

  /// The operator's own Claude home, source of the managed-settings consent
  /// this store propagates. A seam because `Platform.environment` cannot be
  /// overridden in-process, and a test that read the real HOME would pass or
  /// fail on whether the machine running it happens to have approved settings.
  final String? Function() claudeHome;

  /// How long a usage reading is reused.
  ///
  /// The endpoint rate-limits callers aggressively (see
  /// `SubscriptionUsageService`), and a dispatch path that probed it per run
  /// would get itself throttled and then read every account as unavailable —
  /// the rotation starving on its own telemetry.
  static const Duration usageCacheTtl = Duration(seconds: 60);

  final Map<String, ({DateTime at, double used, DateTime? resetsAt})>
  _usageCache = {};

  final String _root;

  /// The Claude Code binary name (or absolute path).
  final String claudeExecutable;

  final Future<ProcessResult> Function(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  })
  _runProcess;

  static Future<ProcessResult> _defaultRunProcess(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  }) => Process.run(
    executable,
    arguments,
    environment: environment,
    includeParentEnvironment: true,
    runInShell: false,
  );

  /// How long a `claude auth status` probe may take. The CLI is a ~280MB
  /// single-file binary and a cold start is slow, but an unbounded probe would
  /// hang the settings screen and, worse, the dispatch preflight.
  static const Duration statusTimeout = Duration(seconds: 25);

  /// The accounts root. Created on demand.
  String get root => _root;

  /// The macOS Keychain service Claude Code stores [configDir]'s credential
  /// under.
  ///
  /// **`CLAUDE_CONFIG_DIR` does not move the credential to a file.** It
  /// namespaces the KEYCHAIN service by the first 8 hex digits of
  /// `sha256(configDir)` — so `claude auth login` against an account directory
  /// writes `Claude Code-credentials-ec489220`, and the directory itself ends
  /// up holding only `.claude.json`. That is why signing in and then
  /// dispatching still failed: the settings list reads the keychain
  /// UNSANDBOXED and shows the account signed in, while the run reads it from
  /// inside a profile that denies `~/Library/Keychains` and finds nothing.
  ///
  /// The unsuffixed `Claude Code-credentials` is the operator's own
  /// no-config-dir login, which this store deliberately never reads.
  static String keychainServiceFor(String configDir) =>
      'Claude Code-credentials-'
      '${sha256.convert(utf8.encode(configDir)).toString().substring(0, 8)}';

  File get _registryFile => File(p.join(_root, 'accounts.json'));

  /// Absolute `CLAUDE_CONFIG_DIR` for [accountId].
  String configDirFor(String accountId) => p.join(_root, accountId);

  /// Every registered account, in creation order, WITHOUT probing the CLI.
  ///
  /// Cheap and synchronous-ish: the dispatch path needs to resolve a config dir
  /// on every run and must not pay for a subprocess to do it.
  Future<List<ClaudeAccount>> list() async {
    final file = _registryFile;
    if (!file.existsSync()) {
      return const [];
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) {
        return const [];
      }
      return [
        for (final row in decoded)
          if (row is Map<String, dynamic>) ClaudeAccount.fromJson(row),
      ];
    } on Object catch (e) {
      // A corrupt registry must not take the server down, and it must not
      // silently look like "no accounts" either — that would send the operator
      // to re-login instead of to the file.
      CcInfraLog.warning('ClaudeAccountStore: could not read ${file.path}: $e');
      return const [];
    }
  }

  /// Every registered account with its live CLI status filled in.
  ///
  /// Probes run concurrently — a settings screen with four accounts should not
  /// wait four cold starts in series.
  Future<List<ClaudeAccount>> listWithStatus() async {
    final at = now();
    final accounts = await list();
    final probed = await Future.wait(
      accounts.map((a) async {
        // Mirror first, so what Settings reports is what a RUN would find.
        // Without it this list reads the keychain unsandboxed and happily shows
        // three signed-in accounts while every dispatch fails signed-out — the
        // exact disagreement that made the bug so confusing.
        await syncCredentialFromKeychain(a.id);
        final expiry = credentialExpiry(a.id);
        final dir = configDirFor(a.id);
        final tokenSavedAt = claudeLongLivedTokenSavedAt(dir);
        final probed = (await _withStatus(a)).copyWith(
          credentialExpiresAt: expiry,
          clearCredentialExpiresAt: expiry == null,
          usesLongLivedToken: readClaudeLongLivedToken(dir) != null,
          longLivedTokenSavedAt: tokenSavedAt,
          clearLongLivedTokenSavedAt: tokenSavedAt == null,
        );
        // `claude auth status` reads the credential's SHAPE, not whether the
        // provider still honours it, so it keeps saying "logged in" about a
        // directory whose token expired hours ago. Fold in the failure a run
        // actually observed, or Settings and dispatch disagree again: three
        // green rows and every run failing on one of them.
        if (_authFailurePending(probed, dir)) {
          return probed.copyWith(
            loggedIn: false,
            statusError:
                probed.authFailedReason ??
                'a run failed to authenticate on this account',
          );
        }
        // The same disagreement, caught BEFORE anything fails — but only for a
        // credential that cannot renew itself. An expired access token with a
        // refresh token beside it is the normal state of any account nobody
        // used overnight; the CLI renews it on the next run, so reporting that
        // as signed out would mark a healthy roster red every morning. Without
        // a refresh token nothing can repair it, so it is reported dead here
        // rather than after a run 401s — which also stops the usage probe (the
        // caller skips it for a logged-out account) from asking the endpoint a
        // question only re-authentication can answer.
        if (credentialBeyondRepair(a.id, at)) {
          return probed.copyWith(loggedIn: false, clearAuthFailure: true);
        }
        return probed.copyWith(clearAuthFailure: true);
      }),
    );
    // Adopt a learned email into the STORED label, once. Otherwise the name
    // only exists for as long as a probe is in hand: the picker (which does
    // not probe) would keep showing "Account 2" while Settings showed the
    // address, and the two surfaces would disagree about the same account.
    //
    // The same pass drops an auth failure that a newer credential has already
    // repaired, so the record does not outlive the problem it describes.
    final dirty = [
      for (var i = 0; i < accounts.length; i++)
        if (probed[i].label != accounts[i].label ||
            probed[i].authFailedAt != accounts[i].authFailedAt)
          i,
    ];
    if (dirty.isNotEmpty) {
      await _writeRegistry([
        for (var i = 0; i < accounts.length; i++)
          if (probed[i].authFailedAt == null)
            accounts[i].copyWith(label: probed[i].label, clearAuthFailure: true)
          else
            accounts[i].copyWith(label: probed[i].label),
      ]);
    }
    return probed;
  }

  /// Creates a new, logged-out account directory and registers it.
  ///
  /// The caller follows up by running `claude auth login` in that directory —
  /// see [loginCommand].
  Future<ClaudeAccount> create({String? label}) async {
    final accounts = await list();
    final id = _mintId(label, taken: {for (final a in accounts) a.id});
    Directory(configDirFor(id)).createSync(recursive: true);
    await _chmod700(configDirFor(id));
    final account = ClaudeAccount(
      id: id,
      label: (label == null || label.trim().isEmpty)
          ? 'Account ${accounts.length + 1}'
          : label.trim(),
      // The first account created becomes the default; otherwise nothing
      // changes hands, because silently moving the default when a second
      // account appears would re-point every existing agent.
      isDefault: accounts.isEmpty,
    );
    await _writeRegistry([...accounts, account]);
    return account;
  }

  /// Prepares [accountId]'s config dir for a headless run in [workingDirectory].
  ///
  /// Claude Code gates both behind interactive dialogs (per config dir; the
  /// operator's `~/.claude` acceptance does not apply to server account dirs):
  /// - Workspace trust: until trusted, project `permissions.allow` is ignored
  ///   (silent under-permission, not a hard fail).
  /// - Managed-settings consent (`remote-settings-consent.json`): unapproved →
  ///   headless exit 1. Copied from the operator's `~/.claude` only — never
  ///   synthesised (propagates a human decision + settings hash).
  /// Best-effort: failure degrades the run, does not stop it.
  Future<void> prepareForRun({
    required String accountId,
    required String workingDirectory,
  }) async {
    final dir = configDirFor(accountId);
    if (!Directory(dir).existsSync() || workingDirectory.isEmpty) {
      return;
    }
    try {
      _trustWorkspace(dir, workingDirectory);
    } catch (e) {
      CcInfraLog.warning(
        'claude accounts: could not trust $workingDirectory '
        'for $accountId: $e',
      );
    }
    try {
      _copyManagedSettingsConsent(dir);
    } catch (e) {
      CcInfraLog.warning(
        'claude accounts: could not propagate managed-settings consent to '
        '$accountId: $e',
      );
    }
    try {
      _suppressCliAttribution(dir);
    } catch (e) {
      CcInfraLog.warning(
        'claude accounts: could not suppress CLI attribution for '
        '$accountId: $e',
      );
    }
  }

  /// Marks [workingDirectory] trusted in this config dir's `.claude.json`.
  void _trustWorkspace(String configDir, String workingDirectory) {
    final file = File(p.join(configDir, '.claude.json'));
    final Map<String, dynamic> config;
    if (file.existsSync()) {
      final decoded = jsonDecode(file.readAsStringSync());
      // A `.claude.json` that is not an object is the CLI's to repair, not
      // ours to overwrite — it holds the account's credentials pointer.
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      config = decoded;
    } else {
      config = <String, dynamic>{};
    }
    final projects = config['projects'];
    final map = projects is Map<String, dynamic>
        ? projects
        : <String, dynamic>{};
    final existing = map[workingDirectory];
    final entry = existing is Map<String, dynamic>
        ? existing
        : <String, dynamic>{};
    if (entry['hasTrustDialogAccepted'] == true) {
      return; // Already trusted; leave the file alone.
    }
    entry['hasTrustDialogAccepted'] = true;
    map[workingDirectory] = entry;
    config['projects'] = map;
    file.writeAsStringSync(jsonEncode(config), flush: true);
  }

  /// Copies the operator's managed-settings consent into this config dir.
  void _copyManagedSettingsConsent(String configDir) {
    final home = claudeHome();
    if (home == null || home.isEmpty) {
      return;
    }
    final source = File(
      p.join(home, '.claude', 'remote-settings-consent.json'),
    );
    if (!source.existsSync()) {
      return;
    }
    final target = File(p.join(configDir, 'remote-settings-consent.json'));
    // Re-copied when the operator's record is newer: an org that changes its
    // settings invalidates the old hash, and the human re-approves once in
    // their own CLI rather than once per account here.
    if (target.existsSync() &&
        !source.lastModifiedSync().isAfter(target.lastModifiedSync())) {
      return;
    }
    source.copySync(target.path);
  }

  /// Seeds `attribution: {commits: false, pullRequests: false}` into this
  /// config dir's `settings.json`.
  ///
  /// `CLAUDE_CONFIG_DIR` makes this dir's `settings.json` the CLI's user-scope
  /// settings file — the operator's `~/.claude/settings.json` never reaches a
  /// pooled run, so the CLI's built-in commit/PR attribution fires on stock
  /// defaults (`Co-Authored-By: Claude …` trailers). Control Center performs
  /// its own attribution (git identity env + co-author trailer), so the CLI's
  /// is suppressed here rather than mirrored from home. The `attribution`
  /// block is used, not the deprecated `includeCoAuthoredBy` key.
  ///
  /// An `attribution` key already present in the file wins — an operator who
  /// customized attribution in an account dir has said their piece, and a
  /// `settings.json` that is not a JSON object is the CLI's to repair, not
  /// ours to overwrite.
  void _suppressCliAttribution(String configDir) {
    const block = {'commits': false, 'pullRequests': false};
    final file = File(p.join(configDir, 'settings.json'));
    if (!file.existsSync()) {
      file.writeAsStringSync(jsonEncode({'attribution': block}), flush: true);
      return;
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    if (decoded.containsKey('attribution')) {
      return;
    }
    decoded['attribution'] = block;
    file.writeAsStringSync(jsonEncode(decoded), flush: true);
  }

  /// Renames [accountId].
  Future<void> rename(String accountId, String label) async {
    final accounts = await list();
    await _writeRegistry([
      for (final a in accounts)
        if (a.id == accountId) a.copyWith(label: label.trim()) else a,
    ]);
  }

  /// Makes [accountId] the account unattributed dispatches use.
  Future<void> setDefault(String accountId) async {
    final accounts = await list();
    if (!accounts.any((a) => a.id == accountId)) {
      return;
    }
    await _writeRegistry([
      for (final a in accounts) a.copyWith(isDefault: a.id == accountId),
    ]);
  }

  /// Logs the account out (best effort) and deletes its directory.
  ///
  /// The logout runs first and its failure is not fatal: the directory is the
  /// credential, so removing it revokes local access either way. Doing it in
  /// the other order would leave a live refresh token in a directory we then
  /// delete without telling Anthropic.
  Future<void> remove(String accountId) async {
    final accounts = await list();
    final target = accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => const ClaudeAccount(id: '', label: ''),
    );
    if (target.id.isEmpty) {
      return;
    }
    try {
      await _runProcess(
        claudeExecutable,
        const ['auth', 'logout'],
        environment: {'CLAUDE_CONFIG_DIR': configDirFor(accountId)},
      ).timeout(statusTimeout);
    } on Object catch (e) {
      CcInfraLog.warning(
        'ClaudeAccountStore: `claude auth logout` failed for $accountId '
        '(deleting the directory anyway): $e',
      );
    }
    final dir = Directory(configDirFor(accountId));
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    final remaining = [
      for (final a in accounts)
        if (a.id != accountId) a,
    ];
    // Removing the default promotes the first survivor, so a dispatch never
    // resolves to nothing while accounts still exist.
    if (target.isDefault && remaining.isNotEmpty) {
      remaining[0] = remaining[0].copyWith(isDefault: true);
    }
    await _writeRegistry(remaining);
  }

  /// What [AccountSelector] needs to know about every registered account.
  ///
  /// "Spent" is the union of two signals with different characters, and both
  /// are needed: the usage endpoint answers BEFORE a run is wasted but is a
  /// cached reading that can lag a plan, while an observed 429 answers only
  /// after a failure but is never wrong. Either one alone leaves a hole.
  Future<Map<String, AccountAvailability>> availability() async {
    final accounts = await list();
    final at = now();
    final entries = await Future.wait(
      accounts.map((a) async {
        final dir = configDirFor(a.id);
        final mirrored = await syncCredentialFromKeychain(a.id);
        // A run that 401'd proved the credential in this directory is dead, and
        // the keychain says nothing about that — the item is still THERE, it
        // just no longer authenticates, so the mirror above happily reports a
        // signed-in account we already watched fail. Honour the observation
        // until a NEWER credential lands (a re-login, or an in-sandbox
        // refresh), which is the only thing that can make it work again.
        // An UNRENEWABLE credential is the same verdict arrived at without a
        // wasted run: it says when it stops working and carries nothing to
        // renew itself with, so a dispatch that could only 401 is skipped now
        // rather than after it fails. Cheap enough for the dispatch path — a
        // read of a file already on disk. A merely-expired token is NOT
        // excluded: the CLI refreshes that on start, and treating it as dead
        // would empty the rotation every morning.
        final signedIn =
            mirrored &&
            !credentialBeyondRepair(a.id, at) &&
            !_authFailurePending(a, dir);
        final cooldown = a.rateLimitedUntil;
        final cooling = cooldown != null && cooldown.isAfter(at);
        // Don't spend a probe on an account that already cannot serve a run.
        final usage = (!signedIn || cooling) ? null : await _usageFor(dir, at);
        // Strictly 100%: the operator asked for every account to be drained
        // fully rather than advanced early, so only a window with nothing left
        // counts as spent. The 429 cooldown catches the boundary this misses.
        final spent = cooling || (usage != null && usage.used >= 1.0);
        return MapEntry(
          a.id,
          AccountAvailability(
            id: a.id,
            signedIn: signedIn,
            spent: spent,
            availableAt: cooling ? cooldown : usage?.resetsAt,
          ),
        );
      }),
    );
    return Map.fromEntries(entries);
  }

  Future<({double used, DateTime? resetsAt})?> _usageFor(
    String configDir,
    DateTime at,
  ) async {
    final cached = _usageCache[configDir];
    if (cached != null && at.difference(cached.at) < usageCacheTtl) {
      return (used: cached.used, resetsAt: cached.resetsAt);
    }
    final probe = probeUsage;
    if (probe == null) {
      return null;
    }
    try {
      final result = await probe(configDir);
      if (result == null) {
        return null;
      }
      _usageCache[configDir] = (
        at: at,
        used: result.usedFraction,
        resetsAt: result.resetsAt,
      );
      return (used: result.usedFraction, resetsAt: result.resetsAt);
    } on Object catch (e) {
      // A failed probe must never make an account look spent — that would let
      // one flaky request stop every run in the workspace.
      CcInfraLog.warning('ClaudeAccountStore: usage probe failed: $e');
      return null;
    }
  }

  /// Records that [accountId] returned a rate-limit response, so the next
  /// dispatch skips it.
  ///
  /// [until] is the reset the provider reported when it gave one; without it
  /// the account is parked for [defaultCooldown], which is long enough to move
  /// a `/goal` onto the next account and short enough that a misread error
  /// does not sideline a working plan for the day.
  Future<void> markRateLimited(String accountId, {DateTime? until}) async {
    final accounts = await list();
    if (!accounts.any((a) => a.id == accountId)) {
      return;
    }
    final expiry = until ?? now().add(defaultCooldown);
    _usageCache.remove(configDirFor(accountId));
    await _writeRegistry([
      for (final a in accounts)
        if (a.id == accountId) a.copyWith(rateLimitedUntil: expiry) else a,
    ]);
  }

  /// Records that a run on [accountId] failed to authenticate, so the next
  /// dispatch does not lead with an account we already watched refuse.
  ///
  /// [reason] is the CLI's own sentence (`OAuth access token has expired.
  /// Re-authenticate to continue.`), kept so Settings can say which account to
  /// sign back in and why instead of just showing it as logged out.
  ///
  /// Re-recording an already-failed account refreshes the timestamp: the point
  /// of reference is "since when has nothing newer appeared", and a second
  /// failure means the credential in the directory at THAT moment was dead too.
  Future<void> markAuthFailed(String accountId, {String? reason}) async {
    final accounts = await list();
    if (!accounts.any((a) => a.id == accountId)) {
      return;
    }
    _usageCache.remove(configDirFor(accountId));
    await _writeRegistry([
      for (final a in accounts)
        if (a.id == accountId)
          a.copyWith(authFailedAt: now(), authFailedReason: reason)
        else
          a,
    ]);
  }

  /// Whether [account]'s recorded auth failure still stands — i.e. no newer
  /// credential has been written into [dir] since it was observed.
  ///
  /// The mtime of `.credentials.json` is the signal because it is the one thing
  /// both repair paths touch: `claude auth login` writes a keychain item with a
  /// later `expiresAt`, which [syncCredentialFromKeychain] then mirrors into
  /// the file, and an in-sandbox refresh writes the file directly. So the flag
  /// clears itself the moment the account could work again, and no operator
  /// ever has to find a "clear this" button.
  ///
  /// An account on a long-lived token is judged by the TOKEN file instead: it
  /// is the credential runs use, and pasting a new one is its re-login.
  bool _authFailurePending(ClaudeAccount account, String dir) {
    final failedAt = account.authFailedAt;
    if (failedAt == null) {
      return false;
    }
    if (readClaudeLongLivedToken(dir) != null) {
      try {
        return !claudeLongLivedTokenFile(
          dir,
        ).statSync().modified.isAfter(failedAt);
      } on Object {
        return true;
      }
    }
    try {
      final file = File(p.join(dir, '.credentials.json'));
      final stat = file.statSync();
      if (stat.type == FileSystemEntityType.notFound) {
        // Nothing to authenticate with at all — the account is signed out for a
        // more basic reason and the mirror already reports that.
        return true;
      }
      return !stat.modified.isAfter(failedAt);
    } on Object {
      return true;
    }
  }

  /// When the credential in [accountId]'s directory stops being accepted, or
  /// null if none / no expiry. Reads envelope `expiresAt` (`claude auth status`
  /// only reports shape). Does not refresh — CLI renews on run; report only.
  ///
  /// Null for an account on a long-lived token: the file credential beside it
  /// is no longer what runs use, so its expiry says nothing about the account.
  DateTime? credentialExpiry(String accountId) {
    if (readClaudeLongLivedToken(configDirFor(accountId)) != null) {
      return null;
    }
    try {
      final file = File(p.join(configDirFor(accountId), '.credentials.json'));
      if (!file.existsSync()) {
        return null;
      }
      final millis = _expiresAt(file.readAsStringSync());
      return millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis);
    } on Object {
      // Unreadable or not a credential envelope — the mirror already reports
      // that as signed out; an unknown expiry must not become an expired one.
      return null;
    }
  }

  /// True when [accountId]'s credential is past expiry AND cannot refresh —
  /// only a human can repair. Expired access with a live refresh still works
  /// (CLI renews on next run); excluding those would empty the pool overnight.
  /// Also true when the refresh token itself has expired.
  bool credentialBeyondRepair(String accountId, DateTime at) {
    final expiry = credentialExpiry(accountId);
    if (expiry == null || expiry.isAfter(at)) {
      return false;
    }
    try {
      final file = File(p.join(configDirFor(accountId), '.credentials.json'));
      return !_canRefresh(file.readAsStringSync(), at);
    } on Object {
      return false;
    }
  }

  static bool _canRefresh(String blob, DateTime at) {
    try {
      final decoded = jsonDecode(blob);
      if (decoded is! Map || decoded['claudeAiOauth'] is! Map) {
        return false;
      }
      final oauth = decoded['claudeAiOauth'] as Map;
      final token = oauth['refreshToken'];
      if (token is! String || token.isEmpty) {
        return false;
      }
      final until = oauth['refreshTokenExpiresAt'];
      // A credential that states no refresh expiry is taken at its word: an
      // unknown deadline must not be read as a passed one.
      return until is! num ||
          DateTime.fromMillisecondsSinceEpoch(until.toInt()).isAfter(at);
    } on Object {
      // Not a credential envelope — treat it as unrenewable.
      return false;
    }
  }

  /// Clears a recorded auth failure (the operator says it is wrong, or signed
  /// the account back in through a path that left the credential file alone).
  Future<void> clearAuthFailure(String accountId) async {
    final accounts = await list();
    await _writeRegistry([
      for (final a in accounts)
        if (a.id == accountId) a.copyWith(clearAuthFailure: true) else a,
    ]);
  }

  /// How long an account is parked after a rate-limit response with no
  /// reported reset time.
  static const Duration defaultCooldown = Duration(minutes: 30);

  /// The accounts a dispatch may use, in the order it should try them.
  ///
  /// [pool] is the workspace's (or agent's) attached set; [pinnedAccountId] is
  /// the conversation's composer pick, which wins over the pool because it is
  /// the most specific scope. [cursor] is the pool's persisted round-robin
  /// position.
  ///
  /// The result is a LIST, not one directory, because a `claude -p` run that
  /// hits a usage limit cannot swap credential mid-turn — the only failover it
  /// has is re-running on the next account, and the sandbox profile has to be
  /// built up front for every directory that run might reach.
  Future<ClaudeDispatchPlan> resolveForDispatch({
    AccountPool pool = const AccountPool(),
    String? pinnedAccountId,
    int cursor = 0,
  }) async {
    final accounts = await list();
    if (accounts.isEmpty) {
      return const ClaudeDispatchPlan(candidates: []);
    }

    // A conversation pin is an explicit instruction for this turn. It gets no
    // failover: the operator named ONE account, and quietly running on another
    // would make the picker a suggestion rather than a choice.
    if (pinnedAccountId != null &&
        accounts.any((a) => a.id == pinnedAccountId)) {
      final refusal = await _refusalFor(pinnedAccountId);
      if (refusal != null) {
        return ClaudeDispatchPlan(candidates: const [], allSpent: refusal);
      }
      final dir = await _preparedDir(pinnedAccountId);
      return ClaudeDispatchPlan(
        candidates: [(accountId: pinnedAccountId, configDir: dir)],
      );
    }

    if (pool.isEmpty) {
      // No pool configured: the pre-existing single-account behaviour, plus the
      // headroom check it used to skip. Skipping it was the hole that mattered
      // most — a pool is the ADVANCED setup, so the install that never opens
      // that screen (one account, the common case) was the one that could only
      // learn its plan was spent by watching `claude -p` fail.
      final fallback =
          accounts.where((a) => a.isDefault).firstOrNull ?? accounts.first;
      final refusal = await _refusalFor(fallback.id);
      if (refusal != null) {
        return ClaudeDispatchPlan(candidates: const [], allSpent: refusal);
      }
      final dir = await _preparedDir(fallback.id);
      return ClaudeDispatchPlan(
        candidates: [(accountId: fallback.id, configDir: dir)],
      );
    }

    final avail = await availability();
    final choice = AccountSelector.select(
      pool: pool,
      availability: avail,
      cursor: cursor,
    );
    switch (choice) {
      case AccountsRemoved(:final accountIds):
        // Refused, NOT the default account. The pool exists to keep this scope
        // off the accounts it does not name, and the default is usually one of
        // those. The gate re-resolves, so attaching a live account resumes it.
        return ClaudeDispatchPlan(
          candidates: const [],
          allSpent: (
            reason: RunCredentialReason.accountsRemoved,
            accountIds: accountIds,
            earliestReset: null,
          ),
        );
      case AccountPoolUnset():
        // Unreachable — the empty pool returned above — but the selector's
        // answer for it is the server default, so say so rather than throw.
        final fallback =
            accounts.where((a) => a.isDefault).firstOrNull ?? accounts.first;
        final refusal = await _refusalFor(fallback.id, availability: avail);
        if (refusal != null) {
          return ClaudeDispatchPlan(candidates: const [], allSpent: refusal);
        }
        final dir = await _preparedDir(fallback.id);
        return ClaudeDispatchPlan(
          candidates: [(accountId: fallback.id, configDir: dir)],
        );
      case AccountsAllSpent(:final accountIds, :final earliestReset):
        // Which of the three it is decides what the operator is asked to do, so
        // it is derived from the candidates rather than flattened to "spent":
        // a plan with a reset time is the only one that comes back by itself,
        // and an account nobody ever signed into is not rate limited.
        final spentSomewhere = accountIds.any(
          (id) => (avail[id]?.signedIn ?? false) && (avail[id]?.spent ?? false),
        );
        return ClaudeDispatchPlan(
          candidates: const [],
          allSpent: (
            reason: spentSomewhere
                ? RunCredentialReason.planSpent
                : _signedOutReason(accountIds, at: now()),
            accountIds: accountIds,
            earliestReset: earliestReset,
          ),
        );
      case AccountChosen(:final cursor):
        // The chosen account first, then every OTHER usable one as failover —
        // the selector's order, shared with the harness lane. Standbys are
        // dropped: re-running a turn on a spent account only spends it again.
        final ordered = choice.order;
        final candidates = <({String accountId, String configDir})>[];
        for (final id in ordered) {
          candidates.add((accountId: id, configDir: await _preparedDir(id)));
        }
        return ClaudeDispatchPlan(candidates: candidates, nextCursor: cursor);
    }
  }

  /// Why [accountId] cannot serve a run right now, or null when it can.
  ///
  /// Shaped as a whole refusal rather than a bare reason so every branch that
  /// declines a dispatch reports the same three facts — what is wrong, which
  /// accounts it is wrong for, and when (if ever) it fixes itself.
  ///
  /// [availability] is threaded in when the caller already computed the map;
  /// the probe behind it costs a keychain read per account and, for a live
  /// account, a usage lookup.
  Future<AccountPoolRefusal?> _refusalFor(
    String accountId, {
    Map<String, AccountAvailability>? availability,
  }) async {
    final avail = (availability ?? await this.availability())[accountId];
    if (avail == null) {
      // Nothing known about it — an unknown account is not a refused one, and
      // guessing here would take a working install offline.
      return null;
    }
    if (avail.spent) {
      return (
        reason: RunCredentialReason.planSpent,
        accountIds: [accountId],
        earliestReset: avail.availableAt,
      );
    }
    // A signed-OUT single account is deliberately NOT refused here, and it is
    // still caught — one layer later, by the dispatch session, which is the
    // only place that can see the whole answer. `CLAUDE_CODE_OAUTH_TOKEN` /
    // `ANTHROPIC_API_KEY` in the run's environment make `claude -p` work with
    // an empty account directory, and this store has no view of a run's
    // caller env or adapter env override. Refusing on the directory alone
    // would take a working install offline to report a credential it was
    // never going to use.
    //
    // Nothing is lost by waiting: the account has already been resolved, so
    // its directory is in the sandbox's writable set, and a `claude auth
    // login` into that same directory is visible in place — no re-resolution,
    // and therefore no reason to answer here.
    return null;
  }

  /// Whether a set of unusable accounts is unusable because nobody is signed in
  /// or because their credentials have run out past repair.
  ///
  /// Expired wins when ANY of them is expired: "sign in again" is the action in
  /// both cases, and naming the expiry is what stops the operator staring at a
  /// row the CLI still calls logged in.
  RunCredentialReason _signedOutReason(
    List<String> accountIds, {
    required DateTime at,
  }) => accountIds.any((id) => credentialBeyondRepair(id, at))
      ? RunCredentialReason.credentialExpired
      : RunCredentialReason.signedOut;

  /// Creates [accountId]'s directory if needed and mirrors its credential in.
  Future<String> _preparedDir(String accountId) async {
    final dir = Directory(configDirFor(accountId));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      await _chmod700(dir.path);
    }
    await syncCredentialFromKeychain(accountId);
    return dir.path;
  }

  /// The single config dir for a dispatch with no pool — the pre-pool
  /// behaviour, kept because most installs have exactly one account.
  ///
  /// Returns null when there are no accounts at all, so the caller leaves
  /// `CLAUDE_CONFIG_DIR` unset and the CLI resolves its own credential exactly
  /// as it did before this feature existed. That fallback is what keeps a
  /// machine with no accounts configured (Linux, where the keychain deny is a
  /// no-op and `~/.claude/.credentials.json` already works) from regressing.
  ///
  /// An [accountId] naming an account that no longer exists falls back to the
  /// default rather than failing: a conversation outlives the account pinned on
  /// it, and refusing to dispatch would be a worse answer than running on the
  /// account the operator would have picked anyway.
  Future<String?> resolveConfigDir({String? accountId}) async {
    final plan = await resolveForDispatch(pinnedAccountId: accountId);
    return plan.active?.configDir;
  }

  /// Mirrors [accountId]'s keychain credential into `.credentials.json` (the
  /// only form a sandboxed run can read — macOS sandbox denies Keychains).
  ///
  /// Never clobbers a newer file credential (in-sandbox refresh can write a
  /// fresher `expiresAt`). Copy only when missing/unreadable/older. Returns
  /// whether the dir holds a usable credential; never throws.
  ///
  /// Only ever the account's OWN namespaced item. Following the operator's
  /// unsuffixed `~/.claude` item instead (what a keychain-seeded account used
  /// to do) put one rotating refresh token in two places, and whichever
  /// refreshed first signed the other out — the operator's own Claude Code,
  /// every morning. An account on a long-lived token skips the mirror
  /// entirely: that token is its credential, and it never refreshes.
  Future<bool> syncCredentialFromKeychain(String accountId) async {
    final dir = configDirFor(accountId);
    if (readClaudeLongLivedToken(dir) != null) {
      return true;
    }
    final file = File(p.join(dir, '.credentials.json'));
    if (!Platform.isMacOS) {
      return file.existsSync();
    }
    final blob = await _readKeychainItem(keychainServiceFor(dir));
    if (blob == null) {
      return file.existsSync();
    }
    if (file.existsSync() && !_isNewer(blob, than: _readFileOrNull(file))) {
      return true;
    }
    try {
      Directory(dir).createSync(recursive: true);
      file.writeAsStringSync(blob, flush: true);
      await _chmod600(file.path);
      return true;
    } on Object catch (e) {
      CcInfraLog.warning(
        'ClaudeAccountStore: could not mirror the keychain credential for '
        '$accountId into ${file.path}: $e',
      );
      return file.existsSync();
    }
  }

  /// Whether [candidate]'s access token outlives [than]'s.
  ///
  /// An unparseable or absent existing copy counts as older, so a corrupt file
  /// is replaced rather than kept forever.
  static bool _isNewer(String candidate, {required String? than}) {
    final mine = _expiresAt(candidate);
    final theirs = than == null ? null : _expiresAt(than);
    if (theirs == null) {
      return true;
    }
    if (mine == null) {
      return false;
    }
    return mine > theirs;
  }

  static int? _expiresAt(String blob) {
    try {
      final decoded = jsonDecode(blob);
      if (decoded is Map && decoded['claudeAiOauth'] is Map) {
        final oauth = decoded['claudeAiOauth'] as Map;
        final value = oauth['expiresAt'];
        return value is num ? value.toInt() : null;
      }
    } on Object {
      // Not a credential envelope.
    }
    return null;
  }

  static String? _readFileOrNull(File file) {
    try {
      return file.readAsStringSync();
    } on Object {
      return null;
    }
  }

  /// Runs `claude auth status --json` against [account]'s directory, with the
  /// account's long-lived token exported exactly as a run would see it.
  Future<ClaudeAccount> _withStatus(ClaudeAccount account) async {
    try {
      final result = await _runProcess(claudeExecutable, const [
        'auth',
        'status',
        '--json',
      ], environment: runEnvironmentFor(account.id)).timeout(statusTimeout);
      final stdout = (result.stdout as String?)?.trim() ?? '';
      if (stdout.isEmpty) {
        return account.copyWith(
          loggedIn: false,
          statusError: 'claude auth status returned nothing',
        );
      }
      final json = jsonDecode(stdout);
      if (json is! Map<String, dynamic>) {
        return account.copyWith(
          loggedIn: false,
          statusError: 'unexpected claude auth status output',
        );
      }
      final email = json['email'] as String?;
      return account.copyWith(
        loggedIn: json['loggedIn'] as bool? ?? false,
        email: email,
        orgName: json['orgName'] as String?,
        subscriptionType: json['subscriptionType'] as String?,
        // An untouched auto-generated label adopts the email once we learn it,
        // so the common case needs no naming step.
        label: _isAutoLabel(account.label) && email != null && email.isNotEmpty
            ? email
            : account.label,
        clearStatusError: true,
      );
    } on Object catch (e) {
      return account.copyWith(loggedIn: false, statusError: _short(e));
    }
  }

  /// The argv a terminal runs to sign this account in, and the environment it
  /// needs. Interactive by construction — it opens a browser and waits.
  ({List<String> argv, Map<String, String> environment}) loginCommand(
    String accountId, {
    String? email,
    bool console = false,
  }) => (
    argv: [
      claudeExecutable,
      'auth',
      'login',
      if (console) '--console',
      if (email != null && email.isNotEmpty) ...['--email', email],
    ],
    environment: {'CLAUDE_CONFIG_DIR': configDirFor(accountId)},
  );

  /// The argv a terminal runs to mint a long-lived token for this account.
  ///
  /// Interactive like [loginCommand] — it opens a browser — but it writes no
  /// credential: it prints a token, and the operator pastes that into
  /// [setLongLivedToken]. Scoped to the account directory anyway, so nothing
  /// it does lands in the operator's own `~/.claude`.
  ({List<String> argv, Map<String, String> environment}) setupTokenCommand(
    String accountId,
  ) => (
    argv: [claudeExecutable, 'setup-token'],
    environment: {'CLAUDE_CONFIG_DIR': configDirFor(accountId)},
  );

  /// The environment a `claude` process needs to run as [accountId]: its
  /// config dir and, when it has one, its long-lived token.
  Map<String, String> runEnvironmentFor(String accountId) {
    final dir = configDirFor(accountId);
    final token = readClaudeLongLivedToken(dir);
    return {'CLAUDE_CONFIG_DIR': dir, claudeLongLivedTokenEnvKey: ?token};
  }

  /// Stores [token] (from `claude setup-token`) as [accountId]'s credential.
  ///
  /// From then on runs authenticate with it instead of the interactive login,
  /// so the keychain mirror stops and the account stops depending on a
  /// rotating refresh token. Pasting a fresh token is also how an account that
  /// 401'd on an expired one is repaired, so a recorded auth failure clears.
  ///
  /// Throws [ArgumentError] for an unknown account or a value that is not a
  /// setup token.
  Future<void> setLongLivedToken(String accountId, String token) async {
    final trimmed = token.trim();
    if (!isWellFormedClaudeLongLivedToken(trimmed)) {
      throw ArgumentError.value(
        '(redacted)',
        'token',
        'not a `claude setup-token` token (expected sk-ant-oat01-…)',
      );
    }
    final accounts = await list();
    if (!accounts.any((a) => a.id == accountId)) {
      throw ArgumentError.value(accountId, 'accountId', 'unknown account');
    }
    final dir = configDirFor(accountId);
    Directory(dir).createSync(recursive: true);
    await _chmod700(dir);
    writeClaudeLongLivedToken(dir, trimmed, at: now());
    await _chmod600(claudeLongLivedTokenFile(dir).path);
    _usageCache.remove(dir);
    await _writeRegistry([
      for (final a in accounts)
        if (a.id == accountId) a.copyWith(clearAuthFailure: true) else a,
    ]);
  }

  /// Drops [accountId]'s long-lived token; runs fall back to whatever
  /// interactive login its directory holds.
  Future<void> clearLongLivedToken(String accountId) async {
    if (!(await list()).any((a) => a.id == accountId)) {
      return;
    }
    final dir = configDirFor(accountId);
    deleteClaudeLongLivedToken(dir);
    _usageCache.remove(dir);
  }

  /// Retires the account an older build seeded from the operator's own
  /// `~/.claude` keychain login.
  ///
  /// That account held a COPY of the operator's credential, refresh token
  /// included. Refresh tokens rotate on use, so the first run that renewed the
  /// copy revoked the operator's own, and their Claude Code asked them to sign
  /// in again — and the next sign-in was copied straight back in, so it
  /// happened again the next day. The copy is deleted (the operator's original
  /// is untouched in the keychain) and the account is left signed out until it
  /// gets its own login or a long-lived token.
  ///
  /// Idempotent: the marker is dropped from the registry once handled.
  /// Returns the ids it retired. Never throws.
  Future<List<String>> retireDefaultLoginCopies() async {
    final retired = <String>[];
    try {
      final file = _registryFile;
      if (!file.existsSync()) {
        return retired;
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) {
        return retired;
      }
      for (final row in decoded) {
        if (row is Map && row['tracks_default_login'] == true) {
          final id = row['id'];
          if (id is String && id.isNotEmpty) {
            retired.add(id);
          }
        }
      }
      if (retired.isEmpty) {
        return retired;
      }
      for (final id in retired) {
        final copy = File(p.join(configDirFor(id), '.credentials.json'));
        if (copy.existsSync()) {
          copy.deleteSync();
        }
      }
      // `toRegistryJson` no longer writes the marker, so a rewrite drops it.
      await _writeRegistry(await list());
      CcInfraLog.info(
        'ClaudeAccountStore: retired ${retired.join(', ')}, which mirrored the '
        "operator's own Claude Code login and signed it out on every refresh. "
        'Sign it in on its own or give it a long-lived token.',
      );
    } on Object catch (e) {
      CcInfraLog.warning(
        'ClaudeAccountStore: could not retire the keychain-seeded account: $e',
      );
    }
    return retired;
  }

  /// Reads one generic-password item, accepting it only if it parses as the
  /// credential envelope.
  ///
  /// The parse is the point: a half-written or unexpected blob copied into an
  /// account directory would look signed-in and fail on the first request
  /// instead of here, where the failure is still legible.
  Future<String?> _readKeychainItem(String service) async {
    try {
      final r = await _runProcess('security', [
        'find-generic-password',
        '-s',
        service,
        '-w',
      ]).timeout(const Duration(seconds: 5));
      if (r.exitCode != 0) {
        return null;
      }
      final out = (r.stdout as String?)?.trim() ?? '';
      if (out.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(out);
      if (decoded is Map && decoded['claudeAiOauth'] is Map) {
        return out;
      }
    } on Object {
      // Keychain locked, denied, or absent.
    }
    return null;
  }

  Future<void> _writeRegistry(List<ClaudeAccount> accounts) async {
    Directory(_root).createSync(recursive: true);
    await _chmod700(_root);
    final tmp = File('${_registryFile.path}.tmp');
    tmp.writeAsStringSync(
      const JsonEncoder.withIndent(
        '  ',
      ).convert([for (final a in accounts) a.toRegistryJson()]),
      flush: true,
    );
    // Rename, not write-in-place: a crash mid-write would otherwise leave a
    // truncated registry, which reads back as "no accounts" and sends every
    // dispatch to an unset CLAUDE_CONFIG_DIR.
    tmp.renameSync(_registryFile.path);
    await _chmod600(_registryFile.path);
  }

  /// A directory-safe id derived from [label], deduped against [taken].
  static String _mintId(String? label, {required Set<String> taken}) {
    final slug = (label ?? '')
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp('^-+|-+\$'), '');
    // No path separators, no dots, no traversal — this becomes a directory
    // name under the data dir and the label is operator input.
    final base = slug.isEmpty ? 'account' : slug;
    if (!taken.contains(base)) {
      return base;
    }
    for (var i = 2; ; i++) {
      final candidate = '$base-$i';
      if (!taken.contains(candidate)) {
        return candidate;
      }
    }
  }

  /// Whether [label] is one we generated, and may therefore replace with the
  /// email the CLI reports.
  static bool _isAutoLabel(String label) =>
      RegExp(r'^Account \d+$').hasMatch(label) || label == 'Keychain account';

  static Future<void> _chmod700(String path) => _chmod('700', path);

  static Future<void> _chmod600(String path) => _chmod('600', path);

  static Future<void> _chmod(String mode, String path) async {
    if (Platform.isWindows) {
      return;
    }
    try {
      await Process.run('chmod', [mode, path]);
    } on Object catch (e) {
      CcInfraLog.warning('ClaudeAccountStore: chmod $mode $path failed: $e');
    }
  }

  static String _short(Object e) {
    final s = e.toString();
    return s.length > 200 ? '${s.substring(0, 200)}…' : s;
  }
}

/// Which accounts one dispatch may run on, in the order it should try them.
///
/// Three distinguishable outcomes, because the caller does something different
/// with each: candidates to run, a refusal to report with a reset time, or an
/// empty plan meaning "this install manages no accounts, let the CLI resolve
/// its own credential".
class ClaudeDispatchPlan {
  /// Creates a [ClaudeDispatchPlan].
  const ClaudeDispatchPlan({
    required this.candidates,
    this.nextCursor,
    this.allSpent,
  });

  /// The accounts to try, best first. Empty means either no accounts are
  /// managed at all, or [allSpent] explains why none can serve this run.
  final List<({String accountId, String configDir})> candidates;

  /// The round-robin cursor to persist. Null when the strategy does not move
  /// one, so a caller can skip the write entirely.
  final int? nextCursor;

  /// Set when no account can serve this run right now.
  ///
  /// The [RunCredentialReason] rides along because the three ways an account
  /// stops working heal three different ways, and telling the operator the
  /// wrong one costs them the fix: a spent plan comes back by itself at
  /// `earliestReset`, a signed-out directory comes back only when a human runs
  /// `claude auth login`, and an unrenewable credential looks signed in right
  /// up until it 401s. It is also what the credential gate branches on to build
  /// the right dialog.
  final AccountPoolRefusal? allSpent;

  /// The account this run starts on, or null.
  ({String accountId, String configDir})? get active =>
      candidates.isEmpty ? null : candidates.first;

  /// Every directory the sandbox must make readable and writable.
  ///
  /// All of them, not just the active one: the profile is generated before the
  /// spawn and a failover re-run inside the same session would otherwise land
  /// on a directory the sandbox never opened.
  List<String> get configDirs => [for (final c in candidates) c.configDir];
}
