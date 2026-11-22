import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/services/lane_tool_forms.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/plan_mode_contract.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_harness/context.dart';
import 'package:test/test.dart';

void main() {
  // `bash` is direct in chat; `wake_me` is not, so it is script-only once a
  // run has `repl`.
  ToolCallForms forms(AdapterTransport transport, {required bool hasRepl}) =>
      laneToolForms(transport: transport, mode: Mode.chat, hasRepl: hasRepl);

  test('a harness run with repl: direct tools directly, the rest from a '
      'script', () {
    final f = forms(AdapterTransport.harness, hasRepl: true);
    expect(f('bash'), ToolCallForm.direct);
    expect(f('wake_me'), ToolCallForm.script);
  });

  test('a harness run whose runner cannot run scripts is never told to use '
      'one', () {
    final f = forms(AdapterTransport.harness, hasRepl: false);
    expect(f('bash'), ToolCallForm.direct);
    expect(f('wake_me'), ToolCallForm.direct);
  });

  test('Claude Code and ACP with repl: a script-only tool in its script '
      'form, a direct one by name', () {
    for (final transport in [
      AdapterTransport.claudeCli,
      AdapterTransport.acp,
    ]) {
      final f = forms(transport, hasRepl: true);
      expect(f('bash'), ToolCallForm.plain);
      expect(f('wake_me'), ToolCallForm.script);
    }
  });

  test('Claude Code and ACP without repl: every tool by name', () {
    for (final transport in [
      AdapterTransport.claudeCli,
      AdapterTransport.acp,
    ]) {
      final f = forms(transport, hasRepl: false);
      expect(f('bash'), ToolCallForm.plain);
      expect(f('wake_me'), ToolCallForm.plain);
    }
  });

  test('pinned verbs are direct', () {
    final f = laneToolForms(
      transport: AdapterTransport.harness,
      mode: Mode.plan,
      hasRepl: true,
    );
    expect(f(planModeExitVerb), ToolCallForm.direct);
    expect(f('ask_user'), ToolCallForm.direct);
  });
}
