import 'package:cc_domain/core/domain/entities/agent_run_log.dart';

/// How the token-activity grid values each day.
enum UsageActivityMode {
  /// Each cell carries its own day's token total.
  daily,

  /// Each cell carries the total of the ISO week its column covers, so a
  /// whole column reads as one figure.
  weekly,

  /// Each cell carries the running total from the grid's first day through
  /// that day, so the grid reads as growth rather than as rhythm.
  cumulative,
}

/// One calendar day of token usage, floored to local midnight.
class UsageDay {
  /// Creates a [UsageDay].
  const UsageDay({required this.day, required this.tokens, required this.runs});

  /// The local-midnight-floored day this total covers.
  final DateTime day;

  /// Total tokens across all five usage axes for the runs that started on
  /// [day].
  final int tokens;

  /// Number of runs that started on [day].
  final int runs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageDay &&
          day == other.day &&
          tokens == other.tokens &&
          runs == other.runs;

  @override
  int get hashCode => Object.hash(day, tokens, runs);
}

/// The headline figures above the token-activity grid.
class UsageSummary {
  /// Creates a [UsageSummary].
  const UsageSummary({
    required this.totalTokens,
    required this.peakDayTokens,
    required this.longestSessionMs,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.activeDays,
  });

  /// A fully zeroed summary, used when there are no runs to aggregate.
  static const empty = UsageSummary(
    totalTokens: 0,
    peakDayTokens: 0,
    longestSessionMs: 0,
    currentStreakDays: 0,
    longestStreakDays: 0,
    activeDays: 0,
  );

  /// Total tokens across all five usage axes over every run considered.
  final int totalTokens;

  /// The largest single-day token total.
  final int peakDayTokens;

  /// The longest single run's wall-clock duration in milliseconds; `0` when no
  /// run recorded one.
  final int longestSessionMs;

  /// Consecutive days with at least one token, counting back from today. A
  /// day with no activity yet does not break the streak — the walk starts at
  /// today and falls back to yesterday — so the figure cannot flicker to zero
  /// each midnight and recover at the first run.
  final int currentStreakDays;

  /// The longest run of consecutive active days anywhere in the window.
  final int longestStreakDays;

  /// Number of distinct days carrying at least one token.
  final int activeDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageSummary &&
          totalTokens == other.totalTokens &&
          peakDayTokens == other.peakDayTokens &&
          longestSessionMs == other.longestSessionMs &&
          currentStreakDays == other.currentStreakDays &&
          longestStreakDays == other.longestStreakDays &&
          activeDays == other.activeDays;

  @override
  int get hashCode => Object.hashAll([
    totalTokens,
    peakDayTokens,
    longestSessionMs,
    currentStreakDays,
    longestStreakDays,
    activeDays,
  ]);
}

/// One cell of the token-activity grid.
class UsageActivityCell {
  /// Creates a [UsageActivityCell].
  const UsageActivityCell({
    required this.day,
    required this.value,
    required this.level,
  });

  /// The local-midnight-floored day this cell represents.
  final DateTime day;

  /// The cell's value under the active [UsageActivityMode].
  final int value;

  /// Intensity bucket, `0` (no activity) through `4` (densest). Always paired
  /// with a text figure in the UI — the grid never reports by color alone.
  final int level;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageActivityCell &&
          day == other.day &&
          value == other.value &&
          level == other.level;

  @override
  int get hashCode => Object.hash(day, value, level);
}

/// A month label anchored to the grid column its month opens in.
class UsageMonthLabel {
  /// Creates a [UsageMonthLabel].
  const UsageMonthLabel({required this.column, required this.monthStart});

  /// Index into [UsageActivityGrid.weeks] this label sits under.
  final int column;

  /// The first day of the labelled month.
  final DateTime monthStart;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageMonthLabel &&
          column == other.column &&
          monthStart == other.monthStart;

