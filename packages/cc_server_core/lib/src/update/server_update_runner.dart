import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:crypto/crypto.dart';

/// Response of one GET through the update runner's HTTP client seam. The
/// default implementation is a plain `dart:io` [HttpClient]; tests substitute
/// their own to serve a fake release catalog.
typedef UpdateHttpGet = Future<(int, List<int>)> Function(Uri uri);

/// Downloads [uri] to [destination], returning the HTTP status. Split from
/// [UpdateHttpGet] so a release archive (natives + models — hundreds of MB)
/// streams to disk instead of being accumulated in memory twice.
typedef UpdateHttpDownload = Future<int> Function(Uri uri, File destination);

/// Runs `cc_server update` — the standalone-server self-update flow.
///
/// Opt-in by construction (a command, never a background timer) and never
/// silent: without `--apply` it only *checks for, downloads and verifies* a
/// newer release into a staging directory **next to the install** (never
/// inside `--data-dir`, which must survive updates untouched); `--apply`
/// performs the swap and prints "restart the process".
///
/// Invariants (from the auto-update spec):
///  * **Verify before exec.** The archive's SHA-256 must match the release's
///    `SHA256SUMS.txt` and when the `gh` CLI is available the SLSA
///    attestation is verified too. A missing checksums file is a hard refusal.
///  * **Whole artifact, never the binary alone.** Natives are boot-required
///    and ABI-coupled, so the unit of update is the whole extracted archive
///    layout (`bin/` + natives + optional code-server).
///  * **Never replace a running server.** `--apply` probes the configured
///    port's `/healthz`; any live server answering there (let alone one with
///    open sessions) is a refusal unless `--force`, which is documented as
///    "you will drop clients".
///  * **Never move backwards by accident.** The latest published release is
///    ORDERED against this build, not merely compared for equality; an older
///    release is refused unless `--allow-downgrade`.
///  * **Windows swaps differently.** Windows refuses to rename a directory
///    containing the running image, so there the live `cc_server.exe` is
///    parked as `.old` and the verified tree is overlaid in place — see
///    `_applyWindows`.
///  * Managed installs refuse instead of fighting their manager: the
///    desktop-embedded binary (spawned with the `CC_EMBEDDED` env), a source
///    checkout (`dart run`) and a Docker container (prints the `docker
///    pull` line instead) all no-op with an explanatory line.
///  * One previous tree is kept as `<install>.bak` for rollback; older `.bak`
///    trees are removed so repeated updates cannot accumulate.
class ServerUpdateRunner {
  /// Creates a runner. [log] receives every human-facing line (CLI stdout or
  /// a test collector); [probeUri] is the healthz endpoint a live server on
  /// this machine would answer. [environment]/[scriptPath]/[dockerEnvFile]
  /// override the process facts the managed-install refusals read (tests).
  ServerUpdateRunner({
    void Function(String line)? log,
    this.probeUri,
    this.releaseApiBase = 'https://api.github.com',
    this.releaseOwner = 'SamuelAlev',
    this.releaseRepo = 'control-center',
    UpdateHttpGet? httpGet,
    UpdateHttpDownload? httpDownload,
    ProcessRunner? processRunner,
    this.installDir,
    this.archOverride,
    Map<String, String>? environment,
    String? scriptPath,
    String? dockerEnvFile,
    this.osOverride,
  }) : _log = log ?? stdout.writeln,
       _httpGet = httpGet ?? _ioHttpGet,
       _httpDownload =
           httpDownload ??
           (httpGet == null
               ? _ioHttpDownload
               // A test that supplies only the small-body seam still gets a
               // working download path (fixtures are tiny by construction).
               : (uri, file) async {
                   final (status, bytes) = await httpGet(uri);
                   if (status == 200) {
                     file.writeAsBytesSync(bytes);
                   }
                   return status;
                 }),
       _process = processRunner ?? Process.run,
       _environment = environment ?? Platform.environment,
       _scriptPath = scriptPath ?? Platform.script.path,
       _dockerEnvFile = dockerEnvFile ?? '/.dockerenv';

  /// Sink for progress lines (defaults to stdout).
  final void Function(String line) _log;

  /// The `/healthz` endpoint probed before `--apply` (from the same
  /// `--port`/env config the server itself uses). Null skips the drain probe.
  final Uri? probeUri;

