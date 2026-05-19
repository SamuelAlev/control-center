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

/// The glyph cell height.
const int kSnapGlyphHeight = 9;

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
  });

  /// The rebuilt history.
  final List<HarnessMessage> messages;

  /// How many pages the middle became.
  final int frames;

  /// How many messages were folded into them.
  final int foldedCount;

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

    final head = messages.sublist(0, keepHead);
    final middle = messages.sublist(keepHead, messages.length - keepTail);
    final tail = messages.sublist(messages.length - keepTail);

    // The previous pass's source comes first, so a second compaction images
    // the WHOLE discarded history rather than only what has been discarded
    // since — and images it from text, never from the last pass's pixels.
    final source = [
      if (retainedSource != null && retainedSource.isNotEmpty) retainedSource,
      renderMessagesAsText(middle),
    ].join('\n\n');

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
          'below. Read them as ordinary conversation history — they are the '
          'same words, drawn rather than typed.]',
        ),
        for (final frame in frames)
          HarnessImageBlock(mediaType: 'image/png', data: frame.base64Data),
      ],
    );

    return SnapcompactResult(
      messages: [...head, imaged, ...tail],
      frames: frames.length,
      foldedCount: middle.length,
      retainedSource: source,
    );
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
