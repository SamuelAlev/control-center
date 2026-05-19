import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The square workspace mark, mirroring the desktop's `WorkspaceAvatar`.
///
/// The logo file lives on the SERVER's disk, so the bytes come from the server
/// — over the RPC channel (`workspaceLogoProvider`), NOT the signed
/// `/workspace/logo` HTTP endpoint the desktop uses. The HTTP lane needs an
/// HTTP origin, and the phone's usual route has none: an HTTPS-served PWA
/// cannot open a plaintext `ws://` LAN socket, so it connects through the
/// broker relay, which carries JSON-RPC frames and nothing else. Fetching the
/// mark over the channel that always exists is what makes it appear at all
/// here.
///
/// [hasLogo] still gates the fetch so a logo-less workspace never spends a
/// round trip on a guaranteed null. Anything missing — no logo, no connection,
/// an undecodable file — renders the workspace initial on the brand gradient,
/// which is the intended mark rather than an error state.
class WorkspaceAvatar extends ConsumerWidget {
  /// Creates a [WorkspaceAvatar].
  const WorkspaceAvatar({
    super.key,
    required this.workspaceId,
    required this.name,
    required this.hasLogo,
    this.size = 24,
    this.radius,
  });

  /// The workspace whose logo to fetch.
  final String workspaceId;

  /// Workspace name — its first character is the fallback mark.
  final String name;

  /// Whether the workspace has a persisted logo.
  final bool hasLogo;

  /// Edge length of the (square) mark.
  final double size;

  /// Corner radius; defaults to 6px so the mark reads as a plate, not a chip.
  final double? radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final r = radius ?? 6;
    final bytes = hasLogo
        ? ref.watch(workspaceLogoProvider(workspaceId)).value
        : null;

    if (bytes != null && bytes.isNotEmpty) {
      final borderRadius = BorderRadius.all(Radius.circular(r));
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          // A transparent logo would otherwise vanish against whatever surface
          // the mark sits on; the hover wash is the same one the surrounding
          // chrome uses, so the plate always reads.
          color: t.hover,
          borderRadius: borderRadius,
          border: Border.all(color: t.borderSecondary),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            // `width`/`height` bind the PAINT size; `cacheWidth` binds the
            // DECODE. Without it a 1024px logo is decoded and held at full
            // size to be drawn into a 24px plate.
            cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
            // An undecodable file must not throw mid-build — degrade to the
            // initial rather than taking the switcher down.
            errorBuilder: (context, error, stack) => _fallback(t, r),
          ),
        ),
      );
    }
    return _fallback(t, r);
  }

  Widget _fallback(DesignSystemTokens t, double r) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.bgTertiary,
          borderRadius: BorderRadius.circular(r),
        ),
        child: Icon(AppIcons.layers, size: size * 0.55, color: t.fgTertiary),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.34, 0.70, 1.0],
          colors: [t.sunshine500, t.sunshine900, t.accent, t.blockEdge],
        ),
        borderRadius: BorderRadius.circular(r),
      ),
      child: Text(
        trimmed.substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.45,
          height: 1,
          fontWeight: FontWeight.w600,
          color: t.fg,
        ),
      ),
    );
  }
}

/// A remote avatar (a forge user, a repo owner) fetched through the server's
/// `/proxy/media` endpoint, falling back to the login's monogram.
///
/// The phone never dials `avatars.githubusercontent.com` itself: the server is
/// the only tier that talks to an upstream, and it is also the only one that
/// can cache the result for every client.
class RemoteAvatar extends ConsumerWidget {
  /// Creates a [RemoteAvatar].
  const RemoteAvatar({
    super.key,
    required this.url,
    required this.fallbackLabel,
    this.size = 20,
  });

  /// The upstream avatar URL (rewritten to the host proxy before loading).
  final String? url;

  /// Text whose first character backs the monogram fallback.
  final String fallbackLabel;

  /// Diameter of the (circular) avatar.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final endpoint = ref.watch(mediaEndpointProvider).value;
    final raw = url;

    if (endpoint != null && raw != null && raw.isNotEmpty) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      return ClipOval(
        child: Image.network(
          endpoint.resolve(raw, maxWidth: (size * dpr).round()),
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          cacheWidth: (size * dpr).round(),
          errorBuilder: (context, error, stack) => _monogram(t),
        ),
      );
    }
    return _monogram(t);
  }

  Widget _monogram(DesignSystemTokens t) {
    final trimmed = fallbackLabel.trim();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.bgTertiary, shape: BoxShape.circle),
      child: trimmed.isEmpty
          ? Icon(AppIcons.user, size: size * 0.6, color: t.fgTertiary)
          : Text(
              trimmed.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: size * 0.46,
                height: 1,
                fontWeight: FontWeight.w600,
                color: t.fgSecondary,
              ),
            ),
    );
  }
}
