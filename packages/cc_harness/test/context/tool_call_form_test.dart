import 'package:cc_harness/context.dart';
import 'package:test/test.dart';

void main() {
  test('each form names the call the run can make', () {
    expect(toolCallText(ToolCallForm.direct, 'x', 'id: "1"'), 'x({id: "1"})');
    expect(
      toolCallText(ToolCallForm.script, 'x', 'id: "1"'),
      'await tools.x({id: "1"})',
    );
    expect(toolCallText(ToolCallForm.plain, 'x', 'id: "1"'), 'x(id: "1")');
  });

  test('without arguments', () {
    expect(toolCallText(ToolCallForm.direct, 'x'), 'x({})');
    expect(toolCallText(ToolCallForm.script, 'x'), 'await tools.x({})');
    expect(toolCallText(ToolCallForm.plain, 'x'), 'x');
  });

  test('a known surface: script-only beats callable, unknown is plain', () {
    final forms = toolFormsOver(callable: ['a', 'b'], scriptOnly: ['b', 'c']);
    expect(forms('a'), ToolCallForm.direct);
    expect(forms('b'), ToolCallForm.script);
    expect(forms('c'), ToolCallForm.script);
    expect(forms('d'), ToolCallForm.plain);
    expect(toolCallIn(forms, 'c', 'h: 1'), 'await tools.c({h: 1})');
    expect(plainToolForm('a'), ToolCallForm.plain);
  });
}
