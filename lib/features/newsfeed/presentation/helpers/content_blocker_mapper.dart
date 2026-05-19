import 'package:cc_domain/features/newsfeed/domain/helpers/abp_parser.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Maps cached blocklist JSON entries into the typed
/// [ContentBlocker] objects expected by `flutter_inappwebview`.
///
/// Used by both the article reader (to attach blockers to the webview)
/// and the pre-warm service (to compile WebKit's content rule list
/// ahead of the first article open).
List<ContentBlocker> buildContentBlockers(List<Map<String, dynamic>> entries) {
  final blockers = <ContentBlocker>[];
  for (final e in entries) {
    final trigger = e['trigger'] as Map<String, dynamic>;
    final action = e['action'] as Map<String, dynamic>;
    final actionType = action['type'] as String?;

    final ifDomainRaw = trigger['if-domain'] as List<dynamic>?;
    final ifDomain =
        ifDomainRaw
            ?.map((s) => s as String)
            .where(AbpParser.isValidIfDomain)
            .toList() ??
        const <String>[];
    // Drop network-block entries whose if-domain list was non-empty but
    // became empty after validation — emitting them with no domain
    // filter would block everything on every site.
    if ((ifDomainRaw?.isNotEmpty ?? false) && ifDomain.isEmpty) {
      continue;
    }
    final resourceType =
        (trigger['resource-type'] as List<dynamic>?)
            ?.map((s) => _parseResourceType(s as String))
            .whereType<ContentBlockerTriggerResourceType>()
            .toList() ??
        const <ContentBlockerTriggerResourceType>[];

    final cbTrigger = ContentBlockerTrigger(
      urlFilter: (trigger['url-filter'] as String?) ?? '.*',
      ifDomain: ifDomain,
      resourceType: resourceType,
    );

    if (actionType == 'css-display-none') {
      final selector = action['selector'] as String?;
      if (selector == null || selector.isEmpty) {
        continue;
      }
      blockers.add(
        ContentBlocker(
          trigger: cbTrigger,
          action: ContentBlockerAction(
            type: ContentBlockerActionType.CSS_DISPLAY_NONE,
            selector: selector,
          ),
        ),
      );
    } else if (actionType == 'block') {
      blockers.add(
        ContentBlocker(
          trigger: cbTrigger,
          action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
        ),
      );
    }
    // Other action types (e.g. 'scriptlet') are not WKContentRuleList
    // actions — they're handled separately by the AdBlockerWebView via
    // runtime JS injection. Silently skip here.
  }
  return blockers;
}

ContentBlockerTriggerResourceType? _parseResourceType(String s) {
  switch (s) {
    case 'image':
      return ContentBlockerTriggerResourceType.IMAGE;
    case 'media':
      return ContentBlockerTriggerResourceType.MEDIA;
    case 'script':
      return ContentBlockerTriggerResourceType.SCRIPT;
    case 'stylesheet':
      return ContentBlockerTriggerResourceType.STYLE_SHEET;
    case 'font':
      return ContentBlockerTriggerResourceType.FONT;
    default:
      return null;
  }
}
