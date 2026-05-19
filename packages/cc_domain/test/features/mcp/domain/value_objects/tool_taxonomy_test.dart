import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/tool_taxonomy.dart';
import 'package:test/test.dart';

void main() {
  group('toolCategoryFor', () {
    test('files a tool under the vocabulary its name already uses', () {
      expect(toolCategoryFor('create_ticket'), ToolCategory.ticketing);
      expect(toolCategoryFor('search_memory'), ToolCategory.memory);
      expect(toolCategoryFor('add_review_node'), ToolCategory.review);
      expect(toolCategoryFor('code_callers'), ToolCategory.codeGraph);
      expect(
        toolCategoryFor('propose_orchestration'),
        ToolCategory.orchestration,
      );
      expect(toolCategoryFor('send_message'), ToolCategory.collaboration);
      expect(toolCategoryFor('publish_artifact'), ToolCategory.artifacts);
      expect(toolCategoryFor('install_skill'), ToolCategory.skills);
      expect(toolCategoryFor('rig_use'), ToolCategory.rigs);
      expect(toolCategoryFor('list_meetings'), ToolCategory.meetings);
      expect(toolCategoryFor('read'), ToolCategory.workspace);
    });

    test('precedence resolves names that belong to two vocabularies', () {
      // Ticketing before forges: this is a ticket operation that happens to
      // name a PR, and a model looking for ticket verbs should find it there.
      expect(toolCategoryFor('ticket_pr_link'), ToolCategory.ticketing);
      // Review before forges, for the same reason in the other direction.
      expect(toolCategoryFor('publish_review_to_github'), ToolCategory.review);
    });

    test(
      'a bridged external tool is filed on its tool name, not its server',
      () {
        // Otherwise every tool from one server lands in one bucket named after
        // the server, which tells a model nothing about what they do.
        expect(
          toolCategoryFor('mcp__acme__create_pull_request'),
          ToolCategory.forge,
        );
      },
    );

    test('an unrecognised name falls back rather than throwing', () {
      // A rule table must never be the reason a newly registered tool cannot
      // be advertised at all.
      expect(toolCategoryFor('zzz_unknown_thing'), ToolCategory.other);
    });

    test('every resident tool name resolves to a real category', () {
      for (final name in ModeToolPolicy.residentNamesFor(Mode.chat)) {
        expect(
          toolCategoryFor(name),
          isNot(ToolCategory.other),
          reason:
              '"$name" is resident but falls in the catch-all bucket; give '
              'the taxonomy a rule that recognises it.',
        );
      }
    });
  });

  group('groupToolsByCategory', () {
    test('groups in enum order and preserves input order inside a group', () {
      final grouped = groupToolsByCategory([
        'send_message',
        'create_ticket',
        'close_ticket',
      ]);
      expect(grouped.keys.toList(), [
        ToolCategory.ticketing,
        ToolCategory.collaboration,
      ]);
      expect(grouped[ToolCategory.ticketing], [
        'create_ticket',
        'close_ticket',
      ]);
    });

    test('an empty input produces no headings', () {
      expect(groupToolsByCategory(const []), isEmpty);
    });
  });
}
