import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:collection/collection.dart';

/// Where one component stands, or one compose service of it.
///
/// The one list of these: writers use [wire], readers [tryParse] and the
/// getters, so "is it up" is decided once instead of per screen.
enum EnvironmentComponentPhase {
  /// Not started yet.
  pending,

  /// A task with nothing to do in this start: it runs on another trigger, or
  /// already ran its one time.
  idle,

  /// Coming up.
  starting,

  /// Coming up on a terminal, where its tool can ask a person what it could
  /// not ask through a pipe. The session is the state's `sessionId`.
  interactive,

  /// A container that runs but has not passed its healthcheck.
  waiting,

  /// A process or app that runs, with no readiness check.
  running,

  /// Up and answering.
  ready,

  /// A task or one-shot service that finished cleanly.
  completed,

  /// Broke while starting or running.
  failed,

  /// A process or app that exited on its own with an error.
  crashed,

  /// Stopped on purpose; start brings it back.
  stopped,

  /// An app window that was closed.
  closed;

  /// Stable wire string.
  String get wire => name;

  /// Parses [wire], or null for an unknown value.
  static EnvironmentComponentPhase? tryParse(String? wire) {
    for (final phase in values) {
      if (phase.name == wire) {
        return phase;
      }
    }
    return null;
  }

  /// Something runs, or is on its way up.
  bool get isLive =>
      this == running ||
      this == ready ||
      this == starting ||
      this == interactive;

  /// Something runs and can be opened or used now.
  bool get isUp => this == running || this == ready;

  /// It broke.
  bool get isFailed => this == failed || this == crashed;

  /// Nothing runs and nothing is coming.
  bool get isDown =>
      this == failed || this == stopped || this == closed || this == crashed;
}

/// Where one component stands.
class EnvironmentComponentState {
  /// Creates an [EnvironmentComponentState].
  EnvironmentComponentState({
    required this.id,
    required this.kind,
    required this.state,
    this.label,
    this.detail,
    this.restarts = 0,
    this.services = const [],
    this.sessionId,
    this.lastRunAt,
    this.lastExitCode,
    this.steps = const [],
  }) {
    if (id.isEmpty || kind.isEmpty) {
      throw ArgumentError('A component state needs an id and a kind');
    }
  }

  /// Parses the wire form.
  factory EnvironmentComponentState.fromJson(Map<String, dynamic> json) =>
      EnvironmentComponentState(
        id: json['id'] as String,
        kind: json['kind'] as String,
        state: json['state'] as String,
        label: json['label'] as String?,
        detail: json['detail'] as String?,
        restarts: (json['restarts'] as num?)?.toInt() ?? 0,
        services: [
          for (final service in (json['services'] as List?) ?? const [])
            Map<String, dynamic>.from(service as Map),
        ],
        sessionId: json['session_id'] as String?,
        lastRunAt: json['last_run_at'] == null
            ? null
            : DateTime.parse(json['last_run_at'] as String),
        lastExitCode: (json['last_exit_code'] as num?)?.toInt(),
        steps: [
          for (final step in (json['steps'] as List?) ?? const [])
            ?EnvironmentProgress.tryFromJson(step),
        ],
      );

  /// Component id.
  final String id;

  /// Component kind.
  final String kind;

  /// The wire form of an [EnvironmentComponentPhase]. Read it through
  /// [phase]; a string a newer build wrote stays readable here.
  final String state;

  /// What [state] means, or null for a value this build does not know.
  EnvironmentComponentPhase? get phase =>
      EnvironmentComponentPhase.tryParse(state);

  /// What to show.
  final String? label;

  /// One-line detail.
  final String? detail;

  /// Restarts since start.
  final int restarts;

  /// Compose or tool services: `{name, state, health, ports}`.
  final List<Map<String, dynamic>> services;

  /// The terminal session of a process or app, or the one a tool's verb is
  /// running on while the state is [EnvironmentComponentPhase.interactive].
  final String? sessionId;

  /// A task's last run.
  final DateTime? lastRunAt;

  /// A task's last exit code.
  final int? lastExitCode;

  /// The steps its tool reported during the last start, in the order they
  /// first appeared.
  final List<EnvironmentProgress> steps;

  /// This state with [state] and optional fields replaced. [clearDetail] and
  /// [clearSessionId] drop what a `null` argument would keep.
  EnvironmentComponentState copyWith({
    String? state,
    String? detail,
    bool clearDetail = false,
    int? restarts,
    List<Map<String, dynamic>>? services,
    String? sessionId,
    bool clearSessionId = false,
    DateTime? lastRunAt,
    int? lastExitCode,
    List<EnvironmentProgress>? steps,
  }) => EnvironmentComponentState(
    id: id,
    kind: kind,
    state: state ?? this.state,
    label: label,
    detail: clearDetail ? null : detail ?? this.detail,
    restarts: restarts ?? this.restarts,
    services: services ?? this.services,
    sessionId: clearSessionId ? null : sessionId ?? this.sessionId,
    lastRunAt: lastRunAt ?? this.lastRunAt,
    lastExitCode: lastExitCode ?? this.lastExitCode,
    steps: steps ?? this.steps,
  );

