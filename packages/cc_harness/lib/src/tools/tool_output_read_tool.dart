/// The bounded retrieval tool: how the model gets back to an original tool
/// output that ingestion compacted out of the window.
///
/// **Why a tool and not a bigger context.** Retrieval is the honest cost of a
/// bounded observation. Making it a *tool* keeps that cost visible and
/// bounded — one call, one range, one price — instead of silently re-running
/// the `search`/`bash`/`read` that produced the text (which is what a model
/// does when the only way back to a dropped observation is to do the work
/// again).
///
/// **Why the scope never comes from arguments.** The handle is model-supplied
/// input, so it is treated as an untrusted name: the scope it is checked
/// against comes from the run's [HarnessToolContext]. A model cannot widen its
/// own reach by naming another conversation's handle — it can only get a
/// denial.
library;

import 'package:cc_harness/src/context/tool_output_reference.dart';
import 'package:cc_harness/src/context/tool_output_store.dart';
import 'package:cc_harness/src/tools/tool.dart';

/// Reads a bounded character range of a stored tool output by handle.
class ToolOutputReadTool extends HarnessTool {
  /// Creates a retrieval tool backed by the supplied output store.
  ToolOutputReadTool(this._store);

  final ToolOutputStore? _store;

  @override
  String get name => 'read_output';

  @override
  String get description =>
      'Read part of a tool output that was too large to show in full. Use the '
      'handle from an "[output omitted …]" marker in an earlier tool result. '
      'Returns an exact character range, bounded per call; page with offset. '
      'Only outputs from this conversation and agent are readable.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  /// Audited safe for speculative (early) execution: a bounded read of an
  /// already-stored output — no external effect, no approval gate, no mutation,
  /// no network. The handle is validated before any lookup and the read is
  /// clamped to [kToolOutputReadMaxChars], so an early start cannot do more
  /// work than the final call would.
  @override
  bool get speculativeReadSafe => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'handle': {
        'type': 'string',
        'description':
            'Handle of the stored output (e.g. "out_ab12cd34…"), taken '
            'verbatim from the "[output omitted …]" marker.',
      },
      'offset': {
        'type': 'integer',
        'description': 'Character offset to start at (default 0).',
        'default': 0,
      },
      'limit': {
        'type': 'integer',
        'description':
            'Characters to return (default $kToolOutputReadDefaultChars, '
            'max $kToolOutputReadMaxChars).',
        'default': kToolOutputReadDefaultChars,
      },
    },
    'required': ['handle'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final handle = args['handle'];
    if (handle is! String || handle.isEmpty) {
      return HarnessToolResult.error('Missing or invalid argument: handle');
    }
    if (!isToolOutputHandle(handle)) {
      // Fail before the store sees it: a malformed handle is a model error, not
      // a lookup, and a name shaped like a path must never reach the filesystem.
      return HarnessToolResult.error(
        'Invalid output handle: "$handle" (expected the "out_…" handle from an '
        'omitted-output marker)',
      );
    }
    final store = _store;
    if (store == null) {
      return HarnessToolResult.error(
        'Output retrieval is unavailable in this run: no store is wired.',
      );
    }
    // Scope from the RUN, never from `args`: a handle is only readable inside
    // the workspace/conversation/agent that produced it.
    final scope = buildToolOutputScope(context);
    if (scope == null) {
      return HarnessToolResult.error(
        'Output retrieval is unavailable for this run: the run has no '
        'workspace scope.',
      );
    }

    final offset = (args['offset'] as num?)?.toInt() ?? 0;
    final limit =
        (args['limit'] as num?)?.toInt() ?? kToolOutputReadDefaultChars;
    if (limit < 1) {
      return HarnessToolResult.error('Invalid limit: must be at least 1 char.');
    }

    final result = await store.read(
      scope,
      handle,
      offsetChars: offset,
      limitChars: limit,
    );
    final chunk = result.chunk;
    if (!result.isOk || chunk == null) {
      switch (result.status) {
        case ToolOutputReadStatus.denied:
          // A local anomaly: the entry is in this scope's own storage but its
          // recorded identity is not this scope's. Saying so is not a
          // disclosure (it names no other run).
          return HarnessToolResult.error(
            'Denied: that stored output does not belong to this '
            'workspace/conversation/agent and will not be read.',
          );
        case ToolOutputReadStatus.notFound:
          return HarnessToolResult.error(
            'Unknown output handle: "$handle". No such output is stored for '
            'this workspace/conversation/agent — it may never have been '
            'stored, or its scope may have been cleared. Re-run the tool that '
            'produced it if you still need the text.',
          );
        case ToolOutputReadStatus.invalid:
          return HarnessToolResult.error('Invalid output handle: "$handle".');
        case ToolOutputReadStatus.unavailable:
          return HarnessToolResult.error(
            'Output retrieval is unavailable in this run.',
          );
        case ToolOutputReadStatus.ok:
          return HarnessToolResult.error('Output retrieval failed.');
      }
    }

    final buffer = StringBuffer()
      ..writeln(
        '[output $handle'
        '${chunk.toolName.isEmpty ? '' : ' (${chunk.toolName})'}: '
        'chars ${chunk.offsetChars}-${chunk.offsetChars + chunk.text.length} '
        'of ${chunk.totalChars}'
        '${chunk.byteLength == chunk.totalChars ? '' : ', ${chunk.byteLength} bytes'}]',
      )
      ..write(chunk.text);
    if (chunk.hasMore) {
      buffer
        ..writeln()
        ..write(
          '[+${chunk.totalChars - chunk.nextOffsetChars} chars remain; '
          'continue with offset=${chunk.nextOffsetChars}]',
        );
    }
    return HarnessToolResult.success(buffer.toString());
  }
}
