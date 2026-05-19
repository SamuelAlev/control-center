import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture rail for the client/server package split (the "backend exodus").
///
/// Each server-side package answers to a hard dependency constraint, and the
/// north star is a Flutter-FREE `dart build cli` server binary. `cc_server`
/// (apps/cc_server) links `cc_server_core → cc_host + cc_infra + cc_persistence
/// + cc_domain + cc_rpc`, so a single `package:flutter` import anywhere in that
/// graph would silently contaminate the binary. `cc_natives` USED to be the
/// other contaminant (it was a Flutter plugin); it is now a pure-Dart `dart:ffi`
/// leaf, so it is ALLOWED in the VM-only server packages (cc_infra /
/// cc_server_core) and instead guarded here against ever re-acquiring Flutter or
/// a back-edge to another cc_* package. Symmetrically, `cc_data` is the web-safe thin-client
/// data layer: a `dart:io`/drift import there breaks `flutter build web`. These
/// tests fail loudly the moment a batch puts the wrong dependency in the wrong
/// package — the guard that lets the exodus "expand easily" instead of
/// regressing the north star. Recommended by the architecture review
/// (2026-06-19), extended after the same review flagged that the binary
/// (apps/cc_server) and the web-safe layer (cc_data) were themselves unguarded.
///
/// Forbidden lists are URI prefixes that must NOT appear in any `import`/`export`
/// directive in that package's source.
void main() {
  // Each package's forbidden import-URI prefixes.
  const rules = <String, List<String>>{
    // Pure contracts: zero infrastructure, web-safe, no app back-reference.
    'cc_domain': [
      'package:flutter',
      'dart:ui',
      'dart:io',
      'dart:ffi',
      'package:drift',
      'package:dio',
      'package:sqlite3',
      'package:cc_natives',
      'package:cc_host',
      'package:cc_infra',
      'package:cc_persistence',
      'package:control_center',
    ],
    // Web-safe RPC client/transport half.
    'cc_rpc': [
      'package:flutter',
      'dart:ui',
      'dart:io',
      'dart:ffi',
      'package:drift',
      'package:cc_natives',
      'package:control_center',
    ],
    // Web-safe thin-client data layer (RPC-backed repository adapters). Must run
    // on Flutter web: no dart:io/ffi, no drift/sqlite3, no VM infra/persistence,
    // no Flutter. Only cc_domain + cc_rpc.
    // Web-safe thin-client data layer — CLOSED allowlist: only cc_domain +
    // cc_rpc. Anything else (dart:io/ffi, drift/sqlite3/dio, ANY VM/server
    // package incl. cc_mcp/cc_server_core) would break `flutter build web`.
    'cc_data': [
      'package:flutter',
      'dart:ui',
      'dart:io',
      'dart:ffi',
      'package:drift',
      'package:sqlite3',
      'package:dio',
      'package:cc_natives',
      'package:cc_infra',
      'package:cc_persistence',
      'package:cc_host',
      'package:cc_mcp',
      'package:cc_server_core',
      'package:control_center',
    ],
    // RPC kernel ONLY (cc_domain + cc_rpc + dart:io + meta). No infra deps, no
    // Flutter, no FFI — it links into the Flutter-free server binary. Forbid
    // every higher server package so the kernel can never back-edge.
    'cc_host': [
      'package:flutter',
      'dart:ui',
      'dart:ffi',
      'package:cc_natives',
      'package:cc_infra',
      'package:cc_persistence',
      'package:cc_server_core',
      'package:cc_mcp',
      'package:dio',
      'package:drift',
      'package:sqlite3',
      'package:control_center',
    ],
    // VM-only dart:io infra adapters. cc_natives (now a pure-Dart dart:ffi leaf,
    // Flutter-free) is ALLOWED here — this is where the rift/fff/tree-sitter/aec
    // adapters live. Still never Flutter, and a LEAF: no back-edge to the kernel,
    // persistence, composition, mcp, or the web-data layer.
    'cc_infra': [
      'package:flutter',
      'dart:ui',
      'package:cc_host',
      'package:cc_persistence',
      'package:cc_server_core',
      'package:cc_mcp',
      'package:cc_data',
      'package:control_center',
    ],
    // Pure-Dart Drift persistence (drift + sqlite3 + dart:io are expected). No
    // native need — keep cc_natives out (the indexer composes in cc_infra). A
    // LEAF alongside cc_infra: no back-edge to kernel/infra/composition/mcp/data.
    'cc_persistence': [
      'package:flutter',
      'dart:ui',
      'package:cc_natives',
      'package:cc_host',
      'package:cc_infra',
      'package:cc_server_core',
      'package:cc_mcp',
      'package:cc_data',
      'package:control_center',
    ],
    // The agent-facing MCP tool surface (Ref-free tools + dispatcher). Pure
    // Dart on cc_domain + cc_rpc + cc_infra, so it links into the server binary.
    // No Flutter, no app back-reference, no Drift/native (it reaches data via
    // cc_domain repo interfaces; the server injects the impls).
    'cc_mcp': [
      'package:flutter',
      'dart:ui',
      'package:control_center',
      'package:cc_natives',
      'package:cc_persistence',
      'package:cc_server_core',
      'package:drift',
      'package:sqlite3',
    ],
    // Pure-Dart app-server composition. cc_natives IS now allowed here: the
    // native-composing DaoCodeGraphRepository (uses cc_natives' content-addressed
    // codeSymbolId/codeEdgeId helpers + cc_persistence DAOs) landed in this
    // package — the documented re-allow condition (review §3). cc_natives is
    // pure-Dart FFI since exodus 32, so it never contaminates the server binary
    // (cc_infra already depends on it).
    'cc_server_core': [
      'package:flutter',
      'dart:ui',
      'package:control_center',
    ],
    // The actual shipped binary (apps/cc_server). The one place a Flutter import
    // literally contaminates `dart build cli` output — so guard it explicitly.
    // It composes via cc_server_core, so it needs no direct cc_natives import.
    'cc_server': [
      'package:flutter',
      'dart:ui',
      'package:cc_natives',
      'package:control_center',
    ],
    // Pure-Dart dart:ffi native bindings leaf (rift/fff/tree-sitter/aec) PLUS
    // the on-device-inference impls (sherpa-onnx ASR/VAD/diarization +
    // onnxruntime_v2 embeddings) that moved here out of the Flutter app. dart:io
    // and dart:ffi are its whole job. It must stay Flutter-free so it links into
    // the server binary without dragging Flutter (this guard makes the
    // de-Fluttering permanent — the `package:flutter/foundation` -> `package:meta`
    // swap for `@immutable`, and the patchwork patch that strips
    // onnxruntime_v2's one `package:flutter/services.dart` import). cc_domain IS
    // allowed: the inference impls implement cc_domain ports
    // (SpeechTranscriber/SpeechActivityDetector/MeetingDiarizationPort) and name
    // its value objects (EmbeddingModelPaths/VoiceModelPaths/Span/
    // DiarizationResult). cc_domain is itself a Flutter-free pure-Dart leaf, so
    // depending on it does NOT contaminate the server binary. No OTHER cc_*
    // back-edge nor the app.
    'cc_natives': [
      'package:flutter',
      'dart:ui',
      'package:control_center',
      'package:cc_rpc',
      'package:cc_host',
      'package:cc_infra',
      'package:cc_persistence',
      'package:cc_server_core',
      'package:cc_data',
      'package:drift',
    ],
    // Flutter-aware native glue for the DESKTOP app only: the in-process
    // Drift/SQLite connection that needs the native sqlite plugin
    // (sqlite3_flutter_libs) + the sqlite_vector extension. It is a Flutter
    // package, so package:flutter / dart:ui ARE allowed (unlike the server
    // packages). It MAY import cc_persistence (for AppDatabase's QueryExecutor)
    // + cc_domain + drift/sqlite3/sqlite3_flutter_libs/sqlite_vector. It must
  };

  // Resolves the source directories to scan for a package. apps/cc_server lives
  // outside packages/ and keeps its entrypoint in bin/.
  List<String> sourceDirsFor(String pkg) => pkg == 'cc_server'
      ? const ['apps/cc_server/lib', 'apps/cc_server/bin']
      : ['packages/$pkg/lib'];

  String pubspecFor(String pkg) => pkg == 'cc_server'
      ? 'apps/cc_server/pubspec.yaml'
      : 'packages/$pkg/pubspec.yaml';

  // Accept BOTH single- and double-quoted directives — a double-quoted
  // `import "package:flutter/...";` must not slip past the rail.
  final directive = RegExp(r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""");

  for (final entry in rules.entries) {
    final pkg = entry.key;
    final forbidden = entry.value;
    test('$pkg source imports nothing forbidden (Flutter-free server rail)', () {
      final dirs = sourceDirsFor(pkg).map(Directory.new).toList();
      expect(
        dirs.any((d) => d.existsSync()),
        isTrue,
        reason: 'no source dirs exist for $pkg (${sourceDirsFor(pkg)})',
      );
      final violations = <String>[];
      for (final dir in dirs.where((d) => d.existsSync())) {
        for (final f in dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
          for (final line in f.readAsLinesSync()) {
            final m = directive.firstMatch(line);
            if (m == null) {
              continue;
            }
            final uri = m.group(1)!;
            for (final bad in forbidden) {
              if (uri.startsWith(bad)) {
                violations.add('${f.path}: $uri');
              }
            }
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            '$pkg must not import ${forbidden.join(", ")}. Found:\n'
            '${violations.join("\n")}',
      );
    });
  }

  // Pubspec-dependency guard. The import check above is the primary rail, but a
  // forbidden dependency can still be added to a package's pubspec without an
  // import yet (e.g. an IDE/`pub add` quick-fix while a bad import existed
  // transiently). Because the pub WORKSPACE resolves all member packages, such
  // a dep silently inverts the dependency direction and lets a future import
  // through `flutter analyze` unnoticed — only this test would catch it. So
  // assert the pubspec `dependencies:` AND `dependency_overrides:` carry
  // nothing forbidden (an override is the more dangerous vector — it reroutes a
  // dep graph-wide and is the exact scenario this guard defends).
  const forbiddenDeps = <String, List<String>>{
    'cc_domain': [
      'control_center',
      'cc_infra',
      'cc_host',
      'cc_persistence',
      'cc_server_core',
      'cc_rpc',
      'drift',
      'dio',
      'sqlite3',
      'cc_natives',
      'flutter',
    ],
    'cc_rpc': ['control_center', 'cc_natives', 'drift', 'flutter'],
    'cc_data': [
      'control_center',
      'cc_infra',
      'cc_persistence',
      'cc_host',
      'cc_server_core',
      'cc_mcp',
      'cc_natives',
      'drift',
      'sqlite3',
      'dio',
      'flutter',
    ],
    'cc_host': [
      'control_center',
      'cc_infra',
      'cc_persistence',
      'cc_server_core',
      'cc_mcp',
      'cc_natives',
      'dio',
      'drift',
      'sqlite3',
      'flutter',
    ],
    'cc_infra': [
      'control_center',
      'cc_host',
      'cc_persistence',
      'cc_server_core',
      'cc_mcp',
      'cc_data',
      'flutter',
    ],
    'cc_persistence': [
      'control_center',
      'cc_host',
      'cc_infra',
      'cc_server_core',
      'cc_mcp',
      'cc_data',
      'cc_natives',
      'flutter',
    ],
    'cc_mcp': [
      'control_center',
      'flutter',
      'cc_natives',
      'cc_persistence',
      'cc_server_core',
      'drift',
      'sqlite3',
    ],
    'cc_server_core': ['control_center', 'flutter'],
    'cc_server': ['control_center', 'cc_natives', 'flutter'],
    // The native + on-device-inference leaf: no Flutter, no app, no Drift, no
    // cc_* back-edge EXCEPT cc_domain (the inference impls implement its ports /
    // name its value objects; cc_domain is a Flutter-free pure-Dart leaf so the
    // dep never contaminates the server binary).
    'cc_natives': [
      'control_center',
      'flutter',
      'drift',
      'cc_rpc',
      'cc_host',
      'cc_infra',
      'cc_persistence',
      'cc_server_core',
      'cc_data',
    ],
  };
  final depLine = RegExp(r'^\s{2}([A-Za-z0-9_]+)\s*:');

  // Scans the named top-level block (e.g. `dependencies:` /
  // `dependency_overrides:`) and returns the immediate child keys.
  List<String> childKeysOf(List<String> lines, String block) {
    final keys = <String>[];
    var inBlock = false;
    for (final line in lines) {
      if (line.startsWith('$block:')) {
        inBlock = true;
        continue;
      }
      // Any other top-level key (no leading space) ends the block.
      if (inBlock && line.isNotEmpty && !line.startsWith(' ')) {
        break;
      }
      if (!inBlock) {
        continue;
      }
      final m = depLine.firstMatch(line);
      if (m != null) {
        keys.add(m.group(1)!);
      }
    }
    return keys;
  }

  for (final entry in forbiddenDeps.entries) {
    final pkg = entry.key;
    final forbidden = entry.value.toSet();
    test('$pkg/pubspec depends on nothing forbidden (Flutter-free server rail)',
        () {
      final file = File(pubspecFor(pkg));
      expect(file.existsSync(), isTrue, reason: 'missing pubspec for $pkg');
      final lines = file.readAsLinesSync();
      // Scan `dependencies:` AND `dependency_overrides:` (NOT dev_dependencies).
      final declared = <String>[
        ...childKeysOf(lines, 'dependencies'),
        ...childKeysOf(lines, 'dependency_overrides'),
      ];
      final bad = declared.where(forbidden.contains).toList();
      expect(
        bad,
        isEmpty,
        reason:
            '$pkg/pubspec.yaml must not depend on ${forbidden.join(", ")}. '
            'Found: ${bad.join(", ")}. A forbidden dependency here inverts the '
            'package graph and links Flutter/app code into the server binary '
            '(or dart:io/drift into the web-safe layer).',
      );
    });
  }
}
