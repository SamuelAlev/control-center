import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The compose project of an environment: `cc-<first 12 of its id>`.
String composeProjectName(String environmentId) {
  final id = environmentId.toLowerCase();
  return 'cc-${id.length > 12 ? id.substring(0, 12) : id}';
}

/// Where an environment's generated override lives.
String composeOverridePath(String stateDir) =>
    p.join(stateDir, 'compose.override.yaml');

/// Where an environment's resolved stack lives: the model preflight checked,
/// and the only stack file `up` reads.
String composeResolvedPath(String stateDir) =>
    p.join(stateDir, 'compose.resolved.json');

/// `COMPOSE_PROJECT_NAME` and `COMPOSE_FILE`, so plain `docker compose` in a
/// terminal or task targets this environment. [composeFile] must be absolute.
Map<String, String> composeVariables({
  required String environmentId,
  required String stateDir,
  required String composeFile,
  String? pathSeparator,
}) => {
  'COMPOSE_PROJECT_NAME': composeProjectName(environmentId),
  'COMPOSE_FILE': [
    composeFile,
    composeOverridePath(stateDir),
  ].join(pathSeparator ?? (Platform.isWindows ? ';' : ':')),
};

/// The file names compose itself looks for, in its order.
const List<String> composeFileNames = [
  'compose.yaml',
  'compose.yml',
  'docker-compose.yaml',
  'docker-compose.yml',
];

/// The absolute compose file in [directory]: [explicit], or the first of
/// [composeFileNames].
String discoverComposeFile(String directory, {String? explicit}) {
  if (explicit != null) {
    if (!isSafeRelativePath(explicit)) {
      throw _failure(
        'compose-file-invalid',
        'Compose file $explicit must be a relative path inside the repo',
      );
    }
    final path = p.join(directory, explicit);
    if (!File(path).existsSync()) {
      throw _failure(
        'compose-file-missing',
        'Compose file $explicit does not exist in $directory',
      );
    }
    return path;
  }
  for (final name in composeFileNames) {
    final path = p.join(directory, name);
    if (File(path).existsSync()) {
      return path;
    }
  }
  throw _failure(
    'compose-file-missing',
    'No compose file in $directory. Looked for ${composeFileNames.join(', ')}',
  );
}

/// Refuses a compose file that pulls configuration from the network.
///
/// This reads the YAML rather than the resolved model, because resolving is
/// what fetches: by the time `config` prints anything, remote content has
/// already been downloaded and interpreted. It follows local includes.
void assertNoRemoteComposeResources(String file) => _scanForRemote(file, {});

void _scanForRemote(String file, Set<String> visited) {
  if (!visited.add(p.normalize(file))) {
    return;
  }
  final Object? document;
  try {
    document = loadYaml(File(file).readAsStringSync());
  } on Object {
    // Compose reports its own parse errors better, with the same file.
    return;
  }
  if (document is! Map) {
    return;
  }
  void check(Object? reference, String where) {
    if (reference is! String) {
      return;
    }
    if (_isRemoteReference(reference)) {
      throw _failure(
        'compose-remote-include',
        'Remote compose resources are refused: $where in ${p.basename(file)} '
            'names $reference. Vendor the file into the repo',
      );
    }
    final local = p.normalize(p.join(p.dirname(file), reference));
    if (FileSystemEntity.isFileSync(local)) {
      _scanForRemote(local, visited);
    }
  }

  final include = document['include'];
  for (final entry in include is List ? include : [?include]) {
    final path = entry is Map ? entry['path'] : entry;
    for (final item in path is List ? path : [path]) {
      check(item, 'include');
    }
  }
  final services = document['services'];
  if (services is Map) {
    for (final entry in services.entries) {
      final service = entry.value;
      final extended = service is Map ? service['extends'] : null;
      if (extended is Map) {
        check(extended['file'], 'extends of ${entry.key}');
      }
    }
  }
}

bool _isRemoteReference(String value) =>
    RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://').hasMatch(value) ||
    value.startsWith('oci:') ||
    value.startsWith('git@') ||
    RegExp(r'\.git(#.*)?$').hasMatch(value);

/// One published port of one service.
class ComposePublishedPort {
  /// Creates a [ComposePublishedPort].
  const ComposePublishedPort({
    required this.service,
    required this.target,
    required this.protocol,
    required this.hostPort,
  });

