import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_infra/src/environments/compose_driver.dart'
    show ComposeServiceState;
import 'package:cc_infra/src/rigs/smolvm_enclosure_backend.dart'
    show kSmolvmEnvironmentWorkdir;
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

// The pure half of environment rigs: reading a compose file on the host
// without Docker, which decides the machine's egress, and reading what the
// guest reports back. Nothing here touches a machine.

/// A stack's images could not be worked out, so neither could what its machine
/// may reach. Egress is fixed at boot: a guess is either a stack that cannot
/// pull or a hole in the allowlist.
class EnvironmentRigImagesUnresolved implements Exception {
  /// Creates an [EnvironmentRigImagesUnresolved].
  const EnvironmentRigImagesUnresolved(this.message);

  /// What could not be resolved.
  final String message;

  @override
  String toString() => 'EnvironmentRigImagesUnresolved: $message';
}

final RegExp _fromLine = RegExp(
  r'^\s*FROM\s+(?:--\S+\s+)*(\S+)(?:\s+AS\s+(\S+))?',
  caseSensitive: false,
  multiLine: true,
);

/// The base images of [dockerfile]'s text. Stage names are not images.
Set<String> dockerfileBaseImages(String dockerfile) {
  final stages = <String>{'scratch'};
  final images = <String>{};
  for (final match in _fromLine.allMatches(dockerfile)) {
    final image = match.group(1)!;
    if (!stages.contains(image.toLowerCase())) {
      if (image.contains(r'$')) {
        throw EnvironmentRigImagesUnresolved(
          'A Dockerfile names its base image through a variable ("$image"), '
          'so the images a rig must reach cannot be known before it boots.',
        );
      }
      images.add(image);
    }
    final stage = match.group(2);
    if (stage != null) {
      stages.add(stage.toLowerCase());
    }
  }
  return images;
}

/// Every image a compose [model] pulls, built services' bases included.
///
/// Only [services] count when given. A build context resolves against
/// [directory] and must stay inside [root]: the file comes from the repo, which
/// on a fork is not ours, and this read happens on the host.
Set<String> composeModelImages(
  Map<String, dynamic> model, {
  Iterable<String>? services,
  String? directory,
  String? root,
}) {
  final declared = model['services'];
  if (declared is! Map) {
    return const {};
  }
  final wanted = services == null || services.isEmpty ? null : services.toSet();
  final images = <String>{};
  for (final entry in declared.entries) {
    if ((wanted != null && !wanted.contains(entry.key)) ||
        entry.value is! Map) {
      continue;
    }
    final service = entry.value as Map;
    final build = service['build'];
    if (build == null) {
      final image = service['image'];
      // An unset `${VAR}` leaves no image at all, and skipping the service
      // would boot a machine whose allowlist cannot pull it.
      if (image is! String || image.trim().isEmpty) {
        throw EnvironmentRigImagesUnresolved(
          'Service "${entry.key}" names no image, or names it through an '
          'unset variable.',
        );
      }
      images.add(image);
      continue;
    }
    images.addAll(
      dockerfileBaseImages(_dockerfileOf(entry.key, build, directory, root)),
    );
  }
  return images;
}

String _dockerfileOf(
  Object? service,
  Object build,
  String? base,
  String? root,
) {
  final spec = build is String ? {'context': build} : build as Map;
  if (spec['dockerfile_inline'] case final String inline) {
    return inline;
  }
  final context = spec['context'] ?? '.';
  if (context is! String || context.contains('://')) {
    throw EnvironmentRigImagesUnresolved(
      'Service "$service" builds from a context outside the worktree, so its '
      'base images cannot be read.',
    );
  }
  final directory = p.normalize(p.join(base ?? '', context));
  final file = p.normalize(
    p.join(directory, spec['dockerfile'] as String? ?? 'Dockerfile'),
  );
  if (root != null && !p.isWithin(root, file)) {
    throw EnvironmentRigImagesUnresolved(
      'Service "$service" builds from outside the worktree.',
    );
  }
  try {
    return File(file).readAsStringSync();
  } on FileSystemException {
    throw EnvironmentRigImagesUnresolved(
      'Service "$service" builds from a Dockerfile that does not exist.',
    );
  }
}

