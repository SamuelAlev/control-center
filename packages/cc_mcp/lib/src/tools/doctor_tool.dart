import 'package:cc_domain/features/agents/domain/entities/diagnostic_result.dart';
import 'package:cc_domain/features/agents/domain/ports/doctor_port.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// MCP tool that runs health diagnostics for the Control Center environment.
class DoctorTool extends McpTool {

  /// Creates a [DoctorTool].
  DoctorTool({required this.doctorPort});

  /// The port used to run health diagnostics.
  final DoctorPort doctorPort;

  @override
  String get name => 'doctor';

  @override
  String get description =>
      'Run health diagnostics for the Control Center environment. '
      'Checks sandbox backend, database, CLI tools, disk space, and network.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'repair': {
            'type': 'boolean',
            'description':
                'Whether to attempt auto-repair for detected issues',
          },
        },
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final report = await doctorPort.runDiagnostics();

    final buf = StringBuffer();
    buf.writeln('## Control Center Health Report');
    buf.writeln();

    for (final result in report.results) {
      final icon = switch (result.status) {
        DiagnosticStatus.ok => '[OK]',
        DiagnosticStatus.warning => '[WARN]',
        DiagnosticStatus.error => '[FAIL]',
      };
      buf.writeln('$icon **${result.name}**: ${result.message ?? "OK"}');
    }

    buf.writeln();
    if (report.allOk) {
      buf.writeln('All checks passed.');
    } else {
      buf.writeln(
        '${report.errorCount} error(s), ${report.warningCount} warning(s).',
      );
    }

    return CallResult.success(buf.toString());
  }
}
