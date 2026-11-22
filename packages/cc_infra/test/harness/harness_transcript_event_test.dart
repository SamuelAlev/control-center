import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/harness/harness_run_factory.dart';
import 'package:test/test.dart';

Future<List<ToolImageRef>> _noImages(
  String toolName,
  HarnessToolResult result,
) async => const [];

void main() {
  test('a nested call start carries its parent call id', () async {
    final event = await harnessTranscriptEvent(
      const LoopToolCallStart(
        toolName: 'read',
        toolUseId: 'r/1',
        args: {'path': 'a.dart'},
        parentToolUseId: 'r',
      ),
      imageRefs: _noImages,
    );

    final call = event! as ToolCallEvent;
    expect(call.toolCallId, 'r/1');
    expect(call.parentToolCallId, 'r');
    expect(call.metadata['parentToolCallId'], 'r');
  });

  test('a nested call result carries its parent call id', () async {
    final event = await harnessTranscriptEvent(
      LoopToolCallResult(
        toolName: 'read',
        toolUseId: 'r/1',
        result: HarnessToolResult.success('body'),
        parentToolUseId: 'r',
      ),
      imageRefs: _noImages,
    );

    final result = event! as ToolResultEvent;
    expect(result.toolCallId, 'r/1');
    expect(result.parentToolCallId, 'r');
  });

  test('a nested call result stores no images', () async {
    var stored = 0;
    final event = await harnessTranscriptEvent(
      LoopToolCallResult(
        toolName: 'screenshot',
        toolUseId: 'r/1',
        result: HarnessToolResult.success('shot'),
        parentToolUseId: 'r',
      ),
      imageRefs: (_, _) async {
        stored++;
        return const [ToolImageRef(ref: 'blob:sha256:00')];
      },
    );

    expect((event! as ToolResultEvent).images, isEmpty);
    expect(stored, 0);
  });

  test('a call the model made has no parent', () async {
    final start = await harnessTranscriptEvent(
      const LoopToolCallStart(toolName: 'read', toolUseId: 'c1', args: {}),
      imageRefs: _noImages,
    );
    final result = await harnessTranscriptEvent(
      LoopToolCallResult(
        toolName: 'read',
        toolUseId: 'c1',
        result: HarnessToolResult.success('body'),
      ),
      imageRefs: _noImages,
    );

    expect((start! as ToolCallEvent).parentToolCallId, isNull);
    expect(
      (start as ToolCallEvent).metadata.containsKey('parentToolCallId'),
      isFalse,
    );
    expect((result! as ToolResultEvent).parentToolCallId, isNull);
  });
}
