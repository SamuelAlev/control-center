import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cc_domain/features/newsfeed/domain/helpers/scriptlet_library.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/newsfeed/presentation/helpers/content_blocker_mapper.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/adblocker_webview_controller.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_server_providers.dart';
import 'package:control_center/features/newsfeed/providers/site_allowlist_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A reusable webview that blocks ads and trackers using the newsfeed's
/// ABP filter pipeline. Inspired by `flutter_adblocker_webview`'s
/// `AdBlockerWebview`, but built on `flutter_inappwebview` so it works on
/// desktop (macOS/Windows) and uses native WebKit `ContentBlocker`s on
/// Apple platforms.
///
/// Blocking is governed by two signals:
/// - The master switch `contentBlockingProvider` (newsfeed settings).
/// - The per-domain allowlist (`siteAllowlistProvider`). Hosts on the
///   allowlist render unblocked.
///
/// When the per-host blocking decision changes for the currently-loaded
/// page, the widget rebuilds its content blockers + fallback scripts and
/// reloads the page.
class AdBlockerWebView extends ConsumerStatefulWidget {
  /// Creates a new [AdBlockerWebView].
  const AdBlockerWebView({
    super.key,
    required this.initialUrl,
    required this.controller,
    this.onLoadStart,
    this.onLoadStop,
    this.onLoadError,
    this.onUrlChanged,
  });

  /// First URL to load.
  final Uri initialUrl;

  /// Controller for driving the webview. **Owned by the caller** — create
  /// it in the parent's `initState` and dispose it in the parent's
  /// `dispose`. This widget does NOT dispose it. Owning the controller in
  /// the parent avoids the lifecycle race where the widget's dispose
  /// would run before the parent's dispose, leaving stale listeners on
  /// disposed [ValueNotifier]s.
  final AdBlockerWebViewController controller;

  /// Called when a page starts loading.
  final ValueChanged<Uri?>? onLoadStart;

  /// Called when a page finishes loading.
  final ValueChanged<Uri?>? onLoadStop;

  /// Called when a main-frame load fails.
  final void Function(Uri? url, String message)? onLoadError;

  /// Called when the visible URL changes (navigation, history pop, etc.).
  final ValueChanged<Uri?>? onUrlChanged;

  @override
  ConsumerState<AdBlockerWebView> createState() => _AdBlockerWebViewState();
}

class _AdBlockerWebViewState extends ConsumerState<AdBlockerWebView> {
  List<ContentBlocker>? _contentBlockers;
  List<UserScript>? _userScripts;
  String? _bootstrapError;

  /// Host of the page currently rendered by the underlying webview.
  /// Tracked so we can detect when the allowlist decision for the
  /// *current* host changes (vs. a sibling host that doesn't matter).
  String _renderedHost = '';

  /// The blocking decision under which `_contentBlockers` / `_userScripts`
  /// were last built. When this diverges from the live decision for
  /// `_renderedHost`, the page reloads with rebuilt rules.
  bool _renderedBlockingEnabled = true;

