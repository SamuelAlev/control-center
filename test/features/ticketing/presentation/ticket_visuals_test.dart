import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_visuals.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => CcTheme(
      data: CcThemeData.light(),
      child: MaterialApp(
        builder: (context, child) => CcTheme(data: CcThemeData.light(), child: child!),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  group('ticket visuals render', () {
    testWidgets('status dot with label', (tester) async {
      await tester.pumpWidget(
        _wrap(const TicketStatusDot(
          status: TicketStatus.inProgress,
          label: 'In progress',
        )),
      );
      expect(find.text('In progress'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('priority indicator shows its label', (tester) async {
      await tester.pumpWidget(
        _wrap(const TicketPriorityIndicator(priority: TicketPriority.high)),
      );
      expect(find.text('High'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('assignee avatar shows the initial', (tester) async {
      await tester.pumpWidget(
        _wrap(const TicketAssigneeAvatar(name: 'Alice')),
      );
      expect(find.text('A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unassigned avatar renders without a name', (tester) async {
      await tester.pumpWidget(
        _wrap(const TicketAssigneeAvatar(name: null)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without the design-token extension (fallback)',
        (tester) async {
      await tester.pumpWidget(
        CcTheme(
          data: CcThemeData.light(),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: TicketPriorityIndicator(priority: TicketPriority.urgent),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Urgent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