  @override
  int get hashCode => Object.hash(column, monthStart);
}

/// The token-activity grid: one column per ISO week (Monday-first), each
/// holding seven day slots. A slot is `null` where the week extends past the
/// grid's last day, so the final column can be partly empty without the
/// renderer inventing future days.
class UsageActivityGrid {
  /// Creates a [UsageActivityGrid].
  const UsageActivityGrid({
    required this.weeks,
    required this.monthLabels,
    required this.maxValue,
    required this.mode,
  });

  /// An empty grid, used when there is nothing to plot.
  static const empty = UsageActivityGrid(
    weeks: [],
    monthLabels: [],
    maxValue: 0,
    mode: UsageActivityMode.daily,
  );

  /// Columns of seven day slots, ascending; `null` marks a slot past the last
  /// day.
  final List<List<UsageActivityCell?>> weeks;

  /// Month labels with the column each one opens in.
  final List<UsageMonthLabel> monthLabels;

  /// The largest cell value in the grid; `0` when every cell is empty.
  final int maxValue;

  /// The mode the cell values were computed under.
  final UsageActivityMode mode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageActivityGrid &&
          _weeksEqual(weeks, other.weeks) &&
          _listEquals(monthLabels, other.monthLabels) &&
          maxValue == other.maxValue &&
          mode == other.mode;

  @override
  int get hashCode => Object.hash(
    Object.hashAll([for (final week in weeks) Object.hashAll(week)]),
    Object.hashAll(monthLabels),
    maxValue,
    mode,
  );
}

/// Tokens attributed to one model over the window.
class UsageModelSlice {
  /// Creates a [UsageModelSlice].
  const UsageModelSlice({
    required this.model,
    required this.tokens,
    required this.runs,
    required this.share,
  });

  /// The model key (`modelId`, falling back to `adapter`).
  final String model;

  /// Total tokens across all five axes attributed to [model].
  final int tokens;

  /// Runs attributed to [model].
  final int runs;

  /// [tokens] as a fraction of the window total; `0` when the total is zero.
  final double share;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageModelSlice &&
          model == other.model &&
          tokens == other.tokens &&
          runs == other.runs &&
          share == other.share;

  @override
  int get hashCode => Object.hash(model, tokens, runs, share);
}

/// One model's daily token series over the trend window.
class UsageTrendSeries {
  /// Creates a [UsageTrendSeries].
  const UsageTrendSeries({required this.model, required this.points});

  /// The model key this series plots.
  final String model;

  /// One entry per day in the window, ascending and dense — days with no
  /// activity carry a zero rather than being omitted, so the line stays
  /// continuous and the x-axis stays evenly spaced.
  final List<UsageDay> points;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageTrendSeries &&
          model == other.model &&
          _listEquals(points, other.points);

  @override
  int get hashCode => Object.hash(model, Object.hashAll(points));
}

/// Computes the Usage surfaces — daily totals, the headline summary, the
/// token-activity grid, the per-model split and the per-model trend — over a
/// collection of [AgentRunLog]s, with no infrastructure dependencies.
///
/// Every figure is derived from each run's `cost.totalTokens` (all five usage
/// axes) and its local-time `startedAt`.
class UsageStatsCalculator {
  /// Creates a [UsageStatsCalculator].
  const UsageStatsCalculator();

  /// How many days the token-activity grid spans, inclusive of today.
  static const int activityWindowDays = 364;

  /// The model key a run is attributed to, falling back through `adapter` to
  /// [unknownModel] so a run with neither still lands in exactly one bucket.
  static String modelKeyOf(AgentRunLog run) {
    final modelId = run.modelId;
    if (modelId != null && modelId.isNotEmpty) {
      return modelId;
    }
    final adapter = run.adapter;
    if (adapter != null && adapter.isNotEmpty) {
      return adapter;
    }
    return unknownModel;
  }

