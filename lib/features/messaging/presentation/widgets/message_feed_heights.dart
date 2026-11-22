part of 'message_feed.dart';

/// The feed's height model, after Delta's: what the list knows about rows it
/// has not laid out.
///
/// Heights are kept by row key, not list index, in [FeedHeightCache], so they
/// survive rows landing, the window growing and the pane being hidden. Three
/// sources, best first: the extent a row had when it was last laid out; a
/// text-layout estimate the idle sweep computed (prose measured with the real
/// chat styles, no widgets built); and the character-count heuristic. A wrong
/// number only moves the scrollbar thumb — what is drawn is always laid out
/// for real — and the scroll anchor keeps the reader still when a better
/// number replaces a worse one.
extension _HeightMethods on _SpaceMessageFeedState {
  /// What a row's height depends on, folded into one number. A cached height
  /// is only reused while this is unchanged.
  int _rowRevision(FeedRow row) => switch (row) {
    ItemRow(:final item) => switch (item) {
      MessageItem() => Object.hash(
        _messageRevision(item.message),
        item.collapseHeader,
        item.canRetry,
        Object.hashAll(item.inlineMessages.map(_messageRevision)),
      ),
      DayItem() => 0,
      UnreadItem(:final count) => count ?? 0,
    },
    TurnHeadRow(:final item) => Object.hash(
      item.collapseHeader,
      item.message.metadata?['inReplyToAgentName'],
    ),
    TurnPartRow(:final plan, :final isFirst, :final segments) => Object.hash(
      isFirst,
      plan.gapBefore,
      _planRevision(plan),
      _nestedRevision(plan, segments),
    ),
    TurnFootRow(:final item) => Object.hash(
      _messageRevision(item.message),
      item.canRetry,
    ),
    // Its own revision space: a stand-in's height is never mistaken for the
    // loaded message's, though both rows share the key `m:<id>`.
    PlaceholderRow(:final entry) => Object.hash(
      #placeholder,
      entry.revision,
      entry.contentChars,
    ),
  };

  static int _messageRevision(Message m) => Object.hash(
    m.content.length,
    m.isStreamingComplete,
    m.turnOutcome,
    m.metadata?['segment_count'],
    m.metadata?['error'],
    m.metadata?['retried'],
  );

  /// A script row's height follows the calls folded into it: how many there
  /// are and how each stands.
  static int _nestedRevision(
    TranscriptRowPlan plan,
    List<TranscriptSegment> segments,
  ) => switch (plan) {
    SegmentRowPlan(:final children) when children.isNotEmpty => Object.hashAll([
      for (final i in children)
        if (i < segments.length)
          if (segments[i] case ToolSegment(:final status)) status,
    ]),
    _ => 0,
  };

  static int _planRevision(TranscriptRowPlan plan) => switch (plan) {
    SegmentRowPlan(:final segment, :final open) => Object.hash(
      open,
      switch (segment) {
        TextSegment(:final text) => text.length,
        ReasoningSegment(:final text, :final durationMs) => Object.hash(
          text.length,
          durationMs == null,
        ),
        ToolSegment(:final status, :final outputs) => Object.hash(
          status,
          outputs.length,
        ),
        ErrorSegment(:final message) => message.length,
        ViolationSegment(:final message) => message.length,
      },
    ),
    InlineMessageRowPlan(:final message) => _messageRevision(message),
    LiveStatusRowPlan() => 1,
  };

  double _columnWidthFor(double crossAxisExtent) =>
      math.min(conversationColumnWidth, math.max(160.0, crossAxisExtent - 32));

