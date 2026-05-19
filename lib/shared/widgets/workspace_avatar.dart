import 'dart:typed_data';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';

/// Square workspace mark used everywhere a workspace is shown (the title-bar
/// switcher, the manage-workspaces editor, …).
///
/// Renders the workspace logo image when one is set, otherwise the workspace
/// initial on the brand block gradient. Falls back to a neutral grid icon only
/// when there is neither a logo nor a name.
///
/// The logo is always served by the connected `cc_server` over its signed
/// `/workspace/logo` endpoint (see [MediaProxyScope.workspaceLogoUrlOf]) — the
/// client never reads the logo from its own filesystem, so the mark renders
/// identically on desktop, web, and remote. [logoBytes] takes precedence as an
/// in-memory preview of a freshly picked logo before it is persisted.
class WorkspaceAvatar extends StatelessWidget {
  /// Creates a [WorkspaceAvatar].
  const WorkspaceAvatar({
    super.key,
    this.workspaceId,
    this.hasLogo = false,
    this.logoBytes,
    required this.size,
    this.name,
    this.radius,
    this.fontSize,
  });

  /// The workspace whose logo to fetch from the server. When null or when
  /// [hasLogo] is false the gradient/initial fallback is shown. Ignored when
  /// [logoBytes] is non-empty.
  final String? workspaceId;

  /// Whether the workspace has a persisted logo. Gates the server fetch so a
  /// logo-less workspace never triggers a pointless 404.
  final bool hasLogo;

  /// In-memory logo image bytes, if any. Used to preview a freshly picked logo
  /// before it is saved (and works on web, where there is no server path yet).
  final Uint8List? logoBytes;

  /// Edge length of the (square) avatar.
  final double size;

  /// Workspace name — its first character is used for the gradient fallback.
  final String? name;

  /// Corner radius. Defaults to 4px for large marks (≥64px), 2px otherwise.
  final double? radius;

  /// Initial font size. Defaults to 45% of [size].
  final double? fontSize;

  static const String _logTag = 'WorkspaceAvatar';

  @override
  Widget build(BuildContext context) {
    final r = radius ?? (size >= 64 ? AppRadii.lg : AppRadii.sm);
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final bytes = logoBytes;
    // In-memory preview (a just-picked logo, before save) wins on every
    // platform — and is the only thing that works before persistence.
    if (bytes != null && bytes.isNotEmpty) {
      return _logoPlate(
        ds,
        Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          // A corrupt/undecodable preview must not throw an uncaught image
          // exception mid-build; fall back to the initial/gradient instead.
          errorBuilder: (context, error, stackTrace) {
            AppLog.w(
              _logTag,
              'Failed to decode in-memory logo bytes (${bytes.length}B): '
              '$error',
            );
            return _fallback(context, r);
          },
        ),
      );
    }

    // Fetch the persisted logo from the connected server. The file lives on the
    // SERVER's disk, never the client's — so the mark renders identically on
    // desktop, web, and remote. Null when there is no live connection yet
    // (MediaProxyScope absent); then we fall back until the server connects.
    final wsId = workspaceId;
    if (wsId != null && hasLogo) {
      final url = MediaProxyScope.workspaceLogoUrlOf(
        context,
        workspaceId: wsId,
      );
      if (url != null) {
        return _logoPlate(
          ds,
          Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            // A 404 (logo configured but file gone) or a decode failure must
            // not crash the build — fall back to the initial/gradient.
            errorBuilder: (context, error, stackTrace) {
              AppLog.w(
                _logTag,
                'Failed to load workspace logo for "$wsId": $error',
              );
              return _fallback(context, r);
            },
          ),
        );
      }
    }

    return _fallback(context, r);
  }

  /// The logo plate: the image on the hover-wash background. A transparent
  /// logo otherwise disappears against whatever surface the mark sits on
  /// (title bar, switcher tile); `hover` is the same wash the surrounding
  /// chrome uses for its hover state, so the mark always reads. The plate
  /// carries a 6px (.375rem) radius and a hairline border so its edge holds
  /// against same-tone surfaces.
  Widget _logoPlate(DesignSystemTokens ds, Widget image) {
    const plateRadius = BorderRadius.all(Radius.circular(6));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ds.hover,
        borderRadius: plateRadius,
        border: Border.all(color: ds.borderSecondary),
      ),
      child: ClipRRect(borderRadius: plateRadius, child: image),
    );
  }

  /// The silent, intended fallback: the workspace initial on the brand gradient,
  /// or a neutral grid mark when there is no name either. Shared by the
  /// no-logo-configured path and the decode/missing-file error paths so a broken
  /// logo degrades gracefully instead of crashing the build.
  Widget _fallback(BuildContext context, double r) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final trimmed = (name ?? '').trim();

    // No logo and no name — keep a neutral mark rather than a stray "?".
    if (trimmed.isEmpty) {
      final bg = ds.bgTertiary;
      final fg = ds.fgTertiary;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(r),
        ),
        child: Icon(AppIcons.layoutGrid, size: size * 0.55, color: fg),
      );
    }

    final ink = ds.fg;
    final initial = trimmed.substring(0, 1).toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.34, 0.70, 1.0],
          colors: [ds.sunshine500, ds.sunshine900, ds.accent, ds.blockEdge],
        ),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(r),
        ),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: fontSize ?? size * 0.45,
          height: 1,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
    );
  }
}
