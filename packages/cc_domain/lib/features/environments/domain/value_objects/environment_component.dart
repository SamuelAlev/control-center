import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
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

  /// Parses [wire], or null.
  static EnvironmentTaskTrigger? tryParse(Object? wire) {
    for (final trigger in values) {
      if (trigger.name == wire) {
        return trigger;
      }
    }
    return null;
  }

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

  /// Parses [wire], defaulting to [onFailure].
  static EnvironmentRestartPolicy parse(Object? wire) =>
      EnvironmentRestartPolicy.values.firstWhere(
        (policy) => policy.wire == wire,
        orElse: () => onFailure,
      );
}

/// How agent input reaches a desktop window.
enum EnvironmentAppInputMode {
  /// Posted to the process, leaving the cursor and focus alone.
  background,

  /// Activates the window and injects at system level.
  foreground;

  /// Parses [wire], defaulting to [background].
  static EnvironmentAppInputMode parse(Object? wire) =>
      wire == 'foreground' ? foreground : background;
}

/// Where a command runs. Both fields are optional.
class EnvironmentCwd {
  /// Creates an [EnvironmentCwd].
  const EnvironmentCwd({this.role, this.path});

  /// Parses a `cwd` object.
  factory EnvironmentCwd.fromJson(Map<String, dynamic> json) => EnvironmentCwd(
    role: json['role'] as String?,
    path: json['path'] as String?,
  );

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

  /// Parses a `ready` object.
  factory EnvironmentReadyProbe.fromJson(Map<String, dynamic> json) =>
      EnvironmentReadyProbe(
        http: json['http'] as String?,
        tcp: json['tcp'] as String?,
        logMatch: json['logMatch'] as String?,
        expectBelow: (json['expectBelow'] as num?)?.toInt() ?? 500,
        timeoutSeconds: (json['timeout'] as num?)?.toInt() ?? 120,
      );

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

