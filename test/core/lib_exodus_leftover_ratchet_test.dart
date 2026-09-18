import 'dart:io';

import 'package:test/test.dart';

/// Leftover in-process assumptions must not return to `lib/` (QUALITY.md R17,
/// R18).
void main() {
  late String root;
  late List<File> libDart;

  setUpAll(() {
    root = _repoRoot();
    libDart = Directory('$root/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  });

  test('lib/ does not call AgentRegistryImpl.global()', () {
    final hits = <String>[];
    final re = RegExp(r'AgentRegistryImpl\.global\s*\(');
    for (final f in libDart) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('///') ||
            line.trimLeft().startsWith('//')) {
          continue;
        }
        if (re.hasMatch(line)) {
          hits.add('${_rel(root, f.path)}:${i + 1}');
        }
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'Live roster must come from RPC (workspaceAgentsProvider + run logs), '
          'not AgentRegistryImpl.global() in the Flutter isolate:\n'
          '${hits.join('\n')}',
    );
  });

  test('lib/features/*/domain holds no create use cases', () {
    const allow = {
      'lib/features/calendar/domain/usecases/link_meeting_to_event_use_case.dart',
      'lib/features/vscode_theme/domain/vscode_editor_theme.dart',
      'lib/features/vscode_theme/domain/vscode_theme_importer.dart',
    };
    final hits = <String>[];
    final domain = Directory('$root/lib/features');
    if (!domain.existsSync()) {
      return;
    }
    for (final feature in domain.listSync().whereType<Directory>()) {
      final dir = Directory('${feature.path}/domain');
      if (!dir.existsSync()) {
        continue;
      }
      for (final f in dir.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) {
          continue;
        }
        final rel = _rel(root, f.path);
        if (allow.contains(rel)) {
          continue;
        }
        hits.add(rel);
      }
    }
    expect(
      hits,
      isEmpty,
      reason:
          'Domain use cases under lib/features belong on the server or in '
          'cc_domain. Remaining files:\n${hits.join('\n')}',
    );
  });

  test('lib/ cc_infra imports stay on the shrinking allowlist', () {
    const allow = {
      'lib/core/utils/cc_infra_logging.dart',
      'lib/core/storage/control_center_paths.dart',
      'lib/bootstrap/thin_client_boot.dart',
      'lib/core/server/tailscale_discovery.dart',
      'lib/features/meetings/presentation/notifiers/meeting_signal_collector_bindings_io.dart',
    };
    final re = RegExp(r"import 'package:cc_infra");
    final hits = <String>[];
    for (final f in libDart) {
      if (re.hasMatch(f.readAsStringSync())) {
        hits.add(_rel(root, f.path));
      }
    }
    hits.sort();
    final extra = hits.where((h) => !allow.contains(h)).toList();
    final stale = allow.where((h) => !hits.contains(h)).toList();
    expect(
      extra,
      isEmpty,
      reason:
          'New lib/ files import package:cc_infra. Promote the type to '
          'cc_domain or use an Rpc* adapter. Extra:\n${extra.join('\n')}',
    );
    expect(
      stale,
      isEmpty,
      reason:
          'Stale cc_infra allowlist entries (file gone or no longer imports '
          'cc_infra) — prune them from this test:\n${stale.join('\n')}',
    );
  });
}

String _rel(String root, String path) =>
    path.substring(root.length + 1).replaceAll(r'\', '/');

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (Directory('${dir.path}/lib').existsSync() &&
        File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
