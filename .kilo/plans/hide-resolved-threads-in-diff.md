# Hide resolved comment threads in diff (keep gutter avatar)

## Goal

When an inline comment thread is resolved, stop rendering the thread card inside the diff content area. Keep showing the commenter's avatar in the left gutter rail so the user can still see where comments were. Tapping the gutter avatar toggles the thread card open/closed in the diff without changing the resolved status.

## File to change

`lib/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_view.dart`

## Changes

### 1. Track resolved threads separately for the gutter overlay

Add fields to `UnifiedDiffViewState`:

```dart
final _resolvedBySlotKey = <String, PrInlineThread>{};
final _resolvedAnchors = <String, (int, int)>{};
```

### 2. In `_buildSlots()` — conditionally include resolved threads (~line 219–263)

In **Pass A** (line ~219), when `_threadAnchoredAt` returns a resolved thread:

- If the thread is the currently focused one (`_focusedThreadId == thread.id`), include it as a normal block/slot (so the card expands inline).
- Otherwise, store it in `_resolvedBySlotKey` / `_resolvedAnchors` for gutter-only avatar rendering.

```dart
if (thread != null) {
  if (thread.resolved && _focusedThreadId != thread.id) {
    final key = 'resolved:${thread.id}';
    _resolvedBySlotKey[key] = thread;
    _resolvedAnchors[key] = (f, d);
  } else {
    threadByLine[d] = thread;
    final h = _commentHeights[thread.id] ?? _estimateThreadHeight(thread);
    blocks.add(DiffCommentBlock(key: thread.id, anchorLine: d, height: h));
  }
}
```

This way, tapping a resolved avatar → `_focusThread(id)` sets `_focusedThreadId` → next `_buildSlots()` call creates a slot → the thread card appears. Tapping again → `_focusThreadId` toggles off → slot removed → card disappears.

In **Pass B** (line ~250), the `threadByLine[d]` lookup naturally handles this — resolved-focused threads are in the map, unfocused ones are not.

### 3. Clear resolved tracking at start of `_buildSlots()`

```dart
_resolvedBySlotKey.clear();
_resolvedAnchors.clear();
```

### 4. In `_buildReviewOverlay()` — render avatars for resolved threads (~line 1137)

After the existing avatar loop, add a loop for resolved thread avatars. The tap handler calls `_focusThread(thread.id)` which toggles the thread card open/closed in the diff:

```dart
for (final entry in _resolvedBySlotKey.keys) {
  final thread = _resolvedBySlotKey[entry]!;
  final (fi, dl) = _resolvedAnchors[entry]!;
  if (hover?.$1 == fi && hover?.$2 == dl) continue;
  final y = screenYOfLine(fi, dl);
  if (!visible(y)) continue;
  final author = thread.entries.isNotEmpty ? thread.entries.first : null;
  items.add(Positioned(
    left: rect.left + 3,
    top: y + (kDiffLineHeight - 18) / 2,
    width: 18,
    height: 18,
    child: GestureDetector(
      onTap: () => _focusThread(thread.id),
      child: GitHubUserAvatar(
        login: author?.author ?? '?',
        avatarUrl: author?.authorAvatarUrl,
        size: 18,
        showHoverCard: false,
      ),
    ),
  ));
}
```

### 5. In `_computeCommentHighlights()` — skip resolved thread highlights (~line 880–894)

For draft threads, skip the yellow highlight when resolved and not focused:

```dart
final draft = ctl?.forAnchor(filePath: filename, line: lineNo, side: side);
if (draft != null && !(draft.resolved && _focusedThreadId != draft.id)) {
  // ... existing highlight logic unchanged
}
```

Server-synthesized threads are always `resolved: false`, so no change needed for the `serverByAnchor` branch.

### 6. Thread card visual hint for resolved state

When a resolved thread is toggled open via the gutter avatar, the existing `PrInlineThreadBlock` already shows a green `checkCircle2` icon and hides suggestion actions. No changes needed — the card already communicates "resolved" visually.

## Summary

| Area | Unresolved | Resolved (collapsed) | Resolved (tapped/expanded) |
|---|---|---|---|
| Gutter avatar | Shown | Shown | Shown |
| Thread card in diff | Shown | Hidden | Shown |
| Yellow highlight on code | Shown | Hidden | Shown (active) |
| Tap gutter avatar | Focus thread | Expand thread card | Collapse thread card |

All changes in a single file: `unified_diff_view.dart`. No new files, widgets, or architecture changes.
