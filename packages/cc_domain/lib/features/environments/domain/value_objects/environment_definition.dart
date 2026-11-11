import 'package:cc_domain/features/environments/domain/services/environment_definition_reader.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_naming.dart';
import 'package:collection/collection.dart';

final _roleKey = RegExp(r'^[a-z][a-z0-9_]*$');

/// What to do when a space lacks a role.
enum EnvironmentWhenMissing {
  /// Add the repo to the space first.
  addToSpace,

  /// Use the registered checkout, read-only by convention.
  useSource,

  /// Leave the variable unset.
  skip;

  /// Every value by wire name.
  static Map<String, EnvironmentWhenMissing> get byWire => {
    for (final value in values) value.name: value,
  };
}

/// One role bound to a workspace repo.
class EnvironmentRole {
  /// Creates an [EnvironmentRole].
  EnvironmentRole({
    required this.key,
    required this.repoId,
    this.anchor = false,
    this.required = false,
    EnvironmentWhenMissing? whenMissing,
  }) : whenMissing =
           whenMissing ??
           (required
               ? EnvironmentWhenMissing.addToSpace
               : EnvironmentWhenMissing.skip) {
    if (key.isEmpty || repoId.isEmpty) {
      throw ArgumentError('A role needs a key and a repoId');
    }
  }

  /// Reads the role called [key], or null when it can't be built.
  static EnvironmentRole? _read(String key, EnvironmentJsonReader reader) {
    // A file meant for linking leaves this out on purpose: repo ids belong
    // to a workspace.
    final repoId = reader.raw('repoId');
    if (repoId == null || (repoId is String && repoId.isEmpty)) {
      reader.report('repoId', 'Pick a repo');
    } else if (repoId is! String) {
      reader.report('repoId', 'Must be a string');
    }
    final anchor = reader.boolean('anchor');
    final required = reader.boolean('required');
    final whenMissing = reader.choice(
      'whenMissing',
      EnvironmentWhenMissing.byWire,
    );
    reader.finish();
    if (repoId is! String || repoId.isEmpty) {
      return null;
    }
    return EnvironmentRole(
      key: key,
      repoId: repoId,
      anchor: anchor ?? false,
      required: required ?? false,
      whenMissing: whenMissing,
    );
  }

  /// Role name.
  final String key;

  /// The bound repo.
  final String repoId;

  /// A space holding this role may start the environment.
  final bool anchor;

  /// The stack can't run without it.
  final bool required;

  /// What to do when the space lacks it.
  final EnvironmentWhenMissing whenMissing;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'repoId': repoId,
    if (anchor) 'anchor': true,
    if (required) 'required': true,
    'whenMissing': whenMissing.name,
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentRole &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// How endpoints reach browsers and agents.
class EnvironmentRouting {
  /// Creates an [EnvironmentRouting].
  const EnvironmentRouting({
    this.mode = EnvironmentRoutingMode.router,
    this.domain,
    this.upstream,
    this.tls = false,
    this.caFile,
  });

  static EnvironmentRouting _read(EnvironmentJsonReader reader) {
    final mode = reader.choice('mode', {
      for (final mode in EnvironmentRoutingMode.values) mode.name: mode,
    });
    final domain = reader.string('domain', nonEmpty: true);
    final upstream = reader.string('upstream', nonEmpty: true);
    final tls = reader.boolean('tls');
    final caFile = reader.string('caFile', nonEmpty: true);
    reader.finish();
    return EnvironmentRouting(
      mode: mode ?? EnvironmentRoutingMode.router,
      domain: domain,
      upstream: upstream,
      tls: tls ?? false,
      caFile: caFile,
    );
  }

  /// Who serves the hostnames.
  final EnvironmentRoutingMode mode;

  /// The boundary a tool's hostnames must stay inside.
  final String? domain;

  /// `host:port` of the tool's proxy.
  final String? upstream;

  /// Whether [upstream] speaks TLS.
  final bool tls;

  /// CA that verifies [upstream].
  final String? caFile;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    if (domain != null) 'domain': domain,
    if (upstream != null) 'upstream': upstream,
    if (tls) 'tls': true,
    if (caFile != null) 'caFile': caFile,
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentRouting &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// Who serves an environment's hostnames.
enum EnvironmentRoutingMode {
  /// CC's own router.
  router,

