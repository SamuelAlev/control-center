import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_template.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/util/command_redaction.dart';

/// What a `cli` operation needs to know about its environment.
class CliContext {
  /// Creates a [CliContext].
  const CliContext({
    required this.component,
    required this.values,
    required this.workingDirectory,
    this.environment = const {},
    this.routingDomain,
  });

  /// The component.
  final CliEnvironmentComponent component;

  /// The placeholder table.
  final EnvironmentValues values;

  /// Where verbs run.
  final String workingDirectory;

  /// Their variables.
  final Map<String, String> environment;

  /// `routing.domain`: the only hostnames a tool may report besides loopback.
  final String? routingDomain;
}

/// Runs a tool that owns its own lifecycle, through the verbs a definition maps.
///
/// Failures throw [EnvironmentDriverException]. [status] is the exception: it
/// is a read, so a failure comes back as a report the caller can show.
class CliDriver {
  /// Creates a [CliDriver].
  CliDriver({
    EnvironmentCommandRunner? runner,
    this.pollInterval = const Duration(seconds: 2),
    this.defaultVerbTimeout = const Duration(minutes: 5),
    this.defaultStatusTimeout = const Duration(seconds: 30),
  }) : _runner = runner ?? EnvironmentCommandRunner();

  final EnvironmentCommandRunner _runner;

  /// Between status reads while waiting for readiness.
  final Duration pollInterval;

  /// A verb's ceiling unless `timeouts` names one.
  final Duration defaultVerbTimeout;

  /// The `status` verb's ceiling unless `timeouts` names one.
  final Duration defaultStatusTimeout;

  /// What the tool says about this environment, with endpoints outside the
  /// declared domain dropped.
  Future<EnvironmentStatusReport> status(CliContext context) async {
    final result = await _run(context, 'status');
    if (!result.succeeded) {
      final error = _failureOf(result);
      final missing =
          context.component.statusMap?.missingErrorCodes.contains(error.code) ??
          false;
      return EnvironmentStatusReport(
        state: missing
            ? EnvironmentReportedState.missing
            : EnvironmentReportedState.failed,
        detail: error.message,
        error: missing ? null : error,
      );
    }
    return _withAllowedEndpoints(
      context,
      _parseReport(context, result.rawStdout),
    );
  }

  /// Brings the environment up and polls until it is ready.
  ///
  /// Status picks the verb: `create` when the tool has no such environment,
  /// `start` when it has a stopped or failed one, nothing when it is already
  /// on its way. Returns the ready report.
  Future<EnvironmentStatusReport> up(
    CliContext context, {
    void Function(EnvironmentCommandEvent event)? onEvent,
  }) async {
    final report = await status(context);
    _throwIfActionable(report);
    switch (report.state) {
      case EnvironmentReportedState.ready:
        return report;
      case EnvironmentReportedState.starting:
        break;
      case EnvironmentReportedState.missing:
        await _verb(context, 'create', onEvent: onEvent);
      case EnvironmentReportedState.stopped:
      case EnvironmentReportedState.failed:
        if (!context.component.verbs.containsKey('start')) {
          if (report.state == EnvironmentReportedState.failed) {
            throw _reportFailure(report);
          }
          await _verb(context, 'create', onEvent: onEvent);
          break;
        }
        await _verb(context, 'start', onEvent: onEvent);
      case EnvironmentReportedState.degraded:
        throw _reportFailure(report);
    }
    return waitReady(context);
  }