  /// The service.
  final String service;

  /// The container port.
  final int target;

  /// `tcp` or `udp`.
  final String protocol;

  /// The leased host port.
  final int hostPort;

  /// The lease key, as in `{port.<service>.<target>}`.
  String get key => composePortKey(service, target);

  /// The `ports:` entry.
  String get mapping =>
      '127.0.0.1:$hostPort:$target${protocol == 'tcp' ? '' : '/$protocol'}';
}

/// The lease key of a published port.
String composePortKey(String service, int target) => '$service.$target';

/// What a compose operation needs to know about its environment.
class ComposeContext {
  /// Creates a [ComposeContext].
  const ComposeContext({
    required this.component,
    required this.environmentId,
    required this.workspaceId,
    required this.spaceId,
    required this.stateDir,
    required this.workingDirectory,
    this.environment = const {},
    this.allowedRoots = const [],
    this.untrusted = false,
  });

  /// The component.
  final ComposeEnvironmentComponent component;

  /// The environment.
  final String environmentId;

  /// Its workspace.
  final String workspaceId;

  /// Its space.
  final String spaceId;

  /// Its state directory.
  final String stateDir;

  /// The worktree the component runs in.
  final String workingDirectory;

  /// Variables for `docker compose`, which also interpolates them.
  final Map<String, String> environment;

  /// The space's worktrees. A bind outside these is a policy finding.
  final List<String> allowedRoots;

  /// Whether this runs code nobody here reviewed, as a fork PR does.
  final bool untrusted;

  /// The compose project.
  String get projectName => composeProjectName(environmentId);

  /// The generated override.
  String get overridePath => composeOverridePath(stateDir);

  /// The resolved stack.
  String get resolvedPath => composeResolvedPath(stateDir);

  /// This context with [environment] replaced.
  ComposeContext withEnvironment(Map<String, String> environment) =>
      ComposeContext(
        component: component,
        environmentId: environmentId,
        workspaceId: workspaceId,
        spaceId: spaceId,
        stateDir: stateDir,
        workingDirectory: workingDirectory,
        environment: environment,
        allowedRoots: allowedRoots,
        untrusted: untrusted,
      );
}

/// A resolved compose stack, ready to preflight and run.
class ComposePlan {
  /// Creates a [ComposePlan].
  const ComposePlan({
    required this.context,
    required this.file,
    required this.model,
    required this.services,
    required this.published,
    required this.ports,
    required this.overrideYaml,
    required this.configHash,
    this.warnings = const [],
    this.envFiles = const {},
  });

  /// Who it is for.
  final ComposeContext context;

  /// The absolute compose file.
  final String file;

  /// `docker compose config`'s model.
  final Map<String, dynamic> model;

  /// The services to run: those selected and their dependencies.
  final List<String> services;

  /// Every published port of [services].
  final List<ComposePublishedPort> published;

  /// Every assignment of the environment, including earlier components'.
  final Map<String, int> ports;

  /// The override's text.
  final String overrideYaml;

  /// Changes when the resolved config or the override does.
  final String configHash;

  /// Non-fatal notes from planning.
  final List<String> warnings;

  /// The `env_file` paths of each service of an untrusted stack. The model
  /// can't show these: `config` has already read them into `environment`.
  final Map<String, List<String>> envFiles;

  /// The variables for terminals and tasks.
  Map<String, String> get variables => composeVariables(
    environmentId: context.environmentId,
    stateDir: context.stateDir,
    composeFile: file,
  );

  /// This plan with its command environment replaced. The contract can only
  /// be built once the plan has fixed the ports, so `up` usually gets a richer
  /// environment than `config` did.
  ComposePlan withEnvironment(Map<String, String> environment) => ComposePlan(
    context: context.withEnvironment(environment),
    file: file,
    model: model,
    services: services,
    published: published,
    ports: ports,
    overrideYaml: overrideYaml,
    configHash: configHash,
    warnings: warnings,
    envFiles: envFiles,
  );
}

