import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_infra/src/context/text_raster.dart';

/// How a provider bills an image, which is the only thing frame shape depends
/// on.
enum ImageBillingModel {
  /// A flat cost per image regardless of pixel count (Gemini). Larger frames
  /// are free characters, so the shape is as wide and dense as the processor
  /// will accept.
  flat,

  /// Cost proportional to area (OpenAI's patches, Anthropic's tiles). A bigger
  /// frame buys nothing — it costs exactly what it holds — so the shape is
  /// tuned for legibility at the smallest area that stays readable.
  area,

  /// The processor downscales past a threshold, which silently destroys the
  /// glyphs. Frames must stay under it.
  downscaling,
}

/// The page shape to render for one reader.
class SnapFrameShape {
  /// Creates a [SnapFrameShape].
  const SnapFrameShape({
    required this.columns,
    required this.rows,
    required this.scale,
    required this.billing,
  });

  /// Characters per line.
  final int columns;

  /// Lines per page.
  final int rows;

  /// Integer pixel scale.
  final int scale;

  /// How the reader bills it.
  final ImageBillingModel billing;

  /// A rasterizer configured for this shape.
  TextRasterizer get rasterizer =>
      TextRasterizer(columns: columns, rows: rows, scale: scale);

  /// Rendered page width in pixels.
  int get pixelWidth => columns * kSnapGlyphWidth * scale;
}

/// The glyph cell width the shapes are computed against.
const int kSnapGlyphWidth = 5;

/// Upper bound on the retained plain-text source carried across folds.
///
/// Every pass prepends the previous pass's source so a second fold re-images
/// the WHOLE discarded history. Left unbounded that source grows with the run
/// while the pages that carry it stay the same size — the retained text is
/// then pure memory growth and, worse, a fold late in a long run spends its
/// pages re-drawing text that has already been folded several times. When the
/// cap is hit the OLDEST end is dropped with an explicit marker, keeping the
/// most recent discarded history.
const int kSnapMaxRetainedSourceChars = 200000;

/// Distinguishes the caption line the snapshot replacement message opens with,
/// so a text-compaction fallback can recognize a region it must rehydrate
/// rather than a region of ordinary history.
const String kSnapcompactCaptionMarker = 'earlier messages are rendered as';

/// Whether [message] is a snapshot replacement (an imaged page).
///
/// The identity marker ([HarnessMessage.isSnapshotCarrier], stamped by the loop
/// from the reported `foldedFromIndex`) is authoritative — it survives image
/// shedding and a restart. The content test is a fallback for legacy pages
/// written before the marker existed.
bool isSnapcompactMessage(HarnessMessage message) {
  if (message.isSnapshotCarrier) {
    return true;
  }
  if (message.role != HarnessRole.user) {
    return false;
  }
  final hasImage = message.content.any((b) => b is HarnessImageBlock);
  return hasImage && message.textContent.contains(kSnapcompactCaptionMarker);
}

/// Rebuilds a snapshot region as TEXT so a text compactor can fold the real
/// conversation instead of the page caption.
///
/// Returns null when there is no retained source to restore — after a restart
/// that did not persist it, for instance. The caller must then surface the loss
/// explicitly rather than let the caption stand in for the history.
///
/// The returned message deliberately carries NO [HarnessMessage.isSnapshotCarrier]
/// marker: it is TEXT now, and its absence is exactly what tells the host the
/// retained source may be dropped.
HarnessMessage? rehydrateSnapshotMessage(
  String? retainedSource, {
  List<String> activatedToolNames = const [],
}) {
  final source = retainedSource?.trim() ?? '';
  if (source.isEmpty) {
    return null;
  }
  return HarnessMessage(
    role: HarnessRole.user,
    content: [
      HarnessTextBlock(
        '[snapshot region restored as text — the same words that were '
        'rendered as pages]\n\n$source',
      ),
    ],
    activatedToolNames: activatedToolNames,
  );
}

