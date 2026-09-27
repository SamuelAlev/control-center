import 'dart:async';
import 'dart:convert';

import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// One user's ordered collection of spaces in a workspace sidebar.
class SpaceFolder {
  /// Creates a folder with a stable id and immutable membership.
  SpaceFolder({
    required this.id,
    required this.name,
    required List<String> spaceIds,
  }) : spaceIds = List.unmodifiable(spaceIds);

  /// Stable identifier for this user's folder.
  final String id;

  /// Display name.
  final String name;

  /// Ordered member space identifiers.
  final List<String> spaceIds;
}

String _preferenceKey(String workspaceId) => 'space_folders.$workspaceId';

List<SpaceFolder> _decodeFolders(String? raw) {
  if (raw == null) {
    return const [];
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    final folderIds = <String>{};
    final folders = <SpaceFolder>[];
    for (final item in decoded) {
      if (item is! Map) {
        continue;
      }
      final id = item['id'];
      final name = item['name'];
      final spaceIds = item['spaceIds'];
      if (id is! String ||
          id.isEmpty ||
          name is! String ||
          spaceIds is! List ||
          !spaceIds.every((spaceId) => spaceId is String) ||
          !folderIds.add(id)) {
        continue;
      }
      folders.add(
        SpaceFolder(id: id, name: name, spaceIds: spaceIds.cast<String>()),
      );
    }
    return List.unmodifiable(folders);
  } on FormatException {
    return const [];
  }
}

String _encodeFolders(List<SpaceFolder> folders) => jsonEncode([
  for (final folder in folders)
    {'id': folder.id, 'name': folder.name, 'spaceIds': folder.spaceIds},
]);

/// Live personal folder order and membership for exactly one workspace.
final spaceFoldersProvider = Provider.family<List<SpaceFolder>, String>((
  ref,
  workspaceId,
) {
  final raw = ref.watch(
    ownServerPrefsProvider.select(
      (prefs) => prefs.value?[_preferenceKey(workspaceId)],
    ),
  );
  return _decodeFolders(raw);
});

/// Serialized writes to one workspace's personal folder preference.
final spaceFolderActionsProvider = Provider.family<SpaceFolderActions, String>(
  SpaceFolderActions.new,
);

/// Archives the space, then removes its personal sidebar folder membership.
/// Read both dependencies before the archive stream unmounts the space row.
Future<void> archiveSpaceAndUnlink(
  WidgetRef ref,
  String workspaceId,
  String spaceId,
) async {
  final service = ref.read(messagingServiceProvider);
  final folders = ref.read(spaceFolderActionsProvider(workspaceId));
  await service.archiveSpace(workspaceId, spaceId);
  await folders.move(spaceId, null);
}

/// Mutations of a user's own folder preference; no workspace-shared data changes.
class SpaceFolderActions {
  /// Binds mutations to the caller's personal preference for one workspace.
  SpaceFolderActions(this._ref, String workspaceId)
    : _key = _preferenceKey(workspaceId) {
    _ref.listen(ownServerPrefsProvider, (previous, next) {
      final prefs = next.value;
      if (prefs == null) {
        return;
      }
      final raw = prefs[_key];
      // A delayed echo of an older write must not undo a newer queued edit.
      if (raw != null && _ownWriteEchoes.remove(raw) && raw != _latestWrite) {
        return;
      }
      _folders = _decodeFolders(raw);
    });
  }

  final Ref _ref;
  final String _key;
  Future<void> _queued = Future<void>.value();
  List<SpaceFolder>? _folders;
  final Set<String> _ownWriteEchoes = {};
  String? _latestWrite;

  Future<void> _mutate(List<SpaceFolder>? Function(List<SpaceFolder>) change) {
    final operation = _queued.then((_) async {
      // Wait for the initial server snapshot rather than overwriting existing
      // folders with an empty list while preferences are still loading.
      if (_folders == null) {
        final server = await _ref.read(ownServerPrefsProvider.future);
        _folders ??= _decodeFolders(server[_key]);
      }
      final updated = change(_folders!);
      if (updated == null) {
        return;
      }
      final raw = _encodeFolders(updated);
      final previous = _folders;
      final previousWrite = _latestWrite;
      final draft = List<SpaceFolder>.unmodifiable(updated);
      _folders = draft;
      _latestWrite = raw;
      _ownWriteEchoes.add(raw);
      try {
        await _ref.read(identityRepositoryProvider).prefsSet(_key, raw);
      } catch (_) {
        _ownWriteEchoes.remove(raw);
        if (identical(_folders, draft)) {
          _folders = previous;
          _latestWrite = previousWrite;
        }
        rethrow;
      }
    });
    // An unsuccessful write must not poison later edits in this workspace.
    _queued = operation.then((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  /// Creates a folder, optionally moving [spaceIds] into it in one write.
  /// Existing memberships are removed before the new folder is published.
  Future<String> create(String name, {List<String> spaceIds = const []}) async {
    final id = const Uuid().v4();
    final members = spaceIds.isEmpty ? const <String>{} : spaceIds.toSet();
    await _mutate(
      (folders) => [
        for (final folder in folders)
          if (members.isNotEmpty && folder.spaceIds.any(members.contains))
            SpaceFolder(
              id: folder.id,
              name: folder.name,
              spaceIds: [
                for (final spaceId in folder.spaceIds)
                  if (!members.contains(spaceId)) spaceId,
              ],
            )
          else
            folder,
        SpaceFolder(
          id: id,
          name: name,
          spaceIds: members.isEmpty ? const [] : members.toList(),
        ),
      ],
    );
    return id;
  }

  /// Changes a folder's name without changing its position or spaces.
  Future<void> rename(String folderId, String name) => _mutate((folders) {
    final index = folders.indexWhere((folder) => folder.id == folderId);
    if (index < 0 || folders[index].name == name) {
      return null;
    }
    final updated = [...folders];
    final folder = updated[index];
    updated[index] = SpaceFolder(
      id: folder.id,
      name: name,
      spaceIds: folder.spaceIds,
    );
    return updated;
  });

  /// Deletes the folder, leaving its spaces unfiled.
  Future<void> delete(String folderId) => _mutate((folders) {
    if (!folders.any((folder) => folder.id == folderId)) {
      return null;
    }
    return [
      for (final folder in folders)
        if (folder.id != folderId) folder,
    ];
  });

  /// Moves a space into [folderId], or removes it from folders when null.
  Future<void> move(String spaceId, String? folderId) => _mutate((folders) {
    if (folderId != null && !folders.any((folder) => folder.id == folderId)) {
      return null;
    }
    final updated = <SpaceFolder>[];
    var changed = false;
    for (final folder in folders) {
      final ids = [
        for (final id in folder.spaceIds)
          if (id != spaceId) id,
      ];
      final isTarget = folder.id == folderId;
      if (isTarget) {
        ids.add(spaceId);
      }
      final folderChanged =
          ids.length != folder.spaceIds.length ||
          (isTarget && !folder.spaceIds.contains(spaceId));
      changed = changed || folderChanged;
      updated.add(
        folderChanged
            ? SpaceFolder(id: folder.id, name: folder.name, spaceIds: ids)
            : folder,
      );
    }
    return changed ? updated : null;
  });
}