/// The selected services and everything they depend on, in model order.
///
/// Throws [EnvironmentDriverException] on a service the model doesn't have.
List<String> composeServiceClosure(
  Map<String, dynamic> services,
  List<String> selected,
) {
  if (selected.isEmpty) {
    return services.keys.toList(growable: false);
  }
  for (final name in selected) {
    if (!services.containsKey(name)) {
      throw _failure(
        'compose-unknown-service',
        'The compose file has no service $name. It has '
            '${services.keys.join(', ')}. A service behind a profile needs that '
            'profile set in the file\'s environment',
      );
    }
  }
  final wanted = <String>{};
  void visit(String name) {
    if (!wanted.add(name)) {
      return;
    }
    final service = services[name];
    final depends = service is Map ? service['depends_on'] : null;
    if (depends is Map) {
      for (final dependency in depends.keys) {
        if (services.containsKey(dependency)) {
          visit('$dependency');
        }
      }
    }
  }

  selected.forEach(visit);
  return [
    for (final name in services.keys)
      if (wanted.contains(name)) name,
  ];
}

/// The `(service, target, protocol)` published by [names], without host ports.
List<({String service, int target, String protocol})> composePublishedTargets(
  Map<String, dynamic> services,
  List<String> names,
) => [
  for (final name in names)
    for (final port in _list(_map(services[name])['ports']))
      if (port is Map && port['target'] is num)
        (
          service: name,
          target: (port['target'] as num).toInt(),
          protocol: (port['protocol'] as String?) ?? 'tcp',
        ),
];

/// The override: per selected service a clean `container_name`, ownership
/// labels, leased loopback ports and injected healthchecks.
///
/// Written by hand because the two tags that matter here, `!reset` and
/// `!override`, are compose extensions no YAML writer emits. Strings go through
/// JSON quoting, which is valid YAML, so a value can't break out of its line.
String renderComposeOverride({
  required ComposeContext context,
  required List<String> services,
  required List<ComposePublishedPort> published,
}) {
  final component = context.component;
  final retries = (component.timeoutSeconds / 2).ceil();
  final out = StringBuffer()
    ..writeln('# Generated by Control Center. Changes are overwritten.')
    ..writeln('services:');
  for (final service in services) {
    final mappings = {
      for (final port in published)
        if (port.service == service) port.mapping,
    };
    final healthcheck = component.healthchecks[service];
    out
      ..writeln('  ${jsonEncode(service)}:')
      ..writeln('    container_name: !reset null')
      ..writeln('    labels:')
      ..writeln('      cc.env: ${jsonEncode(context.environmentId)}')
      ..writeln('      cc.workspace: ${jsonEncode(context.workspaceId)}')
      ..writeln('      cc.space: ${jsonEncode(context.spaceId)}');
    if (mappings.isNotEmpty) {
      out.writeln('    ports: !override');
      for (final mapping in mappings) {
        out.writeln('      - ${jsonEncode(mapping)}');
      }
    }
    if (healthcheck != null && healthcheck.isNotEmpty) {
      out
        ..writeln('    healthcheck:')
        ..writeln('      test: ${jsonEncode(['CMD', ...healthcheck])}')
        ..writeln('      interval: 2s')
        // As many tries as the timeout allows. With Docker's default of 3 a
        // database still initialising turns `unhealthy` after six seconds, and
        // that fails `up` for anything with `condition: service_healthy`.
        ..writeln('      retries: $retries');
    }
  }
  return out.toString();
}

/// The text of the resolved stack file.
///
/// `config` has already made every path absolute and interpolated every
/// variable, and it keeps a literal `$` escaped as `$$`, so reading this back
/// changes nothing. A profile is the exception: it was active when [model] was
/// resolved, but nothing says it still is once the file sits in the state
/// directory, away from the worktree's `.env`, and a service in a profile that
/// is off is one its dependents can't find.
String composeResolvedFile(Map<String, dynamic> model) {
  final services = _map(model['services']);
  return const JsonEncoder.withIndent('  ').convert({
    ...model,
    'services': {
      for (final entry in services.entries)
        entry.key: {..._map(entry.value)}..remove('profiles'),
    },
  });
}

/// A stable hash of [model] and [overrideYaml].
String composeConfigHash(Map<String, dynamic> model, String overrideYaml) =>
    sha256
        .convert(utf8.encode('${jsonEncode(_canonical(model))}\n$overrideYaml'))
        .toString();

