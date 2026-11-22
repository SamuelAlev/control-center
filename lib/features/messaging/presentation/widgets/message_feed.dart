import 'dart:async';
import 'dart:math' as math;

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_outline_entry.dart';
import 'package:cc_markdown/cc_markdown.dart' show CcSelectionScope;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/day_separator.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/message_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_plan.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/anchor_follow_physics.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_height_cache.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_height_sweep.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_helpers.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_items.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_placeholder_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_row_geometry.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_rows.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_text_measure.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_timeline.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_turn_row_views.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_turn_state.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/jump_to_latest.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/list_extent_sync.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/row_extent_estimate.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/unread_divider.dart';
import 'package:control_center/features/messaging/providers/live_turn_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

part 'message_feed_anchor.dart';
part 'message_feed_build.dart';
part 'message_feed_heights.dart';
part 'message_feed_history.dart';
part 'message_feed_navigation.dart';
part 'message_feed_precalc.dart';
part 'message_feed_rows.dart';
part 'message_feed_scrolling.dart';
part 'message_feed_turns.dart';
part 'message_feed_window.dart';

/// How far below the viewport top a freshly anchored turn lands, leaving the
/// previous turn peeking into view so the reader keeps the prior context.
const double kPreviousTurnPeek = 64;
const double _bottomThreshold = kFollowPinThreshold;

/// How long the feed must be still — no window emission, no scroll — before it
/// starts measuring row extents.
const Duration _precalcIdleDelay = Duration(milliseconds: 700);

/// Scrollable feed of space messages — windowed (newest-N + load-older),
/// rendered bottom-up via a reverse list so follow-bottom and streaming growth
/// stay anchored without scroll jumps.
///
/// Follow behavior implements the message-scroller model: the live edge is
/// followed while the reader is on it — including across their own sends — and
/// any interaction releases following. A reader browsing history is held in
/// place as turns land below the fold.
///
/// Opening the chat — and returning to it after the pane was hidden — lands on
/// the live edge instantly: no scroll animation, no anchor hunt, the newest
/// message on screen. The unread divider still marks where the reader left off,
/// up in the scrollback, but it is never scrolled to.
class SpaceMessageFeed extends ConsumerStatefulWidget {
  /// Creates a new [SpaceMessageFeed].
  const SpaceMessageFeed({
    super.key,
    required this.spaceId,
    required this.conversationId,
    this.onStartThread,
    this.onOpenThread,
  });

  /// Space to display messages for.
  final String spaceId;

  /// The conversation (stream) inside the space to display.
  final String conversationId;

  /// "Start thread" affordance on text messages: opens a conversation
  /// anchored to the hovered message. Null hides the affordance.
  final void Function(Message message)? onStartThread;

  /// Opens an existing thread from the "N replies" row under its anchor
  /// message. Null hides that row.
  final void Function(String threadId)? onOpenThread;

  @override
  ConsumerState<SpaceMessageFeed> createState() => _SpaceMessageFeedState();
}

class _SpaceMessageFeedState extends ConsumerState<SpaceMessageFeed> {
  void _set(VoidCallback fn) => setState(fn);

  void _openThread(String threadId) => widget.onOpenThread?.call(threadId);

  final _scrollController = ScrollController();
  final _follow = FollowState();
  final _rowKeys = <String, GlobalKey>{};

  /// Bubble widgets reused when a window emission changes some other row.
  ///
  /// The list builder runs again for every visible index. Returning the same
  /// widget instance is what lets the element skip the update, so a streaming
  /// turn does not re-parse every other bubble in the window.
  final _keptRows = <String, _KeptFeedRow>{};

  /// List extent queries and offscreen-row reveals for deep anchors.
  final _listController = ListController();

  /// Reads where rows are laid out, for the scroll anchor.
  late final _geometry = FeedRowGeometry(_listController);

  /// Row key per list index (reverse order: index 0 is the newest row),
  /// mirrored from the last build. The scroll anchor names a row by key, so it
  /// survives rows landing or leaving around it.
  List<String> _rowKeysByIndex = const [];
  Map<String, int> _indexByRowKey = const {};

  /// [_rowKeysByIndex] with stand-ins marked: the keys list extents are
  /// synced by (see `_mirrorRowKeys`).
  List<String> _slotKeysByIndex = const [];

  /// Whether a post-frame anchor capture is already scheduled.
  bool _anchorCaptureArmed = false;

  /// Refines row extents once the feed is idle, bounded to
  /// [kFeedPrecalcRowBudget] rows. Armed by [_deferPrecalculation].
  final _precalcPolicy = IdlePrecalculationPolicy();

  /// Re-arms [_precalcPolicy] once nothing has moved for
  /// [_precalcIdleDelay].
  Timer? _precalcTimer;

  /// Set when activity lands while [_precalcTimer] is already running, so the
  /// timer re-runs its wait instead of being cancelled and reallocated on
  /// every scroll tick.
  bool _precalcDeferredAgain = false;

  /// The list rows of the window (ascending, oldest→newest): an agent
  /// turn whose transcript is known spans several rows.
  List<FeedRow> _rows = const [];

  /// Per-turn state for every agent turn in the window, shared by the rows a
  /// turn spans.
  final _turns = <String, FeedTurnState>{};

