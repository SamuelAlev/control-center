import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ratchet over the resident tool set — the names sent to the model up front.
///
/// A resident name is matched against the tools a run materializes, so a name
/// that matches nothing is INERT: no error, no warning, the tool is simply
/// deferred. That is a silent regression in exactly the direction this feature
/// is trying to move, and it has already happened once — `residentBuiltins`
/// said `file_search` while the tool is called `search_files`, which quietly
/// pushed a core built-in into the deferred half.
///
/// So this reads the real tool-name literals out of the tree and pins them
/// against the policy. A rename that forgets the policy fails here rather than
/// in an agent's behaviour a week later.
void main() {
  final root = Directory.current.path;

  /// Every `String get name => '...'` in the tool-defining packages.
  Set<String> declaredToolNames() {
    const dirs = [
      'packages/cc_mcp/lib/src/tools',
      'packages/cc_harness_runtime/lib/src/tools',
      'packages/cc_infra/lib/src/harness',
      'packages/cc_mcp_client/lib/src',
    ];
    final names = <String>{};
    final literal = RegExp(r"""get name =>\s*'([a-z0-9_]+)'""");
    // Some tools indirect through a constant (`=> toolName`), so the constant
    // declarations are harvested too rather than being reported missing.
    final constant = RegExp(
      r"""static const String toolName = '([a-z0-9_]+)'""",
    );
    for (final dir in dirs) {
      final d = Directory('$root/$dir');
      if (!d.existsSync()) {
        continue;
      }
      for (final f in d.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) {
          continue;
        }
        // Some sources carry non-UTF8 bytes in fixtures; read leniently.
        final src = String.fromCharCodes(f.readAsBytesSync());
        for (final m in literal.allMatches(src)) {
          names.add(m.group(1)!);
        }
        for (final m in constant.allMatches(src)) {
          names.add(m.group(1)!);
        }
      }
    }
    return names;
  }

  test('every resident tool name is a tool that actually exists', () {
    final declared = declaredToolNames();
    expect(
      declared,
      isNotEmpty,
      reason: 'the scan found no tools at all — the paths above have moved',
    );
    final resident = {
      ...ModeToolPolicy.residentBuiltins,
      ...ModeToolPolicy.residentDiscovery,
      ...ModeToolPolicy.residentMcpTools,
    };
    final unknown = resident.difference(declared).toList()..sort();
    expect(
      unknown,
      isEmpty,
      reason:
          'These names are resident but match no tool, so they are inert and '
          'the tool they meant to keep loaded is being deferred instead: '
          '${unknown.join(', ')}',
    );
  });

  test('every mode resident set stays under the selection-accuracy band', () {
    // Published evaluations put tool-selection accuracy falling off between 30
    // and 50 tools in context. The resident set is the part that is ALWAYS in
    // context, so it is the number that has to stay inside that band — this
    // is the budget the whole two-tier surface exists to hold.
    for (final mode in Mode.values) {
      final resident = profileFor(mode).toToolResidencySpec().residentNames;
      expect(
        resident.length,
        lessThanOrEqualTo(40),
        reason:
            'the ${mode.name} resident set has grown to ${resident.length} '
            'names. Adding one costs its schema on every request of every '
            'run forever, so a tool earns a place by being used in MOST runs '
            '— not by being important when it is used.',
      );
    }
  });

  test('the discovery tools are resident in every mode', () {
    // A deferred surface whose only way in is itself deferred has no way in.
    for (final mode in Mode.values) {
      final resident = profileFor(mode).toToolResidencySpec().residentNames;
      expect(resident, containsAll(ModeToolPolicy.residentDiscovery));
    }
  });

  test('a mode never has to discover the verb that delivers its output', () {
    for (final mode in Mode.values) {
      final profile = profileFor(mode);
      final resident = profile.toToolResidencySpec().residentNames;
      for (final verb in profile.pinnedVerbs) {
        expect(
          resident,
          contains(verb),
          reason:
              '"$verb" is pinned in ${mode.name} but is not resident: a run '
              'would have to go looking for the call that produces its '
              'deliverable.',
        );
      }
    }
  });
}
