// A table only scrolls as `display: block`, and then its rows shrink to their
// content inside the block, leaving the frame's border and background running
// past them. Wrapping each markdown table lets the wrapper scroll and frame
// while the table stays a real table that fills it (see starlight.css).
//
// Astro 7 renders Markdown and MDX with Sätteri. `markdown.rehypePlugins` would
// move the whole site onto the legacy `unified` processor (whose installed copy
// cannot render MDX), so this is a Sätteri hast plugin, added to Astro's
// processor the same way Starlight adds its own.
import type { AstroIntegration } from 'astro';
import type { HastPluginDefinition } from 'satteri';

export function tableScrollPlugin(): HastPluginDefinition {
  return {
    name: 'table-scroll',
    element: [
      {
        filter: ['table'],
        visit(node, ctx) {
          ctx.wrapNode(node, { type: 'element', tagName: 'div', properties: { className: ['table-scroll'] }, children: [] });
        },
      },
    ],
  };
}

/** Wraps every Markdown and MDX table in a `.table-scroll` frame. */
export function tableScroll(): AstroIntegration {
  return {
    name: 'cc-table-scroll',
    hooks: {
      'astro:config:setup': ({ config, logger }) => {
        const { processor } = config.markdown;
        if (processor.name !== 'satteri') {
          logger.warn(`tables are not framed: the "${processor.name}" Markdown processor does not run Sätteri hast plugins`);
          return;
        }
        (processor.options as { hastPlugins: unknown[] }).hastPlugins.push(tableScrollPlugin());
      },
    },
  };
}
