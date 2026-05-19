import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for the cc_markdown engine: one-shot rendering, live streaming,
/// and a compact variant. The gallery builds its own [CcMarkdownStyle] from
/// cc_ui tokens (it cannot import the host app's `appMarkdownStyle`).

const _path = '[Components]/Content';

const _kitchenSink = '''
# Heading one

A paragraph with **bold**, *italic*, ~~strikethrough~~, `inline code`, and a
[link](https://anthropic.com).

## Lists

- bullet one
- bullet two
  - nested
- [x] done task
- [ ] open task

1. first
2. second

## Table

| Name | Role | Cost |
|:-----|:----:|-----:|
| Ada  | lead |  \$12 |
| Bee  | eng  |   \$4 |

## Code

```dart
void main() {
  print('hello, cc_markdown');
}
```

> A blockquote with a footnote reference.[^1]

<details>
<summary>Show details</summary>

Hidden content revealed on tap.

</details>

[^1]: The footnote definition renders at the end.
''';

CcMarkdownStyle _galleryStyle(BuildContext context, {bool compact = false}) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final size = compact ? 13.0 : 15.0;
  final body = TextStyle(fontSize: size, height: 1.55, color: t.textPrimary);
  return CcMarkdownStyle(
    paragraph: body,
    h1: TextStyle(
      fontSize: compact ? 20 : 24,
      fontWeight: FontWeight.w700,
      color: t.textPrimary,
    ),
    h2: TextStyle(
      fontSize: compact ? 17 : 19,
      fontWeight: FontWeight.w600,
      color: t.textPrimary,
    ),
    h3: TextStyle(
      fontSize: compact ? 15 : 16,
      fontWeight: FontWeight.w600,
      color: t.textPrimary,
    ),
    code: TextStyle(fontFamily: 'monospace', fontSize: size - 1),
    inlineCode: TextStyle(fontFamily: 'monospace', fontSize: size - 1),
    link: body.copyWith(
      color: t.textBrandPrimary,
      decoration: TextDecoration.underline,
    ),
    blockquote: body.copyWith(color: t.textTertiary),
    codeblockDecoration: BoxDecoration(
      color: t.bgSecondary,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: t.borderSecondary),
    ),
    codeblockPadding: const EdgeInsets.all(12),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: t.borderSecondary, width: 3)),
    ),
    blockquotePadding: const EdgeInsets.only(left: 12),
    tableBorder: TableBorder.all(color: t.borderSecondary, width: 0.5),
    tableHeadDecoration: BoxDecoration(color: t.bgSecondary),
    horizontalRuleColor: t.borderSecondary,
  );
}

/// A full one-shot document exercising every core block + inline.
@widgetbook.UseCase(name: 'Document', type: CcMarkdown, path: _path)
Widget ccMarkdownDocumentUseCase(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 640,
      child: SingleChildScrollView(
        child: CcMarkdown(
          data: _kitchenSink,
          selectable: true,
          style: _galleryStyle(context),
        ),
      ),
    ),
  );
}

/// The compact style variant, side by side conceptually with the default.
@widgetbook.UseCase(name: 'Compact', type: CcMarkdown, path: _path)
Widget ccMarkdownCompactUseCase(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: CcMarkdown(
          data: _kitchenSink,
          selectable: true,
          style: _galleryStyle(context, compact: true),
        ),
      ),
    ),
  );
}