Object? _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => '$key').toList()..sort();
    return {for (final key in keys) key: _canonical(value[key])};
  }
  if (value is List) {
    return value.map(_canonical).toList(growable: false);
  }
  return value;
}

/// A bind whose source does not exist.
class ComposeMissingBind {
  /// Creates a [ComposeMissingBind].
  const ComposeMissingBind({
    required this.service,
    required this.source,
    required this.relativePath,
    this.gitignored,
  });

  /// The service.
  final String service;

  /// The absolute source.
  final String source;

  /// The source as a person would write it.
  final String relativePath;

  /// Whether git ignores it, or null when that can't be told.
  final bool? gitignored;

  /// What to tell them.
  String get message {
    final reason = switch (gitignored) {
      true =>
        '$relativePath is gitignored, so a fresh worktree does not have it. '
            'Add it to seedFiles',
      false =>
        '$relativePath is not gitignored, so this branch should contain it',
      null => 'If it lives in the source checkout, add it to seedFiles',
    };
    return 'Service $service bind-mounts $relativePath, which does not exist. '
        'Docker would create an empty directory in its place. $reason';
  }
}

/// A resolved setting that reaches past the container boundary.
class ComposePolicyFinding {
  /// Creates a [ComposePolicyFinding].
  const ComposePolicyFinding({
    required this.service,
    required this.rule,
    required this.detail,
  });

  /// The service, or null for a setting of the stack as a whole.
  final String? service;

  /// `privileged`, `host-pid`, `host-network`, `host-ipc`, `host-userns`,
  /// `host-cgroup`, `host-uts`, `container-namespace`, `docker-socket`,
  /// `devices`, `bind-outside-worktree`, `volumes-from`, `capability`,
  /// `security-opt`, `build-context`, `build-ssh`, `build-entitlement`,
  /// `secret-file`, `external-volume`, or for an untrusted stack alone
  /// `env-file-outside-worktree`, `network-mode`, `build-cache`,
  /// `volume-type`, `volume-driver`, `volume-name`, `external-network`,
  /// `network-driver`, `network-name`, `logging-driver` or `key-not-allowed`.
  final String rule;

  /// What it does.
  final String detail;

  /// What to tell them.
  String get message =>
      service == null ? 'The stack $detail' : 'Service $service $detail';
}

/// What preflight found.
class ComposePreflightResult {
  /// Creates a [ComposePreflightResult].
  const ComposePreflightResult({
    this.missingBinds = const [],
    this.warnings = const [],
    this.refusals = const [],
  });

  /// Binds that would silently become empty directories.
  final List<ComposeMissingBind> missingBinds;

  /// Findings on a trusted space.
  final List<ComposePolicyFinding> warnings;

  /// Findings on an untrusted one.
  final List<ComposePolicyFinding> refusals;

  /// Whether the stack may start.
  bool get ok => missingBinds.isEmpty && refusals.isEmpty;

  /// Throws [EnvironmentDriverException] unless [ok].
  void throwIfBlocked() {
    if (missingBinds.isNotEmpty) {
      throw _failure(
        'compose-missing-bind',
        missingBinds.map((bind) => bind.message).join('\n'),
      );
    }
    if (refusals.isNotEmpty) {
      throw _failure(
        'compose-policy-refused',
        'Refused for untrusted code:\n'
            '${refusals.map((finding) => finding.message).join('\n')}',
      );
    }
  }
}

/// The bind sources of [names] that have to exist: every bind but the Docker
/// socket, which the policy check owns and which may live inside a VM.
List<({String service, String source})> composeBindSources(
  Map<String, dynamic> services,
  List<String> names,
) => [
  for (final name in names)
    for (final volume in _list(_map(services[name])['volumes']))
      if (volume is Map &&
          volume['type'] == 'bind' &&
          volume['source'] is String &&
          !_isDockerSocket(volume['source'] as String))
        (service: name, source: volume['source'] as String),
];

/// The paths of an `env_file` value, in any of the shapes compose prints.
List<String> composeEnvFilePaths(Object? value) => [
  for (final entry in value is List ? value : [?value])
    if (entry is Map) '${entry['path']}' else '$entry',
];