  /// The transcript memo this feed listens to for turns becoming known.
  TranscriptLruCache? _transcriptCache;

  /// Mono font the turn rows render with, read in build.
  String _codeFont = '';

  /// Row heights by row key: what the list is told about rows it has not
  /// laid out.
  late final FeedHeightCache _heights = ref.read(feedHeightCacheProvider);

  /// Text-layout measurement of unmeasured rows while the feed is idle.
  late final FeedHeightSweep _heightSweep = FeedHeightSweep(
    measure: _measureSweepJob,
    onMeasured: _onSweepMeasured,
  );

  /// The chat prose styles, for the sweep. Resolved in build.
  FeedTextMeasurer? _measurer;

  /// What each row's height depends on (see `_rowRevision`), by row key.
  Map<String, int> _revisionByRowKey = const {};

  bool _didInitialLanding = false;
  bool _cursorSnapshotTaken = false;

  /// Newest rendered message, including completion state: an agent turn keeps
  /// its id and creation time when its final answer arrives.
  Message? _lastNewest;

  /// Snapshot of the last window emission, rendered while the pane is hidden
  /// (all live watches dropped) and, on reveal, until the first fresh
  /// emission — so the tree never collapses to a spinner across a hide/show.
  ({List<Message> messages, bool hasMore})? _frozenWindow;

  /// Whether the pane was visible on the previous build (IndexedStack tab).
  bool _wasVisible = true;

  /// Set on hidden→visible; consumed by [_onWindowChanged] so the first fresh
  /// window after a hidden spell is not mistaken for content the reader
  /// witnessed arriving.
  bool _pendingRevealReconcile = false;
  int _newWhileAway = 0;
  String? _highlightedMessageId;
  String? _highlightedRowKey;

  /// One-shot focus targets this feed has already claimed: a permalink, or
  /// a tool call to show ([_FocusClaims]).
  final _claims = _FocusClaims();

  /// Cutoff the unread divider is drawn against: agent messages created after
  /// it are "new". Seeded from the open-time read cursor when the cursor
  /// snapshot is taken, then advanced past every arrival the reader witnessed —
  /// so a reply they watched land is never "new", while a turn that arrived
  /// during a hidden spell (or below the fold) still is.
  DateTime? _readFrontier;

  String? _lastStampedNewestId;

  Timer? _cursorDebounce;

  /// Newest agent-turn id we last announced as "started", so we announce at
  /// most once per turn.
  String? _announcedStartFor;

  /// Newest agent-turn id we last announced as "finished", so the completion
  /// cue fires once when streaming ends (not on every token flush).
  String? _announcedDoneFor;

  /// Whether the newest agent turn was still streaming on the previous
  /// emission, used to detect the stream→complete transition.
  bool _newestWasStreaming = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _follow.probe = _probeAnchor;
    final transcripts = ref.read(transcriptCacheProvider);
    _transcriptCache = transcripts;
    transcripts.addPutListener(_onTranscriptPut);
    _deferPrecalculation();
  }

  @override
  void dispose() {
    _cursorDebounce?.cancel();
    _highlightTimer?.cancel();
    _precalcTimer?.cancel();
    _recenterTimer?.cancel();
    _transcriptCache?.removePutListener(_onTranscriptPut);
    _heightSweep.dispose();
    for (final turn in _turns.values) {
      turn.live.structure.removeListener(_onTurnStructure);
      turn.dispose();
    }
    _turns.clear();
    _listController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// The in-flight highlight-pulse timer, so a dispose (or a second jump
  /// before the first pulse ends) cancels it rather than leaving it to fire
  /// into a disposed State. The `mounted` guard below made it benign, not
  /// absent — an unreferenced pending timer keeps this State reachable.
  bool _programmatic = false;

  Timer? _highlightTimer;

  /// Whether the viewport is sitting on the live edge right now, independent of
  /// [FollowState.mode]. A permalink open parks the reader in `anchored` mode,
  /// and a space whose content fits the viewport never fires [_onScroll] to
  /// re-engage following — so mode alone reports a reader who is plainly looking
  /// at the newest turn as "away".
  bool get _isAtLiveEdge =>
      _scrollController.hasClients &&
      _scrollController.position.pixels <= _bottomThreshold;

  /// The conversation's outline: every message's size, so the feed lays out
  /// history it has not loaded. Null until it first loads.
  List<ConversationOutlineEntry>? _outline;

  /// Whether the outline could not be read (and none was read before): the
  /// feed then shows the live window alone, with no spinner waiting for it.
  bool _outlineFailed = false;

  /// The message the history range is loaded around, or null when only the
  /// live window is loaded.
  String? _rangeAnchorId;

  /// The loaded history range's messages (ascending). Kept while a new range
  /// loads, so moving the range never flashes stand-ins.
  List<Message>? _range;

  /// The live window's oldest message the outline was last refreshed for, so
  /// an outline that stays out of step is refetched once, not every build.
  String? _outlineRefreshedFor;

  /// Coalesces re-centering the history range while the reader scrolls.
  Timer? _recenterTimer;

  bool _showJumpControl = false;

  @override
  Widget build(BuildContext context) => _buildFeed(context);
}
