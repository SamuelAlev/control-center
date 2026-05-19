import 'package:cc_domain/features/dispatch/domain/context/tool_result_elision.dart';
import 'package:test/test.dart';

void main() {
  const e = ToolResultElision();

  test('flags an empty grep result', () {
    expect(
      e.isUseless(toolName: 'grep', outputs: 'No matches found', isError: false),
      isTrue,
    );
  });

  test('flags a timed-out job even on a non-search tool', () {
    expect(
      e.isUseless(
        toolName: 'bash',
        outputs: 'command timed out after 30s with no output produced',
        isError: false,
      ),
      isTrue,
    );
  });

  test('keeps a real error message', () {
    expect(
      e.isUseless(
        toolName: 'bash',
        outputs: 'fatal: not a git repository, aborting the operation',
        isError: true,
      ),
      isFalse,
    );
  });

  test('keeps a non-empty search result', () {
    expect(
      e.isUseless(
        toolName: 'grep',
        outputs: 'lib/main.dart:42: final x = 1; // a real hit line here',
        isError: false,
      ),
      isFalse,
    );
  });

  test('never elides protected tools', () {
    expect(
      e.isUseless(
        toolName: 'skill',
        outputs: 'no results' * 20,
        isError: false,
      ),
      isFalse,
    );
  });

  test('classifies empty output as useless', () {
    expect(e.isUseless(toolName: 'grep', outputs: '', isError: false), isTrue);
  });
}