  /// Extent of the row at reverse [index] for a list that has not laid it
  /// out: measured, else text-measured, else the heuristic.
  double _estimateRowExtent(int? index, double crossAxisExtent) {
    if (index == null) {
      return kUnknownRowExtent;
    }
    final i = _rows.length - 1 - index;
    if (i < 0 || i >= _rows.length) {
      return kUnknownRowExtent;
    }
    final row = _rows[i];
    final key = row.key;
    if (row is PlaceholderRow) {
      return _heights.lastMeasured(key, width: crossAxisExtent) ??
          estimateFeedRowExtent(
            row,
            columnWidth: _columnWidthFor(crossAxisExtent),
          );
    }
    final revision = _revisionByRowKey[key] ?? _rowRevision(row);
    return _heights.measured(key, width: crossAxisExtent, revision: revision) ??
        _heights.estimated(key, width: crossAxisExtent, revision: revision) ??
        estimateFeedRowExtent(
          row,
          columnWidth: _columnWidthFor(crossAxisExtent),
        );
  }

  /// Remembers the real extent of every row the list has measured: the laid
  /// out ones, and the ones its idle precalculation built.
  void _recordMeasuredHeights() {
    if (!_listController.isAttached) {
      return;
    }
    final width = _geometry.crossAxisExtent;
    if (width == null) {
      return;
    }
    final count = math.min(
      _listController.numberOfItems,
      _rowKeysByIndex.length,
    );
    for (var index = 0; index < count; index++) {
      final (extent, estimated) = _listController.extentForIndex(index);
      if (estimated) {
        continue;
      }
      final key = _rowKeysByIndex[index];
      final revision = _revisionByRowKey[key];
      if (revision == null) {
        continue;
      }
      _heights.recordMeasured(key, extent, width: width, revision: revision);
    }
  }

  /// Queues text measurement for every row nothing better is known about,
  /// nearest the viewport first. Runs only while the feed is idle.
  void _scheduleHeightSweep() {
    if (!_listController.isAttached || _listController.isLocked) {
      return;
    }
    final width = _geometry.crossAxisExtent;
    if (width == null) {
      return;
    }
    _recordMeasuredHeights();
    final visible = _listController.visibleRange;
    final center = visible == null ? 0 : (visible.$1 + visible.$2) ~/ 2;
    final jobs = <(int, SweepJob)>[];
    for (var index = 0; index < _rowKeysByIndex.length; index++) {
      final i = _rows.length - 1 - index;
      if (i < 0) {
        continue;
      }
      final row = _rows[i];
      if (row is PlaceholderRow) {
        continue;
      }
      final key = row.key;
      final revision = _revisionByRowKey[key] ?? 0;
      if (_heights.measured(key, width: width, revision: revision) != null ||
          _heights.estimated(key, width: width, revision: revision) != null) {
        continue;
      }
      jobs.add((
        (index - center).abs(),
        SweepJob(key: key, revision: revision, width: width, payload: row),
      ));
    }
    jobs.sort((a, b) => a.$1.compareTo(b.$1));
    _heightSweep.schedule([for (final job in jobs) job.$2]);
    _heightSweep.resume();
  }

  /// Text-layout height of one row, without building it.
  double? _measureSweepJob(SweepJob job) {
    final row = job.payload;
    final measurer = _measurer;
    if (row is! FeedRow || measurer == null) {
      return null;
    }
    return estimateFeedRowExtent(
      row,
      columnWidth: _columnWidthFor(job.width),
      prose: measurer.proseHeight,
    );
  }

  /// Stores a swept height and hands it to the list in place of its guess.
  ///
  /// The list only asks for an estimate when a row is inserted, so a better
  /// estimate goes in as a remove + add at the same index. Rows the list has
  /// measured for real are left alone.
  void _onSweepMeasured(SweepJob job, double extent) {
    _heights.recordEstimated(
      job.key,
      extent,
      width: job.width,
      revision: job.revision,
    );
    final index = _indexByRowKey[job.key];
    if (index == null ||
        !_listController.isAttached ||
        _listController.isLocked ||
        index >= _listController.numberOfItems) {
      return;
    }
    final (_, estimated) = _listController.extentForIndex(index);
    if (!estimated) {
      return;
    }
    _listController
      ..removeItem(index)
      ..addItem(index);
  }
}