  /// GitHub Releases REST base. Tests point this at a local fixture server.
  final String releaseApiBase;

  /// Owner/repo of the published releases (draft releases are invisible to
  /// `releases/latest` — the "published only" rule falls out for free).
  /// Owner/repo of the published releases.
  final String releaseOwner;

  /// The repository half of the same.
  final String releaseRepo;

  final UpdateHttpGet _httpGet;
  final UpdateHttpDownload _httpDownload;
  final ProcessRunner _process;

  /// Overrides the detected install directory (tests).
  final String? installDir;

  /// Overrides the detected CPU arch (tests).
  final String? archOverride;

  /// Overrides the detected OS name — `macos`/`windows`/`linux` (tests).
  final String? osOverride;

  /// Process facts the managed-install refusals read (tests inject fakes).
  final Map<String, String> _environment;
  final String _scriptPath;
  final String _dockerEnvFile;

  /// Exit code: success (including the honest no-ops — up to date, managed
  /// install, Docker pointer).
  static const int ok = 0;

  /// Exit code: the update did not happen (verification failed, a live
  /// server refused, unrecognised layout…).
  static const int failure = 1;

  /// Checks, downloads, verifies and (with [apply]) installs the latest
  /// published standalone-server release. Returns the process exit code.
  ///
  /// [allowDowngrade] permits installing a release OLDER than this binary —
  /// off by default, because `releases/latest` moving backwards (a yanked
  /// release, or a locally built binary ahead of the published one) must not
  /// silently roll a server back under its own data.
  Future<int> run({
    bool apply = false,
    bool force = false,
    bool allowDowngrade = false,
  }) async {
    final refusal = await _refuseIfManaged();
    if (refusal != null) {
      return refusal;
    }

    final bundle = _resolveInstallBundle();
    if (bundle == null) {
      _log(
        'cc_server update: refusing — could not recognise this install layout '
        '(expected <install>/bin/cc_server). The binary must live inside a '
        'release archive layout for a whole-tree update.',
      );
      return failure;
    }

    final release = await _fetchLatestRelease();
    if (release == null) {
      _log('cc_server update: could not resolve the latest published release.');
      return failure;
    }

    final comparison = compareVersions(release.version, BuildInfo.buildVersion);
    if (comparison == 0) {
      _log(
        'cc_server ${BuildInfo.buildVersion} (${BuildInfo.buildGitSha}) is up '
        'to date '
        '(latest release: ${release.tag}).',
      );
      return ok;
    }
    if (comparison < 0 && !allowDowngrade) {
      // `releases/latest` is BEHIND this binary. That is a yanked release, a
      // locally built binary, or a repo misconfiguration — never something to
      // apply silently under a server that already has newer data on disk.
      _log(
        'cc_server update: refusing — the latest published release '
        '(${release.tag}) is OLDER than this binary '
        '(${BuildInfo.buildVersion}). Pass --allow-downgrade to install it '
        'anyway (a downgrade can be incompatible with data written by the '
        'newer build).',
      );
      return failure;
    }
    _log(
      comparison < 0
          ? '--allow-downgrade: installing ${release.tag}, which is OLDER '
                'than this binary (${BuildInfo.buildVersion}).'
          : 'Update available: ${release.tag} (this binary: '
                '${BuildInfo.buildVersion} (${BuildInfo.buildGitSha}); '
                'published ${release.publishedAt ?? 'unknown'}).',
    );

    final asset = release.assetFor(_platformName(), _archName());
    if (asset == null) {
      _log(
        'cc_server update: release ${release.tag} has no archive for '
        '${_platformName()}-${_archName()}. Open '
        '${release.htmlUrl} for the available assets.',
      );
      return failure;
    }

    final stagingRoot = Directory(
      '${bundle.parent.path}/${_baseName(bundle.path)}.staging',
    );
    final archiveFile = File('${stagingRoot.path}/${asset.name}');

    // A previous `cc_server update` (no --apply) already downloaded and
    // verified this exact archive and told the operator to re-run with
    // --apply. Re-verify it rather than re-downloading: the checksum gate is
    // what makes reuse safe and it is the same gate a fresh download passes.
    final expectedSha = await _expectedSha256(release, asset.name);
    if (expectedSha == null) {
      return failure;
    }
    var reused = false;
    if (archiveFile.existsSync() && _sha256OfFile(archiveFile) == expectedSha) {
      _log('Reusing the verified ${asset.name} already staged.');
      reused = true;
    } else {
      if (stagingRoot.existsSync()) {
        stagingRoot.deleteSync(recursive: true);
      }
      stagingRoot.createSync(recursive: true);
      _log('Downloading ${asset.name}…');
      try {
        final status = await _httpDownload(Uri.parse(asset.url), archiveFile);
        if (status != 200) {
          _log('cc_server update: download failed (HTTP $status).');
          return failure;
        }
      } catch (e) {
        _log('cc_server update: download failed: $e');
        return failure;
      }
      // Verify BEFORE exec — fail-closed against the release's own
      // SHA256SUMS.txt.
      final actual = _sha256OfFile(archiveFile);
      if (actual != expectedSha) {
        _log(
          'cc_server update: refusing — SHA-256 mismatch.\n'
          '  expected $expectedSha\n'
          '  actual   $actual',
        );
        return failure;
      }
      _log('SHA-256 verified (${asset.name}).');
    }
    // Defense in depth on top of the checksum: SLSA provenance when gh exists.
    if (!await _verifyAttestation(archiveFile)) {
      return failure;
    }
    // A reused archive may sit beside a half-extracted tree from the earlier
    // run; clear everything except the archive itself before extracting.
    if (reused) {
      for (final entry in stagingRoot.listSync()) {
        if (entry.path != archiveFile.path) {
          entry.deleteSync(recursive: true);
        }
      }
    }

    _log('Extracting ${asset.name}…');
    final extract = await _process('tar', [
      'xf',
      archiveFile.path,
      '-C',
      stagingRoot.path,
    ]);
    if (extract.exitCode != 0) {
      _log(
        'cc_server update: extraction failed: '
        '${(extract.stderr as String).trim()}',
      );
      return failure;
    }
    final staged = Directory(
      '${stagingRoot.path}/${asset.name.replaceAll(RegExp(r'\.(tar\.gz|zip)$'), '')}',
    );
    // The expected binary name follows the TARGET platform, which is the
    // override when one is set — otherwise a windows-layout test on a POSIX
    // host would look for the wrong file.
    final binaryName = _isWindowsTarget ? 'cc_server.exe' : 'cc_server';
    final stagedBinary = File('${staged.path}/bin/$binaryName');
    if (!stagedBinary.existsSync()) {
      _log(
        'cc_server update: the archive does not contain the expected '
        'bin/$binaryName layout — refusing.',
      );
      return failure;
    }

    if (!apply) {
      _log(
        'Verified and staged ${release.tag} at ${staged.path}.\n'
        'Apply it with: cc_server update --apply',
      );
      return ok;
    }

    return _apply(
      bundle: bundle,
      staged: staged,
      stagingRoot: stagingRoot,
      force: force,
    );
  }