  /// The tool's proxy; hostnames come from its status.
  tool,
}

/// One option on the Start form.
class EnvironmentOption {
  /// Creates an [EnvironmentOption].
  EnvironmentOption({
    required this.key,
    required this.type,
    this.label,
    this.values = const [],
    this.defaultValue,
    this.agentDefault,
  }) {
    if (key.isEmpty) {
      throw ArgumentError('An option needs a key');
    }
  }

  /// The option types.
  static const Set<String> types = {'bool', 'enum', 'multi', 'string'};

  static EnvironmentOption? _read(EnvironmentJsonReader reader) {
    final key = reader.string('key', required: true, nonEmpty: true);
    final type = reader.choice('type', {for (final type in types) type: type});
    final label = reader.string('label');
    final values = reader.strings('values');
    final defaultValue = reader.raw('default');
    final agentDefault = reader.raw('agentDefault');
    reader.finish();
    if (key == null ||
        (reader.has('type') && type == null) ||
        (reader.has('values') && values == null)) {
      return null;
    }
    return EnvironmentOption(
      key: key,
      type: type ?? 'string',
      label: label,
      values: values ?? const [],
      defaultValue: defaultValue,
      agentDefault: agentDefault,
    );
  }

  /// Stable key.
  final String key;

  /// `bool`, `enum`, `multi` or `string`.
  final String type;

  /// What to show.
  final String? label;

  /// Allowed values for `enum` and `multi`.
  final List<String> values;

  /// The default.
  final Object? defaultValue;

  /// The default for a run started by an agent.
  final Object? agentDefault;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'key': key,
    'type': type,
    if (label != null) 'label': label,
    if (values.isNotEmpty) 'values': values,
    if (defaultValue != null) 'default': defaultValue,
    if (agentDefault != null) 'agentDefault': agentDefault,
  };

  /// The string form of [value], as placeholders and `CC_ENV_OPT_*` see it.
  static String render(Object? value) {
    if (value is List) {
      return value.join(',');
    }
    return value == null ? '' : '$value';
  }

  @override
  bool operator ==(Object other) =>
      other is EnvironmentOption &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// One host-readiness row.
class EnvironmentCheck {
  /// Creates an [EnvironmentCheck].
  EnvironmentCheck({
    required this.id,
    required this.label,
    this.command,
    this.expectOutput,
    this.file,
    this.hint,
    this.fix,
  }) {
    if ((command == null) == (file == null)) {
      throw ArgumentError('A check needs exactly one of command and file');
    }
  }

  static EnvironmentCheck? _read(EnvironmentJsonReader reader) {
    final id = reader.string('id', required: true, nonEmpty: true);
    final label = reader.string('label', nonEmpty: true);
    final command = reader.has('command')
        ? EnvironmentCommand.read(
            reader.raw('command'),
            reader.pathOf('command'),
            reader.issues,
          )
        : null;
    final expectOutput = reader.string('expectOutput', nonEmpty: true);
    final file = reader.string('file', nonEmpty: true);
    final hint = reader.string('hint');
    final fix = reader.string('fix');
    if (reader.has('command') == reader.has('file')) {
      reader.reportHere('Needs exactly one of command and file');
    }
    if (reader.has('expectOutput') && !reader.has('command')) {
      reader.report('expectOutput', 'Only goes with command');
    }
    reader.finish();
    if (id == null || (command == null) == (file == null)) {
      return null;
    }
    return EnvironmentCheck(
      id: id,
      label: label ?? id,
      command: command,
      expectOutput: expectOutput,
      file: file,
      hint: hint,
      fix: fix,
    );
  }

  /// Stable id.
  final String id;

  /// What to show.
  final String label;

  /// Passes on exit 0, or when [expectOutput] matches.
  final EnvironmentCommand? command;

  /// A regular expression over stdout.
  final String? expectOutput;

  /// Passes when this file exists.
  final String? file;

  /// What to do when it fails.
  final String? hint;

  /// A copyable fix.
  final String? fix;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    if (command != null) 'command': command!.toJson(),
    if (expectOutput != null) 'expectOutput': expectOutput,
    if (file != null) 'file': file,
    if (hint != null) 'hint': hint,
    if (fix != null) 'fix': fix,
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentCheck &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// When to create, stop and allow environments.
class EnvironmentPolicy {
  /// Creates an [EnvironmentPolicy].
  const EnvironmentPolicy({
    this.autoCreate = EnvironmentAutoCreate.off,
    this.followPrHead = true,
    this.idleStopMinutes = 240,
    this.forkPrs,
    this.maxRunning = 6,
    this.rigTtlHours = 24,
  });

