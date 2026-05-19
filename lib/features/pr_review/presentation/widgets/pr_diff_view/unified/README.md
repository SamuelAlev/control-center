# Unified PR diff renderer

This directory implements the **PR "Files changed" diff viewer** — the thing that
renders every changed file in a pull request as a scrollable, syntax-highlighted,
commentable diff. It is built to stay at a **stable 60 fps with up to 3000 files
and no white space / loading flashes while dragging the scrollbar**, which the
previous per-file widget approach could not guarantee.

> TL;DR: one continuous canvas paints the code; a Fenwick tree gives an exact
> scroll extent; structure is parsed synchronously so there is always something
> to paint; colour fades in off-thread; the few interactive rows (file headers,
> "show N lines" gaps, comment threads) are real widgets hosted as *sparse
> children* of one custom sliver.

---

## Why it's built this way

A naïve "ListView of per-file diff widgets" has three fatal problems at scale:

1. **White space on fast scroll** — each file widget hydrates its diff
   asynchronously, so flinging the scrollbar outruns the work and you see blank
   areas / spinners.
2. **Scrollbar drift** — the total scroll extent is estimated from per-file
   height guesses; as real heights are measured the thumb jumps.
3. **Per-cell churn** — 3000 `StatefulWidget` cells (each with its own painter,
   stream, caches) thrash the framework on a fling.

The unified renderer fixes all three by inverting the model: **one render object
owns the whole PR's row space**, paints only the visible rows directly to a
canvas, and derives an *exact* extent from a Fenwick tree. The expensive part
(syntax colour) is the only thing that's async, and it is never on the critical
path — plain text is always paintable.

---

## How the PR detail screen composes it

```
PullRequestDetailScreen
└─ _PrDetailBody
   └─ CustomScrollView (one PrimaryScrollController + Scrollbar)        ← the only scrollable
      ├─ SliverToBoxAdapter        PR header (scrolls away)
      ├─ SliverPersistentHeader    tab strip (pinned, 44px)            ← StickyHeaderInset(top: 44)
      └─ SliverPadding             active tab body
         └─ FilesTab → PrDiffView
            └─ SliverMainAxisGroup
               ├─ SliverToBoxAdapter   diff toolbar (file count, +/−, split toggle…)
               └─ UnifiedDiffView      ← the diff itself (this directory)
```

`PrDiffView` (`../pr_diff_view.dart`) is a thin shell: it builds the toolbar and
hosts `UnifiedDiffView`, and forwards `jumpToFile(index)` (used by the file-tree
sidebar) to it.

---

## The pieces (this directory)

