/// Anthropic native tool deferral — capability detection and wire helpers.
///
/// **Why this exists.** The loop has always activated a deferred tool by
/// appending its schema to the top-level `tools` array. That preserves the
/// resident breakpoint but NOT the layers after it: Anthropic's documented
/// cache order is tools → system → messages, so any change inside the `tools`
/// array invalidates the cached system prompt and history that follow it. The
/// probe's captured requests showed neither `defer_loading` nor `tool_reference`
/// — activation was rewriting the largest cached region in the request.
///
/// With native deferral the request carries the WHOLE admitted catalog on every
/// turn (Anthropic needs the definitions server-side to expand a reference) and
/// the API keeps deferred definitions out of the context prefix itself, so an
/// activation appends a small reference block instead of rewriting the prefix.
/// See: https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool
///
/// **No beta header.** The current Messages API documents `defer_loading` and
/// `tool_reference` as ordinary request/response fields with no `anthropic-beta`
/// opt-in; an unrecognized beta value is itself a rejected request, so sending
/// one speculatively would break the very models this is meant to speed up.
library;

/// Model families that support tool search / `defer_loading`.
///
/// From the API's model-compatibility table: every Claude Opus/Sonnet/Haiku 4.5
/// and newer, plus the 5-series families. Claude Opus 4.1 and earlier do NOT
/// support it — sending them `defer_loading` or a `tool_reference` block is a
/// rejected request, not a no-op, which is why this list is an allowlist and
/// not a version comparison.
const List<String> _supportedModelPrefixes = [
  'claude-fable-5',
  'claude-mythos-5',
  'claude-opus-5',
  'claude-sonnet-5',
  'claude-haiku-5',
  'claude-opus-4-8',
  'claude-opus-4-7',
  'claude-opus-4-6',
  'claude-opus-4-5',
  'claude-sonnet-4-6',
  'claude-sonnet-4-5',
  'claude-haiku-4-5',
];

/// A trailing snapshot date (`-20250929`), stripped before matching so a dated
/// id and its family alias agree.
final RegExp _snapshotSuffix = RegExp(r'-\d{8}$');

/// Whether [model] supports native tool deferral (`defer_loading` +
/// `tool_reference`).
///
/// A null/empty or unrecognized id answers `false`: an unknown endpoint must
/// fall back to the ordinary full-schema request rather than have fields it may
/// not understand pushed at it.
bool anthropicSupportsToolDeferral(String? model) {
  if (model == null || model.isEmpty) {
    return false;
  }
  var id = model.trim().toLowerCase();
  // Tolerate a qualified `anthropic/claude-…` id reaching this boundary.
  final slash = id.indexOf('/');
  if (slash != -1) {
    id = id.substring(slash + 1);
  }
  id = id.replaceFirst(_snapshotSuffix, '');
  for (final prefix in _supportedModelPrefixes) {
    if (id == prefix || id.startsWith('$prefix-')) {
      return true;
    }
  }
  return false;
}

/// Applies the deferral decision to a wire tool list, in place.
///
/// `deferredCount` is how many tools SHOULD be deferred; the list must already
/// be ordered resident-first so the resident block stays the cache prefix.
///
/// Two guards, both about not sending a request the API rejects:
///
/// * With nothing deferred there is nothing to do (the ordinary request is what
///   every non-deferring model gets).
/// * The API rejects an all-deferred request ("all tools deferred" is a 400),
///   so when the caller has marked every tool the flags are dropped and the
///   catalog is sent plainly. That is the pre-existing behavior — the model
///   sees every tool immediately — rather than a failed run.
///
/// Returns whether deferral was actually applied.
bool applyAnthropicDeferral(List<Map<String, dynamic>> wireTools) {
  if (wireTools.isEmpty) {
    return false;
  }
  final deferred = wireTools.where((t) => t['defer_loading'] == true).length;
  if (deferred == 0) {
    return false;
  }
  if (deferred == wireTools.length) {
    for (final tool in wireTools) {
      tool.remove('defer_loading');
    }
    return false;
  }
  return true;
}

/// Index the tools-array cache breakpoint should sit at.
///
/// The breakpoint must land on the last RESIDENT tool: a deferred schema loads
/// behind it, so a breakpoint at the end of the array would sit after a
/// definition that can appear mid-run. [requested] is the caller's intent (it
/// tracks the resident block); null, out-of-range or a deferred index all snap
/// back to the last non-deferred tool.
int residentToolBreakpointIndex(
  List<Map<String, dynamic>> wireTools,
  int? requested,
) {
  if (wireTools.isEmpty) {
    return -1;
  }
  var lastResident = -1;
  for (var i = 0; i < wireTools.length; i++) {
    if (wireTools[i]['defer_loading'] != true) {
      lastResident = i;
    }
  }
  if (lastResident < 0) {
    return wireTools.length - 1;
  }
  if (requested == null || requested < 0 || requested >= wireTools.length) {
    return lastResident;
  }
  return wireTools[requested]['defer_loading'] == true
      ? lastResident
      : requested;
}