/// The explicit marker written in place of a snapshot region whose retained
/// source was not available (e.g. a restart that did not persist it) — a
/// labeled loss, never a silent one.
const String snapshotUnavailableMarker =
    '[snapshot region unavailable: retained source not persisted]';

/// Rehydrates every snapshot region in [history] back to text, so a text
/// compactor folds the REAL conversation rather than the page captions.
///
/// [retainedSource] is cumulative (a later pass's source contains every earlier
/// pass's), so the NEWEST snapshot message is replaced with the full restored
/// text and any EARLIER one with a pointer marker. Message COUNT is preserved,
/// so checkpoint indices do not shift because of rehydration.
List<HarnessMessage> rehydrateSnapcompactHistory(
  List<HarnessMessage> history,
  String? retainedSource,
) {
  var newest = -1;
  for (var i = history.length - 1; i >= 0; i--) {
    if (isSnapcompactMessage(history[i])) {
      newest = i;
      break;
    }
  }
  if (newest < 0) {
    return history;
  }
  final restored = rehydrateSnapshotMessage(
    retainedSource,
    activatedToolNames: collectActivatedToolNames(history),
  );
  final out = <HarnessMessage>[];
  for (var i = 0; i < history.length; i++) {
    final m = history[i];
    if (!isSnapcompactMessage(m)) {
      out.add(m);
      continue;
    }
    if (i == newest) {
      out.add(restored ?? HarnessMessage.user(snapshotUnavailableMarker));
    } else {
      out.add(
        HarnessMessage(
          role: HarnessRole.user,
          content: const [
            HarnessTextBlock(
              '[superseded snapshot: its text is restored in the later region]',
            ),
          ],
          activatedToolNames: m.activatedToolNames,
          // No snapshot-carrier marker: this is a pointer, not a page — the
          // source may be dropped once no real page remains.
        ),
      );
    }
  }
  return out;
}

/// Picks the page shape for [modelId].
///
/// **Priced for the API that carries the request, not the weights.** A Claude
/// served through Vertex is billed by Vertex; a Llama served by three vendors is
/// billed three ways. So the match is on the model ID as the ROUTE names it —
/// the same string the provider was resolved from — and an unrecognised one
/// falls back to the conservative area-billed shape rather than guessing
/// generously.
SnapFrameShape snapFrameShapeFor(String? modelId) {
  final id = (modelId ?? '').toLowerCase();

  // Gemini bills a flat ~1120 tokens per image at any pixel size below its
  // cap, so every extra character on the page is free. Widest shape.
  if (id.contains('gemini') || id.contains('google/')) {
    return const SnapFrameShape(
      columns: 400,
      rows: 220,
      scale: 1,
      billing: ImageBillingModel.flat,
    );
  }

  // These processors downscale past ~1792px, which turns a 5px glyph into
  // mush. The width is chosen to stay under it with room to spare.
  if (id.contains('kimi') || id.contains('glm') || id.contains('moonshot')) {
    return const SnapFrameShape(
      columns: 300,
      rows: 180,
      scale: 1,
      billing: ImageBillingModel.downscaling,
    );
  }

  // Anthropic tiles up to a cap; OpenAI bills patches by area. Same answer for
  // both: no bigger than it needs to be.
  return const SnapFrameShape(
    columns: 300,
    rows: 200,
    scale: 1,
    billing: ImageBillingModel.area,
  );
}

/// What one snapcompact pass produced.
class SnapcompactResult {
  /// Creates a [SnapcompactResult].
  const SnapcompactResult({
    required this.messages,
    required this.frames,
    required this.foldedCount,
    required this.retainedSource,
    this.replacementIndex = 0,
  });

  /// The rebuilt history.
  final List<HarnessMessage> messages;

  /// How many pages the middle became.
  final int frames;

  /// How many messages were folded into them.
  final int foldedCount;

