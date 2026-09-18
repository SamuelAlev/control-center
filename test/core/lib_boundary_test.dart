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
/// baseline, so a new backend leak fails CI immediately and every exodus batch
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
      why:
          'Raw FFI is native/server work — it belongs in cc_natives, never the app.',
    ),
    (
      label: 'on-device inference imports',
      match: (s) =>
          // On-device inference has no pub dependency; these two clauses keep
          // it that way. A package that imports `package:flutter` cannot link
          // into the Flutter-free server binary and a second ONNX Runtime in
          // the process is a Windows loader hazard.
          s.contains('package:onnxruntime_v2') ||
          s.contains('package:sherpa_onnx') ||
          // The native is server-side too: the desktop SHIPS libcc_inference
          // (packaging stages it into the bundle so the cc_server it spawns
          // can load it) but must never BIND it. An import here would mean
          // inference running in the Flutter isolate.
          s.contains('cc_inference_bindings') ||
          s.contains('inference_library.dart'),
      baseline: 0,
      why:
          'On-device inference (embeddings/speech) lives in the pure-Dart cc_natives package behind cc_domain ports and executes in cc_server — lib/ holds zero such imports.',
    ),
    (
      label: 'direct package:drift API imports',
      match: (s) => s.contains("import 'package:drift/drift.dart'"),
      baseline: 0,
      why:
          'Drift is persistence — only data-layer impls touch it and those live in cc_persistence. '
          'The desktop native connection lives in the cc_app_native package; lib/ names QueryExecutor via that package re-export, not a drift import.',
    ),
    (
      label: 'package:sqlite3 imports',
      match: (s) => s.contains("import 'package:sqlite3/"),
      baseline: 0,
      why:
          'Raw sqlite3 is the native DB driver — it belongs in the native connector package '
          '(cc_app_native) or the pure-Dart cc_persistence, never the app.',
    ),
    (
      label: 'package:sqlite_vector imports',
      match: (s) => s.contains("import 'package:sqlite_vector/"),
      baseline: 0,
      why:
          'The sqlite_vector extension is loaded by the native connector in cc_app_native; '
          'lib/ never imports it.',
    ),
    (
      label: 'package:sqlite3_flutter_libs imports',
      match: (s) => s.contains("import 'package:sqlite3_flutter_libs/"),
      baseline: 0,
      why:
          'sqlite3_flutter_libs (the native sqlite plugin) is declared and bundled by '
          'cc_app_native; lib/ never imports it.',
    ),
    (
      label: 'package:archive imports',
      match: (s) => s.contains("import 'package:archive/"),
      baseline: 0,
      why:
          'Archive (de)compression is server-side model/asset work — the model '
          'managers that use it live in cc_infra (pure-Dart), never the app.',
    ),
    (
      label: 'package:rss_dart imports',
      match: (s) => s.contains("import 'package:rss_dart/"),
      baseline: 0,
      why:
          'RSS/Atom parsing is server-side newsfeed work — it lives in cc_infra '
          '(RssFetcherService), reached over RPC; lib/ holds zero such imports.',
    ),
    (
      label: 'direct cc_persistence DAO / repo-impl imports',
      match: (s) =>
          s.contains('package:cc_persistence/repositories/') ||
          s.contains('package:cc_persistence/database/daos/'),
      baseline: 0,
      why:
          'The app reaches data through repository INTERFACES (cc_domain) wired via providers — not DAOs/impls.',
    ),
    (
      label: 'package:cc_persistence imports (any)',
      match: (s) => s.contains('package:cc_persistence'),
      baseline: 0,
      why:
          'The desktop is a thin client exactly like web: it opens no database, so it never links '
          'cc_persistence at all (not even for logging seams) — the connected cc_server owns the DB.',
    ),
    (
      label: 'package:cc_server_core imports',
      match: (s) => s.contains('package:cc_server_core'),
      baseline: 0,
      why:
          'cc_server_core builds the MCP tool registry + RPC catalog for the headless cc_server binary. '
          'The desktop hosts no MCP server and no in-process RPC catalog — it only ever talks to a '
          'connected cc_server over rpcClientProvider.',
    ),
    (
      label: 'package:cc_host imports',
      match: (s) => s.contains('package:cc_host'),
      baseline: 0,
      why:
          'cc_host is the in-process WebRTC/RPC remote-control kernel — server-side execution. The '
          'desktop pairing UI talks to the connected cc_server over `pairing.*` RPC ops instead.',
    ),
    (
      label: 'package:cc_mcp imports',
      match: (s) => s.contains('package:cc_mcp'),
      baseline: 0,
      why:
          'cc_mcp is the MCP tool/dispatcher implementation that links into the headless cc_server '
          'binary. The desktop builds no MCP registry and hosts no MCP server.',
    ),
    (
      label: 'repository IMPLEMENTATIONS (class X implements YRepository)',
      match: (s) =>
          RegExp(r'class\s+\w+\s+implements\s+\w*Repository').hasMatch(s),
      baseline: 0,
      why:
          'Repository implementations are the data layer — they belong in '
          'cc_data / cc_persistence / cc_infra. RpcCacheRepository and '
          'KeyValueSiteAllowlistRepository now live in cc_data. Do not raise '
          'this baseline to admit a lib/ impl.',
    ),
    (
      label: 'icon package imports (phosphor)',
      // Match the import directive only (not the package name appearing in a
      // doc comment or in AppIcons `_package` string constants).
      match: (s) =>
          RegExp("import\\s+'package:phosphoricons_flutter").hasMatch(s),
      baseline: 0,
      why:
          'Icon font packages expose ~1500-member classes of static const '
          'fields; importing one stack-overflows the web dev compiler (DDC), '
          'and their pubspecs bundle every style whether or not it is used. '
          'lib/ must use the web-safe codepoint set in '
          'lib/shared/icons/app_icons.dart (AppIcons.*, generated by '
          'tool/gen_icon_seams.py), which resolves against the single Phosphor '
          'style vendored by cc_ui.',
    ),
    (
      label: 'package:dio imports (direct HTTP client)',
      match: (s) => s.contains("import 'package:dio/"),
      baseline: 0,
      why:
          'External network I/O belongs in cc_server, not the client — clients call '
          'server RPC ops. Filter-list downloads now go through '
          '`newsfeed.filterLists.*`. Do NOT raise this baseline.',
    ),
    (
      label: 'Process.run / Process.start (process execution)',
      match: (s) => RegExp(r'Process\.(run|start)\(').hasMatch(s),
      baseline: 0,
      why:
          'Process execution belongs in cc_server / cc_infra. NativeEditorLauncher, '
          'RevealInFileManager, CcServerProcess and the Tailscale CLI now live in '
          'cc_infra. The former leak pr_review/.../pr_doc_agent.dart was UNWIRED '
          'dead code and was DELETED rather than have an unused server RPC op built '
          'for it. Do not raise this baseline.',
    ),
    (
      label: 'package:cc_infra imports (server-side infra coupling)',
      match: (s) => s.contains("import 'package:cc_infra"),
      baseline: 5,
      why:
          'cc_infra is the server-side VM-only adapter package (git, process, dio '
          'clients, sandbox). A thin client should not link it. Remaining hits are '
          'honest IO seams: logging (CcInfraLog), CcPaths, spawning the local '
          'cc_server, Tailscale discovery before a connection exists, and the '
          'desktop process-meeting signal collector. Never raise this.',
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
