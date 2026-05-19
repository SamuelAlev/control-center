import 'package:cc_domain/features/ticketing/domain/context/ticket_context_input.dart';
import 'package:cc_domain/features/ticketing/domain/context/ticket_context_snapshot.dart';
import 'package:cc_domain/features/ticketing/domain/context/ticket_context_snapshot_builder.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = TicketContextSnapshotBuilder();
  final now = DateTime.utc(2026);

  Ticket ticket({String? description, List<String> labels = const []}) =>
      Ticket(
        id: 't1',
        workspaceId: 'ws',
        title: 'Fix login retry',
        externalKey: 'ENG-123',
        description: description,
        labels: labels,
        priority: TicketPriority.high,
        status: TicketStatus.inProgress,
        url: 'https://linear.app/x/ENG-123',
        createdAt: now,
        updatedAt: now,
      );

  test('renders a compact header with key/title/status', () {
    final snap = builder.build(TicketContextInput(ticket: ticket()));
    expect(snap.text, contains('ENG-123'));
    expect(snap.text, contains('Fix login retry'));
    expect(snap.text, contains('Status: inProgress'));
    expect(snap.meta.partial, isFalse);
  });

  test('includes comments/children when present', () {
    final snap = builder.build(
      TicketContextInput(
        ticket: ticket(description: 'A short description'),
        comments: [
          const TicketContextComment(
            author: 'agent-a',
            body: 'looking into it',
          ),
        ],
        children: [
          const TicketContextChild(
            key: 'ENG-124',
            title: 'sub',
            status: 'open',
          ),
        ],
      ),
    );
    expect(snap.text, contains('## Description'));
    expect(snap.text, contains('## Comments'));
    expect(snap.text, contains('looking into it'));
    expect(snap.text, contains('## Sub-issues'));
    expect(snap.text, contains('ENG-124'));
    expect(snap.meta.partial, isFalse);
  });

  test('stays within the 12k budget and marks partial when truncated', () {
    final huge = 'x' * 50000;
    final snap = builder.build(
      TicketContextInput(ticket: ticket(description: huge)),
    );
    expect(snap.charCount, lessThanOrEqualTo(12000));
    expect(snap.meta.partial, isTrue);
    expect(snap.meta.truncatedSections, contains('description'));
    expect(snap.text, contains('truncated'));
  });

  test('respects a custom smaller budget', () {
    final snap = builder.build(
      TicketContextInput(ticket: ticket(description: 'y' * 5000)),
      options: const TicketContextOptions(budgetChars: 500),
    );
    expect(snap.charCount, lessThanOrEqualTo(500));
    expect(snap.meta.partial, isTrue);
  });

  test('caps the number of comments by depth and marks partial', () {
    final snap = builder.build(
      TicketContextInput(
        ticket: ticket(),
        comments: List.generate(
          50,
          (i) => TicketContextComment(author: 'a$i', body: 'comment $i'),
        ),
      ),
      options: const TicketContextOptions(maxComments: 5),
    );
    expect(snap.meta.partial, isTrue);
    expect(snap.meta.truncatedSections, contains('comments'));
    // Only the last 5 comments are kept.
    expect(snap.text, contains('comment 49'));
    expect(snap.text, isNot(contains('comment 10')));
  });

  test('surfaces per-section load errors and marks partial', () {
    final snap = builder.build(
      TicketContextInput(
        ticket: ticket(),
        sectionErrors: {'comments': 'vendor timeout'},
      ),
    );
    expect(snap.meta.partial, isTrue);
    expect(snap.meta.sectionErrors['comments'], 'vendor timeout');
    expect(snap.text, contains('vendor timeout'));
  });

  test('omits disabled sections without marking partial', () {
    final snap = builder.build(
      TicketContextInput(
        ticket: ticket(),
        comments: [const TicketContextComment(author: 'a', body: 'hi')],
      ),
      options: const TicketContextOptions(includeComments: false),
    );
    expect(snap.text, isNot(contains('## Comments')));
    expect(snap.meta.partial, isFalse);
  });
}