  static EnvironmentPolicy _read(EnvironmentJsonReader reader) {
    final autoCreate = reader.choice('autoCreate', {
      for (final value in EnvironmentAutoCreate.values) value.wire: value,
    });
    final followPrHead = reader.boolean('followPrHead');
    final idleStopMinutes = reader.integer('idleStopMinutes');
    final forkPrs = reader.choice('forkPrs', {
      for (final value in EnvironmentForkPolicy.values) value.name: value,
    });
    final maxRunning = reader.integer('maxRunning');
    final rigTtlHours = reader.integer('rigTtlHours');
    reader.finish();
    return EnvironmentPolicy(
      autoCreate: autoCreate ?? EnvironmentAutoCreate.off,
      followPrHead: followPrHead ?? true,
      idleStopMinutes: idleStopMinutes ?? 240,
      forkPrs: forkPrs,
      maxRunning: maxRunning ?? 6,
      rigTtlHours: rigTtlHours ?? 24,
    );
  }

  /// When environments start on their own.
  final EnvironmentAutoCreate autoCreate;

  /// Sync and refresh on PR head moves.
  final bool followPrHead;

  /// Idle stop delay. Zero disables it.
  final int idleStopMinutes;

  /// Fork PR handling, or null for the default.
  final EnvironmentForkPolicy? forkPrs;

  /// Running environments allowed for this definition.
  final int maxRunning;

  /// Lifetime of an environment rig.
  final int rigTtlHours;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'autoCreate': autoCreate.wire,
    'followPrHead': followPrHead,
    'idleStopMinutes': idleStopMinutes,
    if (forkPrs != null) 'forkPrs': forkPrs!.name,
    'maxRunning': maxRunning,
    'rigTtlHours': rigTtlHours,
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentPolicy &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// When environments start on their own.
enum EnvironmentAutoCreate {
  /// Never.
  off('off'),

  /// For PR spaces.
  prSpaces('prSpaces'),

  /// For every eligible space.
  allSpaces('allSpaces');

  const EnvironmentAutoCreate(this.wire);

  /// Stable wire string.
  final String wire;
}

/// How fork PRs are treated.
enum EnvironmentForkPolicy {
  /// Run in a VM.
  rig,

  /// Each start needs an admin.
  approval,

  /// Refused.
  deny,
}

/// Where an environment runs.
enum EnvironmentPlacement {
  /// On the host, as the server's OS user.
  host,

  /// In a dedicated microVM.
  rig,
}

/// A complete environment definition.
class EnvironmentDefinition {
  /// Creates an [EnvironmentDefinition].
  EnvironmentDefinition({
    this.contract = 1,
    required this.name,
    required this.repos,
    required this.naming,
    this.routing = const EnvironmentRouting(),
    this.seedFiles = const [],
    this.options = const [],
    this.env = const {},
    this.checks = const [],
    required this.components,
    this.placement = EnvironmentPlacement.host,
    this.policy = const EnvironmentPolicy(),
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('A definition needs a name');
    }
    if (repos.isEmpty) {
      throw ArgumentError('A definition needs at least one role');
    }
  }

  /// Parses a definition.
  ///
  /// Throws [EnvironmentDefinitionException] listing every shape issue. Use
  /// [parseEnvironmentDefinition] to get them without a throw. Semantic rules
  /// live in `validateEnvironmentDefinition`, which must also run at read
  /// time.
  factory EnvironmentDefinition.fromJson(Map<String, dynamic> json) {
    final (:definition, :issues) = parseEnvironmentDefinition(json);
    if (definition == null) {
      throw EnvironmentDefinitionException(issues);
    }
    return definition;
  }