/// Top-level keys an untrusted stack may use.
const Set<String> _untrustedTopLevelKeys = {
  'name',
  'version',
  'services',
  'networks',
  'volumes',
  'secrets',
  'configs',
};

/// Service keys an untrusted stack may use.
///
/// An allowlist, because each Compose release adds keys and some reach past
/// the container: `use_api_socket` hands it the Docker socket, and a
/// `post_start` hook can ask to be privileged. A new key stays refused until
/// someone has read what it does.
const Set<String> _untrustedServiceKeys = {
  'annotations',
  'attach',
  'build',
  'cap_add',
  'cap_drop',
  'cgroup',
  'command',
  'configs',
  'container_name',
  'cpu_count',
  'cpu_percent',
  'cpu_period',
  'cpu_quota',
  'cpu_shares',
  'cpus',
  'cpuset',
  'depends_on',
  'deploy',
  'develop',
  'devices',
  'dns',
  'dns_opt',
  'dns_search',
  'domainname',
  'entrypoint',
  'env_file',
  'environment',
  'expose',
  'extra_hosts',
  'group_add',
  'healthcheck',
  'hostname',
  'image',
  'init',
  'ipc',
  'labels',
  'links',
  'logging',
  'mac_address',
  'mem_limit',
  'mem_reservation',
  'mem_swappiness',
  'memswap_limit',
  'network_mode',
  'networks',
  'oom_kill_disable',
  'oom_score_adj',
  'pid',
  'pids_limit',
  'platform',
  'ports',
  'privileged',
  'profiles',
  'pull_policy',
  'read_only',
  'restart',
  'scale',
  'secrets',
  'security_opt',
  'shm_size',
  'stdin_open',
  'stop_grace_period',
  'stop_signal',
  'sysctls',
  'tmpfs',
  'tty',
  'ulimits',
  'user',
  'userns_mode',
  'uts',
  'volumes',
  'volumes_from',
  'working_dir',
};

/// `build` keys an untrusted stack may use.
const Set<String> _untrustedBuildKeys = {
  'additional_contexts',
  'args',
  'cache_from',
  'cache_to',
  'context',
  'dockerfile',
  'dockerfile_inline',
  'entitlements',
  'extra_hosts',
  'labels',
  'network',
  'no_cache',
  'platforms',
  'privileged',
  'pull',
  'secrets',
  'shm_size',
  'ssh',
  'tags',
  'target',
  'ulimits',
};

/// `secrets` and `configs` keys an untrusted stack may use. `environment` is
/// missing on purpose: it reads a variable of the server's own process.
const Set<String> _untrustedFileObjectKeys = {'name', 'content', 'file'};

/// Top-level `volumes` keys an untrusted stack may use.
const Set<String> _untrustedVolumeKeys = {
  'name',
  'driver',
  'driver_opts',
  'external',
  'labels',
};

/// Top-level `networks` keys an untrusted stack may use.
const Set<String> _untrustedNetworkKeys = {
  'name',
  'driver',
  'external',
  'attachable',
  'enable_ipv4',
  'enable_ipv6',
  'internal',
  'ipam',
  'labels',
};

/// Capabilities that give a container nothing over the host: Docker's defaults,
/// which adding changes nothing, and what ordinary images ask for. The rest
/// include `DAC_READ_SEARCH` and `SYS_ADMIN`, both known ways out of a
/// container.
const Set<String> _harmlessCapabilities = {
  'AUDIT_WRITE',
  'CHOWN',
  'DAC_OVERRIDE',
  'FOWNER',
  'FSETID',
  'IPC_LOCK',
  'KILL',
  'MKNOD',
  'NET_BIND_SERVICE',
  'NET_RAW',
  'SETFCAP',
  'SETGID',
  'SETPCAP',
  'SETUID',
  'SYS_CHROOT',
  'SYS_NICE',
};

/// What sharing each namespace with the host is called, and what it does.
const Map<String, ({String rule, String detail})> _hostNamespaces = {
  'pid': (rule: 'host-pid', detail: 'shares the host PID namespace'),
  'network_mode': (rule: 'host-network', detail: 'uses the host network'),
  'ipc': (rule: 'host-ipc', detail: 'shares the host IPC namespace'),
  'userns_mode': (
    rule: 'host-userns',
    detail: 'shares the host user namespace',
  ),
  'cgroup': (rule: 'host-cgroup', detail: 'shares the host cgroup namespace'),
  'uts': (rule: 'host-uts', detail: 'shares the host UTS namespace'),
};