  /// Environment refusals that must run before anything touches the network.
  /// Returns an exit code to surface, or null to continue.
  Future<int?> _refuseIfManaged() async {
    final env = _environment;
    // The desktop's embedded server is managed by the .app/installer — the
    // ONLY correct way to update it is updating the app (Sparkle / installer),
    // which swaps the whole tree.
    if (env['CC_EMBEDDED'] == '1' || env['CC_BOOTSTRAP_DEVICE_ID'] != null) {
      _log(
        'cc_server update: no-op — this binary is managed by the Control '
        'Center app. Update it by updating the app.',
      );
      return ok;
    }
    // A `dart run` source checkout: `git pull` is the update path.
    if (_scriptPath.endsWith('.dart')) {
      _log(
        'cc_server update: no-op — this is a source checkout run through '
        'the Dart VM. Update it with git.',
      );
      return ok;
    }
    // Inside a container the image is the unit of update.
    if (File(_dockerEnvFile).existsSync() || env['container'] != null) {
      _log(
        'cc_server update: running inside a container — update by pulling a '
        'newer image:\n'
        '  docker pull ghcr.io/${releaseOwner.toLowerCase()}/cc-server:latest\n'
        'then recreate the container. A running container must never rewrite '
        'itself.',
      );
      return ok;
    }
    return null;
  }

