// -*- mode: dart -*-
// Writes the `deploy.json` manifest a hosted web client polls to notice that
// the origin has moved on and offer a consent-driven refresh.
//
// It derives every field from the ALREADY-STAMPED
// packages/cc_domain/lib/src/build_info.dart, which is the whole point: the
// manifest and the `BuildInfo` compiled into the bundle are then the same
// identity by construction. This replaced three separate inline heredocs (in
// release.yml, deploy-webapp.yml and deploy-remote.yml) that had drifted into
// two different semantics — the release wrote the TAG version while the deploy
// workflows grepped a pubspec, so the same PWA reported a different version
// depending on whether it came from GHCR or Cloudflare. One of them even read
// apps/cc_remote/pubspec.yaml while its own gen_build_info.dart read the root.
//
// `deploy.json`, NOT `version.json`: `flutter build web` writes its own
// build/web/version.json (app_name / build_number, no git sha) and would
// overwrite this.
//
// The clients compare the GIT SHA (lib/core/update/deployed_version.dart,
// apps/cc_remote/lib/update/remote_update.dart) — `version` is displayed, not
// compared.
//
// Usage (repo root, AFTER gen_build_info.dart and the web build):
//   dart run tool/gen_deploy_manifest.dart build/web
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/gen_deploy_manifest.dart <out-dir>');
    exit(2);
  }
  final outDir = Directory(args.single);
  if (!outDir.existsSync()) {
    stderr.writeln(
      'gen_deploy_manifest: ${outDir.path} does not exist — '
      'run the web build first.',
    );
    exit(1);
  }

  final info = _readBuildInfo();
  // A manifest claiming `dev` would make every client believe a new deploy had
  // landed on every poll, so refuse rather than ship a manifest that lies.
  if (info['gitSha'] == 'dev') {
    stderr.writeln(
      'gen_deploy_manifest: build_info.dart is unstamped (gitSha=dev). Run '
      '`dart run tool/gen_build_info.dart` first, or the deployed clients will '
      'compare against a placeholder.',
    );
    exit(1);
  }

  final file = File('${outDir.path}/deploy.json');
  file.writeAsStringSync('${jsonEncode(info)}\n');
  stdout.writeln('Wrote ${file.path}: ${jsonEncode(info)}');
}

/// Parses the three `const` values out of the stamped build-identity file.
///
/// Reading the generated Dart (rather than re-deriving from git + pubspec) is
/// what guarantees the manifest and the compiled-in `BuildInfo` agree: there is
/// only one place either can come from.
Map<String, String> _readBuildInfo() {
  final file = File('packages/cc_domain/lib/src/build_info.dart');
  if (!file.existsSync()) {
    stderr.writeln('gen_deploy_manifest: ${file.path} not found');
    exit(1);
  }
  final source = file.readAsStringSync();

  String read(String name) {
    final match = RegExp("String $name = '([^']*)'").firstMatch(source);
    if (match == null) {
      stderr.writeln('gen_deploy_manifest: no $name in ${file.path}');
      exit(1);
    }
    return match.group(1)!;
  }

  return {
    'version': read('buildVersion'),
    'gitSha': read('buildGitSha'),
    'builtAt': read('buildTime'),
  };
}
