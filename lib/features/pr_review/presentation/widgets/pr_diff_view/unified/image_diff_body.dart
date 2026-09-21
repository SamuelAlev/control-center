import 'dart:convert';
import 'dart:math' as math;

import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/image_diff_resolution.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/media/disk_cached_network_image.dart';
import 'package:control_center/core/theme/diff_colors.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/image_viewer_labels.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

part 'image_diff_checker.dart';

/// First Fenwick estimate for an image preview before the slot is measured.
///
/// Sized for GitHub-style chrome (labels + a small asset + captions + mode
/// bar), not a 360px well. Large screenshots grow the slot via measure.
const double kImageDiffEstimateHeight = 160;

/// How the two sides of an image/SVG diff are composed.
enum ImageDiffViewMode {
  /// Side-by-side before and after.
  twoUp,

  /// Stacked pictures with a draggable divider.
  swipe,

  /// Pixel-difference overlay PNG.
  difference,
}

/// Fetches blob refs for an image/SVG before/after comparison. Returns refs
/// only — never bytes.
typedef ImageDiffResolver =
    Future<ImageDiffResolution> Function({
      required String path,
      String? previousPath,
      required String baseRef,
      required String headRef,
      required PrFileStatus status,
    });

/// Raster / SVG comparison body hosted in the unified Diff-tab sliver.
///
/// Bytes never ride RPC: [resolve] returns [ImageDiffResolution] blob refs
/// and pictures are painted from the signed `/blob` lane. Assets render at
/// 1:1 intrinsic pixels (capped, never upscaled) so a 12×12 icon is 12px,
/// matching GitHub's pictures view.
class ImageDiffBody extends StatefulWidget {
  /// Creates an [ImageDiffBody].
  const ImageDiffBody({
    super.key,
    required this.path,
    this.previousPath,
    required this.status,
    required this.workspaceId,
    required this.baseRef,
    required this.headRef,
    this.resolve,
    this.cached,
    this.onLoaded,
    this.isSvg = false,
  });

  /// Path of the file on the head side.
  final String path;

  /// Path on the base side when renamed.
  final String? previousPath;

  /// Added / removed / modified / renamed — decides which sides exist.
  final PrFileStatus status;

  /// Workspace used to mint `/blob` URLs.
  final String workspaceId;

  /// Commit SHA for the before side (the PR base SHA for v1).
  final String baseRef;

  /// Commit SHA for the after side (selected commit or PR head).
  final String headRef;

  /// Server resolver. Null skips the fetch (empty panes).
  final ImageDiffResolver? resolve;

  /// Previously resolved refs, used to skip the loader on recycle.
  final ImageDiffResolution? cached;

  /// Called with a freshly resolved result so the view can cache it.
  final ValueChanged<ImageDiffResolution>? onLoaded;

  /// Whether to paint with [SvgPicture] instead of [Image].
  final bool isSvg;

  @override
  State<ImageDiffBody> createState() => _ImageDiffBodyState();
}

class _ImageDiffBodyState extends State<ImageDiffBody> {
  static const _maxAssetHeight = 360.0;
  static const _stackBelow = 520.0;

  ImageDiffResolution? _resolved;
  Object? _error;
  bool _loading = false;
  ImageDiffViewMode _mode = ImageDiffViewMode.twoUp;
  Size? _baseSize;
  Size? _headSize;
  Size? _overlaySize;

  @override
  void initState() {
    super.initState();
    _resolved = widget.cached;
    if (_resolved == null && widget.resolve != null) {
      _loading = true;
      _fetch();
    }
  }

  @override
  void didUpdateWidget(ImageDiffBody old) {
    super.didUpdateWidget(old);
    final same =
        old.path == widget.path &&
        old.previousPath == widget.previousPath &&
        old.baseRef == widget.baseRef &&
        old.headRef == widget.headRef &&
        old.status == widget.status;
    if (same) {
      return;
    }
    _resolved = widget.cached;
    _error = null;
    _mode = ImageDiffViewMode.twoUp;
    _baseSize = null;
    _headSize = null;
    _overlaySize = null;
    if (_resolved == null && widget.resolve != null) {
      _loading = true;
      _fetch();
    } else {
      _loading = false;
    }
  }

