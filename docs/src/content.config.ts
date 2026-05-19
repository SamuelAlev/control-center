import { defineCollection, z } from 'astro:content';
import { docsLoader } from '@astrojs/starlight/loaders';
import { docsSchema } from '@astrojs/starlight/schema';

export const collections = {
	docs: defineCollection({
		loader: docsLoader(),
		// Optional freshness dates surfaced in the TechArticle JSON-LD (see the
		// Head override). Set `datePublished`/`dateModified` in frontmatter when
		// a page ships or gets a substantive update — not for cosmetic edits.
		schema: docsSchema({
			extend: z.object({
				datePublished: z.coerce.date().optional(),
				dateModified: z.coerce.date().optional(),
			}),
		}),
	}),
};
