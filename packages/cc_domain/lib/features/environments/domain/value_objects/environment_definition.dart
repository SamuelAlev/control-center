import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_naming.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_template.dart';
import 'package:collection/collection.dart';

/// What to do when a space lacks a role.
enum EnvironmentWhenMissing {
  /// Add the repo to the space first.
  addToSpace,

  /// Use the registered checkout, read-only by convention.
  useSource,

  /// Leave the variable unset.
  skip;

  /// Parses [wire], or null.
  static EnvironmentWhenMissing? tryParse(Object? wire) {
    for (final value in values) {
      if (value.name == wire) {
        return value;
      }
    }
    return null;
  }
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

  /// Parses a role.
  factory EnvironmentRole.fromJson(String key, Map<String, dynamic> json) =>
      EnvironmentRole(
        key: key,
        repoId: (json['repoId'] as String?) ?? '',
        anchor: json['anchor'] == true,
        required: json['required'] == true,
        whenMissing: EnvironmentWhenMissing.tryParse(json['whenMissing']),
      );

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

  /// Parses a `routing` object.
  factory EnvironmentRouting.fromJson(Map<String, dynamic> json) =>
      EnvironmentRouting(
        mode: json['mode'] == 'tool'
            ? EnvironmentRoutingMode.tool
            : EnvironmentRoutingMode.router,
        domain: json['domain'] as String?,
        upstream: json['upstream'] as String?,
        tls: json['tls'] == true,
        caFile: json['caFile'] as String?,
      );

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

  /// Parses an option.
  factory EnvironmentOption.fromJson(Map<String, dynamic> json) =>
      EnvironmentOption(
        key: (json['key'] as String?) ?? '',
        type: (json['type'] as String?) ?? 'string',
        label: json['label'] as String?,
        values: [
          for (final value in (json['values'] as List?) ?? const []) '$value',
        ],
        defaultValue: json['default'],
        agentDefault: json['agentDefault'],
      );

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

  /// Parses a check.
  factory EnvironmentCheck.fromJson(
    Map<String, dynamic> json, {
    required String path,
  }) => EnvironmentCheck(
    id: json['id'] as String,
    label: (json['label'] as String?) ?? json['id'] as String,
    command: json['command'] == null
        ? null
        : EnvironmentCommand.fromJson(json['command'], path: '$path.command'),
    expectOutput: json['expectOutput'] as String?,
    file: json['file'] as String?,
    hint: json['hint'] as String?,
    fix: json['fix'] as String?,
  );

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

  /// Parses a `policy` object.
  factory EnvironmentPolicy.fromJson(Map<String, dynamic> json) =>
      EnvironmentPolicy(
        autoCreate: EnvironmentAutoCreate.parse(json['autoCreate']),
        followPrHead: json['followPrHead'] as bool? ?? true,
        idleStopMinutes: (json['idleStopMinutes'] as num?)?.toInt() ?? 240,
        forkPrs: EnvironmentForkPolicy.tryParse(json['forkPrs']),
        maxRunning: (json['maxRunning'] as num?)?.toInt() ?? 6,
        rigTtlHours: (json['rigTtlHours'] as num?)?.toInt() ?? 24,
      );

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

  /// Parses [wire], defaulting to [off].
  static EnvironmentAutoCreate parse(Object? wire) =>
      values.firstWhere((value) => value.wire == wire, orElse: () => off);
}

/// How fork PRs are treated.
enum EnvironmentForkPolicy {
  /// Run in a VM.
  rig,

  /// Each start needs an admin.
  approval,

  /// Refused.
  deny;

  /// Parses [wire], or null.
  static EnvironmentForkPolicy? tryParse(Object? wire) {
    for (final value in values) {
      if (value.name == wire) {
        return value;
      }
    }
    return null;
  }
}

/// Where an environment runs.
enum EnvironmentPlacement {
  /// On the host, as the server's OS user.
  host,

  /// In a dedicated microVM.
  rig;