  Future<void> _fetch() async {
    final resolve = widget.resolve;
    if (resolve == null) {
      return;
    }
    try {
      final next = await resolve(
        path: widget.path,
        previousPath: widget.previousPath,
        baseRef: widget.baseRef,
        headRef: widget.headRef,
        status: widget.status,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _resolved = next;
        _loading = false;
        _error = null;
      });
      widget.onLoaded?.call(next);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    final l10n = AppLocalizations.of(context);
    final surface = tokens.bgPrimary;

    if (_loading) {
      return ColoredBox(
        color: surface,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CcSpinner()),
        ),
      );
    }
    if (_error != null) {
      return ColoredBox(
        color: surface,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Text(
              l10n.failedToLoad,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
          ),
        ),
      );
    }

    final resolved = _resolved ?? ImageDiffResolution.empty;
    final showBase =
        widget.status != PrFileStatus.added && resolved.baseRef != null;
    final showHead =
        widget.status != PrFileStatus.removed && resolved.headRef != null;
    final canOverlay = !widget.isSvg && resolved.overlayRef != null;
    final comparison = showBase && showHead;
    final mode =
        (!comparison || (_mode == ImageDiffViewMode.difference && !canOverlay))
        ? ImageDiffViewMode.twoUp
        : _mode;

    // RTL carve-out: image diffs keep physical left = deleted, right = added
    // so they match the surrounding LTR diff canvas in every locale.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            key: const Key('image-diff-body'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildStage(
                context,
                l10n,
                resolved: resolved,
                mode: mode,
                showBase: showBase,
                showHead: showHead,
                canOverlay: canOverlay,
              ),
              if (mode == ImageDiffViewMode.difference) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.imageDiffChangedPercent(
                    resolved.changedPercent.toStringAsFixed(1),
                  ),
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
                  ),
                ),
              ],
              if (comparison) ...[
                const SizedBox(height: AppSpacing.md),
                _ModeBar(
                  mode: mode,
                  canOverlay: canOverlay,
                  onChanged: (next) => setState(() => _mode = next),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStage(
    BuildContext context,
    AppLocalizations l10n, {
    required ImageDiffResolution resolved,
    required ImageDiffViewMode mode,
    required bool showBase,
    required bool showHead,
    required bool canOverlay,
  }) {
    if (mode == ImageDiffViewMode.swipe && showBase && showHead) {
      return _swipeStage(context, l10n, resolved);
    }
    if (mode == ImageDiffViewMode.difference && canOverlay) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 640.0;
          return _AssetColumn(
            key: const Key('image-diff-overlay'),
            label: l10n.imageDiffModeDifference,
            accent: context.ds.textSecondary,
            blobRef: resolved.overlayRef!,
            workspaceId: widget.workspaceId,
            isSvg: false,
            knownSize: _overlaySize,
            maxWidth: available,
            maxHeight: _maxAssetHeight,
            onSize: (s) {
              if (_overlaySize == s) {
                return;
              }
              setState(() => _overlaySize = s);
            },
          );
        },
      );
    }
    if (showBase && showHead) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 640.0;
          final stacked = available < _stackBelow;
          final sideMax = stacked
              ? available
              : math.max(0.0, (available - AppSpacing.xl * 2) / 2);
          final deleted = _deletedColumn(
            context,
            l10n,
            resolved,
            maxWidth: sideMax,
          );
          final added = _addedColumn(
            context,
            l10n,
            resolved,
            maxWidth: sideMax,
          );
          if (stacked) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                deleted,
                const SizedBox(height: AppSpacing.lg),
                added,
              ],
            );
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              deleted,
              const SizedBox(width: AppSpacing.xl * 2),
              added,
            ],
          );
        },
      );
    }
    if (showHead) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 640.0;
          return _addedColumn(context, l10n, resolved, maxWidth: available);
        },
      );
    }
    if (showBase) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 640.0;
          return _deletedColumn(context, l10n, resolved, maxWidth: available);
        },
      );
    }
    return Text(
      l10n.failedToLoad,
      style: CcTypography.caption.copyWith(color: context.ds.textTertiary),
    );
  }

  Widget _deletedColumn(
    BuildContext context,
    AppLocalizations l10n,
    ImageDiffResolution resolved, {
    required double maxWidth,
  }) {
    return _AssetColumn(
      label: l10n.imageDiffDeleted,
      accent: DiffColors.of(context).deletionAccent,
      blobRef: resolved.baseRef!,
      workspaceId: widget.workspaceId,
      isSvg: widget.isSvg,
      knownSize: _baseSize,
      maxWidth: maxWidth,
      maxHeight: _maxAssetHeight,
      onSize: (s) {
        if (_baseSize == s) {
          return;
        }
        setState(() => _baseSize = s);
      },
    );
  }

  Widget _addedColumn(
    BuildContext context,
    AppLocalizations l10n,
    ImageDiffResolution resolved, {
    required double maxWidth,
  }) {
    return _AssetColumn(
      label: l10n.imageDiffAdded,
      accent: DiffColors.of(context).additionAccent,
      blobRef: resolved.headRef!,
      workspaceId: widget.workspaceId,
      isSvg: widget.isSvg,
      knownSize: _headSize,
      maxWidth: maxWidth,
      maxHeight: _maxAssetHeight,
      onSize: (s) {
        if (_headSize == s) {
          return;
        }
        setState(() => _headSize = s);
      },
    );
  }

  Widget _swipeStage(
    BuildContext context,
    AppLocalizations l10n,
    ImageDiffResolution resolved,
  ) {
    final tokens = context.ds;
    final colors = DiffColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 640.0;
        final maxW = available;
        final beforeDisplay = _fitDisplay(
          _baseSize ?? const Size(16, 16),
          maxW,
          _maxAssetHeight,
        );
        final afterDisplay = _fitDisplay(
          _headSize ?? const Size(16, 16),
          maxW,
          _maxAssetHeight,
        );
        final canvas = Size(
          math.max(beforeDisplay.width, afterDisplay.width),
          math.max(beforeDisplay.height, afterDisplay.height),
        );
        return _SwipeStage(
          layoutWidth: available,
          canvas: canvas,
          beforeLabel: l10n.imageDiffDeleted,
          afterLabel: l10n.imageDiffAdded,
          beforeAccent: colors.deletionAccent,
          afterAccent: colors.additionAccent,
          beforeCaption: _baseSize == null
              ? null
              : l10n.imageDiffDimensions(
                  _baseSize!.width.round(),
                  _baseSize!.height.round(),
                ),
          afterCaption: _headSize == null
              ? null
              : l10n.imageDiffDimensions(
                  _headSize!.width.round(),
                  _headSize!.height.round(),
                ),
          captionStyle: CcTypography.caption.copyWith(
            color: tokens.textTertiary,
          ),
          before: _SizedDiffImage(
            blobRef: resolved.baseRef!,
            workspaceId: widget.workspaceId,
            isSvg: widget.isSvg,
            accent: colors.deletionAccent,
            knownSize: _baseSize,
            maxWidth: maxW,
            maxHeight: _maxAssetHeight,
            onSize: (s) {
              if (_baseSize == s) {
                return;
              }
              setState(() => _baseSize = s);
            },
          ),
          after: _SizedDiffImage(
            blobRef: resolved.headRef!,
            workspaceId: widget.workspaceId,
            isSvg: widget.isSvg,
            accent: colors.additionAccent,
            knownSize: _headSize,
            maxWidth: maxW,
            maxHeight: _maxAssetHeight,
            onSize: (s) {
              if (_headSize == s) {
                return;
              }
              setState(() => _headSize = s);
            },
          ),
        );
      },
    );
  }
}