  static EnvironmentDefinition? _read(EnvironmentJsonReader reader) {
    // Required, so a definition says which contract it was written for; the
    // version itself is the validator's to judge.
    final contract = reader.integer('contract', required: true);
    final name = reader.string('name', required: true, nonEmpty: true);

    final roleReader = reader.object('repos', required: true);
    final repos = <EnvironmentRole?>[];
    if (roleReader != null) {
      if (roleReader.keys.isEmpty) {
        reader.report('repos', 'Needs at least one role');
      }
      for (final key in roleReader.keys.toList()) {
        if (!_roleKey.hasMatch(key)) {
          roleReader.report(
            key,
            'Role names use lower-case letters, digits and underscores, '
            'starting with a letter',
          );
        }
        final role = roleReader.object(key);
        repos.add(role == null ? null : EnvironmentRole._read(key, role));
      }
      roleReader.finish();
    }

    final namingReader = reader.object('naming');
    final naming = namingReader == null
        ? const EnvironmentNaming()
        : EnvironmentNaming.read(namingReader);
    final routingReader = reader.object('routing');
    final routing = routingReader == null
        ? const EnvironmentRouting()
        : EnvironmentRouting._read(routingReader);
    final seedFiles = reader.strings('seedFiles');
    final options = [
      for (final option
          in reader.objects('options') ?? const <EnvironmentJsonReader>[])
        EnvironmentOption._read(option),
    ];
    final env = reader.stringMap('env');
    final checks = [
      for (final check
          in reader.objects('checks') ?? const <EnvironmentJsonReader>[])
        EnvironmentCheck._read(check),
    ];
    final components = [
      for (final component
          in reader.objects('components', required: true) ??
              const <EnvironmentJsonReader>[])
        EnvironmentComponent.read(component),
    ];
    final placement = reader.choice('placement', {
      for (final value in EnvironmentPlacement.values) value.name: value,
    });
    final policyReader = reader.object('policy');
    final policy = policyReader == null
        ? const EnvironmentPolicy()
        : EnvironmentPolicy._read(policyReader);
    reader.finish(schema: true);

    if (reader.issues.isNotEmpty || name == null || repos.isEmpty) {
      return null;
    }
    return EnvironmentDefinition(
      contract: contract ?? 1,
      name: name,
      repos: repos.cast<EnvironmentRole>(),
      naming: naming,
      routing: routing,
      seedFiles: seedFiles ?? const [],
      options: options.cast<EnvironmentOption>(),
      env: env ?? const {},
      checks: checks.cast<EnvironmentCheck>(),
      components: components.cast<EnvironmentComponent>(),
      placement: placement ?? EnvironmentPlacement.host,
      policy: policy,
    );
  }

  /// Whether a tool here can finish a start on a terminal, for when it needs a
  /// person: a password, or some other question it can't ask through a pipe.
  bool get canFinishOnTerminal => components
      .whereType<CliEnvironmentComponent>()
      .any((component) => component.interactive.isNotEmpty);

  /// Contract version.
  final int contract;

  /// Display name.
  final String name;

  /// Roles, in declared order. The first one a space has is the default cwd.
  final List<EnvironmentRole> repos;

  /// How environments are named.
  final EnvironmentNaming naming;

  /// How endpoints are routed.
  final EnvironmentRouting routing;

  /// Gitignored files copied from the source checkout.
  final List<String> seedFiles;

  /// Start form options.
  final List<EnvironmentOption> options;

  /// Variables set on tasks, processes, apps and space terminals.
  final Map<String, String> env;

  /// Host-readiness rows.
  final List<EnvironmentCheck> checks;

  /// The components, in start order.
  final List<EnvironmentComponent> components;

  /// Where it runs.
  final EnvironmentPlacement placement;

  /// Lifecycle policy.
  final EnvironmentPolicy policy;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'contract': contract,
    'name': name,
    'repos': {for (final role in repos) role.key: role.toJson()},
    'naming': naming.toJson(),
    'routing': routing.toJson(),
    if (seedFiles.isNotEmpty) 'seedFiles': seedFiles,
    if (options.isNotEmpty)
      'options': [for (final option in options) option.toJson()],
    if (env.isNotEmpty) 'env': env,
    if (checks.isNotEmpty)
      'checks': [for (final check in checks) check.toJson()],
    'components': [for (final component in components) component.toJson()],
    'placement': placement.name,
    'policy': policy.toJson(),
  };

  /// The role called [key], or null.
  EnvironmentRole? role(String key) {
    for (final role in repos) {
      if (role.key == key) {
        return role;
      }
    }
    return null;
  }

  /// The component called [id], or null.
  EnvironmentComponent? component(String id) {
    for (final component in components) {
      if (component.id == id) {
        return component;
      }
    }
    return null;
  }

  /// Whether there is anything to start. Without this there is no Start
  /// button. A task only counts when it is part of starting: `provision`,
  /// `archive`, `change` and `manual` all work on a worktree alone.
  bool get hasStack => components.any(
    (component) =>
        component is! TaskEnvironmentComponent ||
        component.when.contains(EnvironmentTaskTrigger.create) ||
        component.when.contains(EnvironmentTaskTrigger.start),
  );

  /// Whether stopping any part of this loses data.
  bool get keepsDataOnStop => components
      .whereType<CliEnvironmentComponent>()
      .every((component) => component.keepsDataOnStop);

