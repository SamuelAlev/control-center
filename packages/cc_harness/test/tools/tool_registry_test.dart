import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

class _FakeTool extends HarnessTool {
  _FakeTool(this.name, this.approvalTier);

  @override
  final String name;
  @override
  final ToolApprovalTier approvalTier;
  @override
  String get description => 'fake $name';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};
  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('ran $name');
}

void main() {
  group('HarnessToolRegistry', () {
    test('first registration wins on name collision', () {
      final first = _FakeTool('read', ToolApprovalTier.read);
      final second = _FakeTool('read', ToolApprovalTier.write);
      final registry = HarnessToolRegistry()
        ..register(first)
        ..register(second);
      expect(registry.length, 1);
      expect(identical(registry.findByName('read'), first), isTrue);
    });

    test('unrestricted policy exposes all tools', () {
      final registry = HarnessToolRegistry.of([
        _FakeTool('read', ToolApprovalTier.read),
        _FakeTool('write', ToolApprovalTier.write),
        _FakeTool('bash', ToolApprovalTier.exec),
        _FakeTool('create_ticket', ToolApprovalTier.write),
      ]);
      final names = registry
          .toolsFor(const ToolSurfaceSpec.unrestricted())
          .map((t) => t.name)
          .toSet();
      expect(names, {'read', 'write', 'bash', 'create_ticket'});
    });

    test(
      'read-only surface drops exec + worktree mutators, keeps MCP writes',
      () {
        final registry = HarnessToolRegistry.of([
          _FakeTool('read', ToolApprovalTier.read),
          _FakeTool('write', ToolApprovalTier.write),
          _FakeTool('edit', ToolApprovalTier.write),
          _FakeTool('bash', ToolApprovalTier.exec),
          _FakeTool('create_ticket', ToolApprovalTier.write),
          _FakeTool('hire_agent', ToolApprovalTier.exec),
        ]);
        final names = registry
            .toolsFor(const ToolSurfaceSpec.readOnlyLegacy())
            .map((t) => t.name)
            .toSet();
        expect(names, {'read', 'create_ticket'});
      },
    );

    test('a pinned name survives the tier ceiling and the deny list', () {
      // A mode's output verb must always be reachable. `submit_plan` is
      // read-tier in practice, but pinning must hold even for a write-tier verb
      // in a surface that otherwise denies it by name.
      final registry = HarnessToolRegistry.of([
        _FakeTool('read', ToolApprovalTier.read),
        _FakeTool('write', ToolApprovalTier.write),
        _FakeTool('propose_orchestration', ToolApprovalTier.write),
        _FakeTool('bash', ToolApprovalTier.exec),
      ]);
      final names = registry
          .toolsFor(
            const ToolSurfaceSpec(
              maxTier: ToolApprovalTier.read,
              denyNames: {'write', 'propose_orchestration'},
              pinnedNames: {'propose_orchestration'},
            ),
          )
          .map((t) => t.name)
          .toSet();
      expect(names, {'read', 'propose_orchestration'});
    });

    test('an allow-list constrains only tiers above freeTier', () {
      // The safety valve: adopting a curated allow-list must not silently strip
      // read tools from a read-only mode.
      final registry = HarnessToolRegistry.of([
        _FakeTool('read', ToolApprovalTier.read),
        _FakeTool('search', ToolApprovalTier.read),
        _FakeTool('create_ticket', ToolApprovalTier.write),
        _FakeTool('sync_vendor', ToolApprovalTier.write),
      ]);
      final names = registry
          .toolsFor(
            const ToolSurfaceSpec(
              maxTier: ToolApprovalTier.write,
              allowNames: {'create_ticket'},
            ),
          )
          .map((t) => t.name)
          .toSet();
      // Both read tools survive without being listed; the unlisted write does not.
      expect(names, {'read', 'search', 'create_ticket'});
    });

    test('describeFor reports why each tool was excluded', () {
      final registry = HarnessToolRegistry.of([
        _FakeTool('read', ToolApprovalTier.read),
        _FakeTool('write', ToolApprovalTier.write),
        _FakeTool('bash', ToolApprovalTier.exec),
      ]);
      final report = registry.describeFor(
        const ToolSurfaceSpec.readOnlyLegacy(),
      );
      expect(report.included, ['read']);
      expect(report.excluded['write'], 'denied by name');
      expect(report.excluded['bash'], contains('tier ceiling'));
    });

    test('schemas reflect registered tools', () {
      final registry = HarnessToolRegistry.of([
        _FakeTool('read', ToolApprovalTier.read),
      ]);
      expect(registry.schemas.single.name, 'read');
    });
  });
}
