import 'package:control_center/features/agents/domain/entities/diagnostic_result.dart';
import 'package:control_center/features/agents/domain/ports/doctor_port.dart';
import 'package:control_center/features/mcp/application/tools/doctor_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDoctorPort implements DoctorPort {
  DoctorReport? _report;

  void stub(DoctorReport report) => _report = report;

  @override
  Future<DoctorReport> runDiagnostics() async => _report!;
}

void main() {
  group('DoctorTool', () {
    late _FakeDoctorPort fakePort;
    late DoctorTool tool;

    setUp(() {
      fakePort = _FakeDoctorPort();
      tool = DoctorTool(doctorPort: fakePort);
    });

    test('name is doctor', () {
      expect(tool.name, 'doctor');
    });

    test('reports all-ok when every check passes', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(name: 'db', status: DiagnosticStatus.ok),
        DiagnosticResult(name: 'disk', status: DiagnosticStatus.ok),
        DiagnosticResult(
          name: 'cli',
          status: DiagnosticStatus.ok,
          message: 'All CLI tools found',
        ),
      ]));

      final result = await tool.run({});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('[OK]'));
      expect(result.content.first.text, contains('All checks passed'));
      expect(result.content.first.text, isNot(contains('[WARN]')));
      expect(result.content.first.text, isNot(contains('[FAIL]')));
    });

    test('reports warnings and errors with counts', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(name: 'db', status: DiagnosticStatus.ok),
        DiagnosticResult(
          name: 'disk',
          status: DiagnosticStatus.warning,
          message: 'Disk 80% full',
        ),
        DiagnosticResult(
          name: 'network',
          status: DiagnosticStatus.error,
          message: 'No internet',
        ),
        DiagnosticResult(
          name: 'sandbox',
          status: DiagnosticStatus.error,
          message: 'Sandbox backend unreachable',
        ),
      ]));

      final result = await tool.run({});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('[OK]'));
      expect(result.content.first.text, contains('[WARN]'));
      expect(result.content.first.text, contains('[FAIL]'));
      expect(result.content.first.text, contains('2 error(s), 1 warning(s)'));
    });

    test('reports warnings-only correctly', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(name: 'db', status: DiagnosticStatus.ok),
        DiagnosticResult(
          name: 'disk',
          status: DiagnosticStatus.warning,
          message: 'Low space',
        ),
      ]));

      final result = await tool.run({});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('0 error(s), 1 warning(s)'));
      expect(result.content.first.text, isNot(contains('[FAIL]')));
    });

    test('reports error-only correctly', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(name: 'db', status: DiagnosticStatus.ok),
        DiagnosticResult(
          name: 'sandbox',
          status: DiagnosticStatus.error,
          message: 'Down',
        ),
      ]));

      final result = await tool.run({});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('1 error(s), 0 warning(s)'));
    });

    test('handles empty report', () async {
      fakePort.stub(const DoctorReport(results: []));

      final result = await tool.run({});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('All checks passed'));
    });

    test('inputSchema has type=object and repair boolean property', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('repair'), isTrue);
      expect((properties['repair'] as Map<String, dynamic>)['type'], 'boolean');
    });

    test('description is non-empty', () {
      expect(tool.description.isNotEmpty, isTrue);
    });

    test('single OK check with null message renders OK placeholder', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(name: 'db', status: DiagnosticStatus.ok),
      ]));

      final result = await tool.run({});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('[OK] **db**: OK'));
    });

    test('single OK check with explicit message', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(
          name: 'db',
          status: DiagnosticStatus.ok,
          message: 'Connected successfully',
        ),
      ]));

      final result = await tool.run({});
      expect(result.isError, isFalse);
      expect(result.content.first.text,
          contains('[OK] **db**: Connected successfully'));
    });

    test('single WARNING check', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(
          name: 'disk',
          status: DiagnosticStatus.warning,
          message: 'Disk 85% full',
        ),
      ]));

      final result = await tool.run({});
      expect(result.isError, isFalse);
      expect(result.content.first.text,
          contains('[WARN] **disk**: Disk 85% full'));
      expect(result.content.first.text, contains('0 error(s), 1 warning(s)'));
    });

    test('single FAIL check', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(
          name: 'sandbox',
          status: DiagnosticStatus.error,
          message: 'Sandbox backend unreachable',
        ),
      ]));

      final result = await tool.run({});
      expect(result.isError, isFalse);
      expect(result.content.first.text,
          contains('[FAIL] **sandbox**: Sandbox backend unreachable'));
      expect(result.content.first.text, contains('1 error(s), 0 warning(s)'));
    });

    test('multiple checks of same status (all OK)', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(name: 'db', status: DiagnosticStatus.ok),
        DiagnosticResult(name: 'disk', status: DiagnosticStatus.ok),
        DiagnosticResult(name: 'network', status: DiagnosticStatus.ok),
      ]));

      final result = await tool.run({});
      expect(result.isError, isFalse);
      expect(
          result.content.first.text, contains('[OK] **db**: OK'));
      expect(
          result.content.first.text, contains('[OK] **disk**: OK'));
      expect(
          result.content.first.text, contains('[OK] **network**: OK'));
      expect(result.content.first.text, contains('All checks passed'));
    });

    test('multiple checks of same status (all WARNING)', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(
          name: 'disk', status: DiagnosticStatus.warning, message: 'Full'),
        DiagnosticResult(
          name: 'cpu', status: DiagnosticStatus.warning, message: 'Hot'),
      ]));

      final result = await tool.run({});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('0 error(s), 2 warning(s)'));
    });

    test('report with all three statuses shows correct icon prefixes', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(name: 'db', status: DiagnosticStatus.ok),
        DiagnosticResult(
          name: 'disk',
          status: DiagnosticStatus.warning,
          message: 'Low space',
        ),
        DiagnosticResult(
          name: 'network',
          status: DiagnosticStatus.error,
          message: 'No internet',
        ),
      ]));

      final result = await tool.run({});
      final text = result.content.first.text;
      expect(text, contains('[OK]'));
      expect(text, contains('[WARN]'));
      expect(text, contains('[FAIL]'));
    });

    test('very long message renders correctly', () async {
      final longMsg = List.filled(150, 'X').join();
      fakePort.stub(DoctorReport(results: [
        DiagnosticResult(
          name: 'verbose-check',
          status: DiagnosticStatus.warning,
          message: longMsg,
        ),
      ]));

      final result = await tool.run({});
      final text = result.content.first.text;
      expect(text, contains('[WARN] **verbose-check**: $longMsg'));
    });

    test('error count is correct in summary footer', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(
          name: 'a',
          status: DiagnosticStatus.error,
          message: 'Down',
        ),
        DiagnosticResult(
          name: 'b',
          status: DiagnosticStatus.error,
          message: 'Down',
        ),
        DiagnosticResult(
          name: 'c',
          status: DiagnosticStatus.error,
          message: 'Down',
        ),
        DiagnosticResult(name: 'ok1', status: DiagnosticStatus.ok),
        DiagnosticResult(name: 'ok2', status: DiagnosticStatus.ok),
      ]));

      final result = await tool.run({});
      expect(result.content.first.text, contains('3 error(s), 0 warning(s)'));
    });

    test('warning count is correct in summary footer', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(
          name: 'w1', status: DiagnosticStatus.warning, message: 'A'),
        DiagnosticResult(
          name: 'w2', status: DiagnosticStatus.warning, message: 'B'),
        DiagnosticResult(
          name: 'w3', status: DiagnosticStatus.warning, message: 'C'),
        DiagnosticResult(
          name: 'w4', status: DiagnosticStatus.warning, message: 'D'),
        DiagnosticResult(name: 'ok', status: DiagnosticStatus.ok),
      ]));

      final result = await tool.run({});
      expect(result.content.first.text, contains('0 error(s), 4 warning(s)'));
    });

    test(
        'allOk false when warnings exist but zero errors',
        () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(
          name: 'disk',
          status: DiagnosticStatus.warning,
          message: 'Low space',
        ),
      ]));

      final result = await tool.run({});
      final text = result.content.first.text;
      expect(text, isNot(contains('All checks passed')));
      expect(text, contains('0 error(s), 1 warning(s)'));
    });

    test('empty string message renders literally', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(
          name: 'disk',
          status: DiagnosticStatus.warning,
          message: '',
        ),
      ]));

      final result = await tool.run({});
      final text = result.content.first.text;
      expect(text, contains('[WARN] **disk**: '));
    });

    test('output contains Control Center Health Report heading', () async {
      fakePort.stub(const DoctorReport(results: [
        DiagnosticResult(name: 'db', status: DiagnosticStatus.ok),
      ]));

      final result = await tool.run({});
      expect(result.content.first.text,
          contains('Control Center Health Report'));
    });
  });
}