  /// This state with [step] recorded: in place when a step of the same
  /// [EnvironmentProgress.key] already reported, at the end otherwise.
  ///
  /// A step with no id can't report again, so nothing ever says it finished.
  /// The next step beginning says it: without ids, steps come one at a time.
  EnvironmentComponentState withStep(EnvironmentProgress step) {
    final key = step.key;
    if (key == null) {
      return this;
    }
    final known = steps.any((item) => item.key == key);
    return copyWith(
      steps: [
        for (final item in steps)
          if (item.key == key)
            step
          else if (!known &&
              item.id == null &&
              item.stepState == EnvironmentStepState.running)
            item.ended(failed: false)
          else
            item,
        if (!known) step,
      ],
    );
  }

  /// This state once the command that reported its steps has exited: a step
  /// still under way went the way the command did.
  EnvironmentComponentState withStepsEnded({required bool failed}) =>
      steps.any((step) => step.stepState == EnvironmentStepState.running)
      ? copyWith(
          steps: [
            for (final step in steps)
              step.stepState == EnvironmentStepState.running
                  ? step.ended(failed: failed)
                  : step,
          ],
        )
      : this;

  /// The step under way, the latest when a tool runs several at once.
  EnvironmentProgress? get currentStep {
    for (final step in steps.reversed) {
      if (step.stepState == EnvironmentStepState.running) {
        return step;
      }
    }
    return null;
  }

  /// Wire form.
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'state': state,
    if (label != null) 'label': label,
    if (detail != null) 'detail': detail,
    'restarts': restarts,
    if (services.isNotEmpty) 'services': services,
    if (sessionId != null) 'session_id': sessionId,
    if (lastRunAt != null) 'last_run_at': lastRunAt!.toUtc().toIso8601String(),
    if (lastExitCode != null) 'last_exit_code': lastExitCode,
    if (steps.isNotEmpty) 'steps': [for (final step in steps) step.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentComponentState &&
      other.id == id &&
      other.kind == kind &&
      other.state == state &&
      other.detail == detail &&
      other.restarts == restarts &&
      other.sessionId == sessionId &&
      other.lastRunAt == lastRunAt &&
      other.lastExitCode == lastExitCode &&
      const ListEquality<EnvironmentProgress>().equals(other.steps, steps) &&
      const DeepCollectionEquality().equals(other.services, services);

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    state,
    detail,
    restarts,
    sessionId,
    lastRunAt,
    lastExitCode,
    const ListEquality<EnvironmentProgress>().hash(steps),
    const DeepCollectionEquality().hash(services),
  );
}

/// A running (or stopped) environment of one space.
class SpaceEnvironment {
  /// Creates a [SpaceEnvironment].
  SpaceEnvironment({
    required this.id,
    required this.workspaceId,
    required this.spaceId,
    required this.definitionId,
    required this.name,
    required this.status,
    this.ports = const {},
    this.endpoints = const [],
    this.components = const [],
    this.options = const {},
    this.warnings = const [],
    this.lastError,
    this.needsRecreate = false,
    this.placement = 'host',
    this.rigId,
    required this.createdBy,
    required this.createdAt,
    required this.lastUsedAt,
  }) {
    if (id.isEmpty || workspaceId.isEmpty || spaceId.isEmpty) {
      throw ArgumentError('SpaceEnvironment needs ids');
    }
    if (definitionId.isEmpty || name.isEmpty) {
      throw ArgumentError('SpaceEnvironment needs a definition and a name');
    }
  }

  /// Parses the wire form.
  factory SpaceEnvironment.fromJson(Map<String, dynamic> json) =>
      SpaceEnvironment(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String,
        spaceId: json['space_id'] as String,
        definitionId: json['definition_id'] as String,
        name: json['name'] as String,
        status: EnvironmentStatus.fromWire(json['status'] as String?),
        ports: {
          for (final entry in ((json['ports'] as Map?) ?? const {}).entries)
            '${entry.key}': (entry.value as num).toInt(),
        },
        endpoints: [
          for (final endpoint in (json['endpoints'] as List?) ?? const [])
            ?EnvironmentEndpoint.tryFromJson(endpoint),
        ],
        components: [
          for (final component in (json['components'] as List?) ?? const [])
            EnvironmentComponentState.fromJson(
              Map<String, dynamic>.from(component as Map),
            ),
        ],
        options: json['options'] is Map
            ? Map<String, dynamic>.from(json['options'] as Map)
            : const {},
        warnings: [
          for (final warning in (json['warnings'] as List?) ?? const [])
            '$warning',
        ],
        lastError: EnvironmentError.tryFromJson(json['last_error']),
        needsRecreate: json['needs_recreate'] == true,
        placement: (json['placement'] as String?) ?? 'host',
        rigId: json['rig_id'] as String?,
        createdBy: (json['created_by'] as String?) ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        lastUsedAt: DateTime.parse(json['last_used_at'] as String),
      );

