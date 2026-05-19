import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

/// One topic column and the fact cards currently shown beneath it.
///
/// A strip is the unit the layout packs. Keeping a topic and its facts in one
/// narrow vertical column is what makes their edges short and vertical instead
/// of a fan across the whole canvas.
class GraphStrip {
  /// Creates a [GraphStrip] for [topicKey] carrying [factKeys].
  const GraphStrip({required this.topicKey, required this.factKeys});

  /// Graph key of the topic node at the head of the strip.
  final String topicKey;

  /// Graph keys of the fact nodes stacked beneath it, top to bottom. Empty
  /// when the topic is collapsed.
  final List<String> factKeys;
}

/// One domain and everything that hangs off it: the cluster the layout treats
/// as a single packable block.
class GraphCluster {
  /// Creates a [GraphCluster] anchored on [domainKey].
  const GraphCluster({
    required this.domainKey,
    required this.strips,
    required this.policyKeys,
  });

  /// Graph key of the domain node that heads the cluster.
  final String domainKey;

  /// The topic strips in the cluster body.
  final List<GraphStrip> strips;

  /// Graph keys of the policies attached to this domain.
  final List<String> policyKeys;

  /// Every node key in this cluster, domain first. Used to draw the cluster's
  /// hull from live node positions.
  Iterable<String> get memberKeys sync* {
    yield domainKey;
    yield* policyKeys;
    for (final strip in strips) {
      yield strip.topicKey;
      yield* strip.factKeys;
    }
  }
}

/// Places the knowledge graph's nodes as a set of per-domain clusters packed to
/// a target aspect ratio.
///
/// ## Why not one flat hierarchy
///
/// This graph used to be three absolute Y bands — domains on one row, topics on
/// the next, facts on the third — with every domain laid side by side along the
/// first row. That is fine for three domains with two topics each and falls
/// apart at real size: a workspace with two domains and 27 topics produced a
/// canvas roughly 5,500 x 450, a 12:1 band. "Fit to view" solves
/// `min(w/W, h/H)`, so it answered ~0.2 and rendered every label at two pixels.
/// Worse, a domain node connected to 27 topics spread over 5,000 points drew 27
/// near-horizontal curves through the same corridor: the "starburst" that graph
/// visualisation literature names as the thing to design away, not to route
/// around.
///
/// So the unit of layout is the CLUSTER, not the row:
///
/// * a domain's topics are packed into a **grid** whose column count targets
///   [targetAspect], not a single row, and each topic's facts stack directly
///   under it ([GraphStrip]) so those edges stay short and vertical;
/// * policies sit beside the domain node in the cluster's header band, where
///   the edge to their domain would be too short to be worth drawing;
/// * the clusters themselves are then shelf-packed, again toward
///   [targetAspect], so eight domains become a block roughly 3 x 3 rather than
///   a line 20,000 points long.
///
/// The target aspect is a CONSTANT rather than the live viewport's, deliberately.
/// Re-flowing on every resize would fight the operator's hand-placed nodes and
/// make the graph jump while a window is being dragged; a fixed landscape
/// target lands close enough on every real panel and keeps the layout a pure
/// function of the data.
class KnowledgeGraphLayout {
  const KnowledgeGraphLayout._();

  /// Horizontal gap between topic strips inside a cluster.
  static const double columnGap = 20;

  /// Vertical gap between strip rows inside a cluster.
  static const double rowGap = 44;

  /// Gap between a topic and its first fact, and between stacked facts.
  static const double factGap = 12;

  /// Gap between a cluster's header band and its topic grid.
  static const double headerGap = 40;

  /// Gap between policy cards in the header band.
  static const double policyGap = 16;

  /// Gap between two packed clusters, horizontally and vertically. Wide enough
  /// that two hulls read as separate regions rather than one field of cards.
  static const double clusterGap = 96;

  /// Inset of the whole graph from the canvas origin.
  static const double origin = 80;

  /// Policies wrap after this many columns so a domain with eight of them does
  /// not stretch its cluster's header past the grid underneath it.
  static const int maxPolicyColumns = 3;

  /// Width-to-height ratio both the per-cluster grid and the cluster packing
  /// aim for. Landscape, because every surface this renders on is.
  static const double targetAspect = 16 / 10;

  /// Computes the top-left offset of every node in [clusters].
  ///
  /// [sizes] must carry the rendered size of every key referenced by
  /// [clusters]; a missing key is treated as zero-sized rather than throwing,
  /// so a node the caller forgot to measure degrades to a stacked position
  /// instead of taking the tab down.
  static Map<String, Offset> compute({
    required List<GraphCluster> clusters,
    required Map<String, Size> sizes,
    double aspect = targetAspect,
  }) {
    if (clusters.isEmpty) {
      return const {};
    }

    final boxes = [
      for (final cluster in clusters) _layoutCluster(cluster, sizes, aspect),
    ];

    final packing = _packBest(boxes, aspect);

    final positions = <String, Offset>{};
    for (var i = 0; i < boxes.length; i++) {
      final at = packing[i];
      boxes[i].local.forEach((key, local) {
        positions[key] = Offset(
          origin + at.dx + local.dx,
          origin + at.dy + local.dy,
        );
      });
    }
    return positions;
  }