/// Checks [names] in [model] against the policy.
///
/// Every finding names something that reaches past the container, so a trusted
/// stack hears about it as a warning. [untrusted] adds the allowlists, which
/// exist because that stack's author is not on our side: it refuses whatever
/// hasn't been shown to be harmless, not only what is known to be harmful.
/// [envFiles] holds what [ComposePlan.envFiles] does.
List<ComposePolicyFinding> composePolicyFindings({
  required Map<String, dynamic> model,
  required List<String> names,
  required List<String> allowedRoots,
  bool untrusted = false,
  Map<String, List<String>> envFiles = const {},
}) {
  final services = _map(model['services']);
  final volumes = _map(model['volumes']);
  final roots = allowedRoots.map(_resolved).toList(growable: false);
  bool inside(String path) {
    if (!p.isAbsolute(path)) {
      return false;
    }
    final resolved = _resolved(path);
    return roots.any((root) => resolved == root || p.isWithin(root, resolved));
  }

  final findings = <ComposePolicyFinding>[];
  void addStack(String rule, String detail) => findings.add(
    ComposePolicyFinding(service: null, rule: rule, detail: detail),
  );
  if (untrusted) {
    for (final key in _unlisted(model, _untrustedTopLevelKeys)) {
      addStack('key-not-allowed', 'sets $key, which is not allowed here');
    }
  }
  _checkFileObjects(model, 'secrets', 'secret', untrusted, inside, addStack);
  _checkFileObjects(model, 'configs', 'config', untrusted, inside, addStack);
  _checkVolumes(model, untrusted, addStack);
  if (untrusted) {
    _checkNetworks(model, addStack);
  }

  for (final name in names) {
    final service = _map(services[name]);
    void add(String rule, String detail) => findings.add(
      ComposePolicyFinding(service: name, rule: rule, detail: detail),
    );

    if (untrusted) {
      for (final key in _unlisted(service, _untrustedServiceKeys)) {
        add('key-not-allowed', 'sets $key, which is not allowed here');
      }
    }
    if (service['privileged'] == true) {
      add('privileged', 'runs privileged');
    }
    _checkNamespaces(service, untrusted, add);
    if (_list(service['devices']).isNotEmpty ||
        _reservedDevices(service).isNotEmpty) {
      add('devices', 'maps host devices');
    }
    if (_isSet(service['volumes_from'])) {
      add('volumes-from', 'mounts the volumes of another container');
    }
    for (final capability in _list(service['cap_add'])) {
      final bare = '$capability'.toUpperCase().replaceFirst('CAP_', '');
      if (!_harmlessCapabilities.contains(bare)) {
        add('capability', 'adds the capability $capability');
      }
    }
    for (final option in _list(service['security_opt'])) {
      if (!_keepsConfinement('$option', untrusted: untrusted)) {
        add('security-opt', 'sets the security option $option');
      }
    }
    for (final path in {
      ...composeEnvFilePaths(service['env_file']),
      ...?envFiles[name],
    }) {
      if (!inside(path)) {
        add(
          'env-file-outside-worktree',
          'reads env file $path, outside the worktrees',
        );
      }
    }
    if (service['build'] != null) {
      _checkBuild(service['build'], untrusted, inside, add);
    }
    if (untrusted) {
      final driver = _map(service['logging'])['driver'];
      if (driver != null &&
          !const {'json-file', 'local', 'none'}.contains(driver)) {
        add('logging-driver', 'logs through $driver');
      }
    }
    for (final volume in _list(service['volumes'])) {
      if (volume is! Map) {
        continue;
      }
      final type = volume['type'];
      if (untrusted && !const {'bind', 'volume', 'tmpfs'}.contains(type)) {
        add('volume-type', 'mounts a $type');
      }
      if (volume['source'] is! String) {
        continue;
      }
      var source = volume['source'] as String;
      if (type == 'volume') {
        // A named volume with a `device` is a bind by another name, and
        // leaving it out would make this check a formality.
        final options = _map(_map(volumes[source])['driver_opts']);
        final device = options['device'];
        if (device is! String || !p.isAbsolute(device)) {
          continue;
        }
        source = device;
      } else if (type != 'bind') {
        continue;
      }
      if (_isDockerSocket(source)) {
        add('docker-socket', 'mounts the Docker socket ($source)');
      } else if (!inside(source)) {
        add('bind-outside-worktree', 'binds $source, outside the worktrees');
      }
    }
  }
  return findings;
}