  /// The index the single replacement message occupies in [messages].
  ///
  /// The folded span is `[replacementIndex, replacementIndex + foldedCount)`.
  /// A caller remapping checkpoint indices must use this — unlike a text fold,
  /// a snapshot keeps a verbatim head, so indices BEFORE this do not shift.
  final int replacementIndex;

  /// The plain text those pages were rendered from.
  ///
  /// **Retained, and re-rendered from on the NEXT compaction.** Carrying the
  /// PNGs forward would re-image an image: each pass would fold the previous
  /// pass's pictures into new pictures, and the text inside them would degrade
  /// with every generation until it was unreadable. Rendering from the source
  /// each time means the glyphs are always one generation old.
  final String retainedSource;

  /// Whether anything was folded.
  bool get didCompact => foldedCount > 0;
}

/// Compacts a history by rendering its middle onto images.
///
/// **The reconstruction shape: verbatim head, imaged middle, verbatim tail.**
/// The head is the task and the constraints, which everything downstream refers
/// back to; the tail is where the work currently is. The middle is the part
/// that gets re-read least and costs most, so that is what becomes pixels. An
/// imaged head would mean the model reads its own instructions through a
/// picture, and an imaged tail would mean it reads the thing it is in the
/// middle of doing that way.
///
/// **No model call.** That is the property that matters: a summarizing
/// compactor shrinks the context by making a request, and during overflow
/// recovery the request it makes is the one that just overflowed. This one
/// cannot fail that way.
class Snapcompactor {
  /// Creates a [Snapcompactor].
  const Snapcompactor({
    required this.shape,
    this.keepHead = 2,
    this.keepTail = 6,
    this.minimumFold = 6,
  });

  /// The page shape for the reader.
  final SnapFrameShape shape;

  /// Messages kept verbatim at the oldest edge.
  final int keepHead;

  /// Messages kept verbatim at the newest edge.
  final int keepTail;

  /// Below this many foldable messages, imaging is not worth an image.
  ///
  /// A picture has a fixed cost floor; folding three short turns into one
  /// costs more than the turns did.
  final int minimumFold;

