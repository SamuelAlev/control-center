import 'package:control_center/features/newsfeed/data/mappers/content_blocker_mapper.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildContentBlockers', () {
    test('returns empty list for empty entries', () async {
      expect(buildContentBlockers([]), isEmpty);
    });

    test('builds a block action from a valid entry', () async {
      final blockers = buildContentBlockers([
        {
          'trigger': {
            'url-filter': '.*ads\\.example\\.com.*',
          },
          'action': {'type': 'block'},
        },
      ]);
      expect(blockers.length, 1);
      expect(
        blockers.first.action.type,
        ContentBlockerActionType.BLOCK,
      );
      expect(
        blockers.first.trigger.urlFilter,
        '.*ads\\.example\\.com.*',
      );
    });

    test('builds a css-display-none action with selector', () async {
      final blockers = buildContentBlockers([
        {
          'trigger': {
            'url-filter': '.*',
          },
          'action': {
            'type': 'css-display-none',
            'selector': '.ad-banner',
          },
        },
      ]);
      expect(blockers.length, 1);
      expect(
        blockers.first.action.type,
        ContentBlockerActionType.CSS_DISPLAY_NONE,
      );
      expect(blockers.first.action.selector, '.ad-banner');
    });

    test('defaults url-filter to .* when missing', () async {
      final blockers = buildContentBlockers([
        {
          'trigger': <String, dynamic>{},
          'action': {'type': 'block'},
        },
      ]);
      expect(blockers.length, 1);
      expect(blockers.first.trigger.urlFilter, '.*');
    });

    test('skips css-display-none with empty selector', () async {
      final blockers = buildContentBlockers([
        {
          'trigger': {'url-filter': '.*'},
          'action': {
            'type': 'css-display-none',
            'selector': '',
          },
        },
      ]);
      expect(blockers, isEmpty);
    });

    test('skips css-display-none with null selector', () async {
      final blockers = buildContentBlockers([
        {
          'trigger': {'url-filter': '.*'},
          'action': {
            'type': 'css-display-none',
            'selector': null,
          },
        },
      ]);
      expect(blockers, isEmpty);
    });

    test('skips unknown action types like scriptlet', () async {
      final blockers = buildContentBlockers([
        {
          'trigger': {'url-filter': '.*'},
          'action': {'type': 'scriptlet'},
        },
      ]);
      expect(blockers, isEmpty);
    });

    test('passes valid if-domain entries', () async {
      final blockers = buildContentBlockers([
        {
          'trigger': {
            'url-filter': '.*',
            'if-domain': ['example.com', '*sub.example.com'],
          },
          'action': {'type': 'block'},
        },
      ]);
      expect(blockers.length, 1);
      expect(
        blockers.first.trigger.ifDomain,
        ['example.com', '*sub.example.com'],
      );
    });

    test('drops entry when all if-domain entries are invalid', () async {
      final blockers = buildContentBlockers([
        {
          'trigger': {
            'url-filter': '.*',
            'if-domain': ['/has/slash', 'UPPERCASE'],
          },
          'action': {'type': 'block'},
        },
      ]);
      // All if-domain entries are invalid → dropped entirely.
      expect(blockers, isEmpty);
    });

    test('keeps entry when some if-domain entries are valid', () async {
      final blockers = buildContentBlockers([
        {
          'trigger': {
            'url-filter': '.*',
            'if-domain': ['valid.com', '/invalid/path'],
          },
          'action': {'type': 'block'},
        },
      ]);
      expect(blockers.length, 1);
      expect(blockers.first.trigger.ifDomain, ['valid.com']);
    });

    test('parses resource types', () async {
      final blockers = buildContentBlockers([
        {
          'trigger': {
            'url-filter': '.*',
            'resource-type': ['image', 'script'],
          },
          'action': {'type': 'block'},
        },
      ]);
      expect(blockers.length, 1);
      expect(
        blockers.first.trigger.resourceType,
        containsAll([
          ContentBlockerTriggerResourceType.IMAGE,
          ContentBlockerTriggerResourceType.SCRIPT,
        ]),
      );
    });

    test('ignores unknown resource types', () async {
      final blockers = buildContentBlockers([
        {
          'trigger': {
            'url-filter': '.*',
            'resource-type': ['image', 'unknown-type'],
          },
          'action': {'type': 'block'},
        },
      ]);
      expect(blockers.length, 1);
      expect(
        blockers.first.trigger.resourceType,
        [ContentBlockerTriggerResourceType.IMAGE],
      );
    });

    test('handles all known resource types', () async {
      final blockers = buildContentBlockers([
        {
          'trigger': {
            'url-filter': '.*',
            'resource-type': [
              'image',
              'media',
              'script',
              'stylesheet',
              'font',
            ],
          },
          'action': {'type': 'block'},
        },
      ]);
      expect(blockers.length, 1);
      expect(
        blockers.first.trigger.resourceType,
        containsAll([
          ContentBlockerTriggerResourceType.IMAGE,
          ContentBlockerTriggerResourceType.MEDIA,
          ContentBlockerTriggerResourceType.SCRIPT,
          ContentBlockerTriggerResourceType.STYLE_SHEET,
          ContentBlockerTriggerResourceType.FONT,
        ]),
      );
    });

    test('processes multiple entries in order', () async {
      final blockers = buildContentBlockers([
        {
          'trigger': {'url-filter': '.*first.*'},
          'action': {'type': 'block'},
        },
        {
          'trigger': {'url-filter': '.*second.*'},
          'action': {
            'type': 'css-display-none',
            'selector': '.ad',
          },
        },
      ]);
      expect(blockers.length, 2);
      expect(blockers[0].trigger.urlFilter, '.*first.*');
      expect(blockers[1].trigger.urlFilter, '.*second.*');
    });

    test('entry with null if-domain defaults to empty list', () async {
      final blockers = buildContentBlockers([
        {
          'trigger': {
            'url-filter': '.*',
          },
          'action': {'type': 'block'},
        },
      ]);
      expect(blockers.length, 1);
      expect(blockers.first.trigger.ifDomain, isEmpty);
    });
  });
}