/// [text] with compose's interpolation applied, as `docker compose config`
/// would apply it to the cases that decide what a rig may reach:
///
/// - `$$` is a literal `$`, and a `$` that starts nothing stays as it is.
/// - `$VAR` and `${VAR}`; an unset variable is empty.
/// - `${VAR:-default}` when unset or empty, `${VAR-default}` only when unset.
/// - `${VAR:+other}` when set and non-empty, `${VAR+other}` when set.
/// - `${VAR:?message}` and `${VAR?message}` refuse, as compose does, with
///   [EnvironmentRigImagesUnresolved]: compose would not run the file either.
///
/// Defaults and alternatives are themselves interpolated, so
/// `${A:-${B:-c}}` works.
String interpolateCompose(String text, Map<String, String> variables) {
  final out = StringBuffer();
  var i = 0;
  while (i < text.length) {
    final char = text[i];
    if (char != r'$' || i + 1 >= text.length) {
      out.write(char);
      i++;
      continue;
    }
    final next = text[i + 1];
    if (next == r'$') {
      out.write(r'$');
      i += 2;
      continue;
    }
    if (next == '{') {
      final close = _closingBrace(text, i + 2);
      if (close < 0) {
        throw EnvironmentRigImagesUnresolved(
          'The compose file has an unterminated "\${" at offset $i.',
        );
      }
      out.write(_braced(text.substring(i + 2, close), variables));
      i = close + 1;
      continue;
    }
    final name = _leadingName.matchAsPrefix(text, i + 1);
    if (name == null) {
      out.write(char);
      i++;
      continue;
    }
    out.write(variables[name.group(0)!] ?? '');
    i = name.end;
  }
  return out.toString();
}

final RegExp _leadingName = RegExp('[A-Za-z_][A-Za-z0-9_]*');