const _mermaidSamples = <(String, String)>[
  (
    'Flowchart (TD, shapes, subgraph)',
    '''
flowchart TD
  A([Incoming PR]) --> B{CI green?}
  B -->|yes| C[Request review]
  B -->|no| D[/Post failures/]
  subgraph review [Review loop]
    C --> E[Reviewer reads diff]
    E --> F{Changes requested?}
    F -->|yes| G[Author pushes fix]
    G --> E
  end
  F -->|no| H[(Merge queue)]
  H --> I((Merged))
  D -.-> G
''',
  ),
  (
    'Flowchart (LR)',
    '''
flowchart LR
  Idea -- draft --> Plan
  Plan == approved ==> Build
  Build --> Test
  Test -->|fail| Build
  Test -->|pass| Ship
''',
  ),
  (
    'Sequence diagram',
    '''
sequenceDiagram
  autonumber
  actor Dev
  participant CC as Control Center
  participant GH as GitHub
  Dev->>CC: open PR review
  CC->>+GH: fetch diff
  GH-->>-CC: files + comments
  loop each file
    CC->>CC: highlight + word-diff
  end
  alt approved
    CC->>GH: submit review
  else changes requested
    CC->>GH: post comments
  end
  Note over Dev,CC: review lands in the inbox
''',
  ),
  (
    'State diagram',
    '''
stateDiagram-v2
  [*] --> Queued
  Queued --> Running: lease
  Running --> Blocked: needs approval
  Blocked --> Running: approved
  Running --> Done
  Running --> Failed: error
  Failed --> Queued: retry
  Done --> [*]
  note right of Blocked : waits on a human
''',
  ),
  (
    'Class diagram',
    '''
classDiagram
  class Principal {
    <<interface>>
    +String id
    +String displayName
  }
  Principal <|-- UserPrincipal
  Principal <|-- AgentPrincipal
  UserPrincipal "1" --> "0..*" Device : registers
  AgentPrincipal --> Workspace : belongs to
  class Workspace {
    +String id
    +String name
    +members()
  }
''',
  ),
  (
    'ER diagram',
    '''
erDiagram
  WORKSPACE ||--o{ AGENT : hosts
  WORKSPACE ||--|{ CHANNEL : contains
  AGENT ||--o{ RUN_LOG : writes
  AGENT {
    string id
    string name
    string role
  }
''',
  ),
  (
    'Pie chart',
    '''
pie title Review time by axis
  "Correctness" : 42
  "Tests" : 23
  "Style" : 18
  "Docs" : 9
  "Other" : 8
''',
  ),
  (
    'Timeline',
    '''
timeline
  title Release history
  section Alpha
    v0.1 : first worktree : agent runs
    v0.2 : PR review
  section Beta
    v0.3 : meetings : calendar
    v0.4 : fleet workers
''',
  ),
];

CcMermaidStyle _galleryMermaidStyle(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return CcMermaidStyle(
    label: TextStyle(fontSize: 12.5, color: t.textPrimary, height: 1.25),
    compartment: TextStyle(
      fontFamily: 'monospace',
      fontSize: 11.5,
      color: t.textSecondary,
    ),
    nodeFill: t.surface,
    nodeBorder: t.borderPrimary,
    accent: t.textTertiary,
    clusterFill: t.bgTertiary,
    clusterBorder: t.borderSecondary,
    noteFill: t.bgTertiary,
    noteBorder: t.borderSecondary,
    edgeColor: t.textTertiary,
    edgeLabelFill: t.bgSecondary,
    activationFill: t.bgQuaternary,
    frameFill: t.bgTertiary,
    frameBorder: t.borderSecondary,
    dividerColor: t.borderSecondary,
    mutedTextColor: t.textTertiary,
    background: t.bgSecondary,
  );
}

/// Every mermaid dialect the engine draws, in one scroll — the reference for
/// checking a shape, a marker, or a theme change at a glance.
@widgetbook.UseCase(name: 'Mermaid diagrams', type: CcMermaidView, path: _path)
Widget ccMermaidUseCase(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final style = _galleryMermaidStyle(context);
  return Center(
    child: SizedBox(
      width: 760,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (title, source) in _mermaidSamples) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.textTertiary,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: t.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.borderSecondary),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: CcMermaidView(source: source, style: style),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    ),
  );
}

/// The same fence inside a markdown document, so the block spacing and the
/// engine's fallback path can be checked in context.
@widgetbook.UseCase(name: 'Mermaid in markdown', type: CcMarkdown, path: _path)
Widget ccMermaidInMarkdownUseCase(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 640,
      child: SingleChildScrollView(
        child: CcMarkdown(
          data:
              '''
## Deployment flow

```mermaid
${_mermaidSamples.first.$2.trim()}
```

An unsupported dialect degrades to its source:

```mermaid
gantt
  title Not drawn
  section A
  task :a1, 2024-01-01, 30d
```
''',
          selectable: true,
          style: _galleryStyle(
            context,
          ).copyWith(mermaid: _galleryMermaidStyle(context)),
        ),
      ),
    ),
  );
}

/// A timer-driven streaming demo: deltas append into [CcStreamingMarkdown] to
/// mimic an LLM response, with a restart button.
@widgetbook.UseCase(name: 'Streaming', type: CcStreamingMarkdown, path: _path)
Widget ccMarkdownStreamingUseCase(BuildContext context) {
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
    final full = _kitchenSink;
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
                style: _galleryStyle(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
