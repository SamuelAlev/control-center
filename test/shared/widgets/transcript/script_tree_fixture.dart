import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';

/// A script with each shape the tree draws: a plain call, a parallel group
/// of five, a loop of twelve with two calls per iteration and a branch.
const String sampleScript = '''
const hits = await tools.search({ pattern: "TODO" });
const docs = await Promise.all([
  tools.read({ path: "README.md" }),
  tools.read({ path: "ARCH.md" }),
  tools.read({ path: "SECURITY.md" }),
  tools.read({ path: "DESIGN.md" }),
  tools.read({ path: "PRODUCT.md" }),
]);
for (const file of hits.files) {
  const text = await tools.read({ path: file });
  await tools.grep({ pattern: "FIXME", path: file });
}
if (hits.files.length > 0) {
  await tools.edit({ path: "TODO.md", old: "", new: hits.summary });
} else {
  await tools.write({ path: "TODO.md", content: "Nothing to do" });
}
return docs.length;''';

/// A loop whose body branches, for the arm caption.
const String branchInLoopScript = '''
for (const f of files) {
  if (f.big) {
    await tools.read({ path: f.path });
  } else {
    await tools.grep({ pattern: "x", path: f.path });
  }
}''';

final DateTime _ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

/// Where `tools.<tool>(` is called on its [nth] line (0-based) of [source]:
/// the column of the tool's name, the point the runner reports.
ScriptCallSite siteOf(String source, String tool, {int nth = 0}) {
  final lines = source.split('\n');
  var seen = 0;
  for (var i = 0; i < lines.length; i++) {
    final at = lines[i].indexOf('tools.$tool(');
    if (at < 0) {
      continue;
    }
    if (seen++ == nth) {
      return ScriptCallSite(i + 1, at + 7);
    }
  }
  throw ArgumentError('no call to $tool #$nth');
}

/// The `repl` call that ran [code].
ToolSegment replSegment({
  String code = sampleScript,
  ToolSegmentStatus status = ToolSegmentStatus.running,
  String description = 'Tidy the TODO list',
}) => ToolSegment(
  toolName: 'repl',
  toolCallId: 'r1',
  inputs: {'code': code, 'description': description},
  outputs: status == ToolSegmentStatus.running ? '' : 'Script completed',
  status: status,
  startedAt: _ts,
  durationMs: status == ToolSegmentStatus.running ? null : 8200,
);

/// A call the script made at the [nth] place `tools.<tool>(` appears.
ToolSegment nestedCall(
  String tool,
  int index, {
  String source = sampleScript,
  int nth = 0,
  Map<String, Object?> inputs = const {},
  ToolSegmentStatus status = ToolSegmentStatus.ok,
  String? outcome,
  bool placed = true,
}) => ToolSegment(
  toolName: tool,
  toolCallId: 'r1/$index',
  inputs: inputs,
  outputs: status == ToolSegmentStatus.error
      ? (outcome == 'denied' ? 'User denied: not now' : 'exit 2')
      : 'ok',
  status: status,
  startedAt: _ts,
  durationMs: status == ToolSegmentStatus.running ? null : 40 + index,
  parentToolCallId: 'r1',
  outcome: outcome,
  callSite: placed ? siteOf(source, tool, nth: nth) : null,
);

/// The read paths the parallel group and the loop name.
const List<String> sampleDocs = [
  'README.md',
  'ARCH.md',
  'SECURITY.md',
  'DESIGN.md',
  'PRODUCT.md',
];

/// The calls [sampleScript] has made at one moment.
///
/// [searchDone]: the first call finished. [docsDone]: how many of the five
/// parallel reads finished (the rest run). [iterations]: loop iterations
/// begun; the last one's second call runs unless [loopDone]. [branch]: the
/// `if` arm's edit was made. [failedIteration] and [deniedEdit] make one grep
/// fail and the edit be denied.
List<ToolSegment> sampleCalls({
  bool searchDone = true,
  int docsDone = 5,
  int iterations = 12,
  bool loopDone = true,
  bool branch = true,
  int? failedIteration,
  bool deniedEdit = false,
}) {
  final out = <ToolSegment>[];
  var index = 0;
  out.add(
    nestedCall(
      'search',
      index++,
      inputs: const {'pattern': 'TODO'},
      status: searchDone ? ToolSegmentStatus.ok : ToolSegmentStatus.running,
    ),
  );
  if (!searchDone) {
    return out;
  }
  for (var i = 0; i < 5; i++) {
    out.add(
      nestedCall(
        'read',
        index++,
        nth: i,
        inputs: {'path': sampleDocs[i]},
        status: i < docsDone ? ToolSegmentStatus.ok : ToolSegmentStatus.running,
      ),
    );
  }
  if (docsDone < 5) {
    return out;
  }
  for (var i = 0; i < iterations; i++) {
    final file = 'lib/feature_${i + 1}.dart';
    out.add(nestedCall('read', index++, nth: 5, inputs: {'path': file}));
    final last = i == iterations - 1;
    out.add(
      nestedCall(
        'grep',
        index++,
        inputs: {'pattern': 'FIXME', 'path': file},
        status: i == failedIteration
            ? ToolSegmentStatus.error
            : (last && !loopDone
                  ? ToolSegmentStatus.running
                  : ToolSegmentStatus.ok),
      ),
    );
  }
  if (!loopDone || !branch) {
    return out;
  }
  out.add(
    nestedCall(
      'edit',
      index++,
      inputs: const {'path': 'TODO.md', 'old_string': '', 'new_string': 'x'},
      status: deniedEdit ? ToolSegmentStatus.error : ToolSegmentStatus.ok,
      outcome: deniedEdit ? 'denied' : null,
    ),
  );
  return out;
}
