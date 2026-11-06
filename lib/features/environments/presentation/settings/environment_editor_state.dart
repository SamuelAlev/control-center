import 'dart:convert';

import 'package:cc_data/cc_data.dart' show environmentIssuesFromMessage;
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/settings/environment_editor_seed.dart';
import 'package:control_center/features/environments/presentation/settings/environment_json_path.dart';
import 'package:control_center/features/environments/presentation/settings/environment_settings_selection.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:control_center/features/environments/presentation/settings/environment_editor_seed.dart';
export 'package:control_center/features/environments/presentation/settings/environment_json_path.dart';
export 'package:control_center/features/environments/presentation/settings/environment_settings_selection.dart';

/// The definition being edited.
@immutable
class EnvironmentEditorState {
  /// Creates an [EnvironmentEditorState].
  const EnvironmentEditorState({
    required this.draft,
    required this.saved,
    this.overrides = const {},
    this.savedOverrides = '{}',
    this.record,
    this.serverIssues = const [],
    this.saving = false,
    this.revision = 0,
    this.jsonError,
  });

  /// The JSON as edited. Forms touch only the keys they own, so anything else
  /// in here survives a save.
  final Map<String, dynamic> draft;

  /// The text the draft is compared with.
  final String saved;

  /// Workspace-side overrides of a file-linked definition. Only these are
  /// editable there: the file itself changes through its repo and approval.
  final Map<String, dynamic> overrides;

  /// The text [overrides] is compared with.
  final String savedOverrides;

  /// What the JSON view can't parse, which blocks Save until it can.
  final String? jsonError;

  /// Whether the definition is read from a repo file.
  bool get linked => record?.hasSource ?? false;

  /// The stored row, once there is one.
  final EnvironmentDefinitionRecord? record;

  /// What the server refused, by path.
  final List<EnvironmentDefinitionIssue> serverIssues;

  /// A save is in flight.
  final bool saving;

  /// Bumps when list items move, so fields keyed by index rebuild.
  final int revision;

  /// Whether there is anything to save.
  bool get dirty => linked
      ? jsonEncode(overrides) != savedOverrides
      : jsonEncode(draft) != saved;

  /// The draft as an entity, or null while it doesn't parse.
  EnvironmentDefinition? get parsed {
    try {
      return EnvironmentDefinition.fromJson(draft);
    } on FormatException {
      return null;
    }
  }

  /// Every known problem: the shape, the validator, then the server.
  ///
  /// [linkedRepoIds] are the workspace's repos, so a role bound to a repo the
  /// workspace no longer links shows as an error rather than at Start.
  List<EnvironmentDefinitionIssue> issuesFor(Set<String>? linkedRepoIds) {
    final List<EnvironmentDefinitionIssue> local;
    final effective = linked
        ? mergeEnvironmentOverrides(draft, overrides)
        : draft;
    try {
      local = validateEnvironmentDefinition(
        EnvironmentDefinition.fromJson(effective),
        linkedRepoIds: linkedRepoIds,
      );
    } on FormatException catch (error) {
      // The server refuses the same shape; once is enough.
      return [
        EnvironmentDefinitionIssue('', error.message),
        ...serverIssues.where((issue) => issue.message != error.message),
      ];
    }
    return [...local, ...serverIssues];
  }

  /// This state with fields replaced.
  EnvironmentEditorState copyWith({
    Map<String, dynamic>? draft,
    String? saved,
    Map<String, dynamic>? overrides,
    List<EnvironmentDefinitionIssue>? serverIssues,
    bool? saving,
    int? revision,
    String? jsonError,
    bool clearJsonError = false,
  }) => EnvironmentEditorState(
    draft: draft ?? this.draft,
    saved: saved ?? this.saved,
    overrides: overrides ?? this.overrides,
    savedOverrides: savedOverrides,
    record: record,
    serverIssues: serverIssues ?? this.serverIssues,
    saving: saving ?? this.saving,
    revision: revision ?? this.revision,
    jsonError: clearJsonError ? null : jsonError ?? this.jsonError,
  );
}

/// Holds one editing session.
class EnvironmentEditorNotifier extends Notifier<EnvironmentEditorState> {
  /// Creates the notifier for [seed].
  EnvironmentEditorNotifier(this.seed);

  /// What this session opened on.
  final EnvironmentEditorSeed seed;

