import 'dart:convert';

import 'package:cc_domain/features/environments/domain/value_objects/environment_naming.dart';

/// Files the scan reads, relative to the repo root.
const List<String> kEnvironmentDraftFiles = [
  'compose.yaml',
  'compose.yml',
  'docker-compose.yaml',
  'docker-compose.yml',
  'conductor.json',
  'run-pty.json',
  'Procfile',
  'package.json',
  'pnpm-lock.yaml',
  'yarn.lock',
  'package-lock.json',
  'bun.lock',
  'bun.lockb',
  'Cargo.toml',
  'pubspec.yaml',
];

/// Proposes a definition from a repo's own files.
///
/// Generic on purpose: it recognises file formats, never products. The result
/// goes to the editor for an admin to review and save, so a wrong guess costs
/// an edit. [files] maps a path from [kEnvironmentDraftFiles] to its content;
/// absent paths are simply missing.
Map<String, dynamic> draftEnvironmentDefinition({
  required String repoId,
  required String repoName,
  required Map<String, String> files,
}) {
  final components = <Map<String, dynamic>>[];
  final notes = <String>[];
  final usedIds = <String>{};

  String uniqueId(String wanted) {
    final base = _componentId(wanted);
    var id = base;
    var suffix = 2;
    while (!usedIds.add(id)) {
      id = '$base-$suffix';
      suffix += 1;
    }
    return id;
  }

  final conductor = _json(files['conductor.json']);
  final conductorScripts = conductor is Map ? conductor['scripts'] : null;
  final setupScript = conductorScripts is Map
      ? conductorScripts['setup']
      : null;
  final runScript = conductorScripts is Map ? conductorScripts['run'] : null;

  // Dependencies follow the worktree: agents need them with or without a stack.
  final install = setupScript is String
      ? setupScript
      : _installCommand(files.keys.toSet());
  if (install != null) {
    components.add({
      'kind': 'task',
      'id': uniqueId('deps'),
      'label': 'Install dependencies',
      'when': ['provision', 'change'],
      'onChange': _lockfiles(files.keys.toSet()),
      'command': install,
    });
  }

  for (final file in const [
    'compose.yaml',
    'compose.yml',
    'docker-compose.yaml',
    'docker-compose.yml',
  ]) {
    if (files.containsKey(file)) {
      components.add({
        'kind': 'compose',
        'id': uniqueId('stack'),
        'file': file,
      });
      break;
    }
  }

  final processes = _processes(files, runScript);
  for (final process in processes) {
    final id = uniqueId(process.id);
    components.add({
      'kind': 'process',
      'id': id,
      'label': process.label,
      'command': process.command,
    });
  }
  if (processes.isNotEmpty) {
    notes.add(
      'Processes keep their usual ports until you declare a port for each '
      'one. Without that, two spaces can collide.',
    );
  }

  final project = environmentSlug(repoName, maxLength: 20);
  return {
    'definition': {
      'contract': 1,
      'name': repoName,
      'repos': {
        'app': {'repoId': repoId, 'anchor': true, 'required': true},
      },
      'naming': {'template': '{branch}', 'project': project},
      'components': components,
    },
    'notes': notes,
  };
}

class _DraftProcess {
  const _DraftProcess(this.id, this.label, this.command);

  final String id;
  final String label;
  final Object command;
}

List<_DraftProcess> _processes(Map<String, String> files, Object? runScript) {
  final runPty = _json(files['run-pty.json']);
  if (runPty is List && runPty.isNotEmpty) {
    return [
      for (final (index, entry) in runPty.indexed)
        if (entry is Map && entry['command'] is List)
          _DraftProcess(
            '${entry['title'] ?? 'process-$index'}',
            '${entry['title'] ?? 'Process ${index + 1}'}',
            [for (final part in entry['command'] as List) '$part'],
          ),
    ];
  }
  final procfile = files['Procfile'];
  if (procfile != null) {
    final found = <_DraftProcess>[];
    for (final line in const LineSplitter().convert(procfile)) {
      final separator = line.indexOf(':');
      if (separator <= 0 || line.startsWith('#')) {
        continue;
      }
      final name = line.substring(0, separator).trim();
      found.add(
        _DraftProcess(name, name, line.substring(separator + 1).trim()),
      );
    }
    if (found.isNotEmpty) {
      return found;
    }
  }
  if (runScript is String) {
    return [_DraftProcess('run', 'Dev server', runScript)];
  }
  final package = _json(files['package.json']);
  final scripts = package is Map ? package['scripts'] : null;
  if (scripts is Map && scripts['dev'] is String) {
    return [
      _DraftProcess('web', 'Dev server', '${_runner(files.keys.toSet())} dev'),
    ];
  }
  return const [];
}

String _runner(Set<String> files) {
  if (files.contains('pnpm-lock.yaml')) {
    return 'pnpm';
  }
  if (files.contains('yarn.lock')) {
    return 'yarn';
  }
  if (files.contains('bun.lock') || files.contains('bun.lockb')) {
    return 'bun run';
  }
  return 'npm run';
}

String? _installCommand(Set<String> files) {
  if (files.contains('pnpm-lock.yaml')) {
    return 'pnpm install --frozen-lockfile --prefer-offline';
  }
  if (files.contains('yarn.lock')) {
    return 'yarn install --frozen-lockfile';
  }
  if (files.contains('bun.lock') || files.contains('bun.lockb')) {
    return 'bun install --frozen-lockfile';
  }
  if (files.contains('package-lock.json')) {
    return 'npm ci';
  }
  return null;
}

List<String> _lockfiles(Set<String> files) => [
  for (final file in const [
    'pnpm-lock.yaml',
    'yarn.lock',
    'package-lock.json',
    'bun.lock',
    'bun.lockb',
  ])
    if (files.contains(file)) file,
];

String _componentId(String value) {
  final slug = value
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9_-]+'), '-')
      .replaceAll(RegExp('^[^a-z]+|-+\$'), '');
  if (slug.isEmpty) {
    return 'process';
  }
  return slug.length > 40 ? slug.substring(0, 40) : slug;
}

Object? _json(String? text) {
  if (text == null) {
    return null;
  }
  try {
    return jsonDecode(text);
  } on FormatException {
    return null;
  }
}
