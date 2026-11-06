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

/// A structured failure from a tool.
class EnvironmentError {
  /// Creates an [EnvironmentError].
  const EnvironmentError({
    required this.code,
    required this.message,
    this.hint,
    this.command,
    this.exitCode,
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

  /// Whether a person has to do something on the host (exit 3).
  bool get needsHostSetup => exitCode == 3;

  /// Wire form.
  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    if (hint != null) 'hint': hint,
    if (command != null) 'command': command,
    if (exitCode != null) 'exitCode': exitCode,
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentError &&
      other.code == code &&
      other.message == message &&
      other.hint == hint &&
      other.command == command &&
      other.exitCode == exitCode;

  @override
  int get hashCode => Object.hash(code, message, hint, command, exitCode);
}

/// One line of progress from stderr.
class EnvironmentProgress {
  /// Creates an [EnvironmentProgress].
  const EnvironmentProgress({required this.type, this.label, this.state});

  /// Parses a stderr line, or null when it is plain log output.
  static EnvironmentProgress? tryParseLine(String line) {
    final text = line.trim();
    if (!text.startsWith('{')) {
      return null;
    }
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return null;
    }
    if (json is! Map || json['type'] is! String) {
      return null;
    }
    final type = json['type'] as String;
    if (type != 'step' && type != 'note') {
      return null;
    }
    return EnvironmentProgress(
      type: type,
      label: (json['label'] ?? json['message']) as String?,
      state: json['state'] as String?,
    );
  }

  /// `step` or `note`.
  final String type;

  /// What to show.
  final String? label;

  /// A step's state.
  final String? state;

  @override
  bool operator ==(Object other) =>
      other is EnvironmentProgress &&
      other.type == type &&
      other.label == label &&
      other.state == state;

  @override
  int get hashCode => Object.hash(type, label, state);
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