  /// Parses a component by its `kind`.
  factory EnvironmentComponent.fromJson(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final kind = json['kind'];
    return switch (kind) {
      'compose' => ComposeEnvironmentComponent.fromJson(json),
      'cli' => CliEnvironmentComponent.fromJson(json, path: path),
      'process' => ProcessEnvironmentComponent.fromJson(json, path: path),
      'task' => TaskEnvironmentComponent.fromJson(json, path: path),
      'app' => AppEnvironmentComponent.fromJson(json, path: path),
      _ => throw FormatException('$path.kind is not a component kind: $kind'),
    };
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

  static List<String> _strings(Object? json) => [
    for (final item in (json as List?) ?? const []) '$item',
  ];

  static Map<String, String> _env(Object? json) => {
    for (final entry in ((json as Map?) ?? const {}).entries)
      '${entry.key}': '${entry.value}',
  };

  static List<String> _ports(Map<String, dynamic> json) => [
    if (json['port'] is String) json['port'] as String,
    ..._strings(json['ports']),
  ];

  static EnvironmentCwd? _cwd(Map<String, dynamic> json) => json['cwd'] is Map
      ? EnvironmentCwd.fromJson(Map<String, dynamic>.from(json['cwd'] as Map))
      : null;

  static EnvironmentCommand _body(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final script = json['script'];
    if (script is List) {
      return ShellEnvironmentCommand(script.join('\n'));
    }
    return EnvironmentCommand.fromJson(json['command'], path: '$path.command');
  }
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

  /// Parses a compose component.
  factory ComposeEnvironmentComponent.fromJson(Map<String, dynamic> json) =>
      ComposeEnvironmentComponent(
        id: json['id'] as String,
        label: json['label'] as String?,
        enabledWhen: json['enabledWhen'] as String?,
        after: EnvironmentComponent._strings(json['after']),
        cwd: EnvironmentComponent._cwd(json),
        env: EnvironmentComponent._env(json['env']),
        file: json['file'] as String?,
        services: EnvironmentComponent._strings(json['services']),
        build: json['build'] as bool? ?? true,
        healthchecks: {
          for (final entry
              in ((json['healthchecks'] as Map?) ?? const {}).entries)
            '${entry.key}': EnvironmentComponent._strings(entry.value),
        },
        http: json['http'] == null
            ? null
            : EnvironmentComponent._strings(json['http']),
        timeoutSeconds: (json['timeout'] as num?)?.toInt() ?? 300,
      );

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
    this.agentPassthrough,
  }) {
    for (final verb in const ['create', 'status', 'destroy']) {
      if (!verbs.containsKey(verb)) {
        throw ArgumentError('A cli component needs the $verb verb');
      }
    }
  }

  /// Parses a cli component.
  factory CliEnvironmentComponent.fromJson(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final verbs = json['verbs'];
    if (verbs is! Map) {
      throw FormatException('$path.verbs is required');
    }
    final passthrough = json['agentPassthrough'];
    final map = json['statusMap'];
    return CliEnvironmentComponent(
      id: json['id'] as String,
      label: json['label'] as String?,
      enabledWhen: json['enabledWhen'] as String?,
      after: EnvironmentComponent._strings(json['after']),
      cwd: EnvironmentComponent._cwd(json),
      env: EnvironmentComponent._env(json['env']),
      verbs: {
        for (final entry in verbs.entries)
          '${entry.key}': EnvironmentCommand.fromJson(
            entry.value,
            path: '$path.verbs.${entry.key}',
          ),
      },
      statusMap: map is Map
          ? EnvironmentStatusMap.fromJson(Map<String, dynamic>.from(map))
          : null,
      keepsDataOnStop: json['keepsDataOnStop'] as bool? ?? true,
      readyTimeoutSeconds: (json['readyTimeout'] as num?)?.toInt() ?? 600,
      timeouts: {
        for (final entry in ((json['timeouts'] as Map?) ?? const {}).entries)
          '${entry.key}': (entry.value as num).toInt(),
      },
      agentPassthrough: passthrough is Map
          ? EnvironmentAgentPassthrough.fromJson(
              Map<String, dynamic>.from(passthrough),
            )
          : null,
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

  /// Parses a rule.
  factory EnvironmentPassthroughRule.fromJson(Map<String, dynamic> json) =>
      EnvironmentPassthroughRule(
        argv: EnvironmentComponent._strings(json['argv']),
        maps: json['maps'] as String,
        positionalName: (json['positionalName'] as num?)?.toInt(),
        nameFilter: json['nameFilter'] == true,
        pathFlags: EnvironmentComponent._strings(json['pathFlags']),
        denyFlags: EnvironmentComponent._strings(json['denyFlags']),
      );

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

  /// Parses a passthrough block.
  factory EnvironmentAgentPassthrough.fromJson(Map<String, dynamic> json) =>
      EnvironmentAgentPassthrough(
        binary: json['binary'] as String,
        allow: [
          for (final rule in (json['allow'] as List?) ?? const [])
            EnvironmentPassthroughRule.fromJson(
              Map<String, dynamic>.from(rule as Map),
            ),
        ],
      );

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

  /// Parses a process component.
  factory ProcessEnvironmentComponent.fromJson(
    Map<String, dynamic> json, {
    required String path,
  }) => ProcessEnvironmentComponent(
    id: json['id'] as String,
    label: json['label'] as String?,
    enabledWhen: json['enabledWhen'] as String?,
    after: EnvironmentComponent._strings(json['after']),
    cwd: EnvironmentComponent._cwd(json),
    env: EnvironmentComponent._env(json['env']),
    ports: EnvironmentComponent._ports(json),
    command: EnvironmentComponent._body(json, path: path),
    endpoint: json['endpoint'] is Map
        ? EnvironmentProcessEndpoint.fromJson(
            Map<String, dynamic>.from(json['endpoint'] as Map),
          )
        : null,
    ready: json['ready'] is Map
        ? EnvironmentReadyProbe.fromJson(
            Map<String, dynamic>.from(json['ready'] as Map),
          )
        : null,
    restart: EnvironmentRestartPolicy.parse(json['restart']),
    restartOn: EnvironmentComponent._strings(json['restartOn']),
  );

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

  /// Parses an endpoint.
  factory EnvironmentProcessEndpoint.fromJson(Map<String, dynamic> json) =>
      EnvironmentProcessEndpoint(
        role: json['role'] as String,
        label: json['label'] as String?,
        primary: json['primary'] == true,
      );

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

  /// Parses a task component.
  factory TaskEnvironmentComponent.fromJson(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final when = <EnvironmentTaskTrigger>{};
    for (final wire in (json['when'] as List?) ?? const []) {
      final trigger = EnvironmentTaskTrigger.tryParse(wire);
      if (trigger == null) {
        throw FormatException('$path.when has an unknown trigger: $wire');
      }
      when.add(trigger);
    }
    return TaskEnvironmentComponent(
      id: json['id'] as String,
      label: json['label'] as String?,
      enabledWhen: json['enabledWhen'] as String?,
      after: EnvironmentComponent._strings(json['after']),
      cwd: EnvironmentComponent._cwd(json),
      env: EnvironmentComponent._env(json['env']),
      ports: EnvironmentComponent._ports(json),
      command: EnvironmentComponent._body(json, path: path),
      when: when,
      onChange: EnvironmentComponent._strings(json['onChange']),
      timeoutSeconds: (json['timeout'] as num?)?.toInt(),
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
    super.after,
    super.cwd,
    super.env,
    super.ports,
    required this.command,
    this.prepare,
    this.isolateHome = false,
    this.windowBundleId,
    this.inputMode = EnvironmentAppInputMode.background,
  });

  /// Parses an app component.
  factory AppEnvironmentComponent.fromJson(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final window = json['window'];
    final match = window is Map ? window['match'] : null;
    return AppEnvironmentComponent(
      id: json['id'] as String,
      label: json['label'] as String?,
      enabledWhen: json['enabledWhen'] as String?,
      after: EnvironmentComponent._strings(json['after']),
      cwd: EnvironmentComponent._cwd(json),
      env: EnvironmentComponent._env(json['env']),
      ports: EnvironmentComponent._ports(json),
      command: EnvironmentComponent._body(json, path: path),
      prepare: json['prepare'] as String?,
      isolateHome: json['isolate'] == 'home',
      windowBundleId: match is Map ? match['bundleId'] as String? : null,
      inputMode: EnvironmentAppInputMode.parse(json['input']),
    );
  }

  /// What to run.
  final EnvironmentCommand command;

  /// A task run before every Launch.
  final String? prepare;

  /// Give the process a private home.
  final bool isolateHome;

  /// Match windows by bundle id when the app leaves the process tree.
  final String? windowBundleId;

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
    if (windowBundleId != null)
      'window': {
        'match': {'bundleId': windowBundleId},
      },
    'input': inputMode.name,
  };

  @override
  bool operator ==(Object other) =>
      other is AppEnvironmentComponent &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}
