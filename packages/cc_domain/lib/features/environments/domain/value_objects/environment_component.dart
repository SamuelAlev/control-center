import 'package:cc_domain/features/environments/domain/services/environment_definition_reader.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status_map.dart';
import 'package:collection/collection.dart';

/// When a task runs.
enum EnvironmentTaskTrigger {
  /// The role's worktree was just created, with or without an environment.
  provision,

  /// Once per environment, and again after a reset.
  create,

  /// Every start.
  start,

  /// After a worktree sync, when a changed path matches `onChange`.
  change,

  /// Only on request.
  manual,

  /// Just before the role's worktree is destroyed.
  archive;

  /// Every trigger by wire name.
  static Map<String, EnvironmentTaskTrigger> get byWire => {
    for (final trigger in values) trigger.name: trigger,
  };

  /// Whether this follows the worktree instead of the environment.
  bool get isWorktreeTrigger => this == provision || this == archive;
}

/// How a process reacts to exiting.
enum EnvironmentRestartPolicy {
  /// Restart with backoff, giving up after repeated failures.
  onFailure('on-failure'),

  /// Always restart.
  always('always'),

  /// Never restart.
  never('never');

  const EnvironmentRestartPolicy(this.wire);

  /// Stable wire string.
  final String wire;

  /// Every policy by wire name.
  static Map<String, EnvironmentRestartPolicy> get byWire => {
    for (final policy in values) policy.wire: policy,
  };
}

/// How agent input reaches a desktop window.
enum EnvironmentAppInputMode {
  /// Posted to the process, leaving the cursor and focus alone.
  background,

  /// Activates the window and injects at system level.
  foreground;

  /// Every mode by wire name.
  static Map<String, EnvironmentAppInputMode> get byWire => {
    for (final mode in values) mode.name: mode,
  };
}

/// Where a command runs. Both fields are optional.
class EnvironmentCwd {
  /// Creates an [EnvironmentCwd].
  const EnvironmentCwd({this.role, this.path});

  /// Reads a `cwd` object.
  static EnvironmentCwd read(EnvironmentJsonReader reader) {
    final role = reader.string('role', nonEmpty: true);
    final path = reader.string('path', nonEmpty: true);
    reader.finish();
    return EnvironmentCwd(role: role, path: path);
  }

  /// The role, or null for the first role the space has.
  final String? role;

  /// A path inside the role's worktree.
  final String? path;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    if (role != null) 'role': role,
    if (path != null) 'path': path,
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentCwd &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// A readiness probe. All fields optional; none means "started".
class EnvironmentReadyProbe {
  /// Creates an [EnvironmentReadyProbe].
  const EnvironmentReadyProbe({
    this.http,
    this.tcp,
    this.logMatch,
    this.expectBelow = 500,
    this.timeoutSeconds = 120,
  });

  /// Reads a `ready` object.
  static EnvironmentReadyProbe read(EnvironmentJsonReader reader) {
    final http = reader.string('http', nonEmpty: true);
    final tcp = reader.string('tcp', nonEmpty: true);
    final logMatch = reader.string('logMatch', nonEmpty: true);
    final expectBelow = reader.integer('expectBelow', min: 200, max: 600);
    final timeout = reader.integer('timeout');
    reader.finish();
    return EnvironmentReadyProbe(
      http: http,
      tcp: tcp,
      logMatch: logMatch,
      expectBelow: expectBelow ?? 500,
      timeoutSeconds: timeout ?? 120,
    );
  }

  /// URL template to poll.
  final String? http;

  /// `host:port` template to connect to.
  final String? tcp;

  /// A regular expression over output.
  final String? logMatch;

  /// HTTP statuses below this count as up.
  final int expectBelow;

  /// How long to wait.
  final int timeoutSeconds;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    if (http != null) 'http': http,
    if (tcp != null) 'tcp': tcp,
    if (logMatch != null) 'logMatch': logMatch,
    'expectBelow': expectBelow,
    'timeout': timeoutSeconds,
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentReadyProbe &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// One part of an environment.
sealed class EnvironmentComponent {
  EnvironmentComponent({
    required this.id,
    this.label,
    this.enabledWhen,
    this.after = const [],
    this.cwd,
    this.env = const {},
    this.ports = const [],
  }) {
    if (id.isEmpty) {
      throw ArgumentError('A component id must not be empty');
    }
  }

