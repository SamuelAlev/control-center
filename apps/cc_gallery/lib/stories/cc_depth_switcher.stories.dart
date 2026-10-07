import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_depth_switcher.stories.g.dart';

/// Stories for [CcDepthSwitcher] — the navigation-stack transition behind a
/// drill-down panel (the sidebar's `depth`). Going deeper, the current page
/// drifts toward the start edge while the next arrives from the end; going
/// back runs the same motion mirrored.
///
/// The stories below are listed under `Primitives → CcDepthSwitcher`.
/// Shallower pages stay mounted while a deeper one is shown, so coming back
/// restores their scroll offset. Reduced motion keeps only a short
/// cross-fade.

const _path = '[Primitives]';

const component = ComponentMeta(name: 'CcDepthSwitcher', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcDepthSwitcherPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    depth: IntArg(
      0,
      name: 'Depth',
      style: const SliderIntArgStyle(min: 0, max: 3, divisions: 3),
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccDepthSwitcherPlaygroundStory(context, args),
  ),
);

final $DrillDown = _Story(
  name: 'Drill-down panel',
  args: _Args.fixed(preview: ccDepthSwitcherDrillDownStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcDepthSwitcherPlayground {
  CcDepthSwitcherPlayground({required this.depth});

  final int depth;
}

/// A sidebar-sized panel with three levels: spaces, settings, integrations.
/// Scroll the spaces list, drill into settings and come back: the list is
/// where you left it.
Widget ccDepthSwitcherDrillDownStory(BuildContext context) {
  return const Center(child: _Frame(child: _DrillDownPanel()));
}

/// Interactive playground — drag the depth to drill in and out. Moving it
/// again before a transition settles reverses it from where it is.
Widget ccDepthSwitcherPlaygroundStory(
  BuildContext context,
  CcDepthSwitcherPlaygroundArgs args,
) {
  final t = context.designSystem!;
  final depth = args.depth;
  return Center(
    child: _Frame(
      child: CcDepthSwitcher(
        depth: depth,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                depth == 0 ? 'Root' : 'Depth $depth',
                style: CcTypography.title.copyWith(color: t.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                depth == 0
                    ? 'The top of the stack.'
                    : 'Pages $depth levels deep arrive from the end edge.',
                style: CcTypography.bodySm.copyWith(color: t.textSecondary),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The pages of the drill-down story, outermost first.
enum _Page { spaces, settings, integrations }

class _DrillDownPanel extends StatefulWidget {
  const _DrillDownPanel();

  @override
  State<_DrillDownPanel> createState() => _DrillDownPanelState();
}

class _DrillDownPanelState extends State<_DrillDownPanel> {
  final List<_Page> _stack = [_Page.spaces];

  void _push(_Page page) => setState(() => _stack.add(page));

  void _pop() => setState(_stack.removeLast);

  @override
  Widget build(BuildContext context) {
    return CcDepthSwitcher(
      depth: _stack.length - 1,
      child: switch (_stack.last) {
        _Page.spaces => _List(
          title: 'Spaces',
          rows: [
            CcTile(
              title: 'Settings',
              leadingIcon: CcIcons.settings,
              trailing: const _DrillChevron(),
              onTap: () => _push(_Page.settings),
            ),
            for (var i = 1; i <= 24; i++)
              CcTile(
                title: 'Space $i',
                leadingIcon: CcIcons.messageSquare,
                onTap: () {},
              ),
          ],
        ),
        _Page.settings => _List(
          title: 'Settings',
          onBack: _pop,
          rows: [
            CcTile(
              title: 'General',
              leadingIcon: CcIcons.settings,
              onTap: () {},
            ),
            CcTile(
              title: 'Appearance',
              leadingIcon: CcIcons.palette,
              onTap: () {},
            ),
            CcTile(
              title: 'Integrations',
              leadingIcon: CcIcons.layers,
              trailing: const _DrillChevron(),
              onTap: () => _push(_Page.integrations),
            ),
            CcTile(
              title: 'API keys',
              leadingIcon: CcIcons.keyRound,
              onTap: () {},
            ),
          ],
        ),
        _Page.integrations => _List(
          title: 'Integrations',
          onBack: _pop,
          rows: [
            CcTile(
              title: 'GitHub',
              leadingIcon: CcIcons.gitBranch,
              onTap: () {},
            ),
            CcTile(
              title: 'Linear',
              leadingIcon: CcIcons.listTodo,
              onTap: () {},
            ),
            CcTile(
              title: 'Webhooks',
              leadingIcon: CcIcons.workflow,
              onTap: () {},
            ),
          ],
        ),
      },
    );
  }
}

/// One page: a header (with a back button below the root) over a scrolling
/// list of rows.
class _List extends StatelessWidget {
  const _List({required this.title, required this.rows, this.onBack});

  final String title;
  final List<Widget> rows;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              if (onBack != null) ...[
                _BackButton(onPressed: onBack!),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                title,
                style: CcTypography.body.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.sm),
            children: rows,
          ),
        ),
      ],
    );
  }
}

/// Returns to the shallower page. cc_ui has no start-pointing chevron, so
/// this flips the drill chevron, which already mirrors under RTL.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brSm,
      semanticLabel: 'Back',
      builder: (context, states) => Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: states.contains(WidgetState.hovered) ? t.hover : null,
          borderRadius: AppRadii.brSm,
        ),
        child: Transform.flip(
          flipX: true,
          child: Icon(CcIcons.chevronRight, size: 16, color: t.textSecondary),
        ),
      ),
    );
  }
}

/// The trailing affordance on a row that drills deeper.
class _DrillChevron extends StatelessWidget {
  const _DrillChevron();

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Icon(CcIcons.chevronRight, size: 16, color: t.textTertiary);
  }
}

/// A sidebar-sized, bordered frame that clips the sliding pages.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Container(
      width: 248,
      height: 380,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: t.borderSecondary),
      ),
      child: child,
    );
  }
}