/// The index of the `}` closing a `${` whose body starts at [from], counting
/// nested `${…}`, or -1.
int _closingBrace(String text, int from) {
  var depth = 1;
  for (var i = from; i < text.length; i++) {
    if (text[i] == r'$' && i + 1 < text.length && text[i + 1] == '{') {
      depth++;
      i++;
    } else if (text[i] == '}') {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  return -1;
}

String _braced(String body, Map<String, String> variables) {
  final name = _leadingName.matchAsPrefix(body);
  if (name == null) {
    throw EnvironmentRigImagesUnresolved(
      'The compose file names an invalid variable "\${$body}".',
    );
  }
  final key = name.group(0)!;
  final rest = body.substring(name.end);
  final value = variables[key];
  final isSet = value != null;
  final isFilled = value != null && value.isNotEmpty;
  if (rest.isEmpty) {
    return value ?? '';
  }
  final colon = rest.startsWith(':');
  if (colon && rest.length < 2) {
    throw EnvironmentRigImagesUnresolved(
      'The compose file uses "\${$body}", which compose does not accept.',
    );
  }
  final operator = colon ? rest.substring(1, 2) : rest.substring(0, 1);
  final operand = rest.substring(colon ? 2 : 1);
  final present = colon ? isFilled : isSet;
  switch (operator) {
    case '-':
      return present ? value : interpolateCompose(operand, variables);
    case '+':
      return present ? interpolateCompose(operand, variables) : '';
    case '?':
      if (present) {
        return value;
      }
      final message = interpolateCompose(operand, variables);
      throw EnvironmentRigImagesUnresolved(
        'The compose file requires $key'
        '${message.isEmpty ? '' : ': $message'}',
      );
    default:
      throw EnvironmentRigImagesUnresolved(
        'The compose file uses "\${$body}", which compose does not accept.',
      );
  }
}

/// A `.env` as compose reads it.
///
/// `#` lines and blank lines are skipped, and an `export ` prefix is allowed.
/// A single-quoted value is literal. A double-quoted one may span lines and
/// understands `\n`, `\t`, `\"` and `\\`. An unquoted one is trimmed, and a
/// ` #` ends it. Unquoted and double-quoted values are interpolated against
/// the keys above them, then [environment].
Map<String, String> parseDotEnv(
  String text, {
  Map<String, String> environment = const {},
}) {
  final result = <String, String>{};
  final lines = const LineSplitter().convert(text);
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trimLeft();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    if (line.startsWith('export ')) {
      line = line.substring('export '.length).trimLeft();
    }
    final equals = line.indexOf('=');
    if (equals <= 0) {
      continue;
    }
    final key = line.substring(0, equals).trim();
    if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_.\-]*$').hasMatch(key)) {
      continue;
    }
    var raw = line.substring(equals + 1).trimLeft();
    final String value;
    if (raw.startsWith("'")) {
      final close = raw.indexOf("'", 1);
      value = close < 0 ? raw.substring(1) : raw.substring(1, close);
    } else if (raw.startsWith('"')) {
      final buffer = StringBuffer();
      var body = raw.substring(1);
      var closed = false;
      while (true) {
        var j = 0;
        while (j < body.length) {
          final c = body[j];
          if (c == r'\' && j + 1 < body.length) {
            buffer.write(switch (body[j + 1]) {
              'n' => '\n',
              't' => '\t',
              'r' => '\r',
              '"' => '"',
              r'\' => r'\',
              r'$' => r'$$',
              final other => '\\$other',
            });
            j += 2;
            continue;
          }
          if (c == '"') {
            closed = true;
            break;
          }
          buffer.write(c);
          j++;
        }
        if (closed || i + 1 >= lines.length) {
          break;
        }
        buffer.write('\n');
        body = lines[++i];
      }
      value = interpolateCompose(buffer.toString(), {
        ...environment,
        ...result,
      });
    } else {
      final comment = raw.indexOf(' #');
      raw = (comment < 0 ? raw : raw.substring(0, comment)).trim();
      value = interpolateCompose(raw, {...environment, ...result});
    }
    result[key] = value;
  }
  return result;
}

/// Every image of the compose file at [file], read here on the host.
///
/// Not `docker compose config`: rig placement exists to keep a compose file
/// nobody reviewed away from the host's Docker. [variables] win over the
/// directory's `.env`. `include` and `extends` are refused rather than half
/// understood.
Set<String> composeFileImages(
  String file, {
  Map<String, String> variables = const {},
  Iterable<String>? services,
  String? root,
}) {
  final directory = p.dirname(file);
  final dotEnv = File(p.join(directory, '.env'));
  final merged = {
    if (dotEnv.existsSync())
      ...parseDotEnv(dotEnv.readAsStringSync(), environment: variables),
    ...variables,
  };
  final Object? parsed;
  try {
    parsed = loadYaml(
      interpolateCompose(File(file).readAsStringSync(), merged),
    );
  } on YamlException catch (e) {
    throw EnvironmentRigImagesUnresolved('The compose file is not valid: $e');
  }
  if (parsed is! Map) {
    throw const EnvironmentRigImagesUnresolved(
      'The compose file holds no services.',
    );
  }
  final model = jsonDecode(jsonEncode(parsed)) as Map<String, dynamic>;
  final declared = model['services'];
  final extending =
      declared is Map &&
      declared.values.any((s) => s is Map && s['extends'] != null);
  if (model['include'] != null || extending) {
    throw const EnvironmentRigImagesUnresolved(
      'The compose file uses include or extends, which a rig cannot read '
      'ahead of booting. Inline those services.',
    );
  }
  return composeModelImages(
    model,
    services: services,
    directory: directory,
    root: root ?? directory,
  );
}

/// One service, as `docker compose ps --format json` reports it.
class EnvironmentRigService {
  /// Creates an [EnvironmentRigService].
  const EnvironmentRigService({
    required this.name,
    required this.state,
    this.health = '',
    this.exitCode = 0,
    this.publishedPorts = const [],
  });