class _AssetColumn extends StatelessWidget {
  const _AssetColumn({
    super.key,
    required this.label,
    required this.accent,
    required this.blobRef,
    required this.workspaceId,
    required this.isSvg,
    required this.onSize,
    required this.maxWidth,
    required this.maxHeight,
    this.knownSize,
  });

  final String label;
  final Color accent;
  final String blobRef;
  final String workspaceId;
  final bool isSvg;
  final Size? knownSize;
  final double maxWidth;
  final double maxHeight;
  final ValueChanged<Size> onSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    final l10n = AppLocalizations.of(context);
    final caption = knownSize == null
        ? null
        : l10n.imageDiffDimensions(
            knownSize!.width.round(),
            knownSize!.height.round(),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: CcTypography.caption.copyWith(
            color: accent,
            fontWeight: CcTypography.semiboldWeight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SizedDiffImage(
          blobRef: blobRef,
          workspaceId: workspaceId,
          isSvg: isSvg,
          accent: accent,
          knownSize: knownSize,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          onSize: onSize,
        ),
        if (caption != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            caption,
            style: CcTypography.caption.copyWith(color: tokens.textTertiary),
          ),
        ],
      ],
    );
  }
}

/// Picture + 1px accent border at 1:1 intrinsic size (capped, never upscaled).
class _SizedDiffImage extends StatefulWidget {
  const _SizedDiffImage({
    required this.blobRef,
    required this.workspaceId,
    required this.isSvg,
    required this.accent,
    required this.maxWidth,
    required this.maxHeight,
    required this.onSize,
    this.knownSize,
  });