  /// Reads a component by its `kind`, or null when it can't be built.
  static EnvironmentComponent? read(EnvironmentJsonReader reader) {
    final kind = reader.choice('kind', const {
      'compose': 'compose',
      'cli': 'cli',
      'process': 'process',
      'task': 'task',
      'app': 'app',
    }, required: true);
    final base = EnvironmentComponentBase._read(reader, kind: kind);
    final component = switch (kind) {
      'compose' => ComposeEnvironmentComponent._read(reader, base),
      'cli' => CliEnvironmentComponent._read(reader, base),
      'process' => ProcessEnvironmentComponent._read(reader, base),
      'task' => TaskEnvironmentComponent._read(reader, base),
      'app' => AppEnvironmentComponent._read(reader, base),
      _ => null,
    };
    // Without a kind there is no telling which fields belong.
    if (kind != null) {
      reader.finish();
    }
    return base == null ? null : component;
  }

  /// Stable id, unique in the definition.
  final String id;

  /// What to show.
  final String? label;

  /// Condition gating this component.
  final String? enabledWhen;

  /// Components to wait for instead of the previous one.
  final List<String> after;

  /// Where it runs.
  final EnvironmentCwd? cwd;

  /// Extra environment variables.
  final Map<String, String> env;

  /// Named ports this component declares.
  final List<String> ports;

  /// `compose`, `cli`, `process`, `task` or `app`.
  String get kind;

  /// What to show, never empty.
  String get displayName => label ?? id;

  /// Every command this component can run.
  Iterable<EnvironmentCommand> get commands;

  /// JSON form.
  Map<String, dynamic> toJson();

  Map<String, dynamic> baseJson() => {
    'kind': kind,
    'id': id,
    if (label != null) 'label': label,
    if (enabledWhen != null) 'enabledWhen': enabledWhen,
    if (after.isNotEmpty) 'after': after,
    if (cwd != null) 'cwd': cwd!.toJson(),
    if (env.isNotEmpty) 'env': env,
    if (ports.length == 1) 'port': ports.single,
    if (ports.length > 1) 'ports': ports,
  };

  /// The named ports in `port` and `ports`, or null after an issue.
  static List<String>? _readPorts(EnvironmentJsonReader reader) {
    final single = reader.raw('port');
    final ports = <String>[];
    var ok = true;
    if (single is String && single.trim().isNotEmpty) {
      ports.add(single);
    } else if (single is List) {
      reader.report('port', 'Holds one port name. Use ports for a list');
      ok = false;
    } else if (single != null) {
      reader.report(
        'port',
        'Must be a port name, such as "web". Control Center picks the number',
      );
      ok = false;
    }
    final many = reader.strings('ports', nonEmpty: true);
    if (reader.has('ports') && many == null) {
      ok = false;
    }
    return ok ? [...ports, ...?many] : null;
  }

  /// What `command` or `script` runs, or null after an issue.
  static EnvironmentCommand? _readBody(EnvironmentJsonReader reader) {
    final hasScript = reader.has('script');
    final hasCommand = reader.has('command');
    if (hasScript && hasCommand) {
      reader.report('script', 'Use command or script, not both');
      return null;
    }
    if (hasScript) {
      return EnvironmentCommand.scriptLines(reader, 'script');
    }
    if (!hasCommand) {
      reader.report('command', 'Required');
      return null;
    }
    return EnvironmentCommand.read(
      reader.raw('command'),
      reader.pathOf('command'),
      reader.issues,
    );
  }
}

/// The fields every component kind shares, as read.
class EnvironmentComponentBase {
  const EnvironmentComponentBase._({
    required this.id,
    this.label,
    this.enabledWhen,
    this.after = const [],
    this.cwd,
    this.env = const {},
  });

  /// The shared fields, or null after an issue in one of them.
  static EnvironmentComponentBase? _read(
    EnvironmentJsonReader reader, {
    required String? kind,
  }) {
    final id = reader.string('id', required: true, nonEmpty: true);
    final label = reader.string('label');
    final enabledWhen = reader.string('enabledWhen', nonEmpty: true);
    List<String>? after = const [];
    if (kind == 'app') {
      reader.refuse(
        'after',
        'An app opens on Launch, once the stack is up, so after has no effect',
      );
    } else {
      after = reader.strings('after');
      if (reader.has('after') && after == null) {
        return null;
      }
    }
    final cwdReader = reader.object('cwd');
    final cwd = cwdReader == null ? null : EnvironmentCwd.read(cwdReader);
    final env = reader.stringMap('env');
    if (id == null ||
        (reader.has('cwd') && cwd == null) ||
        (reader.has('env') && env == null)) {
      return null;
    }
    return EnvironmentComponentBase._(
      id: id,
      label: label,
      enabledWhen: enabledWhen,
      after: after ?? const [],
      cwd: cwd,
      env: env ?? const {},
    );
  }

