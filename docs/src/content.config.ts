import { defineCollection, z } from 'astro:content';
import { docsSchema, i18nSchema } from '@astrojs/starlight/schema';
import { docsLoader, i18nLoader } from '@astrojs/starlight/loaders';
import english from './content/i18n/en.json';

type CustomTranslationKey = Extract<keyof typeof english, `docs.${string}`>;
const customTranslations = Object.fromEntries(
	Object.keys(english)
		.filter((key) => key.startsWith('docs.'))
		.map((key) => [key, z.string().optional()]),
) as Record<CustomTranslationKey, z.ZodOptional<z.ZodString>>;

export const collections = {
	docs: defineCollection({
		loader: docsLoader({
			// Match landing URLs exactly, including BCP-47 region casing. Lowercase
			// locale folders collide with landing output on case-insensitive disks.
			// A locale's manual mirrors the English file names and sets its
			// translated URL as `slug` (checked by scripts/manual-i18n.ts).
			generateId: ({ entry, data }) => data.slug
				? String(data.slug).normalize('NFC')
				: entry.replace(/\.[^.]+$/, '').replace(/\/index$/, ''),
		}),
		// Optional freshness dates surfaced in the TechArticle JSON-LD (see the
		// Head override). Set `datePublished`/`dateModified` in frontmatter when
		// a page ships or gets a substantive update — not for cosmetic edits.
		schema: docsSchema({
			extend: z.object({
				datePublished: z.coerce.date().optional(),
				dateModified: z.coerce.date().optional(),
				// Locale manual pages: git blob id of the English revision this page
				// was translated from (scripts/manual-i18n.ts). Absent until translated.
				sourceHash: z.string().regex(/^[0-9a-f]{40}$/).optional(),
			}),
		}),
	}),
	i18n: defineCollection({
		loader: i18nLoader(),
		schema: i18nSchema({ extend: z.object(customTranslations) }),
	}),
};
