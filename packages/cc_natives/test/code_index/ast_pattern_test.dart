import 'package:cc_natives/cc_natives.dart';
import 'package:test/test.dart';

/// Builds a node from a compact literal shape, so the matcher can be tested
/// without a grammar. The text of a parent is its children joined — enough for
/// the equality constraint, which compares normalized text.
AstNode n(String type, {String? text, List<AstNode> children = const []}) {
  final resolved =
      text ?? (children.isEmpty ? type : children.map((c) => c.text).join(' '));
  return AstNode(
    type: type,
    isNamed: !type.startsWith('#'),
    startByte: 0,
    endByte: resolved.length,
    startLine: 1,
    endLine: 1,
    text: resolved,
    children: children,
  );
}

/// `foo(a, b)` as most grammars shape it.
AstNode call(String fn, List<AstNode> args) => n(
  'call',
  children: [
    n('identifier', text: fn),
    // The parentheses are anonymous tokens a real grammar emits, and they
    // matter here: a metavariable is recognized by a node's WHOLE text, so an
    // argument list rendered without them would read as one itself.
    n(
      'arguments',
      text: '(${args.map((a) => a.text).join(', ')})',
      children: args,
    ),
  ],
);

AstNode id(String name) => n('identifier', text: name);

/// A pattern arrives wrapped in whatever the grammar needed to make it a file.
AstNode wrapped(AstNode inner) => n(
  'program',
  text: inner.text,
  children: [
    n('expression_statement', text: inner.text, children: [inner]),
  ],
);

