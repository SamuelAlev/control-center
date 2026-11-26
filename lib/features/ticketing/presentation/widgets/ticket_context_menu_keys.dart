import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_context_menu.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens a ticket's context menu from the keyboard: Shift+F10 or the Menu
/// key on the focused row, the keys a desktop uses in place of a secondary
/// click. The menu opens at the row's bottom-start corner.
class TicketContextMenuKeys extends ConsumerWidget {
  /// Wraps a focusable ticket row ([child]).
  const TicketContextMenuKeys({
    super.key,
    required this.ticket,
    required this.workspaceId,
    required this.child,
  });

  /// The ticket the menu acts on.
  final Ticket ticket;

  /// The workspace that owns [ticket].
  final String workspaceId;

  /// The row; its focus node is what the keys are pressed on.
  final Widget child;

  static const _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.f10, shift: true):
        _OpenTicketMenuIntent(),
    SingleActivator(LogicalKeyboardKey.contextMenu): _OpenTicketMenuIntent(),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: {
          _OpenTicketMenuIntent: CallbackAction<_OpenTicketMenuIntent>(
            onInvoke: (_) {
              final box = context.findRenderObject();
              if (box is! RenderBox || !box.hasSize) {
                return null;
              }
              final corner = AlignmentDirectional.bottomStart
                  .resolve(Directionality.of(context))
                  .alongSize(box.size);
              showTicketContextMenu(
                context: context,
                ref: ref,
                position: box.localToGlobal(corner),
                ticket: ticket,
                workspaceId: workspaceId,
              );
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}

class _OpenTicketMenuIntent extends Intent {
  const _OpenTicketMenuIntent();
}
