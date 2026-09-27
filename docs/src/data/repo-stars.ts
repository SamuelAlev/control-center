import { REPO_URL } from './site.ts';

const githubRepoApi = `https://api.github.com/repos${new URL(REPO_URL).pathname}`;

/** Only the Worker contacts GitHub. Cloudflare caches successful upstream responses per edge. */
export async function repoStarCount(fetchRepo: typeof fetch = fetch): Promise<number | null> {
  let upstream: Response;
  try {
    upstream = await fetchRepo(githubRepoApi, {
      headers: {
        Accept: 'application/vnd.github+json',
        'User-Agent': 'Control-Center-Docs',
        'X-GitHub-Api-Version': '2022-11-28',
      },
      signal: AbortSignal.timeout(8000),
      cf: { cacheEverything: true, cacheTtlByStatus: { '200-299': 300, '400-599': 0 } },
    } as RequestInit);
  } catch {
    return null;
  }
  if (!upstream.ok) return null;

  let repo: unknown;
  try {
    repo = await upstream.json();
  } catch {
    return null;
  }
  const stars = typeof repo === 'object' && repo !== null && 'stargazers_count' in repo
    ? repo.stargazers_count : undefined;
  if (typeof stars !== 'number' || !Number.isSafeInteger(stars) || stars < 0) return null;
  return stars;
}

/** Fill prerendered navigation as HTML streams through the Worker. */
export function renderRepoStars(response: Response, getCount: () => Promise<number | null> = repoStarCount): Response {
  let language = 'en';
  let count: Promise<number | null> | undefined;
  const headers = new Headers(response.headers);
  // HTML must not outlive the edge's five-minute GitHub cache in a browser.
  headers.set('Cache-Control', 'no-store');
  headers.delete('ETag');
  return new HTMLRewriter()
    .on('html', { element(element) { language = element.getAttribute('lang') ?? 'en'; } })
    .on('[data-repo-star-count]', {
      async element(element) {
        const stars = await (count ??= getCount());
        if (stars === null) return;
        element.setInnerContent(new Intl.NumberFormat(language).format(stars));
        element.removeAttribute('hidden');
      },
    })
    .transform(new Response(response.body, { status: response.status, statusText: response.statusText, headers }));
}