  final String blobRef;
  final String workspaceId;
  final bool isSvg;
  final Color accent;
  final double maxWidth;
  final double maxHeight;
  final Size? knownSize;
  final ValueChanged<Size> onSize;

  @override
  State<_SizedDiffImage> createState() => _SizedDiffImageState();
}

class _SizedDiffImageState extends State<_SizedDiffImage> {
  static const _expandMin = 64.0;

  Size? _loaded;
  String? _svg;
  String? _attachedUrl;
  ImageStream? _rasterStream;
  late final ImageStreamListener _listener;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener(_onRaster);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFromContext();
  }

  @override
  void didUpdateWidget(_SizedDiffImage old) {
    super.didUpdateWidget(old);
    if (old.blobRef == widget.blobRef &&
        old.workspaceId == widget.workspaceId &&
        old.isSvg == widget.isSvg) {
      return;
    }
    _attachedUrl = null;
    _loaded = null;
    _svg = null;
    _syncFromContext();
  }

  @override
  void dispose() {
    _gen++;
    _detachRaster();
    super.dispose();
  }

  void _detachRaster() {
    _rasterStream?.removeListener(_listener);
    _rasterStream = null;
  }

  void _syncFromContext() {
    final url = MediaProxyScope.blobUrlOf(
      context,
      workspaceId: widget.workspaceId,
      ref: widget.blobRef,
    );
    if (url == _attachedUrl) {
      return;
    }
    _detachRaster();
    _attachedUrl = url;
    if (url == null) {
      return;
    }
    if (widget.isSvg) {
      _loadSvg(url);
    } else {
      final provider = DiskCachedNetworkImage(url);
      _rasterStream = provider.resolve(const ImageConfiguration());
      _rasterStream!.addListener(_listener);
    }
  }

  void _onRaster(ImageInfo info, bool synchronous) {
    final size = Size(
      info.image.width.toDouble(),
      info.image.height.toDouble(),
    );
    _emit(size);
  }

  Future<void> _loadSvg(String url) async {
    final gen = ++_gen;
    try {
      final response = await http.get(Uri.parse(url));
      if (!mounted || gen != _gen) {
        return;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }
      final svg = utf8.decode(response.bodyBytes);
      final parsed = _parseSvgIntrinsicSize(svg);
      final size = Size(parsed.$1, parsed.$2);
      setState(() => _svg = svg);
      _emit(size);
    } on Object {
      // Leave the placeholder; the parent already has a load-failure lane
      // for the resolution RPC. A missing picture is quieter than a toast.
    }
  }

  void _emit(Size size) {
    if (_loaded == size) {
      return;
    }
    _loaded = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      widget.onSize(size);
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = MediaProxyScope.blobUrlOf(
      context,
      workspaceId: widget.workspaceId,
      ref: widget.blobRef,
    );
    final intrinsic = _loaded ?? widget.knownSize;
    if (url == null || intrinsic == null) {
      return const SizedBox.shrink();
    }
    final display = _fitDisplay(intrinsic, widget.maxWidth, widget.maxHeight);
    final Widget picture;
    if (widget.isSvg) {
      picture = _svg == null
          ? SizedBox(width: display.width, height: display.height)
          : SvgPicture.string(
              _svg!,
              width: display.width,
              height: display.height,
              fit: BoxFit.fill,
            );
    } else {
      picture = Image(
        image: DiskCachedNetworkImage(url),
        width: display.width,
        height: display.height,
        fit: BoxFit.fill,
        filterQuality: display.width < intrinsic.width
            ? FilterQuality.medium
            : FilterQuality.none,
        gaplessPlayback: true,
      );
    }
    final framed = DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: widget.accent)),
      child: SizedBox(
        width: display.width,
        height: display.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(
              key: Key('image-diff-checker'),
              painter: ImageDiffCheckerPainter(),
            ),
            picture,
          ],
        ),
      ),
    );
    final expandable =
        display.width >= _expandMin && display.height >= _expandMin;
    if (!expandable) {
      return framed;
    }
    return CcExpandableImage(
      labels: appImageViewerLabels(context),
      title: widget.blobRef,
      enabled: true,
      viewerBuilder: (_) => widget.isSvg
          ? SvgPicture.string(
              _svg ?? '<svg xmlns="http://www.w3.org/2000/svg"/>',
              fit: BoxFit.contain,
            )
          : Image(image: DiskCachedNetworkImage(url), fit: BoxFit.contain),
      child: framed,
    );
  }
}

