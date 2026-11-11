import 'dart:convert';

/// The lifecycle state of a space's environment.
enum EnvironmentStatus {
  /// Row written, first start under way.
  creating,

  /// Components are coming up.
  starting,

  /// Every enabled component is ready.
  ready,

  /// Running, but something needs attention.
  degraded,

  /// A component failed.
  failed,

  /// A start stopped for something only a person can do: an answer at a
  /// terminal, a sign-in, a dependency that isn't there. Nothing is broken,
  /// and the next start picks up where this one stopped.
  blocked,

  /// Stopped. Start brings it back.
  stopped,

  /// Stop in progress.
  stopping,

  /// Destroy in progress.
  destroying,

  /// Destroyed, or no longer known to its tool.
  gone;

  /// Stable wire/storage string.
  String get wire => name;

  /// Parses [wire], defaulting to [failed] for an unknown value.
  static EnvironmentStatus fromWire(String? wire) => EnvironmentStatus.values
      .firstWhere((s) => s.name == wire, orElse: () => failed);

  /// Whether a mutation may start from this state.
  bool get isBusy =>
      this == creating ||
      this == starting ||
      this == stopping ||
      this == destroying;

  /// Whether anything is expected to be running.
  bool get isRunning => this == ready || this == degraded || this == starting;

  /// Whether it stays as it is until someone acts: it broke, or it waits for
  /// a person. Either way the row says why, and no report replaces that.
  bool get needsAttention => this == failed || this == blocked;

  /// Whether a row in this state may be written as [next].
  ///
  /// The table is the lifecycle's one statement of order, enforced where
  /// rows are written. It forbids only what no real path does: a teardown
  /// under way ends failed or gone, never back up; a stop under way is not
  /// overtaken by a report that it is up; and nothing comes up from stopped
  /// or gone without starting first. Every other move stays open, because a
  /// failed environment can recover on its own.
  bool canBecome(EnvironmentStatus next) {
    if (next == this) {
      return true;
    }
    return switch (this) {
      destroying => next == failed || next == gone,
      stopping => next != ready && next != degraded,
      stopped || gone => next != ready && next != degraded,
      creating || starting || ready || degraded || failed || blocked => true,
    };
  }
}

/// What a tool reports about itself.
enum EnvironmentReportedState {
  /// Up and answering.
  ready,

  /// Coming up.
  starting,

  /// Not running, can start again.
  stopped,

  /// Broken.
  failed,

  /// The tool has no such environment.
  missing,

  /// The report could not be understood.
  degraded;

  /// Parses [wire], or null for an unknown value.
  static EnvironmentReportedState? tryParse(String? wire) {
    for (final state in values) {
      if (state.name == wire) {
        return state;
      }
    }
    return null;
  }
}

/// Somewhere an environment can be reached.
class EnvironmentEndpoint {
  /// Creates an [EnvironmentEndpoint].
  EnvironmentEndpoint({
    required this.role,
    String? label,
    this.url,
    this.hostPort,
    this.primary = false,
  }) : label = label ?? role {
    if (role.isEmpty) {
      throw ArgumentError('EnvironmentEndpoint.role must not be empty');
    }
    if (url == null && hostPort == null) {
      throw ArgumentError('An endpoint needs a url or a hostPort');
    }
  }

  /// Parses an endpoint, returning null when it can't be used.
  static EnvironmentEndpoint? tryFromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final role = json['role'];
    final url = json['url'];
    final hostPort = json['hostPort'] ?? json['host_port'];
    if (role is! String || role.isEmpty) {
      return null;
    }
    if (url is! String && hostPort is! int) {
      return null;
    }
    return EnvironmentEndpoint(
      role: role,
      label: json['label'] is String ? json['label'] as String : null,
      url: url is String ? url : null,
      hostPort: hostPort is int ? hostPort : null,
      primary: json['primary'] == true,
    );
  }

  /// Stable role.
  final String role;

  /// What to show.
  final String label;

  /// Full URL, when this is HTTP.
  final String? url;

  /// A direct host port, when there is one.
  final int? hostPort;

  /// The environment's main entry point.
  final bool primary;

  /// Wire form.
  Map<String, dynamic> toJson() => {
    'role': role,
    'label': label,
    if (url != null) 'url': url,
    if (hostPort != null) 'host_port': hostPort,
    if (primary) 'primary': true,
  };

  /// The hostname in [url], or null.
  String? get host {
    final text = url;
    if (text == null) {
      return null;
    }
    final parsed = Uri.tryParse(text);
    return parsed == null || parsed.host.isEmpty ? null : parsed.host;
  }

  /// Whether this endpoint may be shown given [domain].
  ///
  /// Output from a tool must not become an arbitrary URL in the UI or router,
  /// so a URL has to be loopback or under the declared domain.
  bool isAllowedFor(String? domain) {
    final name = host;
    if (name == null) {
      return url == null;
    }
    final lower = name.toLowerCase();
    if (lower == 'localhost' ||
        lower == '127.0.0.1' ||
        lower.endsWith('.localhost')) {
      return true;
    }
    if (domain == null) {
      return false;
    }
    final suffix = domain.toLowerCase();
    return lower == suffix || lower.endsWith('.$suffix');
  }

  @override
  bool operator ==(Object other) =>
      other is EnvironmentEndpoint &&
      other.role == role &&
      other.label == label &&
      other.url == url &&
      other.hostPort == hostPort &&
      other.primary == primary;

  @override
  int get hashCode => Object.hash(role, label, url, hostPort, primary);
}