  /// Whether rig placement can run this. Host binaries, tools with host
  /// credentials and desktop windows can't move into a VM.
  bool get isRigEligible => components.every(
    (component) =>
        component is ComposeEnvironmentComponent ||
        component is TaskEnvironmentComponent,
  );

  /// Whether anything here runs on the server host as its OS user, outside a
  /// rig: host placement, a check that runs a command, or a task that
  /// follows the worktree (provision and archive run in a space's worktree on
  /// the host whatever the placement). Only the server owner may save or
  /// approve such a definition.
  bool get runsOnHost =>
      placement == EnvironmentPlacement.host ||
      checks.any((check) => check.command != null) ||
      components.whereType<TaskEnvironmentComponent>().any(
        (task) => task.when.any((trigger) => trigger.isWorktreeTrigger),
      );

  /// The effective fork PR policy.
  EnvironmentForkPolicy get forkPolicy =>
      policy.forkPrs ??
      (isRigEligible
          ? EnvironmentForkPolicy.rig
          : EnvironmentForkPolicy.approval);

  /// Every named port any component declares.
  Set<String> get namedPorts => {
    for (final component in components) ...component.ports,
  };

  /// Every endpoint role a process declares.
  Set<String> get processEndpointRoles => {
    for (final component in components.whereType<ProcessEnvironmentComponent>())
      if (component.endpoint != null) component.endpoint!.role,
  };

  /// Compose services the definition names.
  Set<String> get composeServices => {
    for (final component in components.whereType<ComposeEnvironmentComponent>())
      ...component.services,
  };

  /// Tasks that follow the worktree, by trigger.
  Iterable<TaskEnvironmentComponent> worktreeTasks(
    EnvironmentTaskTrigger trigger,
  ) => components.whereType<TaskEnvironmentComponent>().where(
    (task) => task.when.contains(trigger),
  );

  /// The role a component runs in, given the [present] roles of a space: the
  /// one it names, or else the first role declared.
  ///
  /// Never another role the space happens to have, which would run the command
  /// in the wrong repo. Null when the space lacks that role: the component is
  /// then not part of that space's environment.
  String? roleFor(EnvironmentComponent component, Set<String> present) {
    final role = component.cwd?.role ?? repos.firstOrNull?.key;
    return present.contains(role) ? role : null;
  }

  @override
  bool operator ==(Object other) =>
      other is EnvironmentDefinition &&
      const DeepCollectionEquality().equals(other.toJson(), toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// One validation problem.
class EnvironmentDefinitionIssue {
  /// Creates an [EnvironmentDefinitionIssue].
  const EnvironmentDefinitionIssue(this.path, this.message);

  /// Where in the definition.
  final String path;

  /// What is wrong.
  final String message;

  @override
  String toString() => path.isEmpty ? message : '$path: $message';

  @override
  bool operator ==(Object other) =>
      other is EnvironmentDefinitionIssue &&
      other.path == path &&
      other.message == message;

  @override
  int get hashCode => Object.hash(path, message);
}

/// A definition, or part of one, whose shape is wrong: every issue found in
/// one pass, each at its path.
class EnvironmentDefinitionException extends FormatException {
  /// Creates an [EnvironmentDefinitionException].
  EnvironmentDefinitionException(this.issues) : super(issues.join('\n'));

  /// What is wrong, by path.
  final List<EnvironmentDefinitionIssue> issues;
}

/// Reads [json] as a definition, strictly: an unknown field, a value of the
/// wrong type or a misspelt choice is an issue at its path, never a default.
///
/// The definition is null unless the issues are empty. These are shape
/// issues only: `checkEnvironmentDefinition` adds the rules of
/// `validateEnvironmentDefinition`.
({EnvironmentDefinition? definition, List<EnvironmentDefinitionIssue> issues})
parseEnvironmentDefinition(Object? json) {
  final issues = <EnvironmentDefinitionIssue>[];
  final reader = EnvironmentJsonReader.of(json, '', issues);
  if (reader == null) {
    return (
      definition: null,
      issues: const [
        EnvironmentDefinitionIssue('', 'A definition must be a JSON object'),
      ],
    );
  }
  EnvironmentDefinition? definition;
  try {
    definition = EnvironmentDefinition._read(reader);
  } on ArgumentError catch (e) {
    // Every constructor rule is checked first; this is the backstop.
    issues.add(EnvironmentDefinitionIssue('', '${e.message}'));
  }
  return (definition: issues.isEmpty ? definition : null, issues: issues);
}
