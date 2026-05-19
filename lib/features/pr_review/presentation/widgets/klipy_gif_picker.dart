import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/gif_result.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/material.dart';

const _kDebounceMs = 400;

/// Searches GIFs SERVER-SIDE over the `gif.search` RPC op (the thin client
/// holds no Klipy app key; the browser can't reach Klipy cross-origin). The
/// host runs Klipy with its configured key and returns flat `GifResult` maps.
Future<List<GifResult>> _searchGifs(RemoteRpcClient rpc, String query) async {
  final data = await rpc.call('gif.search', {'query': query});
  return _parseGifs(data);
}

/// Fetches trending GIFs SERVER-SIDE over the `gif.trending` RPC op.
Future<List<GifResult>> _trendingGifs(RemoteRpcClient rpc) async {
  final data = await rpc.call('gif.trending', const {});
  return _parseGifs(data);
}

List<GifResult> _parseGifs(Map<String, dynamic> data) => [
  for (final g in (data['gifs'] as List? ?? const []))
    GifResult.fromWire((g as Map).cast<String, dynamic>()),
];

/// Shows a GIF search popover powered by Klipy (server-side).
///
/// On selection, [onGifSelected] is called with the GIF data, then the
/// overlay is dismissed. If [anchorPosition] is provided (in screen coords),
/// the picker is positioned near that point; otherwise centered. [rpcClient]
/// drives the `gif.*` ops — pass `ref.read(rpcClientProvider)`.
Future<void> showGifPicker({
  required BuildContext anchor,
  required RemoteRpcClient rpcClient,
  required void Function(GifResult gif) onGifSelected,
  Offset? anchorPosition,
}) async {
  final overlay = Overlay.of(anchor, rootOverlay: true);
  late final OverlayEntry entry;
  void dismiss() => entry.remove();
  entry = OverlayEntry(
    builder: (_) => _GifPickerBody(
      rpcClient: rpcClient,
      onSelected: (gif) {
        onGifSelected(gif);
        dismiss();
      },
      onClose: dismiss,
      anchorPosition: anchorPosition,
    ),
  );
  overlay.insert(entry);
}

Widget _positionWidget(Widget child, Offset? anchor, MediaQueryData media) {
  if (anchor == null) {
    return Center(child: child);
  }

  final screenW = media.size.width;
  final screenH = media.size.height;
  final spaceBelow = screenH - anchor.dy - 12;
  final spaceAbove = anchor.dy - 12;
  final top = spaceBelow >= 300 || spaceBelow >= spaceAbove
      ? anchor.dy + 12
      : null;
  final bottom = top == null ? screenH - anchor.dy + 12 : null;
  final left = (anchor.dx - 12).clamp(12.0, screenW - 440 - 12);
  if (top != null) {
    return Positioned(left: left, top: top, child: child);
  }

  if (bottom != null) {
    return Positioned(left: left, bottom: bottom, child: child);
  }
  return Center(child: child);
}

class _GifPickerBody extends StatefulWidget {
  const _GifPickerBody({
    required this.rpcClient,
    required this.onSelected,
    required this.onClose,
    this.anchorPosition,
  });

  final RemoteRpcClient rpcClient;
  final void Function(GifResult gif) onSelected;
  final VoidCallback onClose;
  final Offset? anchorPosition;

  @override
  State<_GifPickerBody> createState() => _GifPickerBodyState();
}

class _GifPickerBodyState extends State<_GifPickerBody> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollCtrl = ScrollController();
  List<GifResult> _gifs = [];
  bool _loading = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTrending());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _gifs = await _trendingGifs(widget.rpcClient);
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _search(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      unawaited(_loadTrending());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: _kDebounceMs), () async {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        _gifs = await _searchGifs(widget.rpcClient, query.trim());
        setState(() => _loading = false);
      } catch (e) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.designSystem ?? DesignSystemTokens.light();
    final mediaQuery = MediaQuery.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onClose,
          ),
        ),
        _positionWidget(
          _buildCard(theme, mediaQuery),
          widget.anchorPosition,
          mediaQuery,
        ),
      ],
    );
  }

  Widget _buildCard(DesignSystemTokens theme, MediaQueryData mediaQuery) {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(12),
      color: theme.bgPrimary,
      child: Container(
        width: 440,
        height: 500,
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.75),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderSecondary),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
              child: Row(
                children: [
                  const Icon(AppIcons.clapperboard, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).searchGifs,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  CcIconButton(
                    icon: AppIcons.x,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  onChanged: _search,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    hintText: AppLocalizations.of(context).searchGifsHint,
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme.textTertiary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.borderSecondary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.borderSecondary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.textPrimary,
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: const Icon(AppIcons.search, size: 16),
                    prefixIconConstraints: const BoxConstraints(minWidth: 36),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(DesignSystemTokens theme) {
    if (_loading && _gifs.isEmpty) {
      return const Center(child: CcSpinner());
    }
    if (_error != null && _gifs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.alertCircle,
                size: 32,
                color: theme.textTertiary,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).failedToLoadGifs,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: theme.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: theme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_gifs.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noGifsFound,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: theme.textTertiary),
        ),
      );
    }
    return GridView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: _gifs.length,
      itemBuilder: (context, index) {
        final gif = _gifs[index];
        return CcTappable(
          onPressed: () => widget.onSelected(gif),
          borderRadius: BorderRadius.circular(8),
          builder: (context, states) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  MediaProxyScope.urlOf(context, gif.previewUrl),
                  fit: BoxFit.cover,
                  // ~131px square tile; cap the per-frame decode (animated GIFs
                  // are resized per frame). Kept stream-through at the proxy so
                  // animation survives — only the in-memory decode shrinks.
                  cacheWidth:
                      (131 * MediaQuery.devicePixelRatioOf(context)).round(),
                  gaplessPlayback: true,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return Container(
                      color: theme.textTertiary.withValues(
                        alpha: 0.1,
                      ),
                      child: const Center(child: CcSpinner()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: theme.textTertiary.withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(
                        AppIcons.imageOff,
                        color: theme.textTertiary,
                        size: 24,
                      ),
                    );
                  },
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.borderSecondary,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
