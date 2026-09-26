# Unified PR diff renderer

`PrDiffView` hosts `UnifiedDiffView` inside the PR detail screen's **single** `CustomScrollView`, below the pinned tab strip. One `RenderUnifiedDiffSliver` paints only visible code rows to canvas; rare interactive rows (file headers, expandable gaps, threads, composers and Markdown previews) are sparse `DiffSlot` widget children. This avoids per-file widget churn at up to 3000 files, blank rows on fast scrollbar jumps and drifting scroll extents.

## Parts and invariants

| File | Responsibility |
| --- | --- |
| `pr_diff_document.dart`, `diff_fenwick.dart` | Flat per-file rows and a Fenwick tree over file heights. `offsetOf`, `indexAtOffset` and total extent use the same source. |
| `diff_structure_store.dart` | Synchronously builds and retains plain-text structure; lazily requests syntax tokens from an isolate worker for the visible range. |
| `unified_diff_sliver.dart`, `unified_row_painter.dart` | Exact sliver geometry, visible canvas rows, sticky header, gutter, search/selection/comment highlights and `(file,line)` text cache. |
| `diff_slot.dart`, `measured_inline_thread.dart` | Sparse widgets; thread/composer height reports reserve actual space in the document. |
| `unified_diff_view.dart`, `file_header.dart` | Integration, state, overlays, expansion, viewed state, search and keyboard navigation. |

`DiffWorkerPool` (`../../../utils/diff_isolate_worker.dart`) handles per-hunk tokenization off-thread and caches by theme revision; grammar state carries across lines. `buildDiffRawLines` creates structure synchronously on the main isolate. Patches arrive inline with paged PR files and are cached by the repository. Initially expanded files parse before first layout, while large files auto-collapse. Plain text must remain paintable before tokens arrive; token completion requests **repaint only**, not relayout/rebuild.

Maintain these constraints when changing rows:

- The Fenwick total is the **only** scroll-extent authority. Expand/collapse, gap splices and measured comments update per-file heights through `PrDiffDocument`; never estimate extent elsewhere. Slot offsets are built after comment heights are reserved. A scrollbar jump must find visible slots by offset rather than hydrate intervening files.
- Token indices refer to **raw** lines. `displayToRaw` skips `@@` headers; the trailing end-of-file gap follows all real rows so earlier indices remain stable. Gap splices shift raw indices and must clear the `(file,line)` painter cache; theme changes clear it too.
- `HeightReporter` must report subsequent child growth (e.g. opening replies), not just initial build. Defer height feedback to a post-frame callback; do not mutate layout/document state during paint or layout.
- The sticky file header pins below the tab strip using `topInset`. The document-to-screen conversion for floating overlays belongs in the **view's** scrollable context: `screenY = viewportTop + precedingScrollExtent + lineDocumentOffset - scrollPixels`. Mapping through a render sliver inside `SliverMainAxisGroup` displaced affordances offscreen. Clamp them below pinned chrome; `geometryListenable` updates post-frame.
- Painted content must track scrolling pixel-for-pixel (including persistent comment highlights); hover tools, avatars and selection toolbar belong in the root `Overlay`. Keep hover/click highlight changes paint-only rather than rebuilding all highlights per pointer movement.

## Selection and review behavior

Mouse-drag selection in unified mode is character-precise across rows/files. The painter renders **real source whitespace** (tabs expanded for layout) and decorates it with `→`/`·` hints; `PrDiffDocument.copyTextBetween` copies raw marker-free source with original spaces/tabs. Share measured mono advance between hit testing and painter highlight. Use mouse-only pan recognition so wheel/trackpad scrolling and gutter comment taps continue to work. Split mode paints side-by-side but its review affordances and character-column mapping are not enabled; split selection is line-granular. Custom selection supports drag and ⌘C/Ctrl+C, not Flutter `SelectionArea` keyboard Select All or context-menu Copy.

The file tree can jump to files; `j`/`k` navigate files, `c` collapses, `v` marks viewed and ⌘F searches across files. Gutter tap/drag creates single-line/range comments; selection opens a floating toolbar. Inline composers are measured slots, including fenced `suggestion` replacement text. Shared `../../utils/server_review_threads.dart` assembles replies into conversations by **root** `in_reply_to_id`, used by both this renderer and the Overview timeline; replies route through `PrInlineCommentsController.replyTo` with the root id. Resolved threads start collapsed; deliberate overrides and optimistic resolve state last until the server stream agrees. Batched comments queue into **one** review on submission, unlike immediate single comments. GitHub suggestion acceptance currently records local applied state; forge suggestions are comments, not patches. GitLab/Bitbucket resolution remains local. Outdated conversations remain readable in the Overview timeline even if the changed line no longer anchors here.