  @override
  EnvironmentEditorState build() {
    final overrides = seed.record?.overridesJson;
    final decoded = overrides == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(overrides) as Map);
    return EnvironmentEditorState(
      draft: seed.draft,
      saved: seed.record == null ? '' : jsonEncode(seed.draft),
      overrides: decoded,
      savedOverrides: jsonEncode(decoded),
      record: seed.record,
    );
  }

  /// Sets one override of a file-linked definition.
  void setOverride(List<Object> path, Object? value) {
    state = state.copyWith(
      overrides: environmentJsonSet(state.overrides, path, value),
      serverIssues: const [],
      // The overrides JSON beside the pickers re-seeds from this.
      revision: state.revision + 1,
    );
  }

  /// Replaces every override from their JSON.
  void replaceOverrides(Map<String, dynamic> overrides) {
    state = state.copyWith(overrides: overrides, serverIssues: const []);
  }

  /// Records what the JSON view can't parse; null clears it.
  void setJsonError(String? error) {
    state = error == null
        ? state.copyWith(clearJsonError: true)
        : state.copyWith(jsonError: error);
  }

  /// Sets one value.
  void set(List<Object> path, Object? value) {
    state = state.copyWith(
      draft: environmentJsonSet(state.draft, path, value),
      serverIssues: const [],
    );
  }

  /// Replaces a list or object, moving any fields keyed by index.
  void restructure(List<Object> path, Object? value) {
    state = state.copyWith(
      draft: environmentJsonSet(state.draft, path, value),
      serverIssues: const [],
      revision: state.revision + 1,
    );
  }

  /// Replaces the whole draft from the JSON view. The view holds the text,
  /// so this keeps the revision: bumping it would rebuild the view mid-edit.
  void replace(Map<String, dynamic> draft) {
    state = state.copyWith(
      draft: draft,
      serverIssues: const [],
      clearJsonError: true,
    );
  }

  /// Drops every edit since the last save.
  void discard() {
    final saved = state.saved.isEmpty ? seed.draft : jsonDecode(state.saved);
    state = state.copyWith(
      draft: Map<String, dynamic>.from(saved as Map),
      overrides: Map<String, dynamic>.from(
        jsonDecode(state.savedOverrides) as Map,
      ),
      serverIssues: const [],
      revision: state.revision + 1,
      clearJsonError: true,
    );
  }

  /// Saves the draft and reopens the editor on what the server stored.
  /// Returns whether it stuck.
  ///
  /// A file-linked definition saves its overrides only, through
  /// `approveSource` pinned to the blob already approved: saving overrides
  /// must neither unlink the file nor approve a newer one nobody reviewed.
  Future<bool> save() async {
    if (state.jsonError != null) {
      return false;
    }
    state = state.copyWith(saving: true, serverIssues: const []);
    final repository = ref.read(environmentRepositoryProvider);
    final current = state.record;
    try {
      final record = current != null && current.hasSource
          ? await repository.approveSource(
              seed.workspaceId,
              definitionId: current.id,
              repoId: current.sourceRepoId!,
              path: current.sourcePath!,
              overrides: state.overrides,
              blobHash: current.approvedBlobHash,
            )
          : await repository.setDefinition(
              seed.workspaceId,
              state.draft,
              definitionId: current?.id,
            );
      ref.invalidate(environmentDefinitionsProvider(seed.workspaceId));
      if (ref.mounted) {
        state = state.copyWith(saving: false);
      }
      // A fresh seed from the stored row: the next session starts from what
      // the server holds, not from this session's draft.
      ref
          .read(environmentEditorSelectionProvider.notifier)
          .open(EnvironmentEditorSeed.record(record));
      return true;
    } on RemoteRpcException catch (error) {
      state = state.copyWith(
        saving: false,
        serverIssues: environmentIssuesFromMessage(error.message),
      );
      return false;
    } on Object catch (error) {
      state = state.copyWith(
        saving: false,
        serverIssues: [EnvironmentDefinitionIssue('', '$error')],
      );
      return false;
    }
  }
}

/// One editing session.
final environmentEditorProvider = NotifierProvider.autoDispose
    .family<
      EnvironmentEditorNotifier,
      EnvironmentEditorState,
      EnvironmentEditorSeed
    >(EnvironmentEditorNotifier.new);