/// `secrets` or `configs`, which [kind] names. `file` binds a host file into
/// the container, so on an untrusted stack it is refused even inside the
/// worktree: a link there passes for a file until `up` follows it.
void _checkFileObjects(
  Map<String, dynamic> model,
  String kind,
  String label,
  bool untrusted,
  bool Function(String path) inside,
  void Function(String rule, String detail) add,
) {
  for (final entry in _map(model[kind]).entries) {
    final object = _map(entry.value);
    final file = object['file'];
    if (file is String && (untrusted || !inside(file))) {
      add('secret-file', 'reads $label ${entry.key} from $file');
    }
    if (untrusted) {
      for (final key in _unlisted(object, _untrustedFileObjectKeys)) {
        add('key-not-allowed', 'sets $key on $label ${entry.key}');
      }
    }
  }
}

void _checkVolumes(
  Map<String, dynamic> model,
  bool untrusted,
  void Function(String rule, String detail) add,
) {
  for (final entry in _map(model['volumes']).entries) {
    final volume = _map(entry.value);
    if (_isSet(volume['external'])) {
      add('external-volume', 'uses the external volume ${entry.key}');
    }
    if (!untrusted) {
      continue;
    }
    for (final key in _unlisted(volume, _untrustedVolumeKeys)) {
      add('key-not-allowed', 'sets $key on volume ${entry.key}');
    }
    final driver = volume['driver'];
    final options = _map(volume['driver_opts']);
    // `type: nfs` and friends mount a remote share, and a `device` that isn't
    // absolute can't be checked, so only a plain bind gets through to the
    // check of its source.
    final plainBind =
        options.length == 3 &&
        options['type'] == 'none' &&
        '${options['o']}'.split(',').contains('bind') &&
        options['device'] is String &&
        p.isAbsolute(options['device'] as String);
    if ((driver != null && driver != 'local') ||
        (options.isNotEmpty && !plainBind)) {
      add('volume-driver', 'mounts volume ${entry.key} through its driver');
    }
    _checkName(
      model,
      volume,
      entry.key,
      add,
      rule: 'volume-name',
      label: 'volume',
    );
  }
}

void _checkNetworks(
  Map<String, dynamic> model,
  void Function(String rule, String detail) add,
) {
  for (final entry in _map(model['networks']).entries) {
    final network = _map(entry.value);
    for (final key in _unlisted(network, _untrustedNetworkKeys)) {
      add('key-not-allowed', 'sets $key on network ${entry.key}');
    }
    if (_isSet(network['external'])) {
      add('external-network', 'joins the external network ${entry.key}');
    }
    final driver = network['driver'];
    if (driver != null && driver != 'bridge') {
      add('network-driver', 'runs network ${entry.key} on the $driver driver');
    }
    _checkName(
      model,
      network,
      entry.key,
      add,
      rule: 'network-name',
      label: 'network',
    );
  }
}

/// A `name:` outside the project is the same thing as `external: true`: it
/// reaches another environment's volume or network, and `down -v` deletes it.
void _checkName(
  Map<String, dynamic> model,
  Map<String, dynamic> object,
  String key,
  void Function(String rule, String detail) add, {
  required String rule,
  required String label,
}) {
  final name = object['name'];
  if (name is String &&
      !_isSet(object['external']) &&
      !name.startsWith('${model['name']}_')) {
    add(rule, 'names $label $key $name, outside this project');
  }
}

void _checkNamespaces(
  Map<String, dynamic> service,
  bool untrusted,
  void Function(String rule, String detail) add,
) {
  for (final entry in _hostNamespaces.entries) {
    final value = service[entry.key];
    if (value == 'host') {
      add(entry.value.rule, entry.value.detail);
    } else if (value is String && value.startsWith('container:')) {
      add('container-namespace', 'joins $value through ${entry.key}');
    }
  }
  final mode = service['network_mode'];
  if (untrusted &&
      mode is String &&
      mode != 'host' &&
      !mode.startsWith('container:') &&
      !mode.startsWith('service:') &&
      !const {'none', 'bridge'}.contains(mode)) {
    add('network-mode', 'joins the network $mode');
  }
}

