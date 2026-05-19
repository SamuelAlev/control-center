import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the adapter honesty matrix (PRD 24 §3).
///
/// These are not behavioral tests — [AdapterEnforcement] is a declaration, and
/// what needs guarding is that the declaration stays *true*. Each assertion below
/// pins a fact about our integration that someone could plausibly flip in the
/// entity without doing the work in `cc_infra` that would make it true.
void main() {
  group('enforcement matrix totality', () {
    test('every transport declares what it enforces', () {
      for (final transport in AdapterTransport.values) {
        final enforcement = enforcementForTransport(transport);
        expect(
          enforcement.modeMappingNote.trim(),
          isNotEmpty,
          reason:
              '$transport owes the operator one honest sentence about how a '
              'mode reaches it',
        );
      }
    });

    test('every catalog adapter resolves to an enforcement declaration', () {
      for (final adapter in predefinedAdapters) {
        expect(
          enforcementForAdapter(adapter),
          enforcementForTransport(adapter.transport),
          reason:
              'enforcement is a property of the transport, so ${adapter.id} '
              'must agree with its transport',
        );
      }
    });

    test('the catalog exercises every transport', () {
      // If a transport has no adapter, its row in the matrix is never shown to
      // anyone and the declaration silently rots.
      expect(
        predefinedAdapters.map((a) => a.transport).toSet(),
        AdapterTransport.values.toSet(),
      );
    });
  });

  group('harness — the honesty invariant', () {
    final harness = enforcementForTransport(AdapterTransport.harness);

    test('declares its in-process tools are NOT sandboxed', () {
      // The load-bearing assertion of this whole file. `ReadTool`/`WriteTool`/
      // `EditTool` execute as Dart in the server process; only `bash` is routed
      // through `SandboxedHarnessCommandRunner`, so no Seatbelt/bwrap profile
      // (and no `readOnlyMounts` entry) constrains them. The tool surface is
      // therefore the only filesystem boundary a harness run has.
      //
      // If you are here because this test failed: flipping this flag to true is
      // only legitimate once the in-process file tools are themselves confined.
      // Changing the declaration does not change the behavior.
      expect(harness.inProcessToolsSandboxed, isFalse);
      expect(
        harness.caveats,
        contains(AdapterEnforcementCaveat.inProcessToolsUnsandboxed),
      );
    });

    test('is the only transport that fully enforces a mode guarantee', () {
      expect(harness.filtersToolSurface, isTrue);
      expect(harness.interceptsToolCalls, isTrue);
      expect(harness.observesCompletionContract, isTrue);
      expect(harness.enforcesModeGuarantees, isTrue);

      final others = AdapterTransport.values
          .where((t) => t != AdapterTransport.harness)
          .map(enforcementForTransport);
      for (final other in others) {
        expect(other.enforcesModeGuarantees, isFalse);
      }
    });

    test('has no unseen native tools to warn about', () {
      // Vacuously true and worth pinning: there is no second process holding
      // tools we cannot gate, so the harness must never carry the
      // native-tools caveat.
      expect(harness.nativeToolsInterceptable, isTrue);
      expect(
        harness.caveats,
        isNot(
          contains(AdapterEnforcementCaveat.nativeToolsBypassControlCenter),
        ),
      );
    });
  });

  group('acp — no permission negotiation at all', () {
    final acp = enforcementForTransport(AdapterTransport.acp);

    test('declares no interception and no surface filtering', () {
      // ACP defines `session/request_permission` for exactly this and Control
      // Center implements no handler: `session/new` carries cwd, model, and an
      // MCP config path, and nothing about mode or permissions.
      expect(acp.interceptsToolCalls, isFalse);
      expect(acp.filtersToolSurface, isFalse);
      expect(acp.nativeToolsInterceptable, isFalse);
      expect(acp.enforcesModeGuarantees, isFalse);
      expect(acp.sandboxIsOnlyFilesystemFloor, isTrue);
    });

    test('carries the caveats that follow from that', () {
      expect(
        acp.caveats,
        containsAll(const [
          AdapterEnforcementCaveat.toolSurfaceNotFiltered,
          AdapterEnforcementCaveat.toolCallsNotIntercepted,
          AdapterEnforcementCaveat.nativeToolsBypassControlCenter,
        ]),
      );
    });
  });

  group('claudeCli — mode is a request, not an enforcement', () {
    final claude = enforcementForTransport(AdapterTransport.claudeCli);

    test("declares Claude's own tools uninterceptable", () {
      // Claude Code is launched with `--dangerously-skip-permissions` (a
      // non-interactive `claude -p` would otherwise block on its own prompt),
      // and Control Center sees only its `mcp__*` calls. `--permission-mode
      // plan` is the entire mode signal, honored by convention.
      expect(claude.nativeToolsInterceptable, isFalse);
      expect(claude.interceptsToolCalls, isFalse);
      expect(claude.filtersToolSurface, isFalse);
      expect(
        claude.caveats,
        contains(AdapterEnforcementCaveat.nativeToolsBypassControlCenter),
      );
    });

    test('the CLI process itself is sandboxed', () {
      // The asymmetry against the harness: a CLI gets the sandbox but not the
      // interception; the harness gets the interception but not the sandbox.
      expect(claude.inProcessToolsSandboxed, isTrue);
      expect(
        claude.caveats,
        isNot(contains(AdapterEnforcementCaveat.inProcessToolsUnsandboxed)),
      );
    });
  });

  group('structuredCli — prompt and sandbox only', () {
    final structured = enforcementForTransport(AdapterTransport.structuredCli);

    test('declares no mode mapping of any kind', () {
      // There is no flag or protocol message telling a structured-JSON CLI it
      // is in a read-only mode, so the mode reaches it as prompt text only.
      expect(structured.filtersToolSurface, isFalse);
      expect(structured.interceptsToolCalls, isFalse);
      expect(structured.nativeToolsInterceptable, isFalse);
      expect(structured.observesCompletionContract, isFalse);
      expect(structured.inProcessToolsSandboxed, isTrue);
    });
  });

  group('completion contract observability', () {
    test('only the harness can hold a run to its deliverable', () {
      // The contract is a property of the loop, and the harness owns the only
      // loop we drive. Observing an MCP output verb after the fact is not the
      // same as being able to nudge a turn that is about to end empty.
      for (final transport in AdapterTransport.values) {
        expect(
          enforcementForTransport(transport).observesCompletionContract,
          transport == AdapterTransport.harness,
          reason: '$transport',
        );
      }
    });
  });

  group('caveats derivation', () {
    test('a caveat appears exactly when its flag is false', () {
      for (final transport in AdapterTransport.values) {
        final e = enforcementForTransport(transport);
        final caveats = e.caveats;
        expect(
          caveats.contains(AdapterEnforcementCaveat.toolSurfaceNotFiltered),
          !e.filtersToolSurface,
          reason: '$transport',
        );
        expect(
          caveats.contains(AdapterEnforcementCaveat.toolCallsNotIntercepted),
          !e.interceptsToolCalls,
          reason: '$transport',
        );
        expect(
          caveats.contains(
            AdapterEnforcementCaveat.nativeToolsBypassControlCenter,
          ),
          !e.nativeToolsInterceptable,
          reason: '$transport',
        );
        expect(
          caveats.contains(
            AdapterEnforcementCaveat.completionContractUnobservable,
          ),
          !e.observesCompletionContract,
          reason: '$transport',
        );
        expect(
          caveats.contains(AdapterEnforcementCaveat.inProcessToolsUnsandboxed),
          !e.inProcessToolsSandboxed,
          reason: '$transport',
        );
      }
    });

    test(
      'no transport is caveat-free — every one has something to disclose',
      () {
        for (final transport in AdapterTransport.values) {
          expect(
            enforcementForTransport(transport).caveats,
            isNotEmpty,
            reason:
                '$transport claims total enforcement; if that is genuinely true '
                'the claim needs the code to back it',
          );
        }
      },
    );

    test('caveats have no duplicates', () {
      for (final transport in AdapterTransport.values) {
        final caveats = enforcementForTransport(transport).caveats;
        expect(caveats.toSet().length, caveats.length, reason: '$transport');
      }
    });
  });

  group('value semantics', () {
    test('equal declarations compare equal', () {
      const a = AdapterEnforcement(
        filtersToolSurface: true,
        interceptsToolCalls: true,
        observesCompletionContract: true,
        nativeToolsInterceptable: true,
        inProcessToolsSandboxed: false,
        modeMappingNote: 'note',
      );
      const b = AdapterEnforcement(
        filtersToolSurface: true,
        interceptsToolCalls: true,
        observesCompletionContract: true,
        nativeToolsInterceptable: true,
        inProcessToolsSandboxed: false,
        modeMappingNote: 'note',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a differing flag breaks equality', () {
      const a = AdapterEnforcement(
        filtersToolSurface: true,
        interceptsToolCalls: true,
        observesCompletionContract: true,
        nativeToolsInterceptable: true,
        inProcessToolsSandboxed: false,
        modeMappingNote: 'note',
      );
      const b = AdapterEnforcement(
        filtersToolSurface: false,
        interceptsToolCalls: true,
        observesCompletionContract: true,
        nativeToolsInterceptable: true,
        inProcessToolsSandboxed: false,
        modeMappingNote: 'note',
      );
      expect(a, isNot(b));
    });

    test('an empty mode-mapping note is rejected', () {
      expect(
        () => AdapterEnforcement(
          filtersToolSurface: false,
          interceptsToolCalls: false,
          observesCompletionContract: false,
          nativeToolsInterceptable: false,
          inProcessToolsSandboxed: true,
          modeMappingNote: ''.trim(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
