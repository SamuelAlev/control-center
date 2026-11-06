import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_mcp/src/tools/environment_read_tools.dart';
import 'package:test/test.dart';

import 'environment_tools_test.dart' as shared;

void main() {
  test('the read tools carry no effect class', () {
    // They inherit the tier default; neither runs anything on the host.
    final status = EnvironmentStatusTool(environments: shared.unusedPort());
    final logs = EnvironmentLogsTool(environments: shared.unusedPort());
    expect(status.actionClasses.contains(ActionClass.hostExecution), isFalse);
    expect(logs.actionClasses.contains(ActionClass.hostExecution), isFalse);
    expect(EnvironmentLogsTool.maxTail, 500);
  });
}
