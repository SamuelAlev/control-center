import 'package:cc_data/cc_data.dart' show RemoteMessagingRepository;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which space's preparation log to read.
typedef SpaceProvisioningLogKey = ({String workspaceId, String spaceId});

/// Lines kept client-side. The server's own bound is what limits a replay.
const int kSpaceProvisioningLogLines = 5000;

/// What a space's workspace preparation printed, then each line as it arrives.
///
/// Subscribing only attaches. A repeated `seq` is a line rewriting itself, so
/// it replaces the last one, and anything older is a reconnect's replay of
/// lines already shown.
final spaceProvisioningLogLinesProvider = StreamProvider.autoDispose
    .family<List<String>, SpaceProvisioningLogKey>((ref, key) async* {
      final lines = <String>[];
      int? lastSeq;
      yield const [];
      final stream = RemoteMessagingRepository(
        ref.watch(rpcClientProvider),
      ).watchSpaceProvisioningLog(key.workspaceId, key.spaceId);
      await for (final line in stream) {
        final seen = lastSeq;
        if (seen != null && line.seq < seen) {
          continue;
        }
        if (line.seq == seen && lines.isNotEmpty) {
          lines.last = line.text;
        } else {
          lines.add(line.text);
        }
        lastSeq = line.seq;
        if (lines.length > kSpaceProvisioningLogLines) {
          lines.removeRange(0, lines.length - kSpaceProvisioningLogLines);
        }
        yield List<String>.unmodifiable(lines);
      }
    });
