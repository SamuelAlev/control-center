import 'package:cc_infra/src/newsfeed/scriptlet_library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateScriptletJs', () {
    test('returns null for unknown scriptlet', () {
      expect(generateScriptletJs('does-not-exist', const []), isNull);
    });

    test('prevent-addEventListener emits IIFE that wraps EventTarget', () {
      final js = generateScriptletJs(
        'prevent-addEventListener',
        ['load', '.indexOf'],
      );
      expect(js, isNotNull);
      expect(js, startsWith('(function(){'));
      expect(js, endsWith('})();'));
      // Args inlined as JSON-encoded literals.
      expect(js, contains('"load"'));
      expect(js, contains('".indexOf"'));
      expect(js, contains('EventTarget.prototype.addEventListener'));
    });

    test('aeld alias maps to prevent-addEventListener', () {
      final a = generateScriptletJs('aeld', ['x', 'y']);
      final b = generateScriptletJs('prevent-addEventListener', ['x', 'y']);
      expect(a, equals(b));
    });

    test('set-constant inlines the value chain', () {
      final js = generateScriptletJs('set-constant', [
        'window.adsbygoogle',
        'noopFunc',
      ]);
      expect(js, isNotNull);
      expect(js, contains('"window.adsbygoogle"'));
      expect(js, contains('"noopFunc"'));
      expect(js, contains('Object.defineProperty'));
    });

    test('set alias maps to set-constant', () {
      final a = generateScriptletJs('set', ['a.b', '1']);
      final b = generateScriptletJs('set-constant', ['a.b', '1']);
      expect(a, equals(b));
    });

    test('set-constant tolerates missing value (no crash)', () {
      final js = generateScriptletJs('set-constant', ['only.chain']);
      expect(js, isNotNull);
      expect(js, contains('"only.chain"'));
    });

    test('set-constant with no args produces a safe no-op', () {
      final js = generateScriptletJs('set-constant', const []);
      expect(js, isNotNull);
      expect(js!.trim(), '(function(){})();');
    });

    test('abort-on-property-read uses ReferenceError', () {
      final js = generateScriptletJs('abort-on-property-read', [
        'window.canRunAds',
      ]);
      expect(js, isNotNull);
      expect(js, contains('"window.canRunAds"'));
      expect(js, contains('ReferenceError'));
    });

    test('aopr alias maps to abort-on-property-read', () {
      final a = generateScriptletJs('aopr', ['x']);
      final b = generateScriptletJs('abort-on-property-read', ['x']);
      expect(a, equals(b));
    });

    test('no-setInterval-if overrides window.setInterval', () {
      final js = generateScriptletJs('no-setInterval-if', ['ads']);
      expect(js, isNotNull);
      expect(js, contains('window.setInterval'));
      expect(js, contains('"ads"'));
    });

    test('nostif alias maps to no-setInterval-if', () {
      final a = generateScriptletJs('nostif', ['x']);
      final b = generateScriptletJs('no-setInterval-if', ['x']);
      expect(a, equals(b));
    });

    test('no-setTimeout-if overrides window.setTimeout', () {
      final js = generateScriptletJs('no-setTimeout-if', ['ads']);
      expect(js, isNotNull);
      expect(js, contains('window.setTimeout'));
      expect(js, contains('"ads"'));
    });

    test('nosttf alias maps to no-setTimeout-if', () {
      final a = generateScriptletJs('nosttf', ['x']);
      final b = generateScriptletJs('no-setTimeout-if', ['x']);
      expect(a, equals(b));
    });

    test('prevent-setTimeout alias maps to no-setTimeout-if', () {
      final a = generateScriptletJs('prevent-setTimeout', ['.indexOf']);
      final b = generateScriptletJs('no-setTimeout-if', ['.indexOf']);
      expect(a, equals(b));
    });

    test('prevent-setInterval alias maps to no-setInterval-if', () {
      final a = generateScriptletJs('prevent-setInterval', ['ads']);
      final b = generateScriptletJs('no-setInterval-if', ['ads']);
      expect(a, equals(b));
    });

    test('abort-current-script hooks the target property', () {
      final js = generateScriptletJs('abort-current-script', [
        'document.getElementsByTagName',
        '.pubads',
      ]);
      expect(js, isNotNull);
      expect(js, contains('"document.getElementsByTagName"'));
      expect(js, contains('".pubads"'));
      expect(js, contains('Object.defineProperty'));
      expect(js, contains('ReferenceError'));
    });

    test('acs alias maps to abort-current-script', () {
      final a = generateScriptletJs('acs', ['a', 'b']);
      final b = generateScriptletJs('abort-current-script', ['a', 'b']);
      expect(a, equals(b));
    });

    test('abort-current-script with no args is a safe no-op', () {
      final js = generateScriptletJs('abort-current-script', const []);
      expect(js, isNotNull);
      expect(js!.trim(), '(function(){})();');
    });

    test('remove-node-text hooks script textContent + MutationObserver', () {
      final js = generateScriptletJs('remove-node-text', [
        'script',
        '/foo|bar/',
      ]);
      expect(js, isNotNull);
      expect(js, contains('"script"'));
      expect(js, contains('"/foo|bar/"'));
      expect(js, contains('MutationObserver'));
      expect(js, contains('HTMLScriptElement.prototype'));
    });

    test('rmnt alias maps to remove-node-text', () {
      final a = generateScriptletJs('rmnt', ['script', 'x']);
      final b = generateScriptletJs('remove-node-text', ['script', 'x']);
      expect(a, equals(b));
    });

    test('remove-node-text with <2 args is a safe no-op', () {
      expect(
        generateScriptletJs('remove-node-text', const [])!.trim(),
        '(function(){})();',
      );
      expect(
        generateScriptletJs('remove-node-text', ['script'])!.trim(),
        '(function(){})();',
      );
    });

    test('set-attr emits selector + attr + value', () {
      final js = generateScriptletJs('set-attr', [
        'c-wiz[data-p] a',
        'rlhc',
        '1',
      ]);
      expect(js, isNotNull);
      expect(js, contains('"c-wiz[data-p] a"'));
      expect(js, contains('"rlhc"'));
      expect(js, contains('"1"'));
      expect(js, contains('setAttribute'));
      expect(js, contains('MutationObserver'));
    });

    test('sa alias maps to set-attr', () {
      final a = generateScriptletJs('sa', ['div', 'data-x', 'y']);
      final b = generateScriptletJs('set-attr', ['div', 'data-x', 'y']);
      expect(a, equals(b));
    });

    test('set-attr with <2 args is a safe no-op', () {
      expect(
        generateScriptletJs('set-attr', const [])!.trim(),
        '(function(){})();',
      );
      expect(
        generateScriptletJs('set-attr', ['div'])!.trim(),
        '(function(){})();',
      );
    });

    test('trusted-click-element emits selector + delay + DOM-ready guard', () {
      final js = generateScriptletJs('trusted-click-element', [
        '#didomi-notice-agree-button',
        '',
        '1000',
      ]);
      expect(js, isNotNull);
      expect(js, contains('"#didomi-notice-agree-button"'));
      expect(js, contains('1000'));
      expect(js, contains('querySelectorAll'));
      expect(js, contains('.click()'));
      expect(js, contains('DOMContentLoaded'));
      expect(js, contains('MutationObserver'));
      // Beyond a bare .click(), we also dispatch a synthetic mouse
      // sequence so CMPs that hook pointerdown/mouseup also fire.
      expect(js, contains('pointerdown'));
      expect(js, contains('mousedown'));
      expect(js, contains('mouseup'));
      expect(js, contains('MouseEvent'));
      // Observer must watch attributes too, so display:none → block
      // transitions trigger a click attempt.
      expect(js, contains('attributes: true'));
      // Only visible elements are clicked.
      expect(js, contains('getBoundingClientRect'));
      // Throttle so we don't loop hot.
      expect(js, contains('THROTTLE_MS'));
    });

    test('click-element alias maps to trusted-click-element', () {
      final a = generateScriptletJs('click-element', ['#x', '', '500']);
      final b = generateScriptletJs('trusted-click-element', [
        '#x',
        '',
        '500',
      ]);
      expect(a, equals(b));
    });

    test('trusted-click-element non-numeric delay falls back to 0', () {
      final js = generateScriptletJs('trusted-click-element', [
        '#x',
        '',
        'not-a-number',
      ]);
      expect(js, isNotNull);
      expect(js, contains('DELAY=0'));
    });

    test('trusted-click-element with no args is a safe no-op', () {
      expect(
        generateScriptletJs('trusted-click-element', const [])!.trim(),
        '(function(){})();',
      );
    });

    test('cookie-remover sets expired cookie across parent domains', () {
      final js = generateScriptletJs('cookie-remover', ['consent-token']);
      expect(js, isNotNull);
      expect(js, contains('"consent-token"'));
      expect(js, contains('document.cookie'));
      expect(js, contains('01 Jan 1970'));
      expect(js, contains('setInterval'));
      expect(js, contains('location.hostname'));
    });

    test('remove-cookie alias maps to cookie-remover', () {
      final a = generateScriptletJs('remove-cookie', ['x']);
      final b = generateScriptletJs('cookie-remover', ['x']);
      expect(a, equals(b));
    });

    test('cookie-remover with regex needle compiles RegExp', () {
      final js = generateScriptletJs('cookie-remover', ['/^euconsent-/']);
      expect(js, isNotNull);
      expect(js, contains('new RegExp'));
    });

    test('cookie-remover with no args is a safe no-op', () {
      expect(
        generateScriptletJs('cookie-remover', const [])!.trim(),
        '(function(){})();',
      );
    });

    test('set-local-storage-item writes value via localStorage.setItem', () {
      final js = generateScriptletJs('set-local-storage-item', [
        'consent.accepted',
        'true',
      ]);
      expect(js, isNotNull);
      expect(js, contains('"consent.accepted"'));
      expect(js, contains('"true"'));
      expect(js, contains('localStorage.setItem'));
    });

    test('set-localstorage-item alias maps to set-local-storage-item', () {
      final a = generateScriptletJs('set-localstorage-item', ['k', 'v']);
      final b = generateScriptletJs('set-local-storage-item', ['k', 'v']);
      expect(a, equals(b));
    });

    test(r'set-local-storage-item with $remove$ deletes the key', () {
      final js = generateScriptletJs(
        'set-local-storage-item',
        ['stale-key', r'$remove$'],
      );
      expect(js, isNotNull);
      expect(js, contains('localStorage.removeItem'));
    });

    test('set-local-storage-item with <2 args is a safe no-op', () {
      expect(
        generateScriptletJs('set-local-storage-item', const [])!.trim(),
        '(function(){})();',
      );
      expect(
        generateScriptletJs('set-local-storage-item', ['k'])!.trim(),
        '(function(){})();',
      );
    });

    test('args are JSON-encoded so they cannot break out of the string', () {
      // Hostile arg with quotes/backslashes — must end up inside a JSON
      // string literal in the source, not as bare JS.
      final js = generateScriptletJs('prevent-addEventListener', [
        'click',
        r'"); alert(1); //',
      ]);
      expect(js, isNotNull);
      // The closing-paren-then-statement attack must be neutralised:
      // the encoded form will contain escaped quotes and the bare
      // `alert(1)` must never appear unquoted in our output.
      expect(js, contains(r'\"'));
      // The arg appears inside a JSON-encoded literal, so the quote that
      // would have terminated the JS string is escaped.
    });
  });
}