  /// Polls `status` until ready, failed, or `readyTimeout`.
  ///
  /// `stopped`, `missing` and unreadable reports don't end the wait: a tool
  /// that returned from `create --no-wait` has every right to say so for a
  /// while. A read that needs a person does, because more polling won't help.
  Future<EnvironmentStatusReport> waitReady(CliContext context) async {
    final limit = Duration(seconds: context.component.readyTimeoutSeconds);
    final deadline = DateTime.now().add(limit);
    while (true) {
      final report = await status(context);
      _throwIfActionable(report);
      switch (report.state) {
        case EnvironmentReportedState.ready:
          return report;
        case EnvironmentReportedState.failed:
          throw _reportFailure(report);
        case EnvironmentReportedState.starting:
        case EnvironmentReportedState.stopped:
        case EnvironmentReportedState.missing:
        case EnvironmentReportedState.degraded:
          break;
      }
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        final detail = report.detail;
        throw EnvironmentDriverException(
          EnvironmentError(
            code: 'ready-timeout',
            message:
                'Not ready after ${limit.inSeconds} s'
                '${detail == null || detail.isEmpty ? '' : ': $detail'}',
          ),
        );
      }
      await Future<void>.delayed(
        remaining < pollInterval ? remaining : pollInterval,
      );
    }
  }

  /// The `stop` verb.
  Future<void> stop(
    CliContext context, {
    void Function(EnvironmentCommandEvent event)? onEvent,
  }) => _verb(context, 'stop', onEvent: onEvent);

  /// The `reset` verb.
  Future<void> reset(
    CliContext context, {
    void Function(EnvironmentCommandEvent event)? onEvent,
  }) => _verb(context, 'reset', onEvent: onEvent);

  /// The `destroy` verb. An environment the tool has already lost counts as
  /// destroyed.
  Future<void> destroy(
    CliContext context, {
    void Function(EnvironmentCommandEvent event)? onEvent,
  }) async {
    final result = await _run(context, 'destroy', onEvent: onEvent);
    if (result.succeeded) {
      return;
    }
    final error = _failureOf(result);
    final missing =
        context.component.statusMap?.missingErrorCodes.contains(error.code) ??
        false;
    if (!missing) {
      throw EnvironmentDriverException(error);
    }
  }

  /// The names the tool knows, from the `list` verb.
  Future<List<String>> list(CliContext context) async {
    final result = await _run(context, 'list');
    if (!result.succeeded) {
      throw EnvironmentDriverException(_failureOf(result));
    }
    final Object? json;
    try {
      json = jsonDecode(result.rawStdout);
    } on FormatException {
      return const [];
    }
    final map = context.component.statusMap;
    if (map != null) {
      return map.names(json);
    }
    return [
      if (json is List)
        for (final item in json)
          if (item is String)
            item
          else if (item is Map && item['name'] is String)
            item['name'] as String,
    ];
  }

  /// The last [tail] lines from the `logs` verb.
  Future<String> logs(
    CliContext context, {
    String? service,
    int tail = 200,
  }) async {
    final result = await _run(
      context,
      'logs',
      extra: _logValues(service: service, tail: tail, follow: false),
    );
    if (!result.succeeded) {
      throw EnvironmentDriverException(_failureOf(result));
    }
    return result.stdout;
  }

  /// Follows the `logs` verb until the subscription is cancelled.
  Stream<String> followLogs(
    CliContext context, {
    String? service,
    int tail = 200,
  }) {
    EnvironmentCommandHandle? handle;
    late final StreamController<String> controller;
    controller = StreamController<String>(
      onListen: () {
        final started = _runner.start(
          _command(context, 'logs'),
          values: context.values.withAll(
            _logValues(service: service, tail: tail, follow: true),
          ),
          workingDirectory: context.workingDirectory,
          environment: context.environment,
        );
        handle = started;
        started.events.listen((event) {
          if (event is EnvironmentCommandOutput && !event.isStderr) {
            controller.add(event.line);
          }
        });
        unawaited(started.result.whenComplete(controller.close));
      },
      onCancel: () => handle?.cancel(),
    );
    return controller.stream;
  }

  /// The `exec` verb. `{command}` is one argument, because that is what a
  /// tool's own `exec` takes, so [command] is joined for a shell to read.
  Future<EnvironmentExecResult> exec(
    CliContext context, {
    required String service,
    required List<String> command,
  }) async {
    final result = await _run(
      context,
      'exec',
      extra: {'service': service, 'command': environmentCommandLine(command)},
    );
    return EnvironmentExecResult(
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr,
    );
  }

  Map<String, String> _logValues({
    required String? service,
    required int tail,
    required bool follow,
  }) => {'service': ?service, 'tail': '$tail', if (follow) 'follow': 'true'};

  Future<void> _verb(
    CliContext context,
    String verb, {
    void Function(EnvironmentCommandEvent event)? onEvent,
  }) async {
    final result = await _run(context, verb, onEvent: onEvent);
    if (!result.succeeded) {
      throw EnvironmentDriverException(_failureOf(result));
    }
  }

  Future<EnvironmentCommandResult> _run(
    CliContext context,
    String verb, {
    Map<String, String> extra = const {},
    void Function(EnvironmentCommandEvent event)? onEvent,
  }) => _runner.run(
    _command(context, verb),
    values: context.values.withAll(extra),
    workingDirectory: context.workingDirectory,
    environment: context.environment,
    timeout: _timeoutFor(context, verb),
    onEvent: onEvent,
  );

  EnvironmentCommand _command(CliContext context, String verb) {
    final command = context.component.verbs[verb];
    if (command == null) {
      throw EnvironmentDriverException(
        EnvironmentError(
          code: 'verb-missing',
          message: '${context.component.displayName} has no $verb verb',
        ),
      );
    }
    return command;
  }

  Duration _timeoutFor(CliContext context, String verb) {
    final seconds = context.component.timeouts[verb];
    if (seconds != null) {
      return Duration(seconds: seconds);
    }
    return verb == 'status' ? defaultStatusTimeout : defaultVerbTimeout;
  }

  EnvironmentStatusReport _parseReport(CliContext context, String stdout) {
    final map = context.component.statusMap;
    if (map == null) {
      final report = EnvironmentStatusReport.parse(stdout);
      // Unparsed output becomes the detail, which is shown: redact that.
      return report.state == EnvironmentReportedState.degraded
          ? EnvironmentStatusReport(
              state: report.state,
              detail: redactSecrets(report.detail ?? ''),
            )
          : report;
    }
    final Object? json;
    try {
      json = jsonDecode(stdout);
    } on FormatException {
      return EnvironmentStatusReport(
        state: EnvironmentReportedState.degraded,
        detail: redactSecrets(stdout.trim()),
      );
    }
    return map.evaluate(json);
  }

  EnvironmentStatusReport _withAllowedEndpoints(
    CliContext context,
    EnvironmentStatusReport report,
  ) {
    final domain = context.routingDomain;
    final allowed = <EnvironmentEndpoint>[];
    for (final endpoint in report.endpoints) {
      if (endpoint.isAllowedFor(domain)) {
        allowed.add(endpoint);
      } else {
        CcInfraLog.warning(
          'dropped endpoint ${endpoint.role} (${endpoint.url}) from '
          '${context.component.displayName}: outside ${domain ?? 'loopback'}',
        );
      }
    }
    if (allowed.length == report.endpoints.length) {
      return report;
    }
    return EnvironmentStatusReport(
      state: report.state,
      detail: report.detail,
      endpoints: allowed,
      services: report.services,
      warnings: report.warnings,
      needsRecreate: report.needsRecreate,
      error: report.error,
    );
  }

  EnvironmentError _failureOf(EnvironmentCommandResult result) =>
      result.error ??
      EnvironmentError(
        code: 'command-failed',
        message: '`${result.display}` exited ${result.exitCode}',
        exitCode: result.exitCode,
      );

  void _throwIfActionable(EnvironmentStatusReport report) {
    final error = report.error;
    final exitCode = error?.exitCode;
    if (error != null && exitCode != null && exitCode >= 3 && exitCode <= 5) {
      throw EnvironmentDriverException(error);
    }
  }

  EnvironmentDriverException _reportFailure(EnvironmentStatusReport report) =>
      EnvironmentDriverException(
        report.error ??
            EnvironmentError(
              code: report.state == EnvironmentReportedState.degraded
                  ? 'status-unreadable'
                  : 'failed',
              // The rule's words lead; the raw fields are only a hint.
              message:
                  report.message ??
                  report.detail ??
                  'The tool reports a failure',
              hint: report.message == null ? null : report.detail,
            ),
      );
}