  /// Lays one cluster out in its own coordinate space, origin at its top-left.
  ///
  /// Shape: a header band (domain node, then its policies to the right) over a
  /// grid of topic strips, both centred on the cluster's width.
  static _ClusterBox _layoutCluster(
    GraphCluster cluster,
    Map<String, Size> sizes,
    double aspect,
  ) {
    Size sizeOf(String key) => sizes[key] ?? Size.zero;

    final local = <String, Offset>{};
    final domainSize = sizeOf(cluster.domainKey);

    // --- Strip measurements -------------------------------------------------
    final strips = cluster.strips;
    final stripWidths = <double>[];
    final stripHeights = <double>[];
    for (final strip in strips) {
      final topicSize = sizeOf(strip.topicKey);
      var width = topicSize.width;
      var height = topicSize.height;
      for (final factKey in strip.factKeys) {
        final factSize = sizeOf(factKey);
        width = math.max(width, factSize.width);
        height += factGap + factSize.height;
      }
      stripWidths.add(width);
      stripHeights.add(height);
    }

    final count = strips.length;
    var columnWidth = 0.0;
    var heightSum = 0.0;
    for (var i = 0; i < count; i++) {
      columnWidth = math.max(columnWidth, stripWidths[i]);
      heightSum += stripHeights[i];
    }

    // Column count that lands the grid nearest [aspect]: for n cells of
    // (cellW x cellH), cols x cellW / (n / cols x cellH) = aspect solves to
    // cols = sqrt(aspect * n * cellH / cellW).
    var columns = 1;
    if (count > 0 && columnWidth > 0) {
      final cellWidth = columnWidth + columnGap;
      final cellHeight = heightSum / count + rowGap;
      columns = math
          .sqrt(aspect * count * cellHeight / cellWidth)
          .round()
          .clamp(1, count);
    }

    final rows = count == 0 ? 0 : (count / columns).ceil();
    final rowHeights = List<double>.filled(rows, 0);
    for (var i = 0; i < count; i++) {
      final row = i ~/ columns;
      rowHeights[row] = math.max(rowHeights[row], stripHeights[i]);
    }

    final usedColumns = math.min(columns, count);
    final bodyWidth = usedColumns == 0
        ? 0.0
        : usedColumns * columnWidth + (usedColumns - 1) * columnGap;
    var bodyHeight = 0.0;
    for (final height in rowHeights) {
      bodyHeight += height;
    }
    if (rows > 1) {
      bodyHeight += (rows - 1) * rowGap;
    }

    // --- Header band --------------------------------------------------------
    final policyKeys = cluster.policyKeys;
    final policyCount = policyKeys.length;
    final policyColumns = policyCount == 0
        ? 0
        : math.min(policyCount, maxPolicyColumns);
    final policyRows = policyCount == 0
        ? 0
        : (policyCount / policyColumns).ceil();
    var policyWidth = 0.0;
    var policyHeight = 0.0;
    for (final key in policyKeys) {
      final size = sizeOf(key);
      policyWidth = math.max(policyWidth, size.width);
      policyHeight = math.max(policyHeight, size.height);
    }
    final policiesWidth = policyCount == 0
        ? 0.0
        : policyColumns * policyWidth + (policyColumns - 1) * policyGap;
    final policiesHeight = policyCount == 0
        ? 0.0
        : policyRows * policyHeight + (policyRows - 1) * policyGap;

    final headerWidth =
        domainSize.width +
        (policyCount == 0 ? 0.0 : policyGap * 2 + policiesWidth);
    final headerHeight = math.max(domainSize.height, policiesHeight);

    final clusterWidth = math.max(bodyWidth, headerWidth);
    final clusterHeight =
        headerHeight + (count == 0 ? 0.0 : headerGap + bodyHeight);

    // --- Placement ----------------------------------------------------------
    final headerX = (clusterWidth - headerWidth) / 2;
    local[cluster.domainKey] = Offset(
      headerX,
      (headerHeight - domainSize.height) / 2,
    );
    if (policyCount > 0) {
      final firstX = headerX + domainSize.width + policyGap * 2;
      final firstY = (headerHeight - policiesHeight) / 2;
      for (var i = 0; i < policyCount; i++) {
        local[policyKeys[i]] = Offset(
          firstX + (i % policyColumns) * (policyWidth + policyGap),
          firstY + (i ~/ policyColumns) * (policyHeight + policyGap),
        );
      }
    }

    final bodyX = (clusterWidth - bodyWidth) / 2;
    var rowY = headerHeight + headerGap;
    for (var i = 0; i < count; i++) {
      final row = i ~/ columns;
      final column = i % columns;
      if (column == 0 && row > 0) {
        rowY += rowHeights[row - 1] + rowGap;
      }
      final stripX =
          bodyX +
          column * (columnWidth + columnGap) +
          (columnWidth - stripWidths[i]) / 2;

      final strip = strips[i];
      final topicSize = sizeOf(strip.topicKey);
      var y = rowY;
      local[strip.topicKey] = Offset(
        stripX + (stripWidths[i] - topicSize.width) / 2,
        y,
      );
      y += topicSize.height;
      for (final factKey in strip.factKeys) {
        final factSize = sizeOf(factKey);
        y += factGap;
        local[factKey] = Offset(
          stripX + (stripWidths[i] - factSize.width) / 2,
          y,
        );
        y += factSize.height;
      }
    }

    return _ClusterBox(local, Size(clusterWidth, clusterHeight));
  }