| File | Responsibility |
|---|---|
| `diff_fenwick.dart` | `DiffFenwickTree` — Fenwick/BIT over per-file heights. O(log n) `offsetOf(file)`, `total`, `indexAtOffset(y)`, O(log n) point `update`. The single source of truth for the scroll extent. |
| `pr_diff_document.dart` | `PrDiffDocument` — the flat per-file model. Owns expanded state, parsed structure, the `displayToRaw` map (drops `@@` hunk headers from rendering), inline-comment layout (`setCommentBlocks` + `commentExtraAbove` prefix sum), and a trailing "show end of file" gap. Answers every offset↔file↔line query. Per-**file** indexing (not per-line) keeps 3000 files at ~3000 Fenwick entries. |
| `diff_structure_store.dart` | `DiffStructureStore` — **structure** (pass-1 parse) is produced *synchronously on demand* on the main isolate and retained, so the painter always has plain text + line numbers (no loading state). **Tokens** (pass-2 syntax colour) are fetched lazily off-thread from the worker pool for the visible window, cached in an LRU, and surfaced via a `repaint` notifier so colour fades in. |
| `unified_row_painter.dart` | `UnifiedRowPainter` — paints **one** diff row (backgrounds, character-precise selection highlight, search highlight, indent guides, code text via a `(file,line)`-keyed `TextPainter` cache, hunk text, pinned gutter + line numbers, word-diff backgrounds). Renders **real** whitespace (tabs expanded to spaces) and paints the `→`/`·` hints as decoration over it, so selected/copied text is genuine source. Plus `kDiffLineHeight` / gutter metrics. |
| `unified_diff_sliver.dart` | `RenderUnifiedDiffSliver` (+ `UnifiedDiffSliver` widget + `UnifiedDiffPaintConfig`) — the heart. A `RenderSliverMultiBoxAdaptor` whose geometry is the Fenwick `total`. It **paints visible code rows** directly, and hosts the sparse interactive rows as **slot children**. Handles the sticky header, the big-scrollbar-jump O(visible) fast path, and drives token fetching from the exact visible range. `isRepaintBoundary` isolates token-fade repaints. |
| `diff_slot.dart` | `DiffSlot` / `DiffSlotKind` — an offset-ordered descriptor of a sparse child (`header` \| `gap` \| `comment` \| `composer` \| `preview`). Code rows are **not** slots (they're painted); only the rare interactive rows are. A `preview` slot is a Markdown file's rendered "rich diff" — it replaces the file's painted body when the per-file Diff/Preview toggle is on. |
| `unified_diff_view.dart` | `UnifiedDiffView` — the integrating widget. Owns the document + store, builds the slot list (memoised by a revision counter), builds each slot's widget (`FastFileHeader`, the `_GapRow`, `MeasuredInlineThread`), and wires expand/collapse, viewed toggle, jump-to-file, gap-expand (fetch + splice), inline comments (draft + synthesised server threads with measured heights), in-diff search (overlay + match highlight), and keyboard nav. |
| `file_header.dart` | `FastFileHeader` (+ `FileHeaderPath`, `LeftTruncatedText`) and the `kFastFileHeaderHeight` / `kPrDiffAutoCollapseThreshold` constants. |
| `measured_inline_thread.dart` | `MeasuredInlineThread` — wraps `PrInlineThreadBlock`, reports its post-layout height back so the document can reserve the exact gap under the anchor row. |

Shared, outside this directory:

- `../../../utils/diff_isolate_worker.dart` — `DiffWorkerPool`: a process-singleton pool of long-lived isolates running the 2-pass pipeline (`parseUnifiedDiff` → `DiffRawLines`, then per-line tokenization via the `highlight` package), with an LRU cache. `buildDiffRawLines` is the shared pass-1 builder used both here and by the main-isolate synchronous parse.
- `../../../utils/diff_parser.dart` — `parseUnifiedDiff`, `DiffLine`/`DiffLineKind`, `DiffToken`, patch extraction.
- `../diff_search_controller.dart`, `../diff_keyboard_handler.dart` — reused as-is (cross-file search + j/k/c/v/⌘F handling).
- `../pr_diff_toolbar.dart`, `../toolbar_chips.dart`, `../commit_range_selector.dart` — the toolbar.
- `../fast_diff_view/worker_pool_indicator.dart` — a debug/breadcrumb indicator for the worker pool (referenced by the shell breadcrumbs).

---

## The rendering pipeline (end to end)

1. **Fetch** — `GitHubPrClient.streamPullRequestFiles` pages all changed files
   (100/page, cap 3000) with the unified-diff **patch inlined** in each file
   record; cached in Drift by the repository. So all patch text is in memory.
2. **Document** — `PrDiffView` → `UnifiedDiffView` builds a `PrDiffDocument`
   from the `PrFile` list. Files over `kPrDiffAutoCollapseThreshold` lines start
   collapsed. Initially-expanded files have their structure parsed up front so
   the extent is exact from frame 1.
3. **Slots** — `UnifiedDiffView._buildSlots` walks the files (memoised by a
   revision counter) and produces the offset-ordered slot list: a header per
   file, a gap affordance per expand-gap row, and a comment block per anchored
   thread. Comment heights are reserved in the document **first** (single pass,
   file order) so slot offsets are exact.
4. **Layout** — `RenderUnifiedDiffSliver.performLayout` sets geometry from the
   Fenwick total, finds the visible slot range by binary search, force-includes
   the sticky file's header slot, lazily creates/garbage-collects slot children,
   and asks the store to fetch tokens for the visible files.
5. **Paint** — paints visible **code rows** straight to the canvas (plain text
   immediately; colour from the token cache when present), then paints the slot
   children on top (sticky header last). The sticky header is pinned just below
   the pinned tab strip (`topInset`), computed with the sliver's screen origin.
6. **Colour fade-in** — token chunks arrive from the worker pool → store bumps
   `repaint` → `markNeedsPaint` (no relayout, no rebuild).

---

## Invariants worth preserving

- **Structure is always synchronous.** `DiffStructureStore.ensureStructure` must
  stay cheap + cache-backed; never make a visible row wait on async structure or
  white space returns.
- **The Fenwick is the only extent authority.** Any per-file height change
  (collapse/expand, measured comment, gap splice) goes through
  `PrDiffDocument` → Fenwick point-update. Never estimate the total elsewhere.
- **Tokens are keyed by raw line index**, `displayToRaw` maps display→raw, and a
  trailing EOF gap is appended *after* all real rows so existing indices — and
  thus the worker's tokens — stay aligned.
- **Comment height feedback must not run during layout/paint.** Measurement
  reports defer via `addPostFrameCallback` → `setState`/revision bump.
- **The `(file,line)` paragraph cache** is invalidated on theme change and after
  a gap splice (`clearLineCache`) because splicing shifts raw indices.

---

## Implemented features

- Single-canvas virtualized rendering; exact scrollbar; 60 fps at 3000 files.
- Synchronous structure → zero white space on scrollbar drag; colour fades in.
- Sticky per-file header (pinned below the tab strip, pushed up by the next file).
- `@@` hunk headers replaced by clickable **"Show N lines" / "Show end of file"**
  gap affordances (real widgets with hover) that fetch + splice context.
- Inline **comments**: draft threads + synthesised server review comments,
  anchored below their line, with reply/resolve, measured heights.
- In-diff **search** (⌘F): cross-file matches, current-match highlight, next/prev.
- **Keyboard**: `j`/`k` step files, `c` collapse/expand, `v` mark viewed, `⌘F`
  search, `Esc` close, `Enter`/`Shift+Enter` next/prev match.
- File-tree **jump-to-file**; per-file viewed toggle; inter-file gap.
- **New comments**: file-level via the header "+" button, and **line-level by
  tapping a code row's gutter** (resolves side + line → composer → create).
- **Text selection + copy** (character-precise): mouse-drag in the code area
  selects a `(file, line, column)` range — sub-line, multi-line, and across
  files — highlighted on the canvas down to the exact column. `⌘C`/`Ctrl+C`
  copies the **raw source** sliced at the precise start/end columns
  (`PrDiffDocument.copyTextBetween`): marker-free, with **real spaces and
  tabs**, never the `→`/`·` hints. This works because the painter now renders
  the *real* whitespace (tabs expanded to spaces so it stays tab-width and
  monospace) and draws the `→`/`·` hints as **decoration on top** — so the
  selectable text is the genuine source, and a display column maps straight
  back to a raw character index (`_displayColToRawCol`). Columns are resolved
  off a measured monospace advance shared by the sliver (hit-testing) and the
  painter (highlight rect). Uses a **mouse-only** `PanGestureRecognizer`, so on
  desktop it never fights scrolling (wheel/trackpad scroll; mouse-drag selects);
  the gutter stays reserved for line-comment taps. (Char-precision applies in
  unified mode; split mode highlights line-granular — its two-column origin
  isn't wired into the column math.)
- **Split (side-by-side) view** (toolbar toggle): deletions/old-numbers on the
  left half, additions/new-numbers on the right, context on both, with a
  divider. Driven by `UnifiedDiffPaintConfig.splitMode`; the painter's
  `hideOldGutter`/`hideNewGutter` size each side's single gutter.

## The review layer (character-based comments + suggestions)

A Pierre-style review layer sits on top of the canvas. Its guiding split:
**painted, scroll-locked things go on the canvas; interactive widgets go in a
root `Overlay`** positioned from the sliver's geometry. A `RenderSliver` can't
host hover or float widgets, so anything that needs either lives in the
overlay; anything that must track the code pixel-for-pixel during a fling is
painted.

- **Selection → floating toolbar.** A text selection drives a dark
  `PrSelectionToolbar` (comment / suggestion / reaction), anchored just below
  the selection's screen rect. The sliver fires `onSelectionChanged`; the
  overlay repositions. A plain click anywhere in the code area (a dedicated tap
  recognizer) — or `Esc` — clears the selection and dismisses the toolbar.
- **Gutter "+" pill (hover + drag).** The overlay hosts a pass-through
  `MouseRegion` that maps the pointer to a row (`rowAtGlobalY`) and draws the
  pill in the rail. Click → comment on that row; vertical drag → select a row
  range (previewed as a live highlight) → composer for the range.
- **Inline composer.** Comment (`PrCommentComposer`) and suggestion
  (`SuggestionComposer` — original read-only deletion row + editable addition
  row) are hosted as a `DiffSlotKind.composer` slot, so they reserve exact
  height through the same measure/Fenwick path as threads. Submitting a
  suggestion wraps the replacement in a ```suggestion fence.
- **Persistent comment highlights** are painted on the **canvas**
  (`DiffCommentHighlight` per `(file, displayLine)`), so they scroll perfectly.
  Char-range anchors highlight only the commented columns; the focused thread
  uses the active (darker) colour. Computed in `_computeCommentHighlights` from
  draft + server threads + the open composer + the pill-drag preview.
- **Commenter avatars** down the left rail are real `GitHubUserAvatar` widgets
  in the overlay (one per visible thread anchor); tapping focuses the thread.
- **Suggestions** render as a mini-diff (`SuggestionAwareMarkdown`) inside the
  thread block, with **Accept & resolve** / **Dismiss** actions.

Coordinate spaces: the overlay maps document space → **global** screen space in
the *view* (which has a `BuildContext`), via the enclosing scrollable's box
(`Scrollable.of(context)` → `localToGlobal`) + the scroll offset +
`precedingScrollExtent` + each line's document offset — i.e. `screenY = vpTop +
preceding + offsetOfLine − pixels`. (We deliberately avoid mapping through the
`RenderSliver`'s own paint transform: it has no `localToGlobal`, and it sits
inside a `SliverMainAxisGroup`, which made `getTransformTo` unreliable —
affordances landed off-screen.) Affordances are clamped below the pinned tab
strip (`topInset`). The overlay rebuilds off the sliver's `geometryListenable`
(bumped **post-frame** after each paint, so it reads settled geometry), plus
`onSelectionChanged` and local hover — one frame behind on fast scroll, which is
fine for these sparse, non-fling affordances.

## Not yet restored (tracked TODOs)

- **Word/double-click selection** and **split-mode** review affordances. Drag
  selection is character-precise in unified mode; double-click-word isn't wired,
  and the toolbar/pill/highlights are gated off in split mode (the per-side
  column origin isn't plumbed into the column math).
- **Comments inbox + "show resolved" toggle + detached-comment indicator** in
  the toolbar. Resolve and accept/dismiss work per-thread; the cross-file
  inbox and resolved-hiding are not yet built.
- **Reactions on existing threads** (chips with counts). The toolbar "react"
  posts a one-emoji comment; wiring the GitHub reactions API onto a thread's
  synced comment (`toggleReviewCommentReaction`) is the follow-up.
- **True suggestion apply** and **server-side resolve/dismiss**. "Accept &
  resolve" records local applied state (GitHub suggestions are comments, not
  patches); dismiss removes drafts locally.
- **System integration of selection** (keyboard-select, context-menu Copy,
  SelectAll) — the selection is custom (mouse-drag + `⌘C`), not a Flutter
  `SelectionArea`.
