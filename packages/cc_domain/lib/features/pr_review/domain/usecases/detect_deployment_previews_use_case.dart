import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/deployment_preview.dart';

/// Detects deployment-preview URLs on a PR from two sources, preferring the
/// structured one:
///
/// 1. **Commit statuses** (primary) — a `deploy-preview`-style status context
///    whose `target_url` is the live site. Robust: no markdown parsing, custom
///    domains included, one entry per site, updates on redeploy.
/// 2. **Text** (fallback) — the PR body and comment bodies:
///    markdown links whose label mentions "preview", bare URLs
///    on known hosting providers, and deploy-preview subdomain conventions.
///
/// Dashboard / deploy-log / QR hosts are always rejected so the Netlify bot's
/// "Latest deploy log" and QR-code links never win over the real preview.
class DetectDeploymentPreviewsUseCase {
  /// Creates a [DetectDeploymentPreviewsUseCase].
  const DetectDeploymentPreviewsUseCase();

  /// Returns the deduped set of previews across [statuses] and [texts].
  ///
  /// [texts] is any bag of markdown (typically the PR body plus every issue
  /// comment). Status-sourced previews take precedence; a text-sourced preview
  /// is only added when neither its URL nor its site is already covered.
  List<DeploymentPreview> detect({
    List<CommitStatus> statuses = const [],
    List<String> texts = const [],
  }) {
    final result = <DeploymentPreview>[];
    final seenUrls = <String>{};
    final seenSites = <String>{};

    void add(DeploymentPreview p) {
      final key = _normalizeUrl(p.url);
      if (key.isEmpty || seenUrls.contains(key)) {
        return;
      }
      // A non-empty site already covered by a higher-priority source wins.
      if (p.siteName.isNotEmpty && seenSites.contains(p.siteName)) {
        return;
      }
      seenUrls.add(key);
      if (p.siteName.isNotEmpty) {
        seenSites.add(p.siteName);
      }
      result.add(p);
    }

    for (final s in _fromStatuses(statuses)) {
      add(s);
    }
    for (final text in texts) {
      for (final p in _fromText(text)) {
        add(p);
      }
    }

    result.sort((a, b) {
      // Structured (status) previews first, then alphabetical by site for a
      // stable tab order.
      if (a.source != b.source) {
        return a.source == DeploymentPreviewSource.commitStatus ? -1 : 1;
      }
      return a.siteName.compareTo(b.siteName);
    });
    return List.unmodifiable(result);
  }

  // --- Commit statuses --------------------------------------------------

  Iterable<DeploymentPreview> _fromStatuses(List<CommitStatus> statuses) sync* {
    for (final s in statuses) {
      final url = s.targetUrl.trim();
      if (url.isEmpty || !_isPreviewContext(s.context) || _isRejectedUrl(url)) {
        continue;
      }
      yield DeploymentPreview(
        siteName: _siteFromContext(s.context),
        url: url,
        source: DeploymentPreviewSource.commitStatus,
        state: switch (s.state) {
          CommitStatusState.success => DeploymentPreviewState.ready,
          CommitStatusState.pending => DeploymentPreviewState.building,
          CommitStatusState.failure ||
          CommitStatusState.error => DeploymentPreviewState.failed,
        },
        updatedAt: s.updatedAt,
      );
    }
  }

  /// A context names a preview when it mentions "preview" anywhere, e.g.
  /// `netlify/test-web-app/deploy-preview` or `vercel – Preview`.
  bool _isPreviewContext(String context) =>
      context.toLowerCase().contains('preview');

