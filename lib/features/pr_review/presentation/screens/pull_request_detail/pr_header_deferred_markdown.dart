part of 'pr_header_section.dart';

/// Paints [placeholder] on the first frame, then [child] — but only the first
/// time this process shows a given body ([contentKey]).
///
/// GitHub-flavoured markdown parse + widget build is the Overview hitch:
/// a long description or a bot report must not run before first paint. Once a
/// body has been rendered its parse is cached, so deferring it again on a
/// remount (a tab switch, a revisit, a restored layout) bought nothing and
/// flashed a stand-in for a frame. The stand-in is the description skeleton
/// the page already showed while the body loaded, not the raw markdown: a
/// truncated plain-text frame read as a different page, and its shorter
/// height pulled the activity timeline up under it.
class _DeferredMarkdown extends StatefulWidget {
  const _DeferredMarkdown({
    required this.contentKey,
    required this.placeholder,
    required this.child,
  });

  final int contentKey;
  final Widget placeholder;
  final Widget child;

  @override
  State<_DeferredMarkdown> createState() => _DeferredMarkdownState();
}

/// Content keys of bodies already rendered once, oldest first. A bounded LRU:
/// an evicted body defers once more, which is the cost of a cold parse anyway.
final Set<int> _renderedBodies = <int>{};
const int _maxRenderedBodies = 64;

/// Records [key] as rendered; true when it had not been rendered before.
bool _firstRenderOf(int key) {
  if (_renderedBodies.remove(key)) {
    _renderedBodies.add(key); // refresh recency
    return false;
  }
  _renderedBodies.add(key);
  while (_renderedBodies.length > _maxRenderedBodies) {
    _renderedBodies.remove(_renderedBodies.first);
  }
  return true;
}

class _DeferredMarkdownState extends State<_DeferredMarkdown> {
  late bool _ready = !_firstRenderOf(widget.contentKey);

  @override
  void initState() {
    super.initState();
    if (_ready) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _ready = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ready ? widget.child : widget.placeholder;
  }
}