/// What a failure is waiting on a person for.
///
/// Read from the exit-code contract every command of a definition shares, so
/// "is this broken, or does it need someone" is decided once, here.
enum EnvironmentBlocker {
  /// Exit 3: the command needs an answer and had no terminal to ask on, such
  /// as a password for `sudo`. Run on a terminal, it asks for itself.
  input(3),

  /// Exit 4: a sign-in ran out. Renewing it is another command, which the
  /// tool names.
  authentication(4),

  /// Exit 5: something it depends on isn't there, such as a container runtime
  /// that isn't running.
  dependency(5);

  const EnvironmentBlocker(this.exitCode);

  /// The exit code that reports it.
  final int exitCode;

  /// The blocker [exitCode] reports, or null for any other code.
  static EnvironmentBlocker? ofExitCode(int? exitCode) {
    for (final blocker in values) {
      if (blocker.exitCode == exitCode) {
        return blocker;
      }
    }
    return null;
  }

  /// Whether the command clears it itself when run on a terminal: it asks, a
  /// person answers. A sign-in or a missing dependency is fixed somewhere
  /// else, so a tool that can sign in from its own prompt reports [input].
  bool get answersOnTerminal => this == input;
}

/// A structured failure from a tool.
class EnvironmentError {
  /// Creates an [EnvironmentError].
  const EnvironmentError({
    required this.code,
    required this.message,
    this.hint,
    this.command,
    this.exitCode,
    this.output,
  });

  /// Parses an error, or null when [json] isn't one.
  static EnvironmentError? tryFromJson(Object? json) {
    if (json is! Map || json['message'] is! String) {
      return null;
    }
    return EnvironmentError(
      code: json['code'] is String ? json['code'] as String : 'error',
      message: json['message'] as String,
      hint: json['hint'] is String ? json['hint'] as String : null,
      command: json['command'] is String ? json['command'] as String : null,
      exitCode: json['exitCode'] is int ? json['exitCode'] as int : null,
      output: json['output'] is String ? json['output'] as String : null,
    );
  }

  /// Stable error code.
  final String code;

  /// What went wrong.
  final String message;

  /// What to do about it.
  final String? hint;

  /// A copyable fix.
  final String? command;

  /// The process exit code, when there was one.
  final int? exitCode;

  /// The last lines the command printed before it failed, when [message] is
  /// the tool's own summary. That summary often names only what gave up
  /// ("compose exited 1"); the reason is in the lines above it.
  final String? output;

  /// What this waits on a person for, or null for a plain failure.
  EnvironmentBlocker? get blocker => EnvironmentBlocker.ofExitCode(exitCode);

  /// Wire form.
  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    if (hint != null) 'hint': hint,
    if (command != null) 'command': command,
    if (exitCode != null) 'exitCode': exitCode,
    if (output != null) 'output': output,
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentError &&
      other.code == code &&
      other.message == message &&
      other.hint == hint &&
      other.command == command &&
      other.exitCode == exitCode &&
      other.output == output;

  @override
  int get hashCode =>
      Object.hash(code, message, hint, command, exitCode, output);
}

/// Where one step of a start stands.
enum EnvironmentStepState {
  /// Not reached yet.
  pending,

  /// Under way.
  running,

  /// Finished.
  done,

  /// Failed.
  failed;

  /// Reads the state a tool wrote. Tools name the same thing differently, so
  /// the common spellings all count. A step announced with no state is the
  /// one under way; a word nobody knows has not started.
  static EnvironmentStepState parse(String? wire) => switch (wire) {
    'done' || 'ok' || 'ready' || 'completed' || 'succeeded' => done,
    'failed' || 'error' || 'crashed' => failed,
    null || 'running' || 'start' || 'started' || 'starting' => running,
    _ => pending,
  };
}

/// One line of progress from stderr.
class EnvironmentProgress {
  /// Creates an [EnvironmentProgress].
  const EnvironmentProgress({
    required this.type,
    this.id,
    this.label,
    this.state,
    this.level,
  });

  /// Parses the stored form of a step ([toJson]), or null when it isn't one.
  static EnvironmentProgress? tryFromJson(Object? json) {
    if (json is! Map || json['label'] is! String) {
      return null;
    }
    return EnvironmentProgress(
      type: 'step',
      id: json['id'] is String ? json['id'] as String : null,
      label: json['label'] as String,
      state: json['state'] is String ? json['state'] as String : null,
    );
  }