  /// See [EnvironmentComponent.id].
  final String id;

  /// See [EnvironmentComponent.label].
  final String? label;

  /// See [EnvironmentComponent.enabledWhen].
  final String? enabledWhen;

  /// See [EnvironmentComponent.after].
  final List<String> after;

  /// See [EnvironmentComponent.cwd].
  final EnvironmentCwd? cwd;

  /// See [EnvironmentComponent.env].
  final Map<String, String> env;
}

/// A compose stack driven natively.
class ComposeEnvironmentComponent extends EnvironmentComponent {
  /// Creates a [ComposeEnvironmentComponent].
  ComposeEnvironmentComponent({
    required super.id,
    super.label,
    super.enabledWhen,
    super.after,
    super.cwd,
    super.env,
    this.file,
    this.services = const [],
    this.build = true,
    this.healthchecks = const {},
    this.http,
    this.timeoutSeconds = 300,
  });

  static ComposeEnvironmentComponent? _read(
    EnvironmentJsonReader reader,
    EnvironmentComponentBase? base,
  ) {
    for (final key in const ['port', 'ports']) {
      reader.refuse(
        key,
        'Compose ports come from the compose file. Read them as '
        '{port.<service>.<port>}',
      );
    }
    final file = reader.string('file', nonEmpty: true);
    final services = reader.strings('services');
    final build = reader.boolean('build');
    final checks = reader.object('healthchecks');
    final healthchecks = <String, List<String>>{};
    var ok = true;
    if (checks != null) {
      for (final service in checks.keys.toList()) {
        final argv = checks.strings(service, nonEmpty: true);
        if (argv == null) {
          ok = false;
        } else {
          healthchecks[service] = argv;
        }
      }
      checks.finish();
    }
    final http = reader.strings('http');
    final timeout = reader.integer('timeout');
    if (base == null || !ok) {
      return null;
    }
    return ComposeEnvironmentComponent(
      id: base.id,
      label: base.label,
      enabledWhen: base.enabledWhen,
      after: base.after,
      cwd: base.cwd,
      env: base.env,
      file: file,
      services: services ?? const [],
      build: build ?? true,
      healthchecks: healthchecks,
      http: http,
      timeoutSeconds: timeout ?? 300,
    );
  }

  /// The compose file, or null to discover it.
  final String? file;

  /// Services to run. Empty means every service.
  final List<String> services;

  /// Whether to build images on start.
  final bool build;

  /// Healthchecks to inject, by service.
  final Map<String, List<String>> healthchecks;

  /// Services whose ports are HTTP, or null to probe.
  final List<String>? http;

  /// How long to wait for readiness.
  final int timeoutSeconds;

  @override
  String get kind => 'compose';

  @override
  Iterable<EnvironmentCommand> get commands => const [];

  @override
  Map<String, dynamic> toJson() => {
    ...baseJson(),
    if (file != null) 'file': file,
    if (services.isNotEmpty) 'services': services,
    'build': build,
    if (healthchecks.isNotEmpty) 'healthchecks': healthchecks,
    if (http != null) 'http': http,
    'timeout': timeoutSeconds,
  };

  @override
  bool operator ==(Object other) =>
      other is ComposeEnvironmentComponent &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// A tool that owns its own lifecycle.
class CliEnvironmentComponent extends EnvironmentComponent {
  /// Creates a [CliEnvironmentComponent].
  CliEnvironmentComponent({
    required super.id,
    super.label,
    super.enabledWhen,
    super.after,
    super.cwd,
    super.env,
    required this.verbs,
    this.statusMap,
    this.keepsDataOnStop = true,
    this.readyTimeoutSeconds = 600,
    this.timeouts = const {},
    this.interactive = const [],
    this.agentPassthrough,
  }) {
    for (final verb in requiredVerbs) {
      if (!verbs.containsKey(verb)) {
        throw ArgumentError('A cli component needs the $verb verb');
      }
    }
  }

