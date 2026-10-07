import 'package:cc_gallery/showcase.dart';
import 'package:cc_gallery/stories/support/markdown_samples.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_streaming_markdown.stories.g.dart';

/// Stories for the cc_markdown engine: one-shot rendering, live streaming, and
/// a compact variant. The gallery builds its own [CcMarkdownStyle] from cc_ui
/// tokens (it cannot import the host app's `appMarkdownStyle`); the shared
/// fixtures live in `support/markdown_samples.dart`.

const _path = '[Components]/Content';

const component = ComponentMeta(name: 'CcStreamingMarkdown', path: _path);

const meta = Meta(Showcase.new);

final $Streaming = _Story(args: _Args.fixed(preview: ccMarkdownStreamingStory));

/// A timer-driven streaming demo: deltas append into [CcStreamingMarkdown] to
/// mimic an LLM response, with a restart button.
Widget ccMarkdownStreamingStory(BuildContext context) {
  return const Center(child: SizedBox(width: 640, child: _StreamingDemo()));
}

class _StreamingDemo extends StatefulWidget {
  const _StreamingDemo();

  @override
  State<_StreamingDemo> createState() => _StreamingDemoState();
}

class _StreamingDemoState extends State<_StreamingDemo> {
  final CcMarkdownStreamController _controller = CcMarkdownStreamController();
  List<String> _chunks = const [];
  int _index = 0;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    _controller.reset();
    // ~30-char deltas of a representative answer.
    const full = markdownKitchenSink;
    final chunks = <String>[];
    for (var i = 0; i < full.length; i += 30) {
      chunks.add(full.substring(i, (i + 30).clamp(0, full.length)));
    }
    _chunks = chunks;
    _index = 0;
    _running = true;
    _tick();
  }

  void _tick() {
    if (!mounted || !_running) {
      return;
    }
    if (_index >= _chunks.length) {
      _controller.complete();
      setState(() => _running = false);
      return;
    }
    _controller.append(_chunks[_index]);
    _index++;
    // No Timer import in the gallery-safe surface — drive via a microtask
    // chain gated on a post-frame callback so it paces to frames.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 40), _tick);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcButton(
          onPressed: _running ? null : _start,
          child: const Text('Replay stream'),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: t.borderSecondary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: CcStreamingMarkdown(
                controller: _controller,
                style: galleryMarkdownStyle(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