  /// Extracts a site label from a status context. Netlify uses
  /// `netlify/<site>/deploy-preview`; we take the segment between the provider
  /// and the `deploy-preview` marker, falling back to the raw context.
  String _siteFromContext(String context) {
    final parts = context.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 3) {
      return parts[1];
    }
    if (parts.length == 2) {
      return parts[0];
    }
    return context;
  }

  // --- Text (fallback) --------------------------------------------------

  // A markdown link `[label](url)` — matches even inside an HTML comment, which
  // is where Netlify puts its machine-readable `[<name> Preview](<url>)` marker.
  static final RegExp _markdownLink = RegExp(
    r'\[([^\]]*)\]\(\s*(https?://[^\s)]+?)\s*\)',
  );

  // A bare/autolinked URL.
  static final RegExp _bareUrl = RegExp(
    r'https?://[^\s<>()\[\]"'
    "'"
    r']+',
  );

  // Text near a URL that signals a deployment preview (used per line).
  static final RegExp _previewKeyword = RegExp(
    r'deploy[\s-]?preview|preview[\s-]?(deployment|url|ready|link)|'
    r'(visit|view|open)\s+preview',
    caseSensitive: false,
  );

  static final RegExp _previewLabel = RegExp(
    r'\bpreview\b',
    caseSensitive: false,
  );

  Iterable<DeploymentPreview> _fromText(String text) sync* {
    if (text.isEmpty) {
      return;
    }
    for (final line in text.split('\n')) {
      final lineMentionsPreview = _previewKeyword.hasMatch(line);

      // Markdown links: label may carry the "preview" signal.
      for (final m in _markdownLink.allMatches(line)) {
        final label = m.group(1) ?? '';
        final url = (m.group(2) ?? '').trim();
        if (_isRejectedUrl(url)) {
          continue;
        }
        if (_previewLabel.hasMatch(label) ||
            lineMentionsPreview ||
            _looksLikePreviewUrl(url)) {
          yield _previewFromUrl(url);
        }
      }

      // Bare URLs: rely on host/subdomain conventions or a nearby keyword.
      for (final m in _bareUrl.allMatches(line)) {
        final url = _trimUrl(m.group(0) ?? '');
        if (_isRejectedUrl(url)) {
          continue;
        }
        if (_looksLikePreviewUrl(url) || lineMentionsPreview) {
          yield _previewFromUrl(url);
        }
      }
    }
  }

  DeploymentPreview _previewFromUrl(String url) => DeploymentPreview(
    siteName: _siteFromUrl(url),
    url: url,
    source: DeploymentPreviewSource.comment,
  );

  // --- URL classification ------------------------------------------------

  // Hosts whose URLs are never a deploy preview (provider dashboards, deploy
  // logs, QR-code images, git forges).
  static const _rejectedHosts = <String>{
    'app.netlify.com',
    'app.vercel.com',
    'vercel.com',
    'github.com',
    'app.github.dev',
    'dashboard.render.com',
  };

  // Path fragments that mark a dashboard/log/asset URL rather than a preview.
  static const _rejectedPathFragments = <String>[
    '/qr-code/',
    '/deploys/',
    '/configuration/',
    '/settings',
  ];

  // Image/asset file extensions — a deployment preview is a browsable web page,
  // never an image. Rejects CI badges (SonarCloud's quality-gate badge on
  // `sonarsource.github.io`, shields.io, coverage badges) that would otherwise
  // pass `_looksLikePreviewUrl` on a preview-looking host such as `*.github.io`.
  static const _rejectedPathExtensions = <String>[
    '.png',
    '.svg',
    '.gif',
    '.jpg',
    '.jpeg',
    '.webp',
    '.avif',
    '.ico',
    '.bmp',
  ];

  // Host suffixes that hosting providers serve previews from.
  static const _previewHostSuffixes = <String>[
    'netlify.app',
    'vercel.app',
    'pages.dev',
    'amplifyapp.com',
    'web.app',
    'firebaseapp.com',
    'onrender.com',
    'render.com',
    'fly.dev',
    'railway.app',
    'up.railway.app',
    'surge.sh',
    'github.io',
    'deno.dev',
    'workers.dev',
    'cloudflarepages.com',
    'now.sh',
  ];

  // Subdomain conventions independent of the base domain (custom domains
  // included): Netlify `deploy-preview-<n>`, Netlify branch alias `x--site`,
  // Vercel branch deploy `x-git-branch-team`.
  static final RegExp _previewSubdomain = RegExp(
    r'(^|\.)deploy-preview-\d+\.|--|-git-',
    caseSensitive: false,
  );

  bool _looksLikePreviewUrl(String url) {
    final host = _hostOf(url);
    if (host.isEmpty) {
      return false;
    }
    for (final suffix in _previewHostSuffixes) {
      if (host == suffix || host.endsWith('.$suffix')) {
        return true;
      }
    }
    return _previewSubdomain.hasMatch(host);
  }

  bool _isRejectedUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return true;
    }
    final host = uri.host.toLowerCase();
    if (_rejectedHosts.contains(host)) {
      return true;
    }
    final lower = url.toLowerCase();
    for (final frag in _rejectedPathFragments) {
      if (lower.contains(frag)) {
        return true;
      }
    }
    // Path (query/fragment excluded) ending in an image extension is an asset,
    // not a preview page.
    final path = uri.path.toLowerCase();
    for (final ext in _rejectedPathExtensions) {
      if (path.endsWith(ext)) {
        return true;
      }
    }
    return false;
  }

  /// A site label from a preview URL: the first host label that isn't the
  /// `deploy-preview-<n>` prefix or `www`, else the host.
  String _siteFromUrl(String url) {
    final host = _hostOf(url);
    if (host.isEmpty) {
      return '';
    }
    final labels = host.split('.');
    for (final label in labels) {
      if (label == 'www' ||
          label.isEmpty ||
          RegExp(r'^deploy-preview-\d+$').hasMatch(label)) {
        continue;
      }
      return label;
    }
    return host;
  }

  String _hostOf(String url) => Uri.tryParse(url)?.host.toLowerCase() ?? '';

  // Trailing punctuation that commonly clings to an autolinked URL.
  String _trimUrl(String url) {
    var out = url.trim();
    while (out.isNotEmpty && '.,;:!)]}>"\''.contains(out[out.length - 1])) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }

  String _normalizeUrl(String url) {
    final trimmed = _trimUrl(url);
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1).toLowerCase()
        : trimmed.toLowerCase();
  }
}
