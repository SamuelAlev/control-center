import 'dart:convert';

import 'package:cc_rpc/src/channel/frame_codec.dart';
import 'package:test/test.dart';

/// Unit tests for the cross-platform frame decoder — the small-frame inline
/// fast path and the large-frame offload path share one `jsonDecode`, exercised
/// at both sides of the isolate threshold.
void main() {
  group('decodeJsonFrame', () {
    test('a small frame decodes inline below the isolate threshold', () async {
      final data = jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'repo/call',
      });
      expect(data.length, lessThan(kIsolateDecodeThresholdChars));

      final frame = await decodeJsonFrame(data);

      expect(frame['jsonrpc'], '2.0');
      expect(frame['id'], 1);
      expect(frame['method'], 'repo/call');
    });

    test(
      'a large frame decodes off the isolate at/above the threshold',
      () async {
        // Build a frame whose serialized form blows well past the 50 KB isolate
        // threshold so it routes through IsolateManager.run on the VM.
        final blob = 'x' * (kIsolateDecodeThresholdChars + 4096);
        final data = jsonEncode({'jsonrpc': '2.0', 'id': 2, 'blob': blob});

        final frame = await decodeJsonFrame(data);

        expect(frame['id'], 2);
        expect(frame['blob'], hasLength(blob.length));
      },
    );
  });
}