  /// The release-archive bundle root: the parent of this binary's `bin/`
  /// directory. Null when the binary does not live in that layout (the
  /// override is held to the same existence bar, so a test pointing at a
  /// phantom dir gets the same refusal a user would).
  Directory? _resolveInstallBundle() {
    final override = installDir;
    if (override != null) {
      return Directory(override).existsSync() ? Directory(override) : null;
    }
    final exe = Platform.resolvedExecutable;
    final exeDir = File(exe).parent;
    if (_baseName(exeDir.path) != 'bin') {
      return null;
    }
    return exeDir.parent;
  }

  Future<UpdateRelease?> _fetchLatestRelease() async {
    try {
      final (status, bytes) = await _httpGet(
        Uri.parse(
          '$releaseApiBase/repos/$releaseOwner/$releaseRepo/releases/latest',
        ),
      );
      if (status != 200) {
        return null;
      }
      final body = jsonDecode(utf8.decode(bytes));
      if (body is! Map) {
        return null;
      }
      return UpdateRelease.fromJson(body.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  /// The expected SHA-256 for [assetName] from the release's
  /// `SHA256SUMS.txt`. Null (with the refusal already logged) when the
  /// release has no checksums asset, it cannot be fetched, or it carries no
  /// entry for this archive — all fail-closed.
  Future<String?> _expectedSha256(
    UpdateRelease release,
    String assetName,
  ) async {
    UpdateAsset? sums;
    for (final a in release.assets) {
      if (a.name == 'SHA256SUMS.txt') {
        sums = a;
      }
    }
    if (sums == null) {
      _log(
        'cc_server update: refusing — the release has no SHA256SUMS.txt '
        'asset to verify against (fail closed).',
      );
      return null;
    }
    try {
      final (status, bytes) = await _httpGet(Uri.parse(sums.url));
      if (status != 200) {
        _log(
          'cc_server update: could not download SHA256SUMS.txt '
          '(HTTP $status).',
        );
        return null;
      }
      final expected = _sha256FromSums(utf8.decode(bytes), assetName);
      if (expected == null) {
        _log(
          'cc_server update: refusing — SHA256SUMS.txt has no entry for '
          '$assetName.',
        );
        return null;
      }
      return expected;
    } catch (e) {
      _log('cc_server update: checksum verification failed: $e');
      return null;
    }
  }

  /// Streams [file] through SHA-256 so a multi-hundred-MB archive is never
  /// held in memory to be hashed.
  static String _sha256OfFile(File file) {
    final output = _DigestSink();
    final input = sha256.startChunkedConversion(output);
    final handle = file.openSync();
    try {
      const chunkSize = 1 << 20;
      while (true) {
        final chunk = handle.readSync(chunkSize);
        if (chunk.isEmpty) {
          break;
        }
        input.add(chunk);
      }
    } finally {
      handle.closeSync();
    }
    input.close();
    return output.digest.toString();
  }

  /// `"<hex>  <filename>"` → hex, for this archive's entry.
  static String? _sha256FromSums(String sums, String fileName) {
    for (final line in sums.split('\n')) {
      final match = RegExp(
        r'^([0-9a-fA-F]{64})\s+\*?(.+)$',
      ).firstMatch(line.trim());
      if (match != null && match.group(2)!.trim() == fileName) {
        return match.group(1)!.toLowerCase();
      }
    }
    return null;
  }

  /// SLSA provenance via the `gh` CLI when it exists; a soft skip otherwise
  /// (the SHA-256 gate above already ran — this is defense in depth). A hard
  /// refusal only when `gh` IS available and the verification fails.
  Future<bool> _verifyAttestation(File archiveFile) async {
    try {
      final gh = await _process('gh', ['--version']);
      if (gh.exitCode != 0) {
        _log(
          'gh CLI not found — skipped SLSA attestation verification '
          '(SHA-256 was verified).',
        );
        return true;
      }
      // --repo, not --owner: --owner accepts an artifact attested by ANY
      // repository under the org, which is a much weaker claim than "this
      // archive was built by control-center's release workflow".
      final result = await _process('gh', [
        'attestation',
        'verify',
        archiveFile.path,
        '--repo',
        '$releaseOwner/$releaseRepo',
      ]);
      if (result.exitCode == 0) {
        _log('SLSA attestation verified.');
        return true;
      }
      _log(
        'cc_server update: refusing — SLSA attestation verification failed: '
        '${(result.stderr as String).trim()}',
      );
      return false;
    } on Object catch (e) {
      _log(
        'gh CLI unavailable ($e) — skipped SLSA attestation verification '
        '(SHA-256 was verified).',
      );
      return true;
    }
  }

  /// The swap: refuse-while-live → staged→install rename with a one-deep
  /// `.bak` rollback tree. Returns the process exit code.
  Future<int> _apply({
    required Directory bundle,
    required Directory staged,
    required Directory stagingRoot,
    required bool force,
  }) async {
    // Drain rule: never silently replace a running server. Any live server
    // answering the healthz probe (it holds the DB, tokens, live runs) is a
    // stop-first refusal; --force is documented as "you will drop clients".
    final probe = probeUri;
    if (probe != null) {
      final live = await _probeLiveServer(probe);
      if (live != null) {
        // A healthz answer we could not parse means "something is listening",
        // not "a cc_server with zero sessions" — say so rather than inventing
        // a session count.
        final who = live.isCcServer
            ? 'a cc_server is live at $probe (${live.connections} open client '
                  '${live.connections == 1 ? 'session' : 'sessions'})'
            : 'something is already listening at $probe (it did not answer '
                  'as a cc_server)';
        if (!force) {
          _log(
            'cc_server update: refusing to apply — $who. Stop it first, or '
            'pass --force (you will drop clients).',
          );
          return failure;
        }
        _log('--force: applying anyway — $who will be dropped.');
      }
    }

    if (_isWindowsTarget) {
      return _applyWindows(
        bundle: bundle,
        staged: staged,
        stagingRoot: stagingRoot,
      );
    }

    final bak = Directory('${bundle.path}.bak');
    if (bak.existsSync()) {
      bak.deleteSync(recursive: true);
    }
    try {
      bundle.renameSync(bak.path);
      staged.renameSync(bundle.path);
    } on FileSystemException catch (e) {
      // Roll back before reporting: a half-swapped install is the one state
      // worse than a failed update.
      if (!bundle.existsSync() && bak.existsSync()) {
        bak.renameSync(bundle.path);
      }
      _log(
        'cc_server update: could not replace ${bundle.path}: ${e.message}\n'
        'Check permissions on the install directory.',
      );
      return failure;
    }
    // The staging scratch (archive + extraction leftovers) is spent; the
    // verified tree itself moved into place above.
    if (stagingRoot.existsSync()) {
      stagingRoot.deleteSync(recursive: true);
    }
    _log(
      'Updated ${bundle.path}.\n'
      'Previous install kept at ${bak.path} (removed on the next update).\n'
      'Restart the cc_server process to run the new version.',
    );
    return ok;
  }

  /// The Windows swap.
  ///
  /// The POSIX path renames the install directory aside, which Windows
  /// refuses while any file beneath it is open — and the file that is open is
  /// *this executable*, running the update. "Stop the server and re-run" does
  /// not help: re-running re-locks it.
  ///
  /// Windows does, however, allow renaming a running image FILE (the section
  /// mapping survives), so the sequence is: move the live exe aside as
  /// `.old`, overlay the verified tree in place and sweep the `.old` on the
  /// next update. There is deliberately no `.bak` tree here — copying a whole
  /// server bundle (natives + models) to get one would double the install
  /// footprint on every update; the archive stays in staging instead.
  Future<int> _applyWindows({
    required Directory bundle,
    required Directory staged,
    required Directory stagingRoot,
  }) async {
    // Sweep any `.old` left by a previous update (now unlocked).
    for (final entry
        in Directory('${bundle.path}/bin').existsSync()
            ? Directory('${bundle.path}/bin').listSync()
            : const <FileSystemEntity>[]) {
      if (entry is File && entry.path.endsWith('.old')) {
        try {
          entry.deleteSync();
        } on FileSystemException {
          // Still locked by a process that has not exited yet — harmless.
        }
      }
    }

    final liveExe = File('${bundle.path}/bin/cc_server.exe');
    final parked = File('${liveExe.path}.old');
    var parkedLive = false;
    try {
      if (liveExe.existsSync()) {
        if (parked.existsSync()) {
          parked.deleteSync();
        }
        liveExe.renameSync(parked.path);
        parkedLive = true;
      }
      _overlayDirectory(staged, bundle);
    } on FileSystemException catch (e) {
      // Put the live binary back before reporting: an install with no
      // cc_server.exe is worse than one that simply did not update.
      if (parkedLive && !liveExe.existsSync() && parked.existsSync()) {
        parked.renameSync(liveExe.path);
      }
      _log(
        'cc_server update: could not replace ${bundle.path}: ${e.message}\n'
        'Check permissions on the install directory and that no other '
        'process is running from it.',
      );
      return failure;
    }
    if (stagingRoot.existsSync()) {
      stagingRoot.deleteSync(recursive: true);
    }
    _log(
      'Updated ${bundle.path}.\n'
      'The previous executable is parked at ${parked.path} and is removed on '
      'the next update.\n'
      'Restart the cc_server process to run the new version.',
    );
    return ok;
  }

  /// Recursively copies [from] over [to], overwriting existing files and
  /// creating missing directories. Files present only in [to] are left alone
  /// (nothing in the archive layout depends on their absence).
  static void _overlayDirectory(Directory from, Directory to) {
    for (final entry in from.listSync(recursive: true)) {
      final relative = entry.path.substring(from.path.length + 1);
      final target = '${to.path}/$relative';
      if (entry is Directory) {
        Directory(target).createSync(recursive: true);
      } else if (entry is File) {
        Directory(File(target).parent.path).createSync(recursive: true);
        entry.copySync(target);
      }
    }
  }

  /// Probes [uri]; returns what answered (and its session count when it
  /// identified itself as a cc_server), or null when nothing answers at all.
  Future<({int connections, bool isCcServer})?> _probeLiveServer(
    Uri uri,
  ) async {
    try {
      final (status, bytes) = await _httpGet(
        uri,
      ).timeout(const Duration(seconds: 4));
      if (status != 200) {
        return (connections: 0, isCcServer: false);
      }
      final body = jsonDecode(utf8.decode(bytes));
      if (body is Map && body['connections'] is int) {
        return (connections: body['connections'] as int, isCcServer: true);
      }
      return (connections: 0, isCcServer: false);
    } catch (_) {
      return null;
    }
  }

  String _platformName() => switch (osOverride ?? Platform.operatingSystem) {
    'macos' => 'macos',
    'windows' => 'windows',
    _ => 'linux',
  };

  /// Whether the install being updated is a Windows one. Reads the override
  /// so the Windows swap is exercisable from a POSIX test host.
  bool get _isWindowsTarget => _platformName() == 'windows';

  String _archName() {
    if (archOverride != null) {
      return archOverride!;
    }
    return Platform.version.contains('arm64') ||
            Platform.version.contains('aarch64')
        ? 'arm64'
        : 'x64';
  }

  static String _baseName(String path) =>
      path.split(Platform.isWindows ? r'\' : '/').last;

  /// Small-body GET (the release JSON and SHA256SUMS.txt). Bounded by a
  /// connect + idle timeout so a hung endpoint fails the update instead of
  /// hanging the command forever.
  static Future<(int, List<int>)> _ioHttpGet(Uri uri) async {
    final client = HttpClient()
      ..userAgent = 'cc-server-updater'
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        bytes.addAll(chunk);
      }
      return (response.statusCode, bytes);
    } finally {
      client.close();
    }
  }

  /// Streams a release archive straight to disk. The archive is the large
  /// artifact (natives + models); buffering it in memory to then write it out
  /// costs twice its size in RSS on a machine that may be a small VPS.
  ///
  /// The idle timeout is per-chunk, not for the whole transfer, so a slow but
  /// progressing download is never cut off.
  static Future<int> _ioHttpDownload(Uri uri, File destination) async {
    final client = HttpClient()
      ..userAgent = 'cc-server-updater'
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != 200) {
        // Drain so the connection can be reused/closed cleanly.
        await response.drain<void>();
        return response.statusCode;
      }
      final sink = destination.openWrite();
      try {
        await response.timeout(const Duration(minutes: 2)).forEach(sink.add);
      } finally {
        await sink.close();
      }
      return response.statusCode;
    } finally {
      client.close();
    }
  }
}