void main() {
  group('significantNode', () {
    test('strips the wrappers the grammar added to make a file', () {
      final inner = call('foo', [id(r'$X')]);
      expect(AstPatternMatcher.significantNode(wrapped(inner)).type, 'call');
    });

    test('stops at a node that says something the pattern meant', () {
      // `return foo()` must not decay to `foo()` — the `return` is the point.
      final ret = n(
        'return_statement',
        text: 'return foo()',
        children: [call('foo', const [])],
      );
      expect(AstPatternMatcher.significantNode(ret).type, 'return_statement');
    });
  });

  group('matching', () {
    test('a metavariable binds one node', () {
      final matcher = AstPatternMatcher(wrapped(call('foo', [id(r'$X')])));
      final matches = matcher.findAll(call('foo', [id('bar')]));
      expect(matches, hasLength(1));
      expect(matches.single[r'X'], 'bar');
    });

    test('a literal in the pattern is asserted, not wildcarded', () {
      final matcher = AstPatternMatcher(wrapped(call('foo', [id('a')])));
      expect(matcher.findAll(call('foo', [id('b')])), isEmpty);
      expect(matcher.findAll(call('foo', [id('a')])), hasLength(1));
    });

    test('a repeated metavariable requires equal text', () {
      // `if ($X) dispose($X)` — the whole reason metavariables beat wildcards.
      final pattern = n(
        'if',
        children: [
          id(r'$X'),
          call('dispose', [id(r'$X')]),
        ],
      );
      final matcher = AstPatternMatcher(pattern);

      final same = n(
        'if',
        children: [
          id('a'),
          call('dispose', [id('a')]),
        ],
      );
      final different = n(
        'if',
        children: [
          id('a'),
          call('dispose', [id('b')]),
        ],
      );

      expect(matcher.findAll(same), hasLength(1));
      expect(
        matcher.findAll(different),
        isEmpty,
        reason:
            'disposing something other than what was tested is the bug '
            'this pattern exists to find',
      );
    });

    test(r'$_ is a wildcard and does not unify with itself', () {
      final pattern = n(
        'if',
        children: [
          id(r'$_'),
          call('dispose', [id(r'$_')]),
        ],
      );
      final matcher = AstPatternMatcher(pattern);
      final different = n(
        'if',
        children: [
          id('a'),
          call('dispose', [id('b')]),
        ],
      );
      expect(matcher.findAll(different), hasLength(1));
    });

    test('a different node type does not match', () {
      final matcher = AstPatternMatcher(call('foo', [id(r'$X')]));
      expect(
        matcher.findAll(n('index', children: [id('foo'), id('a')])),
        isEmpty,
      );
    });

    test('arity must match without a variadic metavariable', () {
      final matcher = AstPatternMatcher(call('foo', [id(r'$X')]));
      expect(matcher.findAll(call('foo', [id('a'), id('b')])), isEmpty);
    });

    test(r'$$$ absorbs a run of any length', () {
      final matcher = AstPatternMatcher(call('foo', [id(r'$$$ARGS')]));
      expect(matcher.findAll(call('foo', const [])), hasLength(1));
      expect(matcher.findAll(call('foo', [id('a'), id('b')])), hasLength(1));
      expect(
        matcher
            .findAll(call('foo', [id('a'), id('b')]))
            .single
            .bindings[r'$$$ARGS']
            ?.text,
        'a, b',
      );
    });

    test(r'$$$ backtracks so a trailing literal still anchors', () {
      final matcher = AstPatternMatcher(
        call('foo', [id(r'$$$HEAD'), id('last')]),
      );
      final matches = matcher.findAll(
        call('foo', [id('a'), id('b'), id('last')]),
      );
      expect(matches, hasLength(1));
      expect(matches.single.bindings[r'$$$HEAD']?.text, 'a, b');
      expect(matcher.findAll(call('foo', [id('a'), id('b')])), isEmpty);
    });

    test('nested matches are both reported', () {
      // Dropping the inner one would make a rewrite silently incomplete.
      final matcher = AstPatternMatcher(call('foo', [id(r'$X')]));
      final nested = call('foo', [
        n(
          'arg',
          text: 'x',
          children: [
            call('foo', [id('y')]),
          ],
        ),
      ]);
      expect(
        matcher.findAll(nested),
        hasLength(2),
        reason: 'the outer call and the inner one are two real sites',
      );

      final twice = n(
        'block',
        children: [
          call('foo', [id('a')]),
          call('foo', [id('b')]),
        ],
      );
      expect(matcher.findAll(twice), hasLength(2));
    });

    test('a failed branch leaves no bindings behind', () {
      // The bug this guards: a partial match binds $X, fails, and the stale
      // binding then makes the NEXT candidate fail its equality check.
      final matcher = AstPatternMatcher(
        n(
          'if',
          children: [
            id(r'$X'),
            call('dispose', [id(r'$X')]),
          ],
        ),
      );
      final subject = n(
        'block',
        children: [
          n(
            'if',
            children: [
              id('a'),
              call('dispose', [id('b')]),
            ],
          ),
          n(
            'if',
            children: [
              id('c'),
              call('dispose', [id('c')]),
            ],
          ),
        ],
      );
      final matches = matcher.findAll(subject);
      expect(matches, hasLength(1));
      expect(matches.single[r'X'], 'c');
    });

    test('honours the match limit', () {
      final matcher = AstPatternMatcher(call('foo', [id(r'$X')]));
      final many = n(
        'block',
        children: [
          for (var i = 0; i < 10; i++) call('foo', [id('a$i')]),
        ],
      );
      expect(matcher.findAll(many, limit: 3), hasLength(3));
    });
  });

  group('renderAstRewrite', () {
    AstMatch matchOf(AstNode pattern, AstNode subject) =>
        AstPatternMatcher(pattern).findAll(subject).single;

    test('substitutes a bound metavariable', () {
      final m = matchOf(call('foo', [id(r'$X')]), call('foo', [id('bar')]));
      expect(renderAstRewrite(r'baz($X)', m), 'baz(bar)');
    });

    test('substitutes a variadic run', () {
      final m = matchOf(
        call('foo', [id(r'$$$A')]),
        call('foo', [id('x'), id('y')]),
      );
      expect(renderAstRewrite(r'baz($$$A)', m), 'baz(x, y)');
    });

    test('leaves an unbound metavariable verbatim', () {
      // Emitting nothing would produce plausible code with a hole in it — the
      // worst outcome for a rewrite nobody reads character by character.
      final m = matchOf(call('foo', [id(r'$X')]), call('foo', [id('bar')]));
      expect(renderAstRewrite(r'baz($X, $Y)', m), r'baz(bar, $Y)');
    });

    test('leaves a bare dollar alone', () {
      final m = matchOf(call('foo', [id(r'$X')]), call('foo', [id('bar')]));
      expect(renderAstRewrite(r'r"$" + $X', m), r'r"$" + bar');
    });

    test('does not stop at a metavariable adjacent to punctuation', () {
      final m = matchOf(call('foo', [id(r'$X')]), call('foo', [id('bar')]));
      expect(renderAstRewrite(r'$X.dispose();', m), 'bar.dispose();');
    });
  });
}
