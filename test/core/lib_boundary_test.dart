import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hard-boundary ratchet for the thin-client exodus.
///
/// The end state: `lib/` (the desktop/web Flutter app) holds ONLY presentation
/// + thin-client wiring; ALL backend/data/infra/native code lives in the
/// `packages/cc_*` packages and runs in the server. The package-side guard is
/// `package_purity_test.dart` (a server package must not import Flutter/app).
/// THIS test guards the other direction: backend must not (re-)accumulate in
/// `lib/`.
///
/// Each metric is a RATCHET — the current count must not EXCEED the recorded
/// baseline, so a new backend leak fails CI immediately, and every exodus batch
/// can only lower a baseline (target: 0). When you move backend out of lib and
/// the count drops, lower the baseline here in the same commit. NEVER raise a
/// baseline to make a leak pass — move the code into a package instead.
void main() {
  final libFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  // (label, matcher, baseline, why-it's-backend)
  final ratchets = <({String label, bool Function(String) match, int baseline, String why})>[
    (
      label: 'dart:ffi imports',
      match: (s) => s.contains("import 'dart:ffi'"),
      baseline: 0,
      why: 'Raw FFI is native/server work — it belongs in cc_natives, never the app.',
    ),
    (
      label: 'onnxruntime_v2 / sherpa_onnx imports',
      match: (s) =>
          s.contains('package:onnxruntime_v2') || s.contains('package:sherpa_onnx'),
      baseline: 0,
      why: 'On-device inference (embeddings/speech) lives in the pure-Dart cc_natives package behind cc_domain ports — lib/ holds zero such imports.',
    ),
    (
      label: 'direct package:drift API imports',
      match: (s) => s.contains("import 'package:drift/drift.dart'"),
      baseline: 0,
      why: 'Drift is persistence — only data-layer impls touch it, and those live in cc_persistence. '
          'The desktop native connection lives in the cc_app_native package; lib/ names QueryExecutor via that package re-export, not a drift import.',
    ),
    (
      label: 'package:sqlite3 imports',
      match: (s) => s.contains("import 'package:sqlite3/"),
      baseline: 0,
      why: 'Raw sqlite3 is the native DB driver — it belongs in the native connector package '
          '(cc_app_native) or the pure-Dart cc_persistence, never the app.',
    ),
    (
      label: 'package:sqlite_vector imports',
      match: (s) => s.contains("import 'package:sqlite_vector/"),
      baseline: 0,
      why: 'The sqlite_vector extension is loaded by the native connector in cc_app_native; '
          'lib/ never imports it.',
    ),
    (
      label: 'package:sqlite3_flutter_libs imports',
      match: (s) => s.contains("import 'package:sqlite3_flutter_libs/"),
      baseline: 0,
      why: 'sqlite3_flutter_libs (the native sqlite plugin) is declared and bundled by '
          'cc_app_native; lib/ never imports it.',
    ),
    (
      label: 'package:archive imports',
      match: (s) => s.contains("import 'package:archive/"),
      baseline: 0,
      why: 'Archive (de)compression is server-side model/asset work — the model '
          'managers that use it live in cc_infra (pure-Dart), never the app.',
    ),
    (
      label: 'package:rss_dart imports',
      match: (s) => s.contains("import 'package:rss_dart/"),
      baseline: 0,
      why: 'RSS/Atom parsing is server-side newsfeed work — it lives in cc_infra '
          '(RssFetcherService), reached over RPC; lib/ holds zero such imports.',
    ),
    (
      label: 'direct cc_persistence DAO / repo-impl imports',
      match: (s) =>
          s.contains('package:cc_persistence/repositories/') ||
          s.contains('package:cc_persistence/database/daos/'),
      baseline: 3,
      why: 'The app reaches data through repository INTERFACES (cc_domain) wired via providers — not DAOs/impls.',
    ),
    (
      label: 'repository IMPLEMENTATIONS (class X implements YRepository)',
      match: (s) => RegExp(r'class\s+\w+\s+implements\s+\w*Repository').hasMatch(s),
      baseline: 2,
      why: 'Repository implementations are the data layer — they belong in cc_persistence/cc_infra.',
    ),
    (
      label: 'package:lucide_icons_flutter imports',
      // Match the import directive only (not the package name appearing in a
      // doc comment or in AppIcons/web_icons `_package` string constants).
      match: (s) => RegExp(
        "import\\s+'package:lucide_icons_flutter",
      ).hasMatch(s),
      baseline: 0,
      why: 'The lucide_icons_flutter `LucideIcons` class has ~1500 static const '
          'fields; importing it stack-overflows the web dev compiler (DDC). lib/ '
          'must use the web-safe codepoint set in lib/shared/icons/app_icons.dart '
          '(AppIcons.*) instead so the UI stays web-buildable.',
    ),
  ];

  for (final r in ratchets) {
    test('lib/ backend ratchet: ${r.label} <= ${r.baseline}', () {
      final hits = <String>[];
      for (final f in libFiles) {
        if (r.match(f.readAsStringSync())) {
          hits.add(f.path);
        }
      }
      expect(
        hits.length,
        lessThanOrEqualTo(r.baseline),
        reason:
            '${r.label}: found ${hits.length} (baseline ${r.baseline}). ${r.why}\n'
            'If you ADDED one, move it into a package instead. If you REMOVED '
            'one, lower the baseline in this test.\nFiles:\n${hits.join("\n")}',
      );
    });
  }
}