  /// Environment id, a UUID.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Owning space.
  final String spaceId;

  /// The definition it was started from.
  final String definitionId;

  /// Its name.
  final String name;

  /// Where it stands.
  final EnvironmentStatus status;

  /// Port assignments, stable for its life.
  final Map<String, int> ports;

  /// Where it can be reached.
  final List<EnvironmentEndpoint> endpoints;

  /// Component states, in start order.
  final List<EnvironmentComponentState> components;

  /// Chosen options.
  final Map<String, dynamic> options;

  /// Non-fatal notes.
  final List<String> warnings;

  /// The last failure.
  final EnvironmentError? lastError;

  /// A change needs destroy and start.
  final bool needsRecreate;

  /// `host` or `rig`.
  final String placement;

  /// The environment rig, at rig placement.
  final String? rigId;

  /// Who started it.
  final String createdBy;

  /// When it was created.
  final DateTime createdAt;

  /// When it last saw activity.
  final DateTime lastUsedAt;

  /// The component whose tool is on a terminal right now, waiting on a
  /// person, or null.
  EnvironmentComponentState? get interactiveComponent =>
      components.firstWhereOrNull(
        (component) =>
            component.phase == EnvironmentComponentPhase.interactive &&
            component.sessionId != null,
      );

  /// What a start goes through, in order: its components, without an app
  /// (someone launches those) and without a task this start has nothing for.
  Iterable<EnvironmentComponentState> get startComponents => components.where(
    (component) =>
        component.kind != 'app' &&
        component.phase != EnvironmentComponentPhase.idle,
  );

  /// The primary endpoint, or the first one.
  EnvironmentEndpoint? get primaryEndpoint =>
      endpoints.firstWhereOrNull((endpoint) => endpoint.primary) ??
      endpoints.firstOrNull;

  /// This environment with fields replaced.
  SpaceEnvironment copyWith({
    EnvironmentStatus? status,
    Map<String, int>? ports,
    List<EnvironmentEndpoint>? endpoints,
    List<EnvironmentComponentState>? components,
    Map<String, dynamic>? options,
    List<String>? warnings,
    EnvironmentError? lastError,
    bool clearLastError = false,
    bool? needsRecreate,
    String? placement,
    String? rigId,
    DateTime? lastUsedAt,
  }) => SpaceEnvironment(
    id: id,
    workspaceId: workspaceId,
    spaceId: spaceId,
    definitionId: definitionId,
    name: name,
    status: status ?? this.status,
    ports: ports ?? this.ports,
    endpoints: endpoints ?? this.endpoints,
    components: components ?? this.components,
    options: options ?? this.options,
    warnings: warnings ?? this.warnings,
    lastError: clearLastError ? null : lastError ?? this.lastError,
    needsRecreate: needsRecreate ?? this.needsRecreate,
    placement: placement ?? this.placement,
    rigId: rigId ?? this.rigId,
    createdBy: createdBy,
    createdAt: createdAt,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );

  /// Wire form.
  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'definition_id': definitionId,
    'name': name,
    'status': status.wire,
    'ports': ports,
    'endpoints': [for (final endpoint in endpoints) endpoint.toJson()],
    'components': [for (final component in components) component.toJson()],
    'options': options,
    'warnings': warnings,
    if (lastError != null) 'last_error': lastError!.toJson(),
    'needs_recreate': needsRecreate,
    'placement': placement,
    if (rigId != null) 'rig_id': rigId,
    'created_by': createdBy,
    'created_at': createdAt.toUtc().toIso8601String(),
    'last_used_at': lastUsedAt.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is SpaceEnvironment &&
      other.id == id &&
      other.workspaceId == workspaceId &&
      other.spaceId == spaceId &&
      other.definitionId == definitionId &&
      other.name == name &&
      other.status == status &&
      other.needsRecreate == needsRecreate &&
      other.placement == placement &&
      other.rigId == rigId &&
      other.lastError == lastError &&
      other.lastUsedAt == lastUsedAt &&
      const MapEquality<String, int>().equals(other.ports, ports) &&
      const ListEquality<EnvironmentEndpoint>().equals(
        other.endpoints,
        endpoints,
      ) &&
      const ListEquality<EnvironmentComponentState>().equals(
        other.components,
        components,
      ) &&
      const ListEquality<String>().equals(other.warnings, warnings);

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    spaceId,
    definitionId,
    name,
    status,
    needsRecreate,
    placement,
    rigId,
    lastError,
    lastUsedAt,
    const MapEquality<String, int>().hash(ports),
    const ListEquality<EnvironmentEndpoint>().hash(endpoints),
    const ListEquality<EnvironmentComponentState>().hash(components),
    const ListEquality<String>().hash(warnings),
  );
}