  /// Every verb a tool can map.
  static const Set<String> knownVerbs = {
    'create',
    'start',
    'stop',
    'destroy',
    'reset',
    'status',
    'list',
    'logs',
    'exec',
  };

  /// The verbs no tool can do without.
  static const Set<String> requiredVerbs = {'create', 'status', 'destroy'};

  /// The verbs that bring an environment up, and so the only ones that may
  /// be [interactive]: a person is there when one of them runs.
  static const Set<String> bringUpVerbs = {'create', 'start', 'reset'};

  /// The condition value set while a verb runs on a terminal, for arguments
  /// that only suit one side: `{"if": "!interactive", "args": ["--json"]}`.
  static const String interactiveValue = 'interactive';

  static CliEnvironmentComponent? _read(
    EnvironmentJsonReader reader,
    EnvironmentComponentBase? base,
  ) {
    for (final key in const ['port', 'ports']) {
      reader.refuse(
        key,
        'A tool picks its own ports and reports them in its status',
      );
    }
    var ok = true;
    final verbs = <String, EnvironmentCommand>{};
    final verbReader = reader.object('verbs', required: true);
    if (verbReader == null) {
      ok = false;
    } else {
      for (final verb in verbReader.keys.toList()) {
        final command = EnvironmentCommand.read(
          verbReader.raw(verb),
          verbReader.pathOf(verb),
          reader.issues,
        );
        if (command == null) {
          ok = false;
        } else {
          verbs[verb] = command;
        }
      }
      for (final verb in requiredVerbs) {
        if (!verbReader.has(verb)) {
          verbReader.report(
            verb,
            'Required: every tool maps ${requiredVerbs.join(', ')}',
          );
          ok = false;
        }
      }
      verbReader.finish();
    }
    final mapReader = reader.object('statusMap');
    final statusMap = mapReader == null
        ? null
        : EnvironmentStatusMap.read(mapReader);
    final keepsDataOnStop = reader.boolean('keepsDataOnStop');
    final readyTimeout = reader.integer('readyTimeout');
    final timeoutReader = reader.object('timeouts');
    final timeouts = <String, int>{};
    if (timeoutReader != null) {
      for (final verb in timeoutReader.keys.toList()) {
        final seconds = timeoutReader.integer(verb);
        if (seconds == null) {
          ok = false;
        } else {
          timeouts[verb] = seconds;
        }
      }
      timeoutReader.finish();
    }
    final interactive = reader.strings('interactive');
    final passthroughReader = reader.object('agentPassthrough');
    final passthrough = passthroughReader == null
        ? null
        : EnvironmentAgentPassthrough._read(passthroughReader);
    if (base == null ||
        !ok ||
        (reader.has('statusMap') && statusMap == null) ||
        (reader.has('agentPassthrough') && passthrough == null) ||
        (reader.has('interactive') && interactive == null)) {
      return null;
    }
    return CliEnvironmentComponent(
      id: base.id,
      label: base.label,
      enabledWhen: base.enabledWhen,
      after: base.after,
      cwd: base.cwd,
      env: base.env,
      verbs: verbs,
      statusMap: statusMap,
      keepsDataOnStop: keepsDataOnStop ?? true,
      readyTimeoutSeconds: readyTimeout ?? 600,
      timeouts: timeouts,
      interactive: interactive ?? const [],
      agentPassthrough: passthrough,
    );
  }

  /// Verbs by name: create, start, stop, destroy, reset, status, list, logs,
  /// exec.
  final Map<String, EnvironmentCommand> verbs;

  /// How to read `status`, or null for the native contract.
  final EnvironmentStatusMap? statusMap;

  /// False when stopping loses data, which disables idle stop.
  final bool keepsDataOnStop;

  /// How long to poll for readiness.
  final int readyTimeoutSeconds;

  /// Per-verb timeouts in seconds.
  final Map<String, int> timeouts;

  /// Verbs the tool can finish on a terminal when it needs a person.
  ///
  /// Such a verb that exits 3 or 4 through a pipe runs again on a terminal
  /// tab, same argv with [interactiveValue] set, where the tool asks for
  /// itself: a `sudo` password, a sign-in. Only for a start a person made.
  final List<String> interactive;

  /// Commands agents may run directly.
  final EnvironmentAgentPassthrough? agentPassthrough;

  @override
  String get kind => 'cli';