  /// Parses [wire], defaulting to [host].
  static EnvironmentPlacement parse(Object? wire) => wire == 'rig' ? rig : host;
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
  /// Throws [FormatException] on a malformed shape. Semantic rules live in
  /// [validateEnvironmentDefinition], which must also run at read time.
  factory EnvironmentDefinition.fromJson(Map<String, dynamic> json) {
    try {
      final repos = json['repos'];
      if (repos is! Map || repos.isEmpty) {
        throw const FormatException('repos needs at least one role');
      }
      // A file meant for linking leaves these out on purpose: repo ids belong
      // to a workspace. Name them all, so one fix doesn't reveal the next.
      final unbound = [
        for (final entry in repos.entries)
          if (entry.value is Map &&
              '${(entry.value as Map)['repoId'] ?? ''}'.isEmpty)
            '${entry.key}',
      ];
      if (unbound.isNotEmpty) {
        throw FormatException('Pick a repo for: ${unbound.join(', ')}');
      }
      final components = json['components'];
      if (components is! List) {
        throw const FormatException('components is required');
      }
      return EnvironmentDefinition(
        contract: (json['contract'] as num?)?.toInt() ?? 1,
        name: (json['name'] as String?) ?? '',
        repos: [
          for (final entry in repos.entries)
            EnvironmentRole.fromJson(
              '${entry.key}',
              Map<String, dynamic>.from(entry.value as Map),
            ),
        ],
        naming: EnvironmentNaming.fromJson(
          json['naming'] is Map
              ? Map<String, dynamic>.from(json['naming'] as Map)
              : const {},
        ),
        routing: json['routing'] is Map
            ? EnvironmentRouting.fromJson(
                Map<String, dynamic>.from(json['routing'] as Map),
              )
            : const EnvironmentRouting(),
        seedFiles: [
          for (final file in (json['seedFiles'] as List?) ?? const []) '$file',
        ],
        options: [
          for (final option in (json['options'] as List?) ?? const [])
            EnvironmentOption.fromJson(
              Map<String, dynamic>.from(option as Map),
            ),
        ],
        env: {
          for (final entry in ((json['env'] as Map?) ?? const {}).entries)
            '${entry.key}': '${entry.value}',
        },
        checks: [
          for (final (index, check)
              in ((json['checks'] as List?) ?? const []).indexed)
            EnvironmentCheck.fromJson(
              Map<String, dynamic>.from(check as Map),
              path: 'checks[$index]',
            ),
        ],
        components: [
          for (final (index, component) in components.indexed)
            EnvironmentComponent.fromJson(
              Map<String, dynamic>.from(component as Map),
              path: 'components[$index]',
            ),
        ],
        placement: EnvironmentPlacement.parse(json['placement']),
        policy: json['policy'] is Map
            ? EnvironmentPolicy.fromJson(
                Map<String, dynamic>.from(json['policy'] as Map),
              )
            : const EnvironmentPolicy(),
      );
    } on FormatException {
      rethrow;
    } on TypeError catch (e) {
      throw FormatException('Malformed definition: $e');
    } on ArgumentError catch (e) {
      throw FormatException('${e.message}');
    }
  }

  /// Whether a tool here can finish a start on a terminal, for when it needs a
  /// person: a password, or some other question it can't ask through a pipe.
  bool get hasSetupVerb => components
      .whereType<CliEnvironmentComponent>()
      .any((component) => component.verbs.containsKey('setup'));

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