  /// Shelf-packs [boxes] and returns each one's top-left offset.
  ///
  /// Shelf packing needs a row width to break on, and the good one depends
  /// entirely on how uneven the clusters are: two clusters of wildly different
  /// size pack better side by side than an area-derived width would suggest.
  /// Rather than guess, this tries every "first row holds the first k clusters"
  /// width plus the area-ideal one and keeps whichever result lands closest to
  /// [aspect]. Cluster counts are domain counts, so the quadratic cost is
  /// nothing.
  static List<Offset> _packBest(List<_ClusterBox> boxes, double aspect) {
    final candidates = <double>[];
    var prefix = 0.0;
    for (var i = 0; i < boxes.length; i++) {
      prefix += boxes[i].size.width + (i > 0 ? clusterGap : 0);
      candidates.add(prefix);
    }
    var area = 0.0;
    for (final box in boxes) {
      area += box.size.width * box.size.height;
    }
    if (area > 0) {
      candidates.add(math.sqrt(area * aspect));
    }

    List<Offset>? best;
    var bestScore = double.infinity;
    for (final width in candidates) {
      final (offsets, size) = _shelfPack(boxes, width);
      if (size.height <= 0 || size.width <= 0) {
        continue;
      }
      // Log-ratio so "twice too wide" and "twice too tall" cost the same.
      final score = (math.log(size.width / size.height) - math.log(aspect))
          .abs();
      if (score < bestScore) {
        bestScore = score;
        best = offsets;
      }
    }
    return best ?? _shelfPack(boxes, double.infinity).$1;
  }

  /// First-fit shelf packing: fill a row left to right until the next cluster
  /// would cross [targetWidth], then start a new row. Rows are centred on the
  /// widest row so the packed block reads as one composition.
  static (List<Offset>, Size) _shelfPack(
    List<_ClusterBox> boxes,
    double targetWidth,
  ) {
    final rows = <List<int>>[];
    var current = <int>[];
    var currentWidth = 0.0;
    for (var i = 0; i < boxes.length; i++) {
      final width = boxes[i].size.width;
      if (current.isEmpty) {
        current = [i];
        currentWidth = width;
      } else if (currentWidth + clusterGap + width <= targetWidth) {
        current.add(i);
        currentWidth += clusterGap + width;
      } else {
        rows.add(current);
        current = [i];
        currentWidth = width;
      }
    }
    if (current.isNotEmpty) {
      rows.add(current);
    }

    final rowWidths = <double>[];
    final rowHeights = <double>[];
    for (final row in rows) {
      var width = 0.0;
      var height = 0.0;
      for (var i = 0; i < row.length; i++) {
        final box = boxes[row[i]];
        width += box.size.width + (i > 0 ? clusterGap : 0);
        height = math.max(height, box.size.height);
      }
      rowWidths.add(width);
      rowHeights.add(height);
    }

    var totalWidth = 0.0;
    var totalHeight = 0.0;
    for (var r = 0; r < rows.length; r++) {
      totalWidth = math.max(totalWidth, rowWidths[r]);
      totalHeight += rowHeights[r] + (r > 0 ? clusterGap : 0);
    }

    final offsets = List<Offset>.filled(boxes.length, Offset.zero);
    var y = 0.0;
    for (var r = 0; r < rows.length; r++) {
      var x = (totalWidth - rowWidths[r]) / 2;
      for (final index in rows[r]) {
        offsets[index] = Offset(x, y);
        x += boxes[index].size.width + clusterGap;
      }
      y += rowHeights[r] + clusterGap;
    }
    return (offsets, Size(totalWidth, totalHeight));
  }
}

/// A cluster laid out in its own coordinate space.
class _ClusterBox {
  const _ClusterBox(this.local, this.size);

  final Map<String, Offset> local;
  final Size size;
}