  /// Folds [messages]' middle into pages.
  SnapcompactResult compact(
    List<HarnessMessage> messages, {
    String? retainedSource,
  }) {
    if (messages.length <= keepHead + keepTail + minimumFold) {
      return SnapcompactResult(
        messages: messages,
        frames: 0,
        foldedCount: 0,
        retainedSource: retainedSource ?? '',
      );
    }

    // Boundary selection is PAIR-SAFE. A message slice may not split a
    // `tool_use` / `tool_result` pair: a head that ended on an assistant turn
    // with an unanswered tool_use would leave the imaged block (a user turn)
    // sitting where the provider requires the tool result, and a tail that
    // began on a `tool` message would orphan a result whose call was imaged.
    // Both are rejected by every provider, so the boundaries are snapped to
    // whole pairs before anything is imaged.
    var headEnd = keepHead;
    while (headEnd > 0 && messages[headEnd - 1].hasToolUse) {
      headEnd--;
    }
    var tailStart = messages.length - keepTail;
    while (tailStart < messages.length &&
        messages[tailStart].role == HarnessRole.tool) {
      tailStart++;
    }
    if (tailStart - headEnd < minimumFold) {
      // The safe boundaries left too little middle to be worth an image.
      return SnapcompactResult(
        messages: messages,
        frames: 0,
        foldedCount: 0,
        retainedSource: retainedSource ?? '',
      );
    }

    final head = messages.sublist(0, headEnd);
    final middle = messages.sublist(headEnd, tailStart);
    final tail = messages.sublist(tailStart);

    // The previous pass's source comes first, so a second compaction images
    // the WHOLE discarded history rather than only what has been discarded
    // since — and images it from text, never from the last pass's pixels.
    final source = _boundSource(
      [
        if (retainedSource != null && retainedSource.isNotEmpty) retainedSource,
        renderMessagesAsText(middle),
      ].join('\n\n'),
    );

    // The rasterizer normalizes unsupported glyphs, tabs and control codes.
    // That is acceptable for a preview, not for replacing exact code or paths
    // in memory. Decline before allocating images; the host uses text folding.
    for (var i = 0; i < source.length; i++) {
      final unit = source.codeUnitAt(i);
      if (unit != 0x0A && (unit < 0x20 || unit > 0x7E)) {
        return SnapcompactResult(
          messages: messages,
          frames: 0,
          foldedCount: 0,
          retainedSource: retainedSource ?? '',
        );
      }
    }

    final frames = shape.rasterizer.render(source);
    if (frames.isEmpty) {
      return SnapcompactResult(
        messages: messages,
        frames: 0,
        foldedCount: 0,
        retainedSource: source,
      );
    }

    // A `user` turn, not a `system` one: a system message at this position
    // changes the shape of the prefix on several providers and costs the whole
    // prompt cache, which is the opposite of what a compaction is for.
    final imaged = HarnessMessage(
      role: HarnessRole.user,
      content: [
        HarnessTextBlock(
          '[${middle.length} earlier messages are rendered as '
          '${frames.length} page${frames.length == 1 ? '' : 's'} of text '
          'below. Read them as ordinary conversation history; they are the '
          'same words, drawn rather than typed.]',
        ),
        for (final frame in frames)
          HarnessImageBlock(mediaType: 'image/png', data: frame.base64Data),
      ],
      // Activation metadata of the imaged region travels WITH the replacement:
      // a search result referencing a deferred tool may be inside the middle,
      // and losing its activation would make that tool uncallable.
      activatedToolNames: collectActivatedToolNames(middle),
      // Page IDENTITY: the host's source-persistence rule keys on this marker
      // (not on an image count), so it is carried here as well as being stamped
      // by the loop from `foldedFromIndex`. Redundant on the loop path; correct
      // for a page built by calling `compact` directly.
      isSnapshotCarrier: true,
    );

    return SnapcompactResult(
      messages: [...head, imaged, ...tail],
      frames: frames.length,
      foldedCount: middle.length,
      replacementIndex: head.length,
      retainedSource: source,
    );
  }

  /// Caps the retained source, dropping the OLDEST end with an explicit marker.
  static String _boundSource(String source) {
    if (source.length <= kSnapMaxRetainedSourceChars) {
      return source;
    }
    // The start of the source is the oldest folded history; the most recent
    // discarded turns sit at the end and are what a later fold should re-image.
    const marker = '[earlier folded history dropped: source cap reached]\n';
    return '$marker'
        '${source.substring(source.length - kSnapMaxRetainedSourceChars + marker.length)}';
  }
}

/// Flattens messages to the plain text a page is rendered from.
///
/// Tool results are included in full: they are most of the discarded bulk, and
/// dropping them here would make snapcompact a summarizer with extra steps.
String renderMessagesAsText(List<HarnessMessage> messages) {
  final buffer = StringBuffer();
  for (final message in messages) {
    final who = switch (message.role) {
      HarnessRole.user => 'USER',
      HarnessRole.assistant => 'ASSISTANT',
      HarnessRole.system => 'SYSTEM',
      HarnessRole.tool => 'TOOL',
    };
    buffer.writeln('--- $who ---');
    for (final block in message.content) {
      switch (block) {
        case HarnessTextBlock(:final text):
          buffer.writeln(text);
        case HarnessToolUseBlock(:final name, :final input):
          buffer.writeln('[call $name] $input');
        case HarnessToolResultBlock(:final content, :final isError):
          buffer.writeln('[result${isError ? ' error' : ''}] $content');
        case HarnessThinkingBlock():
          // Reasoning is the model's scratch space and the single largest
          // thing in a long history. Re-showing it as a picture spends the
          // page on text the model would not have re-read anyway.
          break;
        case HarnessImageBlock():
          buffer.writeln('[image omitted]');
      }
    }
    buffer.writeln();
  }
  return buffer.toString();
}
