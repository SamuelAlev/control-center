/**
 * Minimal HTML → markdown converter for the constrained HTML this site keeps
 * in data modules (page sections, changelog items): headings, paragraphs,
 * links, lists, emphasis, code, pre blocks, blockquotes and tables. Not a
 * general-purpose converter — an unknown tag degrades to its text content
 * rather than guessing.
 *
 * Pure module: no Astro imports, so unit tests exercise it directly.
 */

const BLOCK_TAGS: Record<string, true> = {
  p: true,
  div: true,
  section: true,
  article: true,
  ul: true,
  ol: true,
  blockquote: true,
  pre: true,
  table: true,
  thead: true,
  tbody: true,
  tr: true,
};

const decodeEntities = (text: string): string =>
  text
    .replace(/&rsquo;/g, '’')
    .replace(/&lsquo;/g, '‘')
    .replace(/&rdquo;/g, '”')
    .replace(/&ldquo;/g, '“')
    .replace(/&mdash;/g, '—')
    .replace(/&ndash;/g, '–')
    .replace(/&hellip;/g, '…')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#0?39;/g, "'")
    .replace(/&#x27;/gi, "'");

interface Token {
  kind: 'text' | 'open' | 'close';
  name?: string;
  attrs?: string;
  text?: string;
}

const TOKEN_RE = /<!--[\s\S]*?-->|<(\/?)([a-zA-Z][a-zA-Z0-9]*)((?:"[^"]*"|'[^']*'|[^>"'])*)>|([^<]+)/g;

function tokenize(html: string): Token[] {
  const tokens: Token[] = [];
  let m: RegExpExecArray | null;
  while ((m = TOKEN_RE.exec(html)) !== null) {
    if (m[0].startsWith('<!--')) continue;
    if (m[2] !== undefined) {
      tokens.push({
        kind: m[1] === '/' ? 'close' : 'open',
        name: m[2].toLowerCase(),
        attrs: m[3] ?? '',
      });
    } else if (m[4] !== undefined) {
      tokens.push({ kind: 'text', text: decodeEntities(m[4]) });
    }
  }
  return tokens;
}

const hrefOf = (attrs: string): string | null => {
  const m = /href\s*=\s*("([^"]*)"|'([^']*)')/i.exec(attrs);
  return m ? (m[2] ?? m[3] ?? null) : null;
};

/**
 * Convert one HTML fragment to markdown. Inline whitespace collapses; block
 * boundaries become blank lines. Relative hrefs are kept as-is (they resolve
 * against the page the markdown mirrors).
 */
export function htmlToMarkdown(html: string): string {
  const out: string[] = [];
  // Inline state.
  let linkStack: string[] = [];
  let listDepth = 0;
  let orderedIndex: number[] = [];
  let inPre = false;
  let headingLevel = 0;
  // Table state: buffer rows so the header separator can be emitted.
  let tableRows: string[][] | null = null;
  let tableCells: string[] | null = null;
  let cellText = '';

  const push = (s: string) => {
    if (tableRows !== null && tableCells !== null && inPre === false) {
      cellText += s;
      return;
    }
    out.push(s);
  };

  const ensureBlank = () => {
    const current = out.join('');
    if (current === '' || current.endsWith('\n\n')) return;
    out.push(current.endsWith('\n') ? '\n' : '\n\n');
  };

  for (const t of tokenize(html)) {
    if (t.kind === 'text') {
      if (inPre) {
        out.push(t.text ?? '');
      } else {
        push((t.text ?? '').replace(/\s+/g, ' '));
      }
      continue;
    }
    const name = t.name!;
    if (t.kind === 'open') {
      if (name === 'table') {
        tableRows = [];
        tableCells = null;
      } else if (name === 'tr' && tableRows !== null) {
        tableCells = [];
      } else if ((name === 'td' || name === 'th') && tableCells !== null) {
        cellText = '';
      } else if (name === 'pre') {
        ensureBlank();
        inPre = true;
        out.push('```');
      } else if (/^h[1-6]$/.test(name)) {
        ensureBlank();
        headingLevel = Number(name[1]);
        out.push(`${'#'.repeat(headingLevel)} `);
      } else if (name === 'a') {
        const href = hrefOf(t.attrs ?? '');
        linkStack.push(href ?? '');
        if (href) push('[');
      } else if (name === 'strong' || name === 'b') push('**');
      else if (name === 'em' || name === 'i') push('*');
      else if (name === 'code' && !inPre) push('`');
      else if (name === 'ul' || name === 'ol') {
        ensureBlank();
        listDepth += 1;
        if (name === 'ol') orderedIndex[listDepth] = 0;
      } else if (name === 'li') {
        const current = out.join('');
        if (!current.endsWith('\n')) out.push('\n');
        const indent = '  '.repeat(Math.max(0, listDepth - 1));
        const marker = orderedIndex[listDepth] !== undefined ? `${(orderedIndex[listDepth] += 1)}.` : '-';
        out.push(`${indent}${marker} `);
      } else if (name === 'blockquote') {
        ensureBlank();
        out.push('> ');
      } else if (name === 'br') push('  \n');
      else if (name === 'hr') {
        ensureBlank();
        out.push('---\n');
      } else if (BLOCK_TAGS[name]) {
        ensureBlank();
      }
      continue;
    }
    // close
    if (name === 'td' || name === 'th') {
      if (tableCells !== null) tableCells.push(cellText.replace(/\|/g, '\\|').trim());
    } else if (name === 'tr') {
      if (tableRows !== null && tableCells !== null) tableRows.push(tableCells);
      tableCells = null;
    } else if (name === 'table') {
      if (tableRows !== null && tableRows.length > 0) {
        ensureBlank();
        const [head, ...body] = tableRows;
        out.push(`| ${head.join(' | ')} |\n`);
        out.push(`| ${head.map(() => '---').join(' | ')} |\n`);
        for (const row of body) out.push(`| ${row.join(' | ')} |\n`);
        out.push('\n');
      }
      tableRows = null;
      tableCells = null;
    } else if (name === 'pre') {
      inPre = false;
      out.push('\n```');
      ensureBlank();
    } else if (/^h[1-6]$/.test(name)) {
      headingLevel = 0;
      ensureBlank();
    } else if (name === 'a') {
      const href = linkStack.pop() ?? '';
      if (href) push(`](${href})`);
    } else if (name === 'strong' || name === 'b') push('**');
    else if (name === 'em' || name === 'i') push('*');
    else if (name === 'code' && !inPre) push('`');
    else if (name === 'ul' || name === 'ol') {
      listDepth = Math.max(0, listDepth - 1);
      ensureBlank();
    } else if (name === 'blockquote') ensureBlank();
    else if (BLOCK_TAGS[name]) ensureBlank();
  }

  return (
    out
      .join('')
      // Tidy: collapse 3+ newlines, trim trailing spaces per line.
      .replace(/ +\n/g, '\n')
      .replace(/\n{3,}/g, '\n\n')
      .replace(/\[\]\(\)/g, '')
      .trim()
  );
}
