import 'package:cc_data/cc_data.dart' show EnvironmentSourceUpdate;
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:collection/collection.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/settings/providers/server_connection_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One space, named by its workspace: a space id alone never picks a database.
typedef EnvironmentSpaceKey = ({String workspaceId, String spaceId});

/// One definition in a workspace.
typedef EnvironmentDefinitionKey = ({String workspaceId, String definitionId});

/// One process or service's output.
typedef EnvironmentLogKey = ({
  String workspaceId,
  String spaceId,
  String target,
});

/// How many log lines a tab keeps. The server's ring holds the rest.
const int kEnvironmentLogLines = 5000;

/// The parsed definition of [record], or null for a row this client can't
/// read. A definition from a newer build must not take the sidebar down.
EnvironmentDefinition? environmentDefinitionOf(
  EnvironmentDefinitionRecord record,
) {
  try {
    return record.definition;
  } on FormatException {
    return null;
  }
}

/// Whether [record] has anything to start. Without a stack there is no Start.
bool environmentHasStack(EnvironmentDefinitionRecord record) =>
    environmentDefinitionOf(record)?.hasStack ?? false;

/// The connected server predates environments.
///
/// Surfaces show one plain notice for this instead of the raw `opUnknown`.
class EnvironmentsUnsupported implements Exception {
  /// Creates an [EnvironmentsUnsupported].
  const EnvironmentsUnsupported();

  @override
  String toString() => 'This server does not support environments';
}

/// [error] as [EnvironmentsUnsupported] when it is an `opUnknown`, else as is.
Object environmentError(Object error) =>
    error is RemoteRpcException && error.code == RpcErrorCodes.opUnknown
    ? const EnvironmentsUnsupported()
    : error;

/// Forwards [stream], turning a missing op into [EnvironmentsUnsupported].
///
/// `yield*` forwards a stream's error as an error event, which no `try` around
/// it sees; awaiting each event is what lets one be caught and translated.
Stream<T> _translated<T>(Stream<T> stream) async* {
  try {
    await for (final event in stream) {
      yield event;
    }
  } on Object catch (error) {
    final translated = environmentError(error);
    if (identical(translated, error)) {
      rethrow;
    }
    throw translated;
  }
}

/// Runs [body], turning a missing op into [EnvironmentsUnsupported].
Future<T> _translatedCall<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on Object catch (error) {
    final translated = environmentError(error);
    if (identical(translated, error)) {
      rethrow;
    }
    throw translated;
  }
}

/// Whether environment endpoints live on a machine this client isn't.
///
/// Loopback and `*.localhost` URLs resolve on the server host only, so a
/// remote client labels them and offers the Browser (VM) instead.
final environmentEndpointsAreRemoteProvider = Provider<bool>((ref) {
  if (kIsWeb) {
    return true;
  }
  return ref.watch(serverListProvider).mode == ServerConnectionMode.remote;
});

/// The environments of one space, live. Empty in a demo, which has no
/// execution surface.
final spaceEnvironmentsProvider = StreamProvider.autoDispose
    .family<List<SpaceEnvironment>, EnvironmentSpaceKey>((ref, key) async* {
      if (ref.watch(isDemoServerProvider) || key.spaceId.isEmpty) {
        yield const [];
        return;
      }
      yield* _translated(
        ref
            .watch(environmentRepositoryProvider)
            .watch(key.workspaceId, key.spaceId),
      );
    });

/// The environment a space runs, or null. Every `environment.` op derives it
/// from the space, so there is one to act on.
final spaceEnvironmentProvider = Provider.autoDispose
    .family<SpaceEnvironment?, EnvironmentSpaceKey>((ref, key) {
      final environments = ref.watch(spaceEnvironmentsProvider(key)).value;
      return environments?.firstWhereOrNull(
        (environment) => environment.status != EnvironmentStatus.gone,
      );
    });

/// Recent runs of a space, live. Feeds the step list and task rows.
final spaceEnvironmentRunsProvider = StreamProvider.autoDispose
    .family<List<EnvironmentRun>, EnvironmentSpaceKey>((ref, key) async* {
      if (ref.watch(isDemoServerProvider) || key.spaceId.isEmpty) {
        yield const [];
        return;
      }
      yield* _translated(
        ref
            .watch(environmentRepositoryProvider)
            .watchRuns(key.workspaceId, key.spaceId),
      );
    });