  @override
  void initState() {
    super.initState();
    _renderedHost = widget.initialUrl.host.toLowerCase();
    AppLog.d(
      'AdBlockerWebView',
      'initState url=${widget.initialUrl} host=$_renderedHost',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _bootstrap();
    });
  }

  bool _resolveBlockingEnabled() {
    final master = ref.read(contentBlockingProvider);
    if (!master) {
      return false;
    }
    final allowedAsync = ref.read(siteAllowlistProvider);
    final allowed = allowedAsync.value ?? const <String>{};
    if (allowed.isEmpty || _renderedHost.isEmpty) {
      return true;
    }
    final repo = ref.read(siteAllowlistRepositoryProvider);
    return !repo.isAllowedUrl('https://$_renderedHost', allowed);
  }

  Future<void> _bootstrap() async {
    final blockingEnabled = _resolveBlockingEnabled();
    AppLog.d(
      'AdBlockerWebView',
      'bootstrap start url=${widget.initialUrl} '
          'host=$_renderedHost blockingEnabled=$blockingEnabled '
          'platform=${Platform.operatingSystem}',
    );
    try {
      final blockers = await _loadContentBlockers(
        blockingEnabled: blockingEnabled,
      );
      final scripts = await _loadUserScripts(blockingEnabled: blockingEnabled);
      AppLog.d(
        'AdBlockerWebView',
        'bootstrap done '
            'blockers=${blockers.length} userScripts=${scripts.length}',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _contentBlockers = blockers;
        _userScripts = scripts;
        _renderedBlockingEnabled = blockingEnabled;
      });
    } on Object catch (e, st) {
      AppLog.e('AdBlockerWebView', 'bootstrap error', e, st);
      if (!mounted) {
        return;
      }
      setState(() {
        _contentBlockers = const [];
        _userScripts = const [];
        _renderedBlockingEnabled = blockingEnabled;
        _bootstrapError = e.toString();
      });
    }
  }

  /// Builds the native `ContentBlocker` list for Apple platforms.
  /// Returns an empty list on Android/Windows/Linux (no WebKit
  /// `WKContentRuleList`) or when blocking is disabled for this host.
  Future<List<ContentBlocker>> _loadContentBlockers({
    required bool blockingEnabled,
  }) async {
    if (!blockingEnabled) {
      AppLog.d('AdBlockerWebView', '_loadContentBlockers: disabled');
      return const [];
    }
    if (!(Platform.isIOS || Platform.isMacOS)) {
      AppLog.d('AdBlockerWebView', '_loadContentBlockers: non-Apple, skipped');
      return const [];
    }
    AppLog.d('AdBlockerWebView', '_loadContentBlockers: readBlocklist…');
    final entries = await ref.read(filterListServiceProvider).readBlocklist();
    final scoped = _filterEntriesForHost(entries, _renderedHost);
    AppLog.d(
      'AdBlockerWebView',
      '_loadContentBlockers: filtered '
          '${entries.length} → ${scoped.length} for host=$_renderedHost',
    );
    final built = buildContentBlockers(scoped);
    AppLog.d(
      'AdBlockerWebView',
      '_loadContentBlockers: built blockers=${built.length}',
    );
    return built;
  }

  /// Filters the blocklist for a page at [host], keeping the WKContentRuleList
  /// compile under WebKit's practical limit while preserving cross-origin
  /// iframe coverage.
  ///
  /// **Block (network) rules** are filtered by host: we drop any block
  /// whose `if-domain` list is non-empty and doesn't match [host]. The
  /// vast majority of rules in EasyList/uBlock are network blocks
  /// anchored to specific publishers, so this cuts the bulk of the
  /// volume.
  ///
  /// **Cosmetic rules (`css-display-none`)** are kept regardless of
  /// `if-domain`. WebKit applies them per-document, so a rule scoped to
  /// `yahoo.com` still hides the cookie banner inside a cross-origin
  /// iframe that TechCrunch loads from `consent.yahoo.com`. Filtering
  /// these by the parent page's host would silently drop those iframe
  /// rules and leave consent dialogs visible.
  List<Map<String, dynamic>> _filterEntriesForHost(
    List<Map<String, dynamic>> entries,
    String host,
  ) {
    if (host.isEmpty) {
      return entries;
    }
    final result = <Map<String, dynamic>>[];
    for (final e in entries) {
      final action = e['action'] as Map<String, dynamic>;
      if (action['type'] == 'css-display-none') {
        result.add(e);
        continue;
      }
      final trigger = e['trigger'] as Map<String, dynamic>;
      final ifDomain = trigger['if-domain'] as List<dynamic>?;
      if (ifDomain == null || ifDomain.isEmpty) {
        result.add(e);
        continue;
      }
      for (final d in ifDomain) {
        final raw = (d as String).toLowerCase();
        // WebKit if-domain entries may be prefixed with `*` to denote a
        // subdomain match.
        final body = raw.startsWith('*') ? raw.substring(1) : raw;
        if (body.isEmpty) {
          continue;
        }
        if (host == body || host.endsWith('.$body')) {
          result.add(e);
          break;
        }
      }
    }
    return result;
  }

  /// Builds the list of [UserScript]s the webview needs to inject:
  /// - **Scriptlets** (uBO `+js(...)`): all platforms. Injected at
  ///   `AT_DOCUMENT_START` so anti-adblock / consent-detection code is
  ///   neutralised before the page's own scripts run.
  /// - **Fallback CSS hiding** (`<style>` tag with combined selectors):
  ///   non-Apple platforms only. On Apple the equivalent is handled
  ///   natively by WebKit's `WKContentRuleList`.
  Future<List<UserScript>> _loadUserScripts({
    required bool blockingEnabled,
  }) async {
    if (!blockingEnabled) {
      return const [];
    }
    final entries = await ref.read(filterListServiceProvider).readBlocklist();
    final scripts = <UserScript>[];

    // Scriptlets (all platforms).
    final matched = <String>[];
    final unknown = <String>[];
    var hostScopedCandidates = 0;
    for (final entry in entries) {
      final action = entry['action'] as Map<String, dynamic>;
      if (action['type'] != 'scriptlet') {
        continue;
      }
      final trigger = entry['trigger'] as Map<String, dynamic>;
      if (!_triggerMatchesHost(trigger, _renderedHost)) {
        continue;
      }
      hostScopedCandidates += 1;
      final name = action['name'] as String?;
      if (name == null || name.isEmpty) {
        continue;
      }
      final argsRaw = action['args'] as List<dynamic>?;
      final args =
          argsRaw?.map((e) => e as String).toList() ?? const <String>[];
      final js = generateScriptletJs(name, args);
      if (js == null) {
        if (!unknown.contains(name)) {
          unknown.add(name);
        }
        continue;
      }
      matched.add(name);
      scripts.add(
        UserScript(
          source: js,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      );
    }
    AppLog.d(
      'AdBlockerWebView',
      '_loadUserScripts: host=$_renderedHost '
          'matched=${matched.length} candidates=$hostScopedCandidates '
          'unknown=${unknown.length}',
    );
    if (matched.isNotEmpty) {
      AppLog.v('AdBlockerWebView', 'matched scriptlets: ${matched.join(", ")}');
    }
    if (unknown.isNotEmpty) {
      AppLog.w(
        'AdBlockerWebView',
        'UNKNOWN scriptlets (not in library): ${unknown.join(", ")}',
      );
    }

    // Fallback `<style>` hiding for platforms without native ContentBlocker.
    if (!Platform.isIOS && !Platform.isMacOS) {
      final selectors = <String>[];
      for (final entry in entries) {
        final action = entry['action'] as Map<String, dynamic>;
        if (action['type'] != 'css-display-none') {
          continue;
        }
        final sel = action['selector'] as String?;
        if (sel != null && sel.isNotEmpty) {
          selectors.add(sel);
        }
      }
      if (selectors.isNotEmpty) {
        final css = '${selectors.join(', ')} { display: none !important; }';
        final escaped = jsonEncode(css);
        final js =
            '(function(){var s=document.createElement("style");'
            's.setAttribute("data-control-center-injected","1");'
            's.appendChild(document.createTextNode($escaped));'
            '(document.head||document.documentElement).appendChild(s);})();';
        scripts.add(
          UserScript(
            source: js,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
          ),
        );
      }
    }

    return scripts;
  }

  /// True when the rule's trigger applies to [host] — either the rule
  /// has no `if-domain` (universal) or one of its domains matches the
  /// host (exact or subdomain suffix). Mirrors the matching logic used
  /// by [_filterEntriesForHost].
  bool _triggerMatchesHost(Map<String, dynamic> trigger, String host) {
    final ifDomain = trigger['if-domain'] as List<dynamic>?;
    if (ifDomain == null || ifDomain.isEmpty) {
      return true;
    }
    if (host.isEmpty) {
      return false;
    }
    for (final d in ifDomain) {
      final raw = (d as String).toLowerCase();
      final body = raw.startsWith('*') ? raw.substring(1) : raw;
      if (body.isEmpty) {
        continue;
      }
      if (host == body || host.endsWith('.$body')) {
        return true;
      }
    }
    return false;
  }

  /// If the live blocking decision for [_renderedHost] differs from what
  /// was used to build the current `_contentBlockers`/`_userScripts`,
  /// rebuild and reload the page.
  Future<void> _maybeRebuildForCurrentHost() async {
    final live = _resolveBlockingEnabled();
    if (live == _renderedBlockingEnabled) {
      return;
    }
    final blockers = await _loadContentBlockers(blockingEnabled: live);
    final scripts = await _loadUserScripts(blockingEnabled: live);
    if (!mounted) {
      return;
    }
    setState(() {
      _contentBlockers = blockers;
      _userScripts = scripts;
      _renderedBlockingEnabled = live;
    });
    await widget.controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    // React to master switch + allowlist changes. `ref.listen` only fires
    // when the value actually changes, so this won't loop.
    ref.listen<bool>(
      contentBlockingProvider,
      (_, _) => _maybeRebuildForCurrentHost(),
    );
    ref.listen<AsyncValue<Set<String>>>(
      siteAllowlistProvider,
      (_, _) => _maybeRebuildForCurrentHost(),
    );

    final theme = Theme.of(context);
    final blockers = _contentBlockers;
    final scripts = _userScripts;
    final ready = blockers != null && scripts != null;

    if (!ready) {
      return Center(
        child: _bootstrapError != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to prepare reader: $_bootstrapError',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            : const CircularProgressIndicator(),
      );
    }

    AppLog.d(
      'AdBlockerWebView',
      'mounting InAppWebView url=${widget.initialUrl} '
          'blockers=${blockers.length} scripts=${scripts.length}',
    );
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri.uri(widget.initialUrl)),
      initialUserScripts: UnmodifiableListView<UserScript>(scripts),
      initialSettings: InAppWebViewSettings(
        // Use a non-persistent (incognito) data store. WebKit otherwise keeps a
        // per-bundle WebCrypto master key in the login keychain
        // (com.apple.WebKit.WebCrypto.master+...), which prompts whenever a page
        // touches crypto.subtle. A trusted, stable signature does NOT suppress
        // this — verified post-signing — because the item's ACL was minted under
        // a different identity. This is a throwaway reader surface, so dropping
        // cookie/cache persistence is free. Do not remove without re-verifying
        // no WebCrypto keychain prompt returns.
        incognito: true,
        contentBlockers: blockers,
        javaScriptEnabled: true,
        isInspectable: kDebugMode,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      onWebViewCreated: (c) {
        AppLog.d('AdBlockerWebView', 'onWebViewCreated fired');
        widget.controller.attach(c);
      },
      onLoadStart: (c, url) async {
        AppLog.d('AdBlockerWebView', 'onLoadStart url=$url');
        widget.controller.isLoading.value = true;
        if (url != null) {
          widget.controller.currentUrl.value = url.toString();
          _renderedHost = url.host.toLowerCase();
        }
        widget.onLoadStart?.call(url);
        widget.onUrlChanged?.call(url);
      },
      onLoadStop: (c, url) async {
        widget.controller.isLoading.value = false;
        if (url != null) {
          widget.controller.currentUrl.value = url.toString();
          _renderedHost = url.host.toLowerCase();
        }
        try {
          final back = await c.canGoBack();
          final forward = await c.canGoForward();
          widget.controller.navState.value = (
            canGoBack: back,
            canGoForward: forward,
          );
        } on Object {
          // best-effort — nav button state will catch up on next event
        }
        widget.onLoadStop?.call(url);
        widget.onUrlChanged?.call(url);
      },
      onReceivedError: (c, request, error) {
        if (request.isForMainFrame ?? false) {
          widget.controller.isLoading.value = false;
          widget.onLoadError?.call(request.url, error.description);
        }
      },
    );
  }
}
