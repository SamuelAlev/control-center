import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_naming.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_template.dart';
import 'package:collection/collection.dart';

/// Validates [json] in full: its shape, then, when that holds, the rules in
/// [validateEnvironmentDefinition]. Empty means it can be saved and run.
List<EnvironmentDefinitionIssue> checkEnvironmentDefinition(
  Object? json, {
  Set<String>? linkedRepoIds,
}) {
  final (:definition, :issues) = parseEnvironmentDefinition(json);
  if (definition == null) {
    return issues;
  }
  return validateEnvironmentDefinition(
    definition,
    linkedRepoIds: linkedRepoIds,
  );
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
final _endpointRole = RegExp(r'^[a-z][a-z0-9-]{0,30}$');
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
/// Pure, and re-run at read time before anything reaches a process, so a
/// stored row edited by hand can't bypass it. [linkedRepoIds]
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
  // The domain filters every reported URL, whoever serves the hostnames.
  final domain = routing.domain;
  if (domain != null && !_allowedSuffixes.any(domain.endsWith)) {
    add('routing.domain', 'Must end in .test, .localhost or .internal');
  }
  if (routing.mode == EnvironmentRoutingMode.tool) {
    if (domain == null || domain.isEmpty) {
      add('routing.domain', 'Tool routing needs a domain');
    }
    if (!_isLoopbackHostPort(routing.upstream)) {
      add('routing.upstream', 'Must be a loopback host:port');
    }
    final caFile = routing.caFile;
    if (caFile != null && !_isHomeRelative(caFile)) {
      add('routing.caFile', 'Must sit under the home directory');
    }
  } else {
    const toolOnly = 'Only goes with "mode": "tool"';
    if (routing.upstream != null) {
      add('routing.upstream', toolOnly);
    }
    if (routing.tls) {
      add('routing.tls', toolOnly);
    }
    if (routing.caFile != null) {
      add('routing.caFile', toolOnly);
    }
  }

  final policy = definition.policy;
  if (policy.idleStopMinutes < 0) {
    add('policy.idleStopMinutes', 'Must be at least 0. 0 turns idle stop off');
  }
  if (policy.maxRunning < 0) {
    add('policy.maxRunning', 'Must be at least 0. 0 means no limit');
  }
  if (policy.rigTtlHours < 1 || policy.rigTtlHours > 720) {
    add('policy.rigTtlHours', 'Must be between 1 and 720');
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
    if (!EnvironmentOption.types.contains(option.type)) {
      add('options[$index].type', 'Unknown option type ${option.type}');
      continue;
    }
    final choices = option.type == 'enum' || option.type == 'multi';
    if (choices && option.values.isEmpty) {
      add('options[$index].values', 'Needs at least one value');
    } else if (!choices && option.values.isNotEmpty) {
      add('options[$index].values', 'Only enum and multi options take values');
    }
    for (final (key, value) in [
      ('default', option.defaultValue),
      ('agentDefault', option.agentDefault),
    ]) {
      final problem = value == null ? null : _optionValueIssue(option, value);
      if (problem != null) {
        add('options[$index].$key', problem);
      }
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
    // A component in an optional role is left out where the space lacks it.
    // Relying on the default should not be how that happens by accident.
    // Worktree tasks are exempt: they run only where that worktree exists.
    // So is a default that is the one anchor: no space starts this without it.
    final fallback = definition.repos.firstOrNull;
    if (cwd?.role == null &&
        fallback != null &&
        !fallback.required &&
        !(fallback.anchor &&
            definition.repos.where((role) => role.anchor).length == 1) &&
        !(component is TaskEnvironmentComponent &&
            component.when.every((trigger) => trigger.isWorktreeTrigger))) {
      add(
        path,
        'Runs in ${fallback.key}, which a space may not have. Name a role in '
        'cwd, or make ${fallback.key} required',
      );
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
  // What a verb is handed besides the table, by verb: a `{service}` in
  // `create` would only be found out when it ran.
  const verbValues = {
    'logs': {'service', 'tail', 'follow'},
    'exec': {'service', 'command'},
  };
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

  void checkTemplate(
    String path,
    String template, {
    Set<String> extra = const {},
  }) {
    for (final key in EnvironmentValues.placeholdersIn(template)) {
      if (extra.contains(key)) {
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

  void checkCondition(
    String path,
    String condition, {
    Set<String> extra = const {},
  }) {
    final key = environmentConditionKey(condition);
    if (extra.contains(key)) {
      return;
    }
    if (!known.contains(key)) {
      add(path, 'Condition reads unknown value $key');
    }
  }

  for (final entry in definition.env.entries) {
    checkTemplate('env.${entry.key}', entry.value);
  }

  final checkIds = <String>{};
  for (final (index, check) in definition.checks.indexed) {
    final path = 'checks[$index]';
    if (!checkIds.add(check.id)) {
      add('$path.id', 'Duplicate check ${check.id}');
    }
    final expectOutput = check.expectOutput;
    final pattern = expectOutput == null ? null : _regexIssue(expectOutput);
    if (pattern != null) {
      add('$path.expectOutput', pattern);
    }
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

  // Endpoints share one namespace per environment, and one is the way in.
  final endpointRoles = <String>{};
  var primaries = 0;
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
    // Components start in declared order, so `after` can only wait for one
    // declared earlier. That also rules out every cycle.
    final earlier = {
      for (final other in definition.components.take(index)) other.id: other,
    };
    for (final dependency in component.after) {
      if (dependency == component.id) {
        add('$path.after', 'A component can not wait for itself');
      } else if (!ids.contains(dependency)) {
        add('$path.after', 'Unknown component $dependency');
      } else if (!earlier.containsKey(dependency)) {
        add(
          '$path.after',
          '$dependency is declared after this component. Move it above, '
              'because components start in order',
        );
      } else if (!_startsWithStack(earlier[dependency]!)) {
        add(
          '$path.after',
          '$dependency never starts with the stack, so there is nothing to '
              'wait for',
        );
      }
    }
    for (final entry in component.env.entries) {
      checkTemplate('$path.env.${entry.key}', entry.value);
    }
    if (component is CliEnvironmentComponent) {
      for (final entry in component.verbs.entries) {
        final verb = entry.key;
        final verbPath = '$path.verbs.$verb';
        if (!CliEnvironmentComponent.knownVerbs.contains(verb)) {
          add(
            verbPath,
            'Unknown verb. A tool maps '
            '${CliEnvironmentComponent.knownVerbs.join(', ')}',
          );
          continue;
        }
        final values = verbValues[verb] ?? const <String>{};
        for (final template in entry.value.templates) {
          checkTemplate(verbPath, template, extra: values);
        }
        checkShell(verbPath, entry.value);
        for (final condition in entry.value.conditions) {
          checkCondition(
            verbPath,
            condition,
            extra: {
              ...values,
              // Set only on a terminal, so only a condition may read it: as a
              // placeholder it would not exist for the piped run.
              if (component.interactive.contains(verb))
                CliEnvironmentComponent.interactiveValue,
            },
          );
        }
      }
    } else {
      for (final command in component.commands) {
        for (final template in command.templates) {
          checkTemplate(path, template);
        }
        checkShell(path, command);
        for (final condition in command.conditions) {
          checkCondition(path, condition);
        }
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
        if (endpoint != null) {
          if (!_endpointRole.hasMatch(endpoint.role)) {
            add(
              '$path.endpoint.role',
              'Use lower-case letters, digits and hyphens, starting with a '
                  'letter, at most 31 characters',
            );
          }
          if (!endpointRoles.add(endpoint.role)) {
            add('$path.endpoint.role', 'Duplicate endpoint ${endpoint.role}');
          }
          if (endpoint.primary && primaries++ > 0) {
            add('$path.endpoint.primary', 'Only one endpoint can be primary');
          }
        }
        final ready = component.ready;
        if (ready != null) {
          final http = ready.http;
          if (http != null &&
              !(http.startsWith('http://') || http.startsWith('https://'))) {
            add(
              '$path.ready.http',
              'Must be a full URL starting with http:// or https://',
            );
          }
          final tcp = ready.tcp;
          if (tcp != null && !_isHostPort(tcp)) {
            add('$path.ready.tcp', 'Must be host:port');
          }
          final logMatch = ready.logMatch;
          final pattern = logMatch == null ? null : _regexIssue(logMatch);
          if (pattern != null) {
            add('$path.ready.logMatch', pattern);
          }
          if (ready.timeoutSeconds < 1) {
            add('$path.ready.timeout', 'Must be at least 1');
          }
        }
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
        for (final MapEntry(key: verb, value: seconds)
            in component.timeouts.entries) {
          if (!component.verbs.containsKey(verb)) {
            add('$path.timeouts.$verb', 'This component has no $verb verb');
          } else if (seconds < 1) {
            add('$path.timeouts.$verb', 'Must be at least 1');
          }
        }
        if (component.readyTimeoutSeconds < 1) {
          add('$path.readyTimeout', 'Must be at least 1');
        }
        for (final (at, endpoint)
            in (component.statusMap?.endpoints ?? const []).indexed) {
          final mapPath = '$path.statusMap.endpoints[$at]';
          if (!endpointRoles.add(endpoint.role)) {
            add('$mapPath.role', 'Duplicate endpoint ${endpoint.role}');
          }
          if (endpoint.primary && primaries++ > 0) {
            add('$mapPath.primary', 'Only one endpoint can be primary');
          }
        }
        for (final (at, verb) in component.interactive.indexed) {
          if (!CliEnvironmentComponent.bringUpVerbs.contains(verb)) {
            add(
              '$path.interactive[$at]',
              'Only ${CliEnvironmentComponent.bringUpVerbs.join(', ')} can '
                  'run on a terminal: a person is there when they do',
            );
          } else if (!component.verbs.containsKey(verb)) {
            add('$path.interactive[$at]', 'This component has no $verb verb');
          }
        }
      case ComposeEnvironmentComponent(:final file):
        if (file != null && !isSafeRelativePath(file)) {
          add('$path.file', 'Must be a relative path inside the repo');
        }
        if (component.timeoutSeconds < 1) {
          add('$path.timeout', 'Must be at least 1');
        }
      case TaskEnvironmentComponent():
        if (component.timeoutSeconds < 1) {
          add('$path.timeout', 'Must be at least 1');
        }
    }
  }

  final composes = [
    for (final (index, component) in definition.components.indexed)
      if (component is ComposeEnvironmentComponent) index,
  ];
  for (final index in composes.skip(1)) {
    add(
      'components[$index]',
      'An environment runs one compose component: they would share one '
          'project. Put these services in the first one\'s file, or list them '
          'in its services',
    );
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

/// Whether [component] is started by a stack's Start: apps open afterwards,
/// and a task that only follows the worktree never runs there.
bool _startsWithStack(EnvironmentComponent component) => switch (component) {
  AppEnvironmentComponent() => false,
  TaskEnvironmentComponent(when: final triggers) => !triggers.every(
    (trigger) => trigger.isWorktreeTrigger,
  ),
  _ => true,
};

/// What is wrong with [value] as a value of [option], or null.
String? _optionValueIssue(EnvironmentOption option, Object value) {
  final allowed = option.values.join(', ');
  switch (option.type) {
    case 'bool':
      return value is bool ? null : 'Must be true or false';
    case 'string':
      return value is String ? null : 'Must be a string';
    case 'enum':
      return value is String && option.values.contains(value)
          ? null
          : 'Must be one of: $allowed';
    case 'multi':
      return value is List &&
              value.every(
                (item) => item is String && option.values.contains(item),
              )
          ? null
          : 'Must be a list of: $allowed';
  }
  return null;
}

/// Whether [value] is `host:port`, where either side may be a placeholder.
bool _isHostPort(String value) => RegExp(
  r'^(\[[0-9A-Fa-f:.]+\]|[^\s:/\[\]]+):(\d{1,5}|\{[^{}\s]+\})$',
).hasMatch(value);

/// The problem with compiling [pattern] as a regular expression, or null.
String? _regexIssue(String pattern) {
  try {
    RegExp(pattern);
    return null;
  } on FormatException catch (e) {
    return 'Not a valid regular expression: ${e.message}';
  }
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