  @override
  Iterable<EnvironmentCommand> get commands => verbs.values;

  @override
  Map<String, dynamic> toJson() => {
    ...baseJson(),
    'keepsDataOnStop': keepsDataOnStop,
    'readyTimeout': readyTimeoutSeconds,
    if (timeouts.isNotEmpty) 'timeouts': timeouts,
    if (interactive.isNotEmpty) 'interactive': interactive,
    'verbs': {
      for (final entry in verbs.entries) entry.key: entry.value.toJson(),
    },
    if (statusMap != null) 'statusMap': statusMap!.toJson(),
    if (agentPassthrough != null)
      'agentPassthrough': agentPassthrough!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is CliEnvironmentComponent &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// One allowed pass-through command.
class EnvironmentPassthroughRule {
  /// Creates an [EnvironmentPassthroughRule].
  const EnvironmentPassthroughRule({
    required this.argv,
    required this.maps,
    this.positionalName,
    this.nameFilter = false,
    this.pathFlags = const [],
    this.denyFlags = const [],
  });

  static EnvironmentPassthroughRule? _read(EnvironmentJsonReader reader) {
    final argv = reader.strings('argv', required: true, nonEmpty: true);
    final maps = reader.string('maps', required: true, nonEmpty: true);
    final positionalName = reader.integer('positionalName', min: 0);
    final nameFilter = reader.boolean('nameFilter');
    final pathFlags = reader.strings('pathFlags');
    final denyFlags = reader.strings('denyFlags');
    reader.finish();
    if (argv == null ||
        maps == null ||
        (reader.has('positionalName') && positionalName == null) ||
        (reader.has('pathFlags') && pathFlags == null) ||
        (reader.has('denyFlags') && denyFlags == null)) {
      return null;
    }
    return EnvironmentPassthroughRule(
      argv: argv,
      maps: maps,
      positionalName: positionalName,
      nameFilter: nameFilter ?? false,
      pathFlags: pathFlags ?? const [],
      denyFlags: denyFlags ?? const [],
    );
  }

  /// Leading arguments. `a|b` matches either.
  final List<String> argv;

  /// The op whose action classes apply.
  final String maps;

  /// Index of the argument forced to the environment's name.
  final int? positionalName;

  /// Filter JSON output to this environment.
  final bool nameFilter;

  /// Flags whose value must resolve inside the run's worktrees.
  final List<String> pathFlags;

  /// Flags that are refused.
  final List<String> denyFlags;

  /// Whether [arguments] start with this rule's [argv].
  bool matches(List<String> arguments) {
    if (arguments.length < argv.length) {
      return false;
    }
    for (final (index, pattern) in argv.indexed) {
      if (!pattern.split('|').contains(arguments[index])) {
        return false;
      }
    }
    return true;
  }

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'argv': argv,
    'maps': maps,
    if (positionalName != null) 'positionalName': positionalName,
    if (nameFilter) 'nameFilter': true,
    if (pathFlags.isNotEmpty) 'pathFlags': pathFlags,
    if (denyFlags.isNotEmpty) 'denyFlags': denyFlags,
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentPassthroughRule &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// A tool's agent-visible command surface.
class EnvironmentAgentPassthrough {
  /// Creates an [EnvironmentAgentPassthrough].
  const EnvironmentAgentPassthrough({
    required this.binary,
    required this.allow,
  });

  static EnvironmentAgentPassthrough? _read(EnvironmentJsonReader reader) {
    final binary = reader.string('binary', required: true, nonEmpty: true);
    final rules = reader.objects('allow', required: true);
    final allow = [
      for (final rule in rules ?? const <EnvironmentJsonReader>[])
        EnvironmentPassthroughRule._read(rule),
    ];
    reader.finish();
    if (binary == null || rules == null || allow.contains(null)) {
      return null;
    }
    return EnvironmentAgentPassthrough(
      binary: binary,
      allow: allow.cast<EnvironmentPassthroughRule>(),
    );
  }

  /// The executable name.
  final String binary;

  /// Allowed commands.
  final List<EnvironmentPassthroughRule> allow;

  /// The first rule matching [arguments].
  EnvironmentPassthroughRule? ruleFor(List<String> arguments) {
    for (final rule in allow) {
      if (rule.matches(arguments)) {
        return rule;
      }
    }
    return null;
  }

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'binary': binary,
    'allow': [for (final rule in allow) rule.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentAgentPassthrough &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// A long-running command CC supervises.
class ProcessEnvironmentComponent extends EnvironmentComponent {
  /// Creates a [ProcessEnvironmentComponent].
  ProcessEnvironmentComponent({
    required super.id,
    super.label,
    super.enabledWhen,
    super.after,
    super.cwd,
    super.env,
    super.ports,
    required this.command,
    this.endpoint,
    this.ready,
    this.restart = EnvironmentRestartPolicy.onFailure,
    this.restartOn = const [],
  });

  static ProcessEnvironmentComponent? _read(
    EnvironmentJsonReader reader,
    EnvironmentComponentBase? base,
  ) {
    final ports = EnvironmentComponent._readPorts(reader);
    final command = EnvironmentComponent._readBody(reader);
    final endpointReader = reader.object('endpoint');
    final endpoint = endpointReader == null
        ? null
        : EnvironmentProcessEndpoint._read(endpointReader);
    final readyReader = reader.object('ready');
    final ready = readyReader == null
        ? null
        : EnvironmentReadyProbe.read(readyReader);
    final restart = reader.choice('restart', EnvironmentRestartPolicy.byWire);
    final restartOn = reader.strings('restartOn');
    if (base == null ||
        ports == null ||
        command == null ||
        (reader.has('endpoint') && endpoint == null)) {
      return null;
    }
    return ProcessEnvironmentComponent(
      id: base.id,
      label: base.label,
      enabledWhen: base.enabledWhen,
      after: base.after,
      cwd: base.cwd,
      env: base.env,
      ports: ports,
      command: command,
      endpoint: endpoint,
      ready: ready,
      restart: restart ?? EnvironmentRestartPolicy.onFailure,
      restartOn: restartOn ?? const [],
    );
  }

  /// What to run.
  final EnvironmentCommand command;

  /// The endpoint it serves on its port.
  final EnvironmentProcessEndpoint? endpoint;

  /// How to tell it is up.
  final EnvironmentReadyProbe? ready;

  /// What to do when it exits.
  final EnvironmentRestartPolicy restart;

  /// Globs of changed paths that restart it.
  final List<String> restartOn;

  @override
  String get kind => 'process';

  @override
  Iterable<EnvironmentCommand> get commands => [command];

  @override
  Map<String, dynamic> toJson() => {
    ...baseJson(),
    'command': command.toJson(),
    if (endpoint != null) 'endpoint': endpoint!.toJson(),
    if (ready != null) 'ready': ready!.toJson(),
    'restart': restart.wire,
    if (restartOn.isNotEmpty) 'restartOn': restartOn,
  };

  @override
  bool operator ==(Object other) =>
      other is ProcessEnvironmentComponent &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// The endpoint a process serves.
class EnvironmentProcessEndpoint {
  /// Creates an [EnvironmentProcessEndpoint].
  const EnvironmentProcessEndpoint({
    required this.role,
    this.label,
    this.primary = false,
  });

  static EnvironmentProcessEndpoint? _read(EnvironmentJsonReader reader) {
    final role = reader.string('role', required: true, nonEmpty: true);
    final label = reader.string('label');
    final primary = reader.boolean('primary');
    reader.finish();
    if (role == null) {
      return null;
    }
    return EnvironmentProcessEndpoint(
      role: role,
      label: label,
      primary: primary ?? false,
    );
  }

  /// Stable role; `{url.<role>}` resolves to it.
  final String role;

  /// What to show.
  final String? label;

  /// The main entry point.
  final bool primary;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'role': role,
    if (label != null) 'label': label,
    if (primary) 'primary': true,
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentProcessEndpoint &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// A one-shot step.
class TaskEnvironmentComponent extends EnvironmentComponent {
  /// Creates a [TaskEnvironmentComponent].
  TaskEnvironmentComponent({
    required super.id,
    super.label,
    super.enabledWhen,
    super.after,
    super.cwd,
    super.env,
    super.ports,
    required this.command,
    required this.when,
    this.onChange = const [],
    int? timeoutSeconds,
  }) : timeoutSeconds = timeoutSeconds ?? _defaultTimeout(when) {
    if (when.isEmpty) {
      throw ArgumentError('A task needs at least one trigger');
    }
  }

  static TaskEnvironmentComponent? _read(
    EnvironmentJsonReader reader,
    EnvironmentComponentBase? base,
  ) {
    final ports = EnvironmentComponent._readPorts(reader);
    final command = EnvironmentComponent._readBody(reader);
    final wires = reader.list('when', required: true, nonEmpty: true);
    final when = <EnvironmentTaskTrigger>{};
    var ok = wires != null;
    for (final (index, wire) in (wires ?? const []).indexed) {
      final trigger = wire is String
          ? EnvironmentTaskTrigger.byWire[wire]
          : null;
      if (trigger == null) {
        reader.issues.add(
          EnvironmentDefinitionIssue(
            '${reader.pathOf('when')}[$index]',
            choiceIssue(wire, EnvironmentTaskTrigger.byWire.keys),
          ),
        );
        ok = false;
      } else {
        when.add(trigger);
      }
    }
    final onChange = reader.strings('onChange');
    final timeout = reader.integer('timeout');
    if (base == null || ports == null || command == null || !ok) {
      return null;
    }
    return TaskEnvironmentComponent(
      id: base.id,
      label: base.label,
      enabledWhen: base.enabledWhen,
      after: base.after,
      cwd: base.cwd,
      env: base.env,
      ports: ports,
      command: command,
      when: when,
      onChange: onChange ?? const [],
      timeoutSeconds: timeout,
    );
  }

  static int _defaultTimeout(Set<EnvironmentTaskTrigger> when) {
    if (when.contains(EnvironmentTaskTrigger.archive)) {
      return 120;
    }
    return 300;
  }

  /// What to run.
  final EnvironmentCommand command;

  /// When it runs.
  final Set<EnvironmentTaskTrigger> when;

  /// Globs of changed paths that run it.
  final List<String> onChange;

  /// How long it may take.
  final int timeoutSeconds;

  /// Whether it follows the worktree.
  bool get isWorktreeTask => when.any((trigger) => trigger.isWorktreeTrigger);

  @override
  String get kind => 'task';

  @override
  Iterable<EnvironmentCommand> get commands => [command];

  @override
  Map<String, dynamic> toJson() => {
    ...baseJson(),
    'when': [for (final trigger in when) trigger.name],
    if (onChange.isNotEmpty) 'onChange': onChange,
    'command': command.toJson(),
    'timeout': timeoutSeconds,
  };

  @override
  bool operator ==(Object other) =>
      other is TaskEnvironmentComponent &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// A desktop application. CC never talks to it, only to its windows.
class AppEnvironmentComponent extends EnvironmentComponent {
  /// Creates an [AppEnvironmentComponent].
  AppEnvironmentComponent({
    required super.id,
    super.label,
    super.enabledWhen,
    super.cwd,
    super.env,
    super.ports,
    required this.command,
    this.prepare,
    this.isolateHome = false,
    this.inputMode = EnvironmentAppInputMode.background,
  });

  static AppEnvironmentComponent? _read(
    EnvironmentJsonReader reader,
    EnvironmentComponentBase? base,
  ) {
    final ports = EnvironmentComponent._readPorts(reader);
    final command = EnvironmentComponent._readBody(reader);
    final prepare = reader.string('prepare', nonEmpty: true);
    final isolateHome = reader.choice('isolate', const {'home': true});
    final input = reader.choice('input', EnvironmentAppInputMode.byWire);
    if (base == null || ports == null || command == null) {
      return null;
    }
    return AppEnvironmentComponent(
      id: base.id,
      label: base.label,
      enabledWhen: base.enabledWhen,
      cwd: base.cwd,
      env: base.env,
      ports: ports,
      command: command,
      prepare: prepare,
      isolateHome: isolateHome ?? false,
      inputMode: input ?? EnvironmentAppInputMode.background,
    );
  }

  /// What to run.
  final EnvironmentCommand command;

  /// A task run before every Launch.
  final String? prepare;

  /// Give the process a private home.
  final bool isolateHome;

  /// How agent input is delivered.
  final EnvironmentAppInputMode inputMode;

  @override
  String get kind => 'app';

  @override
  Iterable<EnvironmentCommand> get commands => [command];

  @override
  Map<String, dynamic> toJson() => {
    ...baseJson(),
    'command': command.toJson(),
    if (prepare != null) 'prepare': prepare,
    if (isolateHome) 'isolate': 'home',
    'input': inputMode.name,
  };

  @override
  bool operator ==(Object other) =>
      other is AppEnvironmentComponent &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}