/// One published GitHub release, filtered to what the updater needs.
class UpdateRelease {
  /// Creates a [UpdateRelease].
  const UpdateRelease({
    required this.tag,
    required this.version,
    required this.htmlUrl,
    required this.publishedAt,
    required this.assets,
  });

  /// The release tag (e.g. `v1.2.3`).
  final String tag;

  /// The tag without the leading `v`.
  final String version;

  /// Human-facing page for this release.
  final String htmlUrl;

  /// When the release was published (RFC-3339), if reported.
  final String? publishedAt;

  /// Every downloadable asset on the release.
  final List<UpdateAsset> assets;

  /// Parses the `releases/latest` REST payload.
  static UpdateRelease? fromJson(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String?;
    if (tag == null || tag.isEmpty) {
      return null;
    }
    final assets = <UpdateAsset>[];
    for (final raw in (json['assets'] as List? ?? const [])) {
      if (raw is Map) {
        final asset = UpdateAsset.fromJson(raw.cast<String, dynamic>());
        if (asset != null) {
          assets.add(asset);
        }
      }
    }
    return UpdateRelease(
      tag: tag,
      version: tag.startsWith('v') ? tag.substring(1) : tag,
      htmlUrl: json['html_url'] as String? ?? '',
      publishedAt: json['published_at'] as String?,
      assets: assets,
    );
  }

