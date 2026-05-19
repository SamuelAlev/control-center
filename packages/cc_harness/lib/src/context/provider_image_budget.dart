import 'package:cc_harness/src/messages.dart';

/// Replacement text for a tool-result image dropped to fit the provider's
/// per-request image ceiling.
const String providerImageOmittedMarker =
    '[image omitted: provider image limit]';

/// The largest number of images one request may carry, per provider family.
///
/// These are HARD API limits, not token economics — exceeding them is a 400
/// from the provider, so the whole turn fails rather than degrading. The
/// per-tool budget (`capToolImages`) bounds what a single call contributes;
/// this bounds what the accumulated CONVERSATION contributes, which is the
/// number that actually creeps up: an agent driving a browser adds a frame
/// every turn, each one survives compaction (text shrinks, a screenshot does
/// not), and after enough turns the request is simply rejected.
///
/// The unknown-provider default is deliberately low. A wrong-but-small guess
/// costs some visual history; a wrong-but-large one costs the turn.
int providerImageLimitFor(String? providerId) {
  final id = (providerId ?? '').toLowerCase();
  if (id.contains('anthropic') ||
      id.contains('claude') ||
      id.contains('bedrock') ||
      id.contains('openrouter')) {
    return 90;
  }
  if (id.contains('openai') ||
      id.contains('codex') ||
      id.contains('azure') ||
      id.contains('google') ||
      id.contains('gemini') ||
      id.contains('vertex')) {
    return 200;
  }
  return 5;
}

/// Drops the OLDEST tool-result images from [history] until at most [limit]
/// remain, replacing an emptied result's images with a marker line so the model
/// can tell "there was a screenshot here and it aged out" from "this tool
/// returned no screenshot".
///
/// Oldest-first is the whole point: the newest frame is the one the agent is
/// reasoning about, and the frame from thirty turns ago is scenery. Text is
/// never touched — only the image blocks — so the transcript's narrative
/// survives intact.
///
/// Returns [history] unchanged when it already fits, so the common case (no
/// images at all) allocates nothing.
List<HarnessMessage> clampProviderContextImages(
  List<HarnessMessage> history,
  int limit,
) {
  var total = 0;
  for (final message in history) {
    for (final block in message.content) {
      if (block is HarnessToolResultBlock) {
        total += block.images.length;
      } else if (block is HarnessImageBlock) {
        total += 1;
      }
    }
  }
  if (total <= limit) {
    return history;
  }

  var toDrop = total - limit;
  final out = <HarnessMessage>[];
  for (final message in history) {
    if (toDrop <= 0) {
      out.add(message);
      continue;
    }
    var changed = false;
    final blocks = <HarnessContentBlock>[];
    for (final block in message.content) {
      if (toDrop <= 0) {
        blocks.add(block);
        continue;
      }
      switch (block) {
        case HarnessToolResultBlock(:final images) when images.isNotEmpty:
          final keep = images.length <= toDrop
              ? const <HarnessImageBlock>[]
              : images.sublist(toDrop);
          toDrop -= images.length - keep.length;
          changed = true;
          blocks.add(
            HarnessToolResultBlock(
              toolUseId: block.toolUseId,
              content: keep.isEmpty && block.content.trim().isEmpty
                  ? providerImageOmittedMarker
                  : (keep.length < images.length
                        ? '${block.content}\n$providerImageOmittedMarker'
                        : block.content),
              isError: block.isError,
              images: keep,
            ),
          );
        case HarnessImageBlock():
          // A user-attached image. Dropping it silently would make the model
          // answer about a picture it can no longer see, so leave a note.
          toDrop -= 1;
          changed = true;
          blocks.add(const HarnessTextBlock(providerImageOmittedMarker));
        default:
          blocks.add(block);
      }
    }
    out.add(
      changed
          ? HarnessMessage(role: message.role, content: blocks)
          : message,
    );
  }
  return out;
}