  /// The role a component runs in, given the [present] roles of a space.
  ///
  /// The first role in declared order that the space has, unless the component
  /// names one.
  String? roleFor(EnvironmentComponent component, Set<String> present) {
    final named = component.cwd?.role;
    if (named != null) {
      return named;
    }
    for (final role in repos) {
      if (present.contains(role.key)) {
        return role.key;
      }
    }
    return null;
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
  String toString() => '$path: $message';

  @override
  bool operator ==(Object other) =>
      other is EnvironmentDefinitionIssue &&
      other.path == path &&
      other.message == message;

  @override
  int get hashCode => Object.hash(path, message);
}

const _reservedEnvKeys = {'PATH', 'HOME'};

/// Variables that make a process load or run something its argv never named.
/// Definitions reach argv, and these would reach past it: the same command,
/// with other code in it.
const _loaderEnvKeys = {
  'BASHOPTS',
  'BASH_ENV',
  'CLASSPATH',
  'DOTNET_STARTUP_HOOKS',
  'ENV',
  'GCONV_PATH',
  'IFS',
  'JAVA_TOOL_OPTIONS',
  'JDK_JAVA_OPTIONS',
  'LUA_INIT',
  'LUA_PATH',
  'NODE_OPTIONS',
  'NODE_PATH',
  'PERL5DB',
  'PERL5LIB',
  'PERL5OPT',
  'PERLLIB',
  'PHPRC',
  'PHP_INI_SCAN_DIR',
  'PROMPT_COMMAND',
  'PYTHONHOME',
  'PYTHONPATH',
  'PYTHONSTARTUP',
  'RUBYLIB',
  'RUBYOPT',
  'SHELLOPTS',
  'ZDOTDIR',
  '_JAVA_OPTIONS',
};
const _loaderEnvPrefixes = ['DYLD_', 'GIT_', 'LD_'];

/// Shells whose `-c` takes a script.
const _shells = {'ash', 'bash', 'dash', 'ksh', 'sh', 'zsh'};

/// Other interpreters, and the flags whose next argument is code.
const _inlineScriptFlags = {
  'cmd': {'/c', '/k'},
  'deno': {'eval'},
  'node': {'-e', '--eval', '-p', '--print'},
  'perl': {'-e', '-E'},
  'php': {'-r'},
  'powershell': {'-c', '-command'},
  'pwsh': {'-c', '-command'},
  'python': {'-c'},
  'ruby': {'-e'},
};

/// Heap limits, the one use of `NODE_OPTIONS` that loads nothing.
final _nodeHeapOptions = RegExp(
  r'^--max-(old|semi)-space-size=\d+( --max-(old|semi)-space-size=\d+)*$',
);
final _envKey = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
final _optionKey = RegExp(r'^[a-z][a-z0-9_]{0,31}$');
final _componentId = RegExp(r'^[a-z][a-z0-9_-]{0,47}$');
const _allowedSuffixes = ['.test', '.localhost', '.internal'];

/// Whether [key] changes how a process loads code. Case is ignored because
/// Windows ignores it.
bool _isLoaderEnvKey(String key) {
  final upper = key.toUpperCase();
  return _loaderEnvKeys.contains(upper) ||
      _loaderEnvPrefixes.any(upper.startsWith);
}

/// Whether [key] is `NODE_OPTIONS` set to nothing but heap limits. `--require`
/// and `--import` are why the variable is otherwise refused.
bool _isHeapSizing(String key, String value) =>
    key.toUpperCase() == 'NODE_OPTIONS' && _nodeHeapOptions.hasMatch(value);

/// The inline code in [argv]. For a shell, that is the script of each `-c`: the
/// first operand after a flag cluster holding `c`, as in `-c`, `-lc` or `-euc`.
/// Later operands are the script's `$1`, `$2` and so on, and those are safe.
///
/// This looks at every position, not only the first, so `env sh -c` and
/// `docker compose exec web sh -c` count too.
Iterable<String> _shellScripts(List<String> argv) sync* {
  for (final (index, argument) in argv.indexed) {
    final name = argument
        .split(RegExp(r'[/\\]'))
        .last
        .toLowerCase()
        .replaceFirst(RegExp(r'\.exe$'), '');
    // `python3.12` is python.
    final inline =
        _inlineScriptFlags[name.replaceFirst(RegExp(r'[\d.]+$'), '')];
    if (inline != null) {
      for (var at = index + 1; at + 1 < argv.length; at++) {
        if (inline.contains(argv[at].toLowerCase())) {
          yield argv[at + 1];
          break;
        }
      }
      continue;
    }
    if (!_shells.contains(name)) {
      continue;
    }
    var script = false;
    var next = index + 1;
    while (next < argv.length) {
      final flag = argv[next];
      if (flag == '--') {
        next++;
        break;
      }
      // A placeholder isn't a flag yet, and an option value can make it one.
      if (flag.length < 2 ||
          !(flag.startsWith('-') || flag.startsWith('+')) ||
          EnvironmentValues.placeholdersIn(flag).isNotEmpty) {
        break;
      }
      final cluster = flag.startsWith('--') ? '' : flag.substring(1);
      script = script || cluster.contains('c');
      // `-o pipefail` and `--rcfile <file>` each take the next argument.
      final takesValue =
          cluster.contains('o') ||
          cluster.contains('O') ||
          const {'--rcfile', '--init-file'}.contains(flag);
      next += takesValue ? 2 : 1;
    }
    if (script && next < argv.length) {
      yield argv[next];
    }
  }
}

/// Checks the rules that keep a definition safe to run.
///
/// Pure, and re-run at read time before anything reaches a process, so a row
/// written by an older build or edited by hand can't bypass it. [linkedRepoIds]
/// is the workspace's repos; pass null to skip that check when the caller has
/// none to hand.
List<EnvironmentDefinitionIssue> validateEnvironmentDefinition(
  EnvironmentDefinition definition, {
  Set<String>? linkedRepoIds,
}) {
  final issues = <EnvironmentDefinitionIssue>[];
  void add(String path, String message) =>
      issues.add(EnvironmentDefinitionIssue(path, message));

  if (definition.contract != 1) {
    add('contract', 'Unsupported contract version ${definition.contract}');
  }

  final roles = {for (final role in definition.repos) role.key};
  if (roles.length != definition.repos.length) {
    add('repos', 'Role names must be unique');
  }
  for (final role in definition.repos) {
    if (linkedRepoIds != null && !linkedRepoIds.contains(role.repoId)) {
      if (role.required) {
        add('repos.${role.key}', 'The repo is not linked to this workspace');
      }
    }
  }
  if (definition.hasStack && !definition.repos.any((role) => role.anchor)) {
    add('repos', 'At least one role must be an anchor');
  }

  final naming = definition.naming;
  final project = naming.project;
  if (project != null && !isValidEnvironmentLabel(project)) {
    add('naming.project', 'Use lower-case letters, digits and hyphens');
  }
  if (naming.maxLength < 1 || naming.maxLength > 63) {
    add('naming.maxLength', 'Must be between 1 and 63');
  }
  final pool = naming.pool;
  if (pool != null) {
    if (!pool.names.contains('{n}')) {
      add('naming.pool.names', 'Must contain {n}');
    }
    if (pool.size < 1) {
      add('naming.pool.size', 'Must be at least 1');
    }
  }

  final routing = definition.routing;
  if (routing.mode == EnvironmentRoutingMode.tool) {
    final domain = routing.domain;
    if (domain == null || domain.isEmpty) {
      add('routing.domain', 'Tool routing needs a domain');
    } else if (!_allowedSuffixes.any(domain.endsWith)) {
      add('routing.domain', 'Must end in .test, .localhost or .internal');
    }
    if (!_isLoopbackHostPort(routing.upstream)) {
      add('routing.upstream', 'Must be a loopback host:port');
    }
    final caFile = routing.caFile;
    if (caFile != null && !_isHomeRelative(caFile)) {
      add('routing.caFile', 'Must sit under the home directory');
    }
  }

  for (final (index, file) in definition.seedFiles.indexed) {
    if (!isSafeRelativePath(file)) {
      add('seedFiles[$index]', 'Must be a relative path inside the repo');
    }
  }

  final optionKeys = <String>{};
  for (final (index, option) in definition.options.indexed) {
    if (!_optionKey.hasMatch(option.key)) {
      add('options[$index].key', 'Must match ${_optionKey.pattern}');
    }
    if (!optionKeys.add(option.key)) {
      add('options[$index].key', 'Duplicate option ${option.key}');
    }
    if (!const {'bool', 'enum', 'multi', 'string'}.contains(option.type)) {
      add('options[$index].type', 'Unknown option type ${option.type}');
    }
  }

  void checkEnv(String path, Map<String, String> env) {
    for (final key in env.keys) {
      if (!_envKey.hasMatch(key)) {
        add('$path.$key', 'Not a valid variable name');
      } else if (_reservedEnvKeys.contains(key) || key.startsWith('CC_')) {
        add('$path.$key', 'Must not shadow PATH, HOME or CC_*');
      } else if (_isLoaderEnvKey(key) && !_isHeapSizing(key, env[key]!)) {
        add('$path.$key', 'Changes what code a process loads');
      }
    }
  }

  checkEnv('env', definition.env);

  final ids = <String>{};
  final portKeys = <String>{};
  for (final (index, component) in definition.components.indexed) {
    final path = 'components[$index]';
    if (!_componentId.hasMatch(component.id)) {
      add('$path.id', 'Must match ${_componentId.pattern}');
    }
    if (!ids.add(component.id)) {
      add('$path.id', 'Duplicate component ${component.id}');
    }
    for (final port in component.ports) {
      if (!portKeys.add(port)) {
        add('$path.port', 'Port $port is declared twice');
      }
    }
    checkEnv('$path.env', component.env);
    final cwd = component.cwd;
    if (cwd != null) {
      final role = cwd.role;
      if (role != null && !roles.contains(role)) {
        add('$path.cwd.role', 'Unknown role $role');
      }
      final relative = cwd.path;
      if (relative != null && !isSafeRelativePath(relative)) {
        add('$path.cwd.path', 'Must stay inside the worktree');
      }
    }
  }

  // Parts of a definition that must resolve to something real.
  final known = <String>{
    'name',
    'id',
    'branch',
    'stateDir',
    'home',
    for (final role in roles) ...['repo.$role', 'source.$role'],
    for (final option in optionKeys) 'opt.$option',
    for (final port in portKeys) 'port.$port',
    for (final role in definition.processEndpointRoles) 'url.$role',
  };
  const verbValues = {'service', 'tail', 'command', 'follow'};
  final hasCompose = definition.components.any(
    (component) => component is ComposeEnvironmentComponent,
  );

  bool isKnown(String key) {
    if (known.contains(key)) {
      return true;
    }
    // Compose ports and URLs are derived from the resolved compose file, so
    // they exist only once a plan has run.
    return hasCompose && RegExp(r'^port\.[A-Za-z0-9_.\-]+\.\d+$').hasMatch(key);
  }

  void checkTemplate(String path, String template, {bool verb = false}) {
    for (final key in EnvironmentValues.placeholdersIn(template)) {
      if (verb && verbValues.contains(key)) {
        continue;
      }
      if (!isKnown(key)) {
        add(path, 'Unknown placeholder {$key}');
      }
    }
  }

  void checkShell(String path, EnvironmentCommand command) {
    for (final script in _shellScripts(command.templates.toList())) {
      if (EnvironmentValues.placeholdersIn(script).isNotEmpty) {
        add(
          path,
          'A placeholder inside inline script text is an injection. Pass it '
          'as an argument after the script instead',
        );
      }
    }
  }

  void checkCondition(String path, String condition, {bool verb = false}) {
    final key = environmentConditionKey(condition);
    if (verb && verbValues.contains(key)) {
      return;
    }
    if (!known.contains(key)) {
      add(path, 'Condition reads unknown value $key');
    }
  }

  for (final entry in definition.env.entries) {
    checkTemplate('env.${entry.key}', entry.value);
  }

  for (final (index, check) in definition.checks.indexed) {
    final path = 'checks[$index]';
    final command = check.command;
    if (command != null) {
      for (final template in command.templates) {
        checkTemplate(path, template);
      }
      checkShell(path, command);
    }
    final file = check.file;
    if (file != null) {
      checkTemplate(path, file);
    }
  }

  for (final (index, component) in definition.components.indexed) {
    final path = 'components[$index]';
    final worktreeTask =
        component is TaskEnvironmentComponent && component.isWorktreeTask;
    final enabled = component.enabledWhen;
    if (enabled != null) {
      checkCondition('$path.enabledWhen', enabled);
      if (worktreeTask) {
        add('$path.enabledWhen', 'Worktree tasks run before options exist');
      }
    }
    for (final dependency in component.after) {
      if (!ids.contains(dependency)) {
        add('$path.after', 'Unknown component $dependency');
      }
    }
    for (final entry in component.env.entries) {
      checkTemplate('$path.env.${entry.key}', entry.value);
    }
    final isCli = component is CliEnvironmentComponent;
    for (final command in component.commands) {
      for (final template in command.templates) {
        checkTemplate(path, template, verb: isCli);
      }
      checkShell(path, command);
      for (final condition in command.conditions) {
        checkCondition(path, condition, verb: isCli);
      }
    }
    if (worktreeTask) {
      for (final template in [
        ...component.env.values,
        for (final command in component.commands) ...command.templates,
      ]) {
        for (final key in EnvironmentValues.placeholdersIn(template)) {
          if (key == 'name' ||
              key.startsWith('port.') ||
              key.startsWith('url.') ||
              key.startsWith('opt.')) {
            add(path, 'Worktree tasks have no environment value {$key}');
          }
        }
      }
    }
    switch (component) {
      case ProcessEnvironmentComponent(:final endpoint, :final ports):
        if (endpoint != null && ports.isEmpty) {
          add('$path.endpoint', 'An endpoint needs a declared port');
        }
        final ready = component.ready;
        for (final template in [?ready?.http, ?ready?.tcp]) {
          checkTemplate('$path.ready', template);
        }
      case AppEnvironmentComponent(:final prepare):
        if (prepare != null &&
            definition.component(prepare) is! TaskEnvironmentComponent) {
          add('$path.prepare', 'Must name a task');
        }
      case CliEnvironmentComponent(:final agentPassthrough):
        if (agentPassthrough != null && agentPassthrough.binary.contains('/')) {
          add('$path.agentPassthrough.binary', 'Must be a bare command name');
        }
      case ComposeEnvironmentComponent(:final file):
        if (file != null && !isSafeRelativePath(file)) {
          add('$path.file', 'Must be a relative path inside the repo');
        }
      case TaskEnvironmentComponent():
        break;
    }
  }

  if (definition.placement == EnvironmentPlacement.rig &&
      !definition.isRigEligible) {
    add('placement', 'Rig placement only runs compose and task components');
  }
  if (definition.policy.forkPrs == EnvironmentForkPolicy.rig &&
      !definition.isRigEligible) {
    add('policy.forkPrs', 'This definition can not run in a rig');
  }
  if (definition.placement == EnvironmentPlacement.rig ||
      definition.policy.forkPrs == EnvironmentForkPolicy.rig) {
    for (final role in definition.repos) {
      if (role.whenMissing == EnvironmentWhenMissing.useSource) {
        add(
          'repos.${role.key}',
          'A rig never receives the source checkout, so useSource can not '
              'be used with rig placement',
        );
      }
    }
  }

  return issues;
}

bool _isLoopbackHostPort(String? value) {
  if (value == null) {
    return false;
  }
  final separator = value.lastIndexOf(':');
  if (separator <= 0) {
    return false;
  }
  final host = value.substring(0, separator);
  final port = int.tryParse(value.substring(separator + 1));
  return (host == '127.0.0.1' || host == 'localhost') &&
      port != null &&
      port > 0 &&
      port < 65536;
}

bool _isHomeRelative(String value) =>
    value.startsWith('~/') && !value.split('/').contains('..');

/// Whether [path] is relative and can't climb out of its root.
bool isSafeRelativePath(String path) {
  if (path.isEmpty || path.startsWith('/') || path.startsWith('~')) {
    return false;
  }
  if (RegExp(r'^[A-Za-z]:').hasMatch(path) || path.contains(r'\')) {
    return false;
  }
  return !path.split('/').contains('..');
}
