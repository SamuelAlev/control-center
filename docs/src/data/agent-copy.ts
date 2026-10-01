/**
 * Agent-facing copy — the prose of each language's llms.txt / llms-full.txt —
 * in `agent-copy/<locale>.json`. `en-US.json` is the source; every other site
 * language translates every key and keeps its `{placeholders}` and code spans
 * (scripts/manual-i18n.ts fails the build otherwise).
 *
 * Build-time only (Vite `import.meta.glob`).
 */
import type { SiteLocale } from './locales';
import english from './agent-copy/en-US.json';

export type AgentCopyKey = keyof typeof english;

const files = import.meta.glob<Record<string, string>>('./agent-copy/*.json', { eager: true, import: 'default' });
const copies = Object.fromEntries(
  Object.entries(files).map(([file, copy]) => [file.slice('./agent-copy/'.length, -'.json'.length), copy]),
);

/** [key] in [locale] with `{name}` placeholders filled from [vars]. */
export function agentText(locale: SiteLocale, key: AgentCopyKey, vars: Record<string, string> = {}): string {
  const template = copies[locale]?.[key] || english[key];
  return template.replace(/\{([a-zA-Z]+)\}/g, (placeholder, name: string) => vars[name] ?? placeholder);
}