class _SwipeStage extends StatefulWidget {
  const _SwipeStage({
    required this.layoutWidth,
    required this.canvas,
    required this.before,
    required this.after,
    required this.beforeLabel,
    required this.afterLabel,
    required this.beforeAccent,
    required this.afterAccent,
    required this.captionStyle,
    this.beforeCaption,
    this.afterCaption,
  });

  final double layoutWidth;
  final Size canvas;
  final Widget before;
  final Widget after;
  final String beforeLabel;
  final String afterLabel;
  final Color beforeAccent;
  final Color afterAccent;
  final TextStyle captionStyle;
  final String? beforeCaption;
  final String? afterCaption;

  @override
  State<_SwipeStage> createState() => _SwipeStageState();
}

class _SwipeStageState extends State<_SwipeStage> {
  double _t = 0.5;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final canvasW = math.max(widget.canvas.width, 8.0);
    final split = (_t * canvasW).clamp(1.0, canvasW - 1.0);
    final labelStyle = CcTypography.caption.copyWith(
      fontWeight: CcTypography.semiboldWeight,
    );
    final chromeWidth = widget.layoutWidth.isFinite
        ? widget.layoutWidth
        : canvasW;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (details) {
        final dx = rtl ? -details.delta.dx : details.delta.dx;
        setState(() {
          _t = (_t + dx / canvasW).clamp(0.02, 0.98);
        });
      },
      child: SizedBox(
        width: chromeWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.beforeLabel,
                    style: labelStyle.copyWith(color: widget.beforeAccent),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.afterLabel,
                    textAlign: TextAlign.end,
                    style: labelStyle.copyWith(color: widget.afterAccent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: SizedBox(
                width: canvasW,
                height: widget.canvas.height,
                child: Stack(
                  children: [
                    Positioned.fill(child: Center(child: widget.after)),
                    // RTL carve-out: the overlay clip is physical left-to-right
                    // so the pictures stay LTR in every locale.
                    ClipRect(
                      clipper: _LeadingClipper(split),
                      child: Center(child: widget.before),
                    ),
                    Positioned(
                      left: split - 1,
                      top: 0,
                      bottom: 0,
                      child: ColoredBox(
                        key: const Key('image-diff-swipe-divider'),
                        color: tokens.accent,
                        child: const SizedBox(width: 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.beforeCaption != null ||
                widget.afterCaption != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.beforeCaption ?? '',
                      style: widget.captionStyle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.afterCaption ?? '',
                      textAlign: TextAlign.end,
                      style: widget.captionStyle,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeBar extends StatelessWidget {
  const _ModeBar({
    required this.mode,
    required this.canOverlay,
    required this.onChanged,
  });

  final ImageDiffViewMode mode;
  final bool canOverlay;
  final ValueChanged<ImageDiffViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    final l10n = AppLocalizations.of(context);
    final items = <({ImageDiffViewMode value, String label})>[
      (value: ImageDiffViewMode.twoUp, label: l10n.imageDiffModeTwoUp),
      (value: ImageDiffViewMode.swipe, label: l10n.imageDiffModeSwipe),
      if (canOverlay)
        (
          value: ImageDiffViewMode.difference,
          label: l10n.imageDiffModeDifference,
        ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.borderPrimary)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    '|',
                    style: CcTypography.bodySm.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                ),
              _ModeItem(
                label: items[i].label,
                selected: items[i].value == mode,
                onPressed: () => onChanged(items[i].value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  const _ModeItem({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    return CcTappable(
      semanticLabel: label,
      onPressed: onPressed,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(8, 5),
            painter: selected ? _CaretPainter(tokens.textPrimary) : null,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: CcTypography.bodySm.copyWith(
              fontWeight: selected
                  ? CcTypography.semiboldWeight
                  : CcTypography.regularWeight,
              color: selected ? tokens.textPrimary : tokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Clips to the leading [width] pixels (physical left; pictures stay LTR).
class _LeadingClipper extends CustomClipper<Rect> {
  const _LeadingClipper(this.width);

  final double width;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, width, size.height);

  @override
  bool shouldReclip(_LeadingClipper old) => old.width != width;
}

class _CaretPainter extends CustomPainter {
  const _CaretPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CaretPainter old) => old.color != color;
}
