import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet over how workflow jobs set themselves up.
///
/// The setup sequence (harden-runner → checkout → flutter-action → pub get →
/// pub get) was copy-pasted into 13 jobs, and the copies had diverged
/// in ways that mattered: the dependency-patch step ran in ci.yml and
/// release.yml but NOT in the three deploy workflows, web-workers.yml, or
/// release.yml's containers job.
///
/// Because `pubspec_overrides.yaml` is gitignored, those five jobs resolved a
/// DIFFERENT dependency graph than the CI job validating the same build — so a
/// green CI did not prove the deployed bundle built from the same deps. The
/// composite action applies patches by default; this test stops a job from
/// quietly going back to a hand-rolled preamble that skips it.
void main() {
  final root = Directory.current.path;
  final workflows = Directory(
    '$root/.github/workflows',
  ).listSync().whereType<File>().where((f) => f.path.endsWith('.yml')).toList();

  test('there are workflows to check', () {
    expect(workflows, isNotEmpty);
  });

  /// A workflow's executable lines — comments explain the history at length in
  /// these files, and prose about a step is not a second copy of it.
  String code(File f) => f
      .readAsLinesSync()
      .where((l) => !l.trimLeft().startsWith('#'))
      .join('\n');

  test('no workflow hand-rolls the Flutter setup', () {
    for (final file in workflows) {
      final name = file.uri.pathSegments.last;
      final source = code(file);
      expect(
        source,
        isNot(contains('subosito/flutter-action')),
        reason:
            '$name pins flutter-action directly. Use '
            './.github/actions/setup-flutter so the SDK pin and the egress '
            'baseline stay in one place.',
      );
      expect(
        source,
        isNot(contains('patchwork')),
        reason:
            '$name patches a dependency in place. Nothing in this repo depends '
            'on a patched package; vendor or wrap it instead.',
      );
    }
  });

  test('every job that builds or tests uses the composite', () {
    for (final file in workflows) {
      final name = file.uri.pathSegments.last;
      final source = file.readAsStringSync();
      final needsFlutter = RegExp(
        r'run: .*(flutter (build|test|analyze|pub)|dart run)',
      ).hasMatch(source);
      if (!needsFlutter) {
        continue;
      }
      expect(
        source,
        contains('./.github/actions/setup-flutter'),
        reason: '$name runs Flutter/Dart but never sets the SDK up',
      );
    }
  });

  test('every harden-runner pin is the same version', () {
    // Most jobs get harden-runner from the composite. `prepare` and `release`
    // legitimately do not — they never touch Flutter, so pulling the SDK in
    // just to harden would cost a minute each — but a direct pin must not drift
    // from the one the composite uses, or an upgrade silently covers some jobs
    // and not others.
    final pins = <String, String>{};
    for (final file in [
      ...workflows,
      File('$root/.github/actions/setup-flutter/action.yml'),
    ]) {
      for (final line in code(file).split('\n')) {
        final match = RegExp(
          r'step-security/harden-runner@([0-9a-f]{40})',
        ).firstMatch(line);
        if (match != null) {
          pins[file.uri.pathSegments.last] = match.group(1)!;
        }
      }
    }
    expect(pins, isNotEmpty);
    expect(
      pins.values.toSet(),
      hasLength(1),
      reason: 'harden-runner is pinned to different SHAs: $pins',
    );
  });

  test('the SDK composite enables the windowing feature flag', () {
    // The desktop shell is built on Flutter's experimental multi-window APIs
    // (lib/app/app_windows.dart), and the feature flag lives in the
    // MACHINE-global Flutter settings (~/.config/flutter/settings), not in the
    // repo — so a fresh runner builds with it OFF, and that binary throws
    //   Unsupported operation: Windowing APIs are not enabled.
    // at its first WindowController. On the desktop the exception unwinds
    // root-widget attach before anything is shown: a Dock icon with no window
    // at all. v0.0.1 shipped exactly that.
    final action = File(
      '$root/.github/actions/setup-flutter/action.yml',
    ).readAsStringSync();
    expect(
      action,
      contains('flutter config --enable-windowing'),
      reason:
          'setup-flutter lost the windowing feature flag — CI-built desktop '
          'binaries launch with no window at all without it',
    );
  });

  /// Splits a workflow into its jobs: the top-level two-space keys under
  /// `jobs:`. Line-based on purpose — a YAML dependency here would be a new
  /// dev_dependency for one test.
  Map<String, List<String>> jobsOf(File file) {
    final lines = file.readAsLinesSync();
    final jobs = <String, List<String>>{};
    var inJobs = false;
    String? current;
    for (final line in lines) {
      if (line.trimRight() == 'jobs:') {
        inJobs = true;
        continue;
      }
      if (!inJobs) {
        continue;
      }
      final header = RegExp(r'^  ([A-Za-z0-9_-]+):\s*$').firstMatch(line);
      if (header != null) {
        current = header.group(1)!;
        jobs[current] = <String>[];
        continue;
      }
      if (current != null) {
        jobs[current]!.add(line);
      }
    }
    return jobs;
  }

  test('every local action use is preceded by a checkout in the same job', () {
    // THE reason the first release failed. A local action is loaded from the
    // WORKSPACE, so GitHub cannot even read `.github/actions/<x>/action.yml`
    // until `actions/checkout` has run. Putting checkout inside the composite
    // and making the composite a job's first step is therefore impossible:
    //
    //   Can't find 'action.yml' ... under '.github/actions/setup-flutter'.
    //   Did you forget to run actions/checkout before running your local action?
    //
    // Every build job died in under six seconds. This is a hard platform
    // constraint, not a preference.
    for (final file in workflows) {
      final name = file.uri.pathSegments.last;
      for (final MapEntry(key: job, value: body) in jobsOf(file).entries) {
        final localAt = body.indexWhere(
          (l) => l.contains('uses: ./.github/actions/'),
        );
        if (localAt == -1) {
          continue;
        }
        final checkoutAt = body.indexWhere(
          (l) => l.contains('uses: actions/checkout@'),
        );
        expect(
          checkoutAt,
          isNot(-1),
          reason:
              '$name/$job uses a local action but never checks out the repo',
        );
        expect(
          checkoutAt,
          lessThan(localAt),
          reason:
              '$name/$job runs a local action before actions/checkout, so the '
              'action file does not exist yet and the job fails immediately',
        );
      }
    }
  });

  test('harden-runner is the first step of every job', () {
    // It installs the egress filter, so anything before it is unmonitored —
    // including the checkout that a local action forces to come early. Since
    // checkout must precede the composite, harden-runner cannot live inside the
    // composite either; it stays inline, first, in each job.
    for (final file in workflows) {
      final name = file.uri.pathSegments.last;
      for (final MapEntry(key: job, value: body) in jobsOf(file).entries) {
        // Only jobs that actually fetch something. ci.yml's `build` gate is
        // pure `echo` over other jobs' results — it has `permissions: {}`, no
        // checkout and no network, so hardening it would be ceremony.
        if (!body.any((l) => l.contains('uses: actions/checkout@'))) {
          continue;
        }
        final steps = body.where((l) => l.contains('- name: ')).toList();
        if (steps.isEmpty) {
          continue;
        }
        expect(
          steps.first,
          contains('Harden runner'),
          reason:
              '$name/$job checks out the repo but does not start with '
              'harden-runner, so its earlier steps egress unmonitored',
        );
      }
    }
  });

  test('build-linux allowlists every host its natives are fetched from', () {
    // `egress-policy: block` means this list is part of the build, not a
    // nicety: a host missing from it fails the release. That makes it exactly
    // the kind of thing a well-meaning refactor flattens into a generic
    // baseline — which is how apt-get started failing with exit 100 after the
    // workflows were consolidated.
    //
    // Each entry below is load-bearing for a specific native or step; see the
    // comment above the step in release.yml for what needs what.
    final release = File(
      '$root/.github/workflows/release.yml',
    ).readAsStringSync();
    final job = release.substring(
      release.indexOf('\n  build-linux:\n'),
      release.indexOf('\n  release:\n'),
    );
    const required = {
      '*.archive.ubuntu.com': 'apt-get (the Linux build deps)',
      'esm.ubuntu.com': 'apt-get',
      'index.crates.io': 'cargo (rift, fff, cc_watcher)',
      'static.crates.io': 'cargo',
      'static.rust-lang.org': 'the Rust toolchain',
      'gitlab.freedesktop.org': 'webrtc-audio-processing (aec)',
      'wrapdb.mesonbuild.com': "meson's abseil-cpp wrap (aec)",
      'downloads.sourceforge.net': 'the pinned LAME tarball',
      '*.dl.sourceforge.net': "sourceforge's per-run mirror redirect",
      'objects.githubusercontent.com': 'release assets (code-server, tarballs)',
      'fulcio.sigstore.dev': 'the SLSA provenance attestation',
      'rekor.sigstore.dev': 'the SLSA provenance attestation',
    };
    for (final MapEntry(key: host, value: why) in required.entries) {
      expect(
        job,
        contains(host),
        reason:
            'build-linux no longer allows egress to $host, which it needs for '
            '$why. With egress-policy: block that fails the release.',
      );
    }
  });

  test('build-linux installs every system lib the plugins configure against', () {
    // `flutter build linux` resolves these through pkg_check_modules at CMake
    // CONFIGURE time, so a missing one is not a degraded feature — it is a
    // release that never builds. libayatana-appindicator3-dev is the one that
    // did it: cnativeapi's tray declares it REQUIRED, and its absence failed
    // the job before a single object was compiled.
    //
    // libpulse-dev is the opposite failure and the more dangerous one: it is
    // OPTIONAL to flutter_webrtc's CMake, which prints a warning and builds a
    // release whose getDisplayMedia({audio:true}) yields no audio track — i.e.
    // meetings that record with no system audio, discovered by a user.
    final release = File(
      '$root/.github/workflows/release.yml',
    ).readAsStringSync();
    final job = release.substring(
      release.indexOf('\n  build-linux:\n'),
      release.indexOf('\n  release:\n'),
    );
    const required = {
      'libgtk-3-dev': 'the Flutter Linux shell (and gtk+-3.0 for every plugin)',
      'libayatana-appindicator3-dev': "cnativeapi's tray (REQUIRED)",
      'libx11-dev': 'cnativeapi (x11, REQUIRED)',
      'libxi-dev': 'cnativeapi (xi, REQUIRED)',
      'libsecret-1-dev': 'flutter_secure_storage_linux (REQUIRED)',
      'libgstreamer1.0-dev': 'audioplayers_linux (REQUIRED)',
      'libnotify-dev': 'local_notifier',
      'libpulse-dev': 'flutter_webrtc system-audio loopback capture',
    };
    for (final MapEntry(key: pkg, value: why) in required.entries) {
      expect(
        job,
        contains(pkg),
        reason:
            'build-linux no longer installs $pkg, which it needs for $why.',
      );
    }
  });

  test('the release build jobs share one prepare action', () {
    // Code generation, natives, credentials and the identity stamp were five
    // identical steps in each of the three build jobs.
    final release = File(
      '$root/.github/workflows/release.yml',
    ).readAsStringSync();
    expect(
      './.github/actions/prepare-release-build'.allMatches(release).length,
      3,
      reason:
          'each of build-macos/build-windows/build-linux should use it once',
    );
    for (final inlined in const [
      'bash scripts/natives/build_natives.sh',
      'bash scripts/release/builtin_credentials.sh inject',
      'dart run build_runner build',
    ]) {
      expect(
        release,
        isNot(contains(inlined)),
        reason: 'release.yml re-inlines "$inlined"; it belongs in the action',
      );
    }
  });

  test('the deploy workflows share one asset-budget implementation', () {
    for (final name in const [
      'deploy-webapp.yml',
      'deploy-remote.yml',
      'deploy-design-system.yml',
      'deploy-docs.yml',
    ]) {
      final source = File('$root/.github/workflows/$name').readAsStringSync();
      expect(
        source,
        contains('assert_asset_budget'),
        reason: '$name no longer uses the shared budget check',
      );
      expect(
        source,
        isNot(contains('find build/web -type f -size')),
        reason: '$name re-inlined the budget check',
      );
    }
  });

  test('deploy.json is written by the generator, never inline', () {
    // Three inline heredocs had drifted into two different version semantics:
    // release.yml wrote the tag version while the deploy workflows grepped a
    // pubspec, so the same PWA reported differently depending on its origin.
    for (final file in workflows) {
      final name = file.uri.pathSegments.last;
      final source = file.readAsStringSync();
      if (!source.contains('deploy.json')) {
        continue;
      }
      expect(
        source,
        isNot(contains('cat > ')),
        reason: '$name writes deploy.json inline; use gen_deploy_manifest.dart',
      );
    }
  });
}