/// The definitions a space can start.
final eligibleDefinitionsProvider = FutureProvider.autoDispose
    .family<List<EnvironmentDefinitionRecord>, EnvironmentSpaceKey>((
      ref,
      key,
    ) async {
      if (ref.watch(isDemoServerProvider) || key.spaceId.isEmpty) {
        return const [];
      }
      final repository = ref.watch(environmentRepositoryProvider);
      return _translatedCall(
        () => repository.eligible(key.workspaceId, key.spaceId),
      );
    });

/// Every definition in a workspace.
final environmentDefinitionsProvider = FutureProvider.autoDispose
    .family<List<EnvironmentDefinitionRecord>, String>((
      ref,
      workspaceId,
    ) async {
      if (ref.watch(isDemoServerProvider)) {
        return const [];
      }
      final repository = ref.watch(environmentRepositoryProvider);
      return _translatedCall(() => repository.listDefinitions(workspaceId));
    });

/// The definition an environment was started from, or null until it loads.
final environmentDefinitionRecordProvider = Provider.autoDispose
    .family<EnvironmentDefinitionRecord?, EnvironmentDefinitionKey>((ref, key) {
      final all = ref
          .watch(environmentDefinitionsProvider(key.workspaceId))
          .value;
      return all?.firstWhereOrNull((record) => record.id == key.definitionId);
    });

/// A definition's host-readiness rows.
final environmentChecksProvider = FutureProvider.autoDispose
    .family<List<EnvironmentCheckResult>, EnvironmentDefinitionKey>(
      (ref, key) => ref
          .watch(environmentRepositoryProvider)
          .check(key.workspaceId, key.definitionId),
    );

/// What a linked definition's file holds now.
final environmentSourceUpdateProvider = FutureProvider.autoDispose
    .family<EnvironmentSourceUpdate?, EnvironmentDefinitionKey>(
      (ref, key) => ref
          .watch(environmentRepositoryProvider)
          .sourceUpdate(key.workspaceId, key.definitionId),
    );

/// A definition's recent runs, polled while something watches.
///
/// There is no subscription here: a test runs on a throwaway clone, so no space
/// exists to watch.
final environmentDefinitionRunsProvider = StreamProvider.autoDispose
    .family<List<EnvironmentRun>, EnvironmentDefinitionKey>((ref, key) async* {
      final repository = ref.watch(environmentRepositoryProvider);
      while (true) {
        yield await repository.listRuns(key.workspaceId, key.definitionId);
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    });

/// What a definition still holds across the workspace, kept fresh while
/// someone is looking: other people's spaces change without a push here.
final environmentInstancesProvider = StreamProvider.autoDispose
    .family<List<EnvironmentInstance>, EnvironmentDefinitionKey>((
      ref,
      key,
    ) async* {
      final repository = ref.watch(environmentRepositoryProvider);
      while (true) {
        yield await repository.listInstances(
          key.workspaceId,
          key.definitionId,
        );
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    });

/// One target's output so far, bounded to [kEnvironmentLogLines].
///
/// Subscribing attaches to what is already running. A restored tab lands here
/// and nothing else, so it can never start anything. Lines the server numbered
/// are kept once: a reconnect replays the tail, and anything at or below the
/// highest number already shown is a repeat.
final environmentLogLinesProvider = StreamProvider.autoDispose
    .family<List<String>, EnvironmentLogKey>((ref, key) async* {
      final lines = <String>[];
      int? lastSeq;
      yield const [];
      final stream = ref
          .watch(environmentRepositoryProvider)
          .watchLogs(key.workspaceId, key.spaceId, target: key.target);
      await for (final event in _translated(stream)) {
        final seq = event.seq;
        if (seq != null) {
          if (lastSeq != null && seq <= lastSeq) {
            continue;
          }
          lastSeq = seq;
        }
        lines.add(event.line);
        if (lines.length > kEnvironmentLogLines) {
          lines.removeRange(0, lines.length - kEnvironmentLogLines);
        }
        yield List<String>.unmodifiable(lines);
      }
    });
