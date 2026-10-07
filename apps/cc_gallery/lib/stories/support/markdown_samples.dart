import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

// Shared fixtures for the cc_markdown stories (CcMarkdown, CcMermaidView,
// CcStreamingMarkdown). The gallery builds its own styles from cc_ui tokens: it
// cannot import the host app's `appMarkdownStyle`.

/// A document exercising every core markdown block and inline.
const markdownKitchenSink = '''
# Heading one

A paragraph with **bold**, *italic*, ~~strikethrough~~, `inline code` and a
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

/// The gallery's [CcMarkdownStyle], from cc_ui tokens.
CcMarkdownStyle galleryMarkdownStyle(
  BuildContext context, {
  bool compact = false,
}) {
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

/// One sample per mermaid dialect the engine draws: `(title, source)`.
const mermaidSamples = <(String, String)>[
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

/// The gallery's [CcMermaidStyle], from cc_ui tokens.
CcMermaidStyle galleryMermaidStyle(BuildContext context) {
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
