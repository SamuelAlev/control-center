import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A space in a workspace.
typedef SpaceAccessKey = ({String workspaceId, String spaceId});

/// Whether the key's space is in the person's space list: null while
/// the list loads (or failed), else whether it is there.
///
/// The server leaves out every space the person may not read, so a space id
/// held from elsewhere (the URL, a notification, a restored layout) that the
/// list lacks may be refused — or may just be newer than the list.
final spaceListedProvider = Provider.autoDispose.family<bool?, SpaceAccessKey>(
  (ref, key) => ref.watch(
    workspaceSpacesProvider(
      key.workspaceId,
    ).select((spaces) => spaces.asData?.value.any((s) => s.id == key.spaceId)),
  ),
);

/// Why the person may not open an unlisted space: the refusal its
/// conversation subscription answers with, or null when it opens after all
/// (a space created after the list last arrived).
///
/// Read once, and only for a space the list lacks; a listed space is
/// readable by construction.
final spaceAccessRefusalProvider = FutureProvider.autoDispose
    .family<Object?, SpaceAccessKey>((ref, key) async {
      try {
        await ref
            .watch(conversationRepositoryProvider)
            .watchForSpace(workspaceId: key.workspaceId, spaceId: key.spaceId)
            .first;
        return null;
      } on StateError {
        // Closed without a frame: nothing refused it.
        return null;
      } on Object catch (error) {
        return error;
      }
    });
