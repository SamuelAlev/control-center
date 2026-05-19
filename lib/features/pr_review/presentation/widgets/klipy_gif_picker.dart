import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/config/env_config.dart';
import 'package:control_center/core/network/app_network.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _kKlipyBaseUrl = 'https://api.klipy.com';
const _kDebounceMs = 400;
const _kPerPage = 30;

final _klipyDio = createDio(baseUrl: _kKlipyBaseUrl)
  ..options.connectTimeout = const Duration(seconds: 5)
  ..options.receiveTimeout = const Duration(seconds: 5);

String get _appKey => EnvConfig.klipyAppKey;

/// A GIF result from Klipy.
class GifResult {
  /// GifResult({.
  const GifResult({
    required this.id,
    required this.url,
    required this.previewUrl,
    required this.width,
    required this.height,
  });

  /// GifResult.fromJson.
  factory GifResult.fromJson(Map<String, dynamic> json) {
    final file = json['file'] as Map<String, dynamic>;
    final sm = file['sm'] as Map<String, dynamic>?;
    final hd = file['hd'] as Map<String, dynamic>?;
    final gif =
        (hd?['gif'] ?? sm?['gif'] ?? sm?['webp']) as Map<String, dynamic>?;
    final preview =
        (sm?['gif'] ?? sm?['webp'] ?? sm?['jpg'] ?? gif)
            as Map<String, dynamic>?;
    return GifResult(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      url: (gif?['url'] as String?) ?? '',
      previewUrl:
          (preview?['url'] as String?) ?? (gif?['url'] as String?) ?? '',
      width: (gif?['width'] as num?)?.toInt() ?? 0,
      height: (gif?['height'] as num?)?.toInt() ?? 0,
    );
  }

  /// Klipy GIF identifier.
  final int id;

  /// Direct URL to the GIF.
  final String url;

  /// Preview URL for grid thumbnails.
  final String previewUrl;

  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;
}

void _checkAppKey() {
  final appKey = _appKey;
  if (appKey.isEmpty) {
    throw StateError(
      'KLIPY_APP_KEY not set. Pass via --dart-define=KLIPY_APP_KEY=...',
    );
  }
}

Future<List<GifResult>> _searchKlipy(String query) async {
  _checkAppKey();
  final response = await _klipyDio.get<Map<String, dynamic>>(
    '/api/v1/$_appKey/gifs/search',
    queryParameters: {
      'q': query,
      'per_page': _kPerPage,
      'format_filter': 'gif',
    },
  );
  final data = response.data?['data'] as Map<String, dynamic>?;
  final items = data?['data'] as List<dynamic>?;
  if (items == null) {
    return [];
  }

  return items
      .map((e) => GifResult.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<List<GifResult>> _trendingKlipy() async {
  _checkAppKey();
  final response = await _klipyDio.get<Map<String, dynamic>>(
    '/api/v1/$_appKey/gifs/trending',
    queryParameters: {'per_page': _kPerPage, 'format_filter': 'gif'},
  );
  final data = response.data?['data'] as Map<String, dynamic>?;
  final items = data?['data'] as List<dynamic>?;
  if (items == null) {
    return [];
  }

  return items
      .map((e) => GifResult.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Shows a GIF search popover powered by Klipy.
///
/// On selection, [onGifSelected] is called with the GIF data, then the
/// overlay is dismissed. If [anchorPosition] is provided (in screen coords),
/// the picker is positioned near that point; otherwise centered.
Future<void> showGifPicker({
  required BuildContext anchor,
  required void Function(GifResult gif) onGifSelected,
  Offset? anchorPosition,
}) async {
  final overlay = Overlay.of(anchor, rootOverlay: true);
  late final OverlayEntry entry;
  void dismiss() => entry.remove();
  entry = OverlayEntry(
    builder: (_) => _GifPickerBody(
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
    required this.onSelected,
    required this.onClose,
    this.anchorPosition,
  });

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
      _gifs = await _trendingKlipy();
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
        _gifs = await _searchKlipy(query.trim());
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

    if (_appKey.isEmpty) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.onClose,
            ),
          ),
          _positionWidget(
            _buildNoKeyCard(theme),
            widget.anchorPosition,
            mediaQuery,
          ),
        ],
      );
    }

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

  Widget _buildNoKeyCard(DesignSystemTokens theme) {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(12),
      color: theme.bgPrimary,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderSecondary),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.keyRound,
              size: 32,
              color: theme.textTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).klipyNotConfigured,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: theme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).klipyNotConfiguredHint,
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
                  const Icon(LucideIcons.clapperboard, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).searchGifs,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  CcIconButton(
                    icon: LucideIcons.x,
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
                    prefixIcon: const Icon(LucideIcons.search, size: 16),
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
                LucideIcons.alertCircle,
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
                  gif.previewUrl,
                  fit: BoxFit.cover,
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
                        LucideIcons.imageOff,
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