  /// Parses a stderr line, or null when it is plain log output.
  static EnvironmentProgress? tryParseLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('{')) {
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) {
      return null;
    }
    final json = decoded;
    String? text(String key) {
      final value = json[key];
      return value is String ? value : null;
    }

    final type = text('type');
    if (type == 'log') {
      final line = text('line');
      return line == null
          ? null
          : EnvironmentProgress(type: 'log', label: line);
    }
    if (type != 'step' && type != 'note') {
      return null;
    }
    // A counter is as good a name as a word: `1` and `"1"` are one step.
    final id = json['id'];
    return EnvironmentProgress(
      type: type!,
      id: id is String
          ? id
          : id is num
          ? '$id'
          : null,
      label: text('label') ?? text('message'),
      state: text('state'),
      level: text('level'),
    );
  }

  /// `step`, `note`, or `log` for a line of output the tool wrapped in JSON.
  final String type;

  /// A step's stable name. A step that reports again under the same id
  /// replaces what it said before, so its label can change as it goes.
  final String? id;

  /// What to show.
  final String? label;

  /// A step's state.
  final String? state;

  /// A note's weight: `warn` stays on the environment, anything else is log
  /// output.
  final String? level;

  /// What tells one step from another: its [id], or its [label] without one.
  String? get key => id ?? label;

  /// Whether this is a step that can be told from the others.
  bool get isStep => type == 'step' && key != null;

  /// Whether this is a line of output, to be read as if it were not JSON.
  bool get isLog => type == 'log';

  /// Where a step stands.
  EnvironmentStepState get stepState => EnvironmentStepState.parse(state);

  /// This step, over: nothing reports for it any more.
  EnvironmentProgress ended({required bool failed}) => EnvironmentProgress(
    type: type,
    id: id,
    label: label,
    state: failed ? 'failed' : 'done',
    level: level,
  );

  /// Whether this is a note worth keeping in sight.
  bool get isWarning =>
      type == 'note' &&
      label != null &&
      (level == 'warn' || level == 'warning');

  /// The line this reads as in a log.
  String get logLine {
    final text = label ?? '';
    if (isLog) {
      return text;
    }
    final suffix = state == null || state == 'running' ? '' : ' ($state)';
    return '[$type] $text$suffix';
  }

  /// A step's stored form.
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (label != null) 'label': label,
    if (state != null) 'state': state,
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentProgress &&
      other.type == type &&
      other.id == id &&
      other.label == label &&
      other.state == state &&
      other.level == level;

  @override
  int get hashCode => Object.hash(type, id, label, state, level);
}

/// What a tool says about an environment, in CC's terms.
class EnvironmentStatusReport {
  /// Creates an [EnvironmentStatusReport].
  const EnvironmentStatusReport({
    required this.state,
    this.message,
    this.detail,
    this.endpoints = const [],
    this.services = const [],
    this.warnings = const [],
    this.needsRecreate = false,
    this.error,
  });

  /// Parses the native status object.
  ///
  /// Tolerant by contract: unknown fields are ignored, and text that isn't a
  /// status object is `degraded` with the raw text as detail rather than a
  /// crash, so a tool printing a banner can't take the environment down.
  factory EnvironmentStatusReport.parse(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return EnvironmentStatusReport(
        state: EnvironmentReportedState.degraded,
        detail: text.trim(),
      );
    }
    if (json is! Map) {
      return EnvironmentStatusReport(
        state: EnvironmentReportedState.degraded,
        detail: text.trim(),
      );
    }
    final state = EnvironmentReportedState.tryParse(json['state'] as String?);
    return EnvironmentStatusReport(
      state: state ?? EnvironmentReportedState.degraded,
      detail: json['detail'] is String ? json['detail'] as String : null,
      endpoints: [
        if (json['endpoints'] is List)
          for (final item in json['endpoints'] as List)
            ?EnvironmentEndpoint.tryFromJson(item),
      ],
      services: [
        if (json['services'] is List)
          for (final item in json['services'] as List)
            if (item is String) item,
      ],
      needsRecreate: json['needsRecreate'] == true,
      error: EnvironmentError.tryFromJson(json['error']),
    );
  }

  /// The reported state.
  final EnvironmentReportedState state;

  /// One-line detail.
  final String? detail;

  /// What the deciding rule says happened, when it says anything.
  final String? message;

  /// Reported endpoints.
  final List<EnvironmentEndpoint> endpoints;

  /// Service names, for logs and exec pickers.
  final List<String> services;

  /// Non-fatal notes.
  final List<String> warnings;

  /// A change needs destroy and start. CC never acts on this alone.
  final bool needsRecreate;

  /// A structured error.
  final EnvironmentError? error;
}