void _checkBuild(
  Object? value,
  bool untrusted,
  bool Function(String path) inside,
  void Function(String rule, String detail) add,
) {
  final build = value is String ? {'context': value} : _map(value);
  if (untrusted) {
    for (final key in _unlisted(build, _untrustedBuildKeys)) {
      add('key-not-allowed', 'sets build.$key, which is not allowed here');
    }
  }
  final context = build['context'];
  if (context is String && !inside(context)) {
    add('build-context', 'builds from $context, outside the worktrees');
  }
  final extra = build['additional_contexts'];
  for (final item in extra is Map ? extra.values : [?extra]) {
    if (item is! String ||
        !(item.startsWith('docker-image://') ||
            item.startsWith('service:') ||
            inside(item))) {
      add('build-context', 'builds from $item, outside the worktrees');
    }
  }
  if (_isSet(build['ssh'])) {
    add('build-ssh', 'forwards the server\'s SSH agent into a build');
  }
  if (build['privileged'] == true) {
    add('privileged', 'builds privileged');
  }
  if (_isSet(build['entitlements'])) {
    add('build-entitlement', 'asks for build entitlements');
  }
  if (build['network'] == 'host') {
    add('host-network', 'builds on the host network');
  }
  if (!untrusted) {
    return;
  }
  final dockerfile = build['dockerfile'];
  if (dockerfile is String &&
      context is String &&
      !inside(p.normalize(p.join(context, dockerfile)))) {
    add('build-context', 'builds from $dockerfile, outside the worktrees');
  }
  // `type=local` reads and writes a path on the host.
  for (final entry in [
    ..._list(build['cache_from']),
    ..._list(build['cache_to']),
  ]) {
    final text = '$entry';
    if (text.contains('type=') &&
        !RegExp(r'(^|,)type=(registry|inline)(,|$)').hasMatch(text)) {
      add('build-cache', 'keeps a build cache at $text');
    }
  }
}

/// GPUs and the like, which `deploy` can ask for without `devices`.
List<Object?> _reservedDevices(Map<String, dynamic> service) => _list(
  _map(_map(_map(service['deploy'])['resources'])['reservations'])['devices'],
);

/// Whether a `security_opt` entry leaves the container's confinement in place.
/// A trusted stack may name its own profile. An untrusted one's `seccomp=<path>`
/// is a file it wrote, so only `no-new-privileges`, which adds to it, is fine.
bool _keepsConfinement(String option, {required bool untrusted}) {
  if (untrusted) {
    return RegExp(r'^no-new-privileges([:=]true)?$').hasMatch(option);
  }
  final lower = option.toLowerCase();
  return !lower.contains('unconfined') && !lower.contains('disable');
}

Iterable<String> _unlisted(Map<String, dynamic> map, Set<String> allowed) =>
    map.keys.where((key) => !key.startsWith('x-') && !allowed.contains(key));

bool _isSet(Object? value) => switch (value) {
  null || false => false,
  final Iterable<Object?> items => items.isNotEmpty,
  final Map<Object?, Object?> items => items.isNotEmpty,
  _ => true,
};

bool _isDockerSocket(String path) => p.basename(path) == 'docker.sock';

/// [path] with links resolved as far as it exists, so a link in the worktree
/// can't pass for a path in the worktree. The missing tail is kept as written.
String _resolved(String path) {
  final absolute = p.normalize(p.absolute(path));
  var head = absolute;
  final tail = <String>[];
  while (true) {
    try {
      final resolved = File(head).resolveSymbolicLinksSync();
      return p.joinAll([resolved, ...tail.reversed]);
    } on FileSystemException {
      final parent = p.dirname(head);
      if (parent == head) {
        return absolute;
      }
      tail.add(p.basename(head));
      head = parent;
    }
  }
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<Object?> _list(Object? value) => value is List ? value : const [];

EnvironmentDriverException _failure(String code, String message) =>
    EnvironmentDriverException(EnvironmentError(code: code, message: message));