  /// The compose service.
  final String name;

  /// The container state: `running`, `exited` and so on.
  final String state;

  /// `healthy`, `starting`, `unhealthy`, or empty with no healthcheck.
  final String health;

  /// The exit code, once exited.
  final int exitCode;

  /// The guest ports it publishes.
  final List<int> publishedPorts;

  /// Whether it has failed for good.
  bool get isFailed =>
      health == 'unhealthy' ||
      state == 'dead' ||
      (state == 'exited' && exitCode != 0);

  /// Whether nothing more needs waiting for. A one-shot that exited 0 counts,
  /// which is what `up --wait` gets wrong.
  bool get isSettled =>
      (state == 'running' && (health.isEmpty || health == 'healthy')) ||
      (state == 'exited' && exitCode == 0);

  /// The same answer in the host driver's terms, so a rig-placed stack reads
  /// like a host one.
  ComposeServiceState toServiceState() => ComposeServiceState(
    service: name,
    state: isFailed
        ? 'failed'
        : state == 'exited'
        ? 'completed'
        : isSettled
        ? 'ready'
        : 'waiting',
    containerState: state,
    health: health,
    exitCode: state == 'exited' || state == 'dead' ? exitCode : null,
  );
}

/// Parses `compose ps --format json`: one object per line, or an array.
List<EnvironmentRigService> parseComposePs(String output) {
  final text = output.trim();
  if (text.isEmpty) {
    return const [];
  }
  final rows = text.startsWith('[')
      ? (jsonDecode(text) as List).cast<Object?>()
      : [
          for (final line in const LineSplitter().convert(text))
            jsonDecode(line),
        ];
  return [
    for (final row in rows.whereType<Map<String, dynamic>>())
      EnvironmentRigService(
        name: row['Service'] as String? ?? '',
        state: row['State'] as String? ?? '',
        health: row['Health'] as String? ?? '',
        exitCode: (row['ExitCode'] as num?)?.toInt() ?? 0,
        publishedPorts: {
          for (final publisher in (row['Publishers'] as List?) ?? const [])
            if (publisher is Map &&
                publisher['PublishedPort'] is num &&
                publisher['PublishedPort'] != 0)
              (publisher['PublishedPort'] as num).toInt(),
        }.toList(growable: false),
      ),
  ];
}

/// The guest path of each role's worktree. The anchor role gets the workdir.
Map<String, String> environmentRigMountPoints(
  EnvironmentDefinition definition,
  Map<String, String> worktrees,
) {
  if (worktrees.isEmpty) {
    throw ArgumentError.value(worktrees, 'worktrees', 'Nothing to mount');
  }
  final anchors = definition.repos.where((role) => role.anchor);
  final anchor = anchors.isNotEmpty && worktrees.containsKey(anchors.first.key)
      ? anchors.first.key
      : worktrees.keys.first;
  return {
    anchor: kSmolvmEnvironmentWorkdir,
    for (final role in worktrees.keys)
      if (role != anchor) role: _extraMountPoint(role),
  };
}

String _extraMountPoint(String role) {
  // The key comes from a definition, which can come from the repo.
  if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(role)) {
    throw ArgumentError.value(role, 'role', 'Not usable in a guest path');
  }
  return '/workspaces/$role';
}

/// One endpoint per forwarded port. [forwards] maps guest to host ports, and
/// [http] names the services that get a URL. A service's first port is its
/// role; later ones add the port, so each role stays unique.
List<EnvironmentEndpoint> environmentRigEndpoints(
  List<EnvironmentRigService> services,
  Map<int, int> forwards, {
  List<String>? http,
}) => [
  for (final service in services)
    for (final (index, port) in service.publishedPorts.indexed)
      if (forwards[port] case final hostPort?)
        EnvironmentEndpoint(
          role: index == 0 ? service.name : '${service.name}-$port',
          hostPort: hostPort,
          url: http != null && http.contains(service.name)
              ? 'http://127.0.0.1:$hostPort'
              : null,
        ),
];