  /// The bucket for runs that name neither a model nor an adapter.
  static const String unknownModel = '—';

  /// Floors [t] to local midnight.
  static DateTime floorToDay(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Floors [t] to the Monday of its ISO week, at local midnight.
  static DateTime floorToWeek(DateTime t) {
    final day = floorToDay(t);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// Total tokens per calendar day, ascending. Days with no runs are omitted;
  /// use [denseDailyTotals] when a gap-free axis is needed.
  List<UsageDay> dailyTotals(Iterable<AgentRunLog> runs) {
    final tokens = <DateTime, int>{};
    final counts = <DateTime, int>{};
    for (final run in runs) {
      final day = floorToDay(run.startedAt);
      tokens.update(
        day,
        (v) => v + run.cost.totalTokens,
        ifAbsent: () => run.cost.totalTokens,
      );
      counts.update(day, (v) => v + 1, ifAbsent: () => 1);
    }
    final days = tokens.keys.toList()..sort();
    return [
      for (final day in days)
        UsageDay(day: day, tokens: tokens[day]!, runs: counts[day]!),
    ];
  }

  /// Total tokens for every day from [start] through [end] inclusive, with
  /// zero-filled gaps so a chart's x-axis stays evenly spaced.
  List<UsageDay> denseDailyTotals(
    Iterable<AgentRunLog> runs, {
    required DateTime start,
    required DateTime end,
  }) {
    final sparse = {for (final entry in dailyTotals(runs)) entry.day: entry};
    return [
      for (final day in _eachDay(floorToDay(start), floorToDay(end)))
        sparse[day] ?? UsageDay(day: day, tokens: 0, runs: 0),
    ];
  }

  /// The headline figures over [runs], with streaks measured relative to
  /// [today] (floored internally, so a caller may pass `DateTime.now()`).
  UsageSummary summarize(
    Iterable<AgentRunLog> runs, {
    required DateTime today,
  }) {
    final daily = dailyTotals(runs);
    if (daily.isEmpty) {
      return UsageSummary.empty;
    }

    var totalTokens = 0;
    var peakDayTokens = 0;
    var activeDays = 0;
    for (final entry in daily) {
      totalTokens += entry.tokens;
      if (entry.tokens > peakDayTokens) {
        peakDayTokens = entry.tokens;
      }
      if (entry.tokens > 0) {
        activeDays++;
      }
    }

    var longestSessionMs = 0;
    for (final run in runs) {
      final duration = run.cost.durationMs;
      if (duration != null && duration > longestSessionMs) {
        longestSessionMs = duration;
      }
    }

    final active = {
      for (final entry in daily)
        if (entry.tokens > 0) entry.day,
    };

    return UsageSummary(
      totalTokens: totalTokens,
      peakDayTokens: peakDayTokens,
      longestSessionMs: longestSessionMs,
      currentStreakDays: _currentStreak(active, floorToDay(today)),
      longestStreakDays: _longestStreak(active),
      activeDays: activeDays,
    );
  }

  /// Builds the token-activity grid ending on [today] and covering the
  /// trailing [activityWindowDays] days, extended back to a Monday so every
  /// column is a whole ISO week.
  UsageActivityGrid activityGrid(
    Iterable<AgentRunLog> runs, {
    required DateTime today,
    required UsageActivityMode mode,
  }) {
    final end = floorToDay(today);
    final gridStart = floorToWeek(
      end.subtract(const Duration(days: activityWindowDays)),
    );

    final byDay = {
      for (final entry in dailyTotals(runs)) entry.day: entry.tokens,
    };

    // Resolve every day's value under the active mode first, so the level
    // thresholds below are computed against the values actually rendered.
    final values = <DateTime, int>{};
    switch (mode) {
      case UsageActivityMode.daily:
        for (final day in _eachDay(gridStart, end)) {
          values[day] = byDay[day] ?? 0;
        }
      case UsageActivityMode.weekly:
        final weekTotals = <DateTime, int>{};
        for (final day in _eachDay(gridStart, end)) {
          final week = floorToWeek(day);
          weekTotals.update(
            week,
            (v) => v + (byDay[day] ?? 0),
            ifAbsent: () => byDay[day] ?? 0,
          );
        }
        for (final day in _eachDay(gridStart, end)) {
          values[day] = weekTotals[floorToWeek(day)] ?? 0;
        }
      case UsageActivityMode.cumulative:
        var running = 0;
        for (final day in _eachDay(gridStart, end)) {
          running += byDay[day] ?? 0;
          values[day] = running;
        }
    }

    var maxValue = 0;
    for (final value in values.values) {
      if (value > maxValue) {
        maxValue = value;
      }
    }

    final weeks = <List<UsageActivityCell?>>[];
    var cursor = gridStart;
    while (!cursor.isAfter(end)) {
      final column = <UsageActivityCell?>[];
      for (var weekday = 0; weekday < 7; weekday++) {
        final day = cursor.add(Duration(days: weekday));
        if (day.isAfter(end)) {
          column.add(null);
          continue;
        }
        final value = values[day] ?? 0;
        column.add(
          UsageActivityCell(
            day: day,
            value: value,
            level: _levelFor(value, maxValue),
          ),
        );
      }
      weeks.add(column);
      cursor = cursor.add(const Duration(days: 7));
    }

    return UsageActivityGrid(
      weeks: weeks,
      monthLabels: _monthLabels(weeks),
      maxValue: maxValue,
      mode: mode,
    );
  }

  /// The per-model token split over [runs], sorted by tokens descending.
  /// Models contributing no tokens are dropped — a zero slice cannot be drawn
  /// and would only pad the legend.
  List<UsageModelSlice> byModel(Iterable<AgentRunLog> runs) {
    final tokens = <String, int>{};
    final counts = <String, int>{};
    for (final run in runs) {
      final key = modelKeyOf(run);
      tokens.update(
        key,
        (v) => v + run.cost.totalTokens,
        ifAbsent: () => run.cost.totalTokens,
      );
      counts.update(key, (v) => v + 1, ifAbsent: () => 1);
    }

    var total = 0;
    for (final value in tokens.values) {
      total += value;
    }

    final slices =
        [
          for (final entry in tokens.entries)
            if (entry.value > 0)
              UsageModelSlice(
                model: entry.key,
                tokens: entry.value,
                runs: counts[entry.key]!,
                share: total == 0 ? 0 : entry.value / total,
              ),
        ]..sort((a, b) {
          final byTokens = b.tokens.compareTo(a.tokens);
          return byTokens != 0 ? byTokens : a.model.compareTo(b.model);
        });
    return slices;
  }

  /// One dense daily series per model across `[start, end]`, ordered by total
  /// tokens descending and capped at [maxSeries] so the legend stays readable.
  /// Models past the cap are folded into a single [otherModels] series rather
  /// than dropped, so the chart still totals the window.
  List<UsageTrendSeries> trend(
    Iterable<AgentRunLog> runs, {
    required DateTime start,
    required DateTime end,
    int maxSeries = 5,
  }) {
    final ranked = byModel(runs);
    if (ranked.isEmpty) {
      return const [];
    }

    final keep = ranked.take(maxSeries).map((s) => s.model).toSet();
    final hasOverflow = ranked.length > maxSeries;

    final grouped = <String, List<AgentRunLog>>{};
    for (final run in runs) {
      final key = modelKeyOf(run);
      final bucket = keep.contains(key) ? key : otherModels;
      grouped.putIfAbsent(bucket, () => []).add(run);
    }

    final series = <UsageTrendSeries>[
      for (final slice in ranked.take(maxSeries))
        if (grouped.containsKey(slice.model))
          UsageTrendSeries(
            model: slice.model,
            points: denseDailyTotals(
              grouped[slice.model]!,
              start: start,
              end: end,
            ),
          ),
    ];
    if (hasOverflow && grouped.containsKey(otherModels)) {
      series.add(
        UsageTrendSeries(
          model: otherModels,
          points: denseDailyTotals(
            grouped[otherModels]!,
            start: start,
            end: end,
          ),
        ),
      );
    }
    return series;
  }

  /// The bucket every model past the trend's series cap folds into.
  static const String otherModels = 'other';

  /// Consecutive active days ending at [today], tolerating a still-quiet today
  /// by falling back to [today] - 1 as the anchor.
  int _currentStreak(Set<DateTime> active, DateTime today) {
    var anchor = today;
    if (!active.contains(anchor)) {
      anchor = anchor.subtract(const Duration(days: 1));
      if (!active.contains(anchor)) {
        return 0;
      }
    }
    var streak = 0;
    var cursor = anchor;
    while (active.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// The longest run of consecutive active days anywhere in [active].
  int _longestStreak(Set<DateTime> active) {
    if (active.isEmpty) {
      return 0;
    }
    var longest = 0;
    for (final day in active) {
      // Only start counting from the first day of a run, so each run is
      // walked once rather than once per member.
      if (active.contains(day.subtract(const Duration(days: 1)))) {
        continue;
      }
      var length = 0;
      var cursor = day;
      while (active.contains(cursor)) {
        length++;
        cursor = cursor.add(const Duration(days: 1));
      }
      if (length > longest) {
        longest = length;
      }
    }
    return longest;
  }

  /// Buckets [value] into `0` (nothing) or `1`..`4` by quartile of [max].
  static int _levelFor(int value, int max) {
    if (value <= 0 || max <= 0) {
      return 0;
    }
    final fraction = value / max;
    if (fraction <= 0.25) {
      return 1;
    }
    if (fraction <= 0.5) {
      return 2;
    }
    if (fraction <= 0.75) {
      return 3;
    }
    return 4;
  }

  /// A label for every month that opens inside the grid, anchored to the
  /// column holding its first day. The first column is skipped when it only
  /// carries the tail of a month, so a label never sits over a stub.
  static List<UsageMonthLabel> _monthLabels(
    List<List<UsageActivityCell?>> weeks,
  ) {
    final labels = <UsageMonthLabel>[];
    int? lastMonth;
    for (var column = 0; column < weeks.length; column++) {
      final first = weeks[column].whereType<UsageActivityCell>().firstOrNull;
      if (first == null) {
        continue;
      }
      final month = first.day.month;
      if (month == lastMonth) {
        continue;
      }
      lastMonth = month;
      // A month whose first column is its last few days would push its label
      // a full column left of where the block actually starts.
      if (column == 0 && first.day.day > 7) {
        continue;
      }
      labels.add(
        UsageMonthLabel(
          column: column,
          monthStart: DateTime(first.day.year, month),
        ),
      );
    }
    return labels;
  }

  /// Every local-midnight day from [start] through [end] inclusive.
  ///
  /// Steps by adding 24 hours and re-flooring rather than by `Duration`
  /// arithmetic alone: across a DST transition a local day is 23 or 25 hours,
  /// so a naive `add(Duration(days: 1))` drifts off midnight and can repeat or
  /// skip a day.
  static Iterable<DateTime> _eachDay(DateTime start, DateTime end) sync* {
    var cursor = floorToDay(start);
    final last = floorToDay(end);
    while (!cursor.isAfter(last)) {
      yield cursor;
      final next = cursor.add(const Duration(hours: 26));
      cursor = DateTime(next.year, next.month, next.day);
    }
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

bool _weeksEqual(
  List<List<UsageActivityCell?>> a,
  List<List<UsageActivityCell?>> b,
) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (!_listEquals(a[i], b[i])) {
      return false;
    }
  }
  return true;
}
