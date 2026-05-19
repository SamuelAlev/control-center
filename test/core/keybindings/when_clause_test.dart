import 'package:control_center/core/keybindings/when_clause.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool eval(String expr, [Map<String, Object?> ctx = const {}]) =>
      WhenClause.parse(expr).evaluate(ctx);

  group('WhenClause truthiness', () {
    test('empty/null clause is always true', () {
      expect(eval(''), isTrue);
      expect(WhenClause.parse(null).evaluate(const {}), isTrue);
      expect(eval('   '), isTrue);
    });

    test('bare key reads context truthiness', () {
      expect(eval('focus', {'focus': true}), isTrue);
      expect(eval('focus', {'focus': false}), isFalse);
      expect(eval('focus', const {}), isFalse);
      expect(eval('focus', {'focus': 'yes'}), isTrue);
      expect(eval('focus', {'focus': ''}), isFalse);
      expect(eval('focus', {'focus': 0}), isFalse);
      expect(eval('focus', {'focus': 'false'}), isFalse);
    });

    test('literals', () {
      expect(eval('true'), isTrue);
      expect(eval('false'), isFalse);
    });
  });

  group('WhenClause operators', () {
    test('negation', () {
      expect(eval('!textInputFocus', {'textInputFocus': true}), isFalse);
      expect(eval('!textInputFocus', {'textInputFocus': false}), isTrue);
      expect(eval('!textInputFocus', const {}), isTrue);
    });

    test('equality with quoted value', () {
      expect(eval("route == '/dashboard'", {'route': '/dashboard'}), isTrue);
      expect(eval("route == '/dashboard'", {'route': '/dashboard/1'}), isFalse);
      expect(eval("route == '/dashboard'", const {}), isFalse);
    });

    test('inequality', () {
      expect(eval("mode != 'insert'", {'mode': 'normal'}), isTrue);
      expect(eval("mode != 'insert'", {'mode': 'insert'}), isFalse);
    });

    test('bareword comparison value', () {
      expect(eval('lang == typescript', {'lang': 'typescript'}), isTrue);
      expect(eval('lang == typescript', {'lang': 'dart'}), isFalse);
    });

    test('regex match', () {
      expect(
        eval(r'route =~ /^\/pull-requests\//',{'route': '/pull-requests/42'}),
        isTrue,
      );
      expect(
        eval(r'route =~ /^\/pull-requests\//',{'route': '/pull-requests'}),
        isFalse,
      );
    });
  });

  group('WhenClause precedence & grouping', () {
    test('and binds tighter than or', () {
      // a || b && c  ==  a || (b && c)
      expect(eval('a || b && c', {'a': true, 'b': false, 'c': false}), isTrue);
      expect(eval('a || b && c', {'a': false, 'b': true, 'c': false}), isFalse);
      expect(eval('a || b && c', {'a': false, 'b': true, 'c': true}), isTrue);
    });

    test('parentheses override precedence', () {
      expect(eval('(a || b) && c', {'a': true, 'b': false, 'c': false}), isFalse);
      expect(eval('(a || b) && c', {'a': true, 'b': false, 'c': true}), isTrue);
    });

    test('realistic combined clause', () {
      const clause = "route == '/messaging' && !textInputFocus";
      expect(eval(clause, {'route': '/messaging'}), isTrue);
      expect(
        eval(clause, {'route': '/messaging', 'textInputFocus': true}),
        isFalse,
      );
      expect(eval(clause, {'route': '/workspaces'}), isFalse);
    });
  });

  group('WhenClause malformed input', () {
    test('disables the binding (evaluates false) rather than crashing', () {
      expect(eval('route =='), isFalse);
      expect(eval('&&'), isFalse);
      expect(eval('(a || b'), isFalse);
    });
  });
}
