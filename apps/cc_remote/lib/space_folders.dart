import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cc_data/cc_data.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A personal, ordered folder in one workspace's space sidebar.
class SpaceFolder {
  SpaceFolder({
    required this.id,
    required this.name,
    required List<String> spaceIds,
  }) : spaceIds = List.unmodifiable(spaceIds);

  final String id;
  final String name;
  final List<String> spaceIds;
}

String _preferenceKey(String workspaceId) => 'space_folders.$workspaceId';

List<SpaceFolder> _decodeFolders(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final folderIds = <String>{};
    final members = <String>{};
    final folders = <SpaceFolder>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final id = item['id'];
      final name = item['name'];
      final ids = item['spaceIds'];
      if (id is! String ||
          id.isEmpty ||
          name is! String ||
          ids is! List ||
          !ids.every((member) => member is String) ||
          !folderIds.add(id)) {
        continue;
      }
      // The first folder owns a space if older data contains duplicate members.
      folders.add(
        SpaceFolder(
          id: id,
          name: name,
          spaceIds: [
            for (final member in ids.cast<String>())
              if (members.add(member)) member,
          ],
        ),
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

// UUID v4 without adding a phone-only dependency to the workspace package.
String _newFolderId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Live preferences for the signed-in user; never bound to one workspace.
final ownServerPrefsProvider = StreamProvider<Map<String, String>>((
  ref,
) async* {
  // Unlike a screen's empty placeholder stream, writes need a first snapshot
  // even if they were requested before the RPC connection appeared.
  final client = await ref.watch(rpcClientProvider.future);
  yield* RemoteIdentityRepository(client).watchOwnPrefs();
});

class _FolderState extends Notifier<List<SpaceFolder>?> {
  _FolderState(this.workspaceId);
  final String workspaceId;

  @override
  List<SpaceFolder>? build() => null;

  void update(List<SpaceFolder> folders) => state = folders;
}

final _folderStateProvider =
    NotifierProvider.family<_FolderState, List<SpaceFolder>?, String>(
      _FolderState.new,
    );

/// Personal folders for [workspaceId], independent of the active workspace.
final spaceFoldersProvider = Provider.family<List<SpaceFolder>, String>((
  ref,
  workspaceId,
) {
  // Mount the action's subscription even before the first mutation. Its state
  // ignores older own echoes while the preference stream continues to update.
  ref.watch(spaceFolderActionsProvider(workspaceId));
  final stored = ref.watch(_folderStateProvider(workspaceId));
  final prefs = ref.watch(ownServerPrefsProvider);
  return stored ?? _decodeFolders(prefs.value?[_preferenceKey(workspaceId)]);
});

/// Serializes changes for one workspace's personal preference key.
final spaceFolderActionsProvider = Provider.family<SpaceFolderActions, String>(
  SpaceFolderActions.new,
);

class SpaceFolderActions {
  SpaceFolderActions(this._ref, String workspaceId)
    : _workspaceId = workspaceId,
      _key = _preferenceKey(workspaceId) {
    _ref.listen(ownServerPrefsProvider, (previous, next) {
      final prefs = next.value;
      if (prefs != null) _acceptSnapshot(prefs);
    });
    final snapshot = _ref.read(ownServerPrefsProvider).value;
    if (snapshot != null) _folders = _decodeFolders(snapshot[_key]);
  }

  final Ref _ref;
  final String _workspaceId;
  final String _key;
  Future<void> _queued = Future<void>.value();
  List<SpaceFolder>? _folders;
  final Set<String> _ownWriteEchoes = {};
  String? _latestWrite;

  void _publish(List<SpaceFolder> folders) {
    _folders = folders;
    _ref.read(_folderStateProvider(_workspaceId).notifier).update(folders);
  }

  void _acceptSnapshot(Map<String, String> prefs) {
    final raw = prefs[_key];
    if (raw != null && _ownWriteEchoes.remove(raw)) {
      if (raw != _latestWrite) return;
    }
    _publish(_decodeFolders(raw));
  }

  Future<void> _mutate(List<SpaceFolder>? Function(List<SpaceFolder>) change) {
    final operation = _queued.then((_) async {
      if (_folders == null) {
        // A pending connection or first snapshot must never erase server data.
        final prefs = await _ref.read(ownServerPrefsProvider.future);
        if (_folders == null) _acceptSnapshot(prefs);
      }
      final updated = change(_folders!);
      if (updated == null) return;
      final raw = _encodeFolders(updated);
      final previous = _folders!;
      final previousWrite = _latestWrite;
      final draft = List<SpaceFolder>.unmodifiable(updated);
      _latestWrite = raw;
      _ownWriteEchoes.add(raw);
      _publish(draft);
      try {
        final client = await _ref.read(rpcClientProvider.future);
        await RemoteIdentityRepository(client).prefsSet(_key, raw);
      } catch (_) {
        _ownWriteEchoes.remove(raw);
        if (identical(_folders, draft)) {
          _latestWrite = previousWrite;
          _publish(previous);
        }
        rethrow;
      }
    });
    _queued = operation.then((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  /// Creates a folder and moves initial members in one preference write.
  Future<String> create(String name, {List<String> spaceIds = const []}) async {
    final id = _newFolderId();
    final members = spaceIds.toSet();
    await _mutate(
      (folders) => [
        for (final folder in folders)
          if (members.isNotEmpty && folder.spaceIds.any(members.contains))
            SpaceFolder(
              id: folder.id,
              name: folder.name,
              spaceIds: [
                for (final member in folder.spaceIds)
                  if (!members.contains(member)) member,
              ],
            )
          else
            folder,
        SpaceFolder(id: id, name: name, spaceIds: members.toList()),
      ],
    );
    return id;
  }

  /// Changes the name without changing folder order or membership.
  Future<void> rename(String folderId, String name) => _mutate((folders) {
    final index = folders.indexWhere((folder) => folder.id == folderId);
    if (index < 0 || folders[index].name == name) return null;
    final updated = [...folders];
    final folder = updated[index];
    updated[index] = SpaceFolder(
      id: folder.id,
      name: name,
      spaceIds: folder.spaceIds,
    );
    return updated;
  });

  /// Removes the personal folder, leaving its spaces intact and unfiled.
  Future<void> delete(String folderId) => _mutate((folders) {
    if (!folders.any((folder) => folder.id == folderId)) return null;
    return [
      for (final folder in folders)
        if (folder.id != folderId) folder,
    ];
  });

  /// Moves [spaceId] into [folderId], or leaves it unfiled when null.
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
      if (isTarget) ids.add(spaceId);
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
