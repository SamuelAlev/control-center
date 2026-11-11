part of '../cc_server_runtime.dart';

/// Opens a rig's watch lane for `/rig/stream/<id>`. The route verifies the
/// signed target, workspace membership and [RigAccess.mayView] before this
/// runs.
RigStreamResolver _rigStreamResolver(RigService rigService) =>
    ({
      required String workspaceId,
      required String rigId,
      required Map<String, dynamic> request,
    }) async {
      // `lane=audio` is the guest's sound as encoded bytes — same auth,
      // same relay-never-decode rule as the frame lane.
      if (request['lane'] == 'audio') {
        final audio = await rigService.watchAudio(
          workspaceId: workspaceId,
          rigId: rigId,
        );
        if (audio == null) {
          return null;
        }
        return (bytes: audio, contentType: 'audio/mpeg');
      }
      final stream = await rigService.watchStream(
        workspaceId: workspaceId,
        rigId: rigId,
        request: RigWatchRequest.fromJson(request),
      );
      if (stream == null) {
        return null;
      }
      return (
        bytes: stream.bytes,
        contentType: stream.negotiated.codec.contentType,
      );
    };