  /// The `cc_server-<ver>-<os>-<arch>.{tar.gz,zip}` asset for [os]/[arch].
  UpdateAsset? assetFor(String os, String arch) {
    for (final asset in assets) {
      if (RegExp(
        'cc_server-.*-$os-$arch\\.(tar\\.gz|zip)\$',
      ).hasMatch(asset.name)) {
        return asset;
      }
    }
    return null;
  }
}

/// One downloadable release asset.
class UpdateAsset {
  /// Creates an [UpdateAsset].
  const UpdateAsset({required this.name, required this.url});

  /// The asset's file name (e.g. `cc_server-1.2.3-linux-x64.tar.gz`).
  final String name;

  /// The browser-facing download URL.
  final String url;

  /// Parses one `assets[]` entry; null when name or URL is missing.
  static UpdateAsset? fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final url = json['browser_download_url'] as String?;
    if (name == null || url == null) {
      return null;
    }
    return UpdateAsset(name: name, url: url);
  }
}

/// Orders two dotted versions: negative when [a] is older than [b], zero when
/// they are the same release, positive when [a] is newer.
///
/// Equality alone is not enough for an updater: it cannot tell "there is a
/// newer release" from "the latest release is older than what is installed",
/// and the second case must never be applied silently. Semver pre-release
/// ordering is honoured (`1.2.0-rc.1` precedes `1.2.0`); build metadata after
/// `+` is ignored, as semver requires.
int compareVersions(String a, String b) {
  if (a == b) {
    return 0;
  }
  final (coreA, preA) = _splitPreRelease(a);
  final (coreB, preB) = _splitPreRelease(b);
  final pa = coreA.split('.');
  final pb = coreB.split('.');
  for (var i = 0; i < pa.length || i < pb.length; i++) {
    final na = i < pa.length ? int.tryParse(pa[i]) ?? 0 : 0;
    final nb = i < pb.length ? int.tryParse(pb[i]) ?? 0 : 0;
    if (na != nb) {
      return na < nb ? -1 : 1;
    }
  }
  if (preA == null && preB == null) {
    return 0;
  }
  // A pre-release precedes the release it leads up to.
  if (preA != null && preB == null) {
    return -1;
  }
  if (preA == null && preB != null) {
    return 1;
  }
  return preA!.compareTo(preB!);
}

/// Splits `1.2.0-rc.1+abc` into (`1.2.0`, `rc.1`).
(String, String?) _splitPreRelease(String version) {
  final withoutBuild = version.split('+').first;
  final dash = withoutBuild.indexOf('-');
  if (dash < 0) {
    return (withoutBuild, null);
  }
  return (withoutBuild.substring(0, dash), withoutBuild.substring(dash + 1));
}

/// Seam over [Process.run] for tests.
typedef ProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

/// Captures the single [Digest] a chunked SHA-256 conversion emits on close.
class _DigestSink implements Sink<Digest> {
  late final Digest digest;

  @override
  void add(Digest data) => digest = data;

  @override
  void close() {}
}
