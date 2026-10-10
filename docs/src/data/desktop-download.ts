import { REPO_URL } from './site.ts';

export type DesktopPlatform = 'macos' | 'windows' | 'windows-arm64' | 'linux';

type ReleaseAsset = {
  name: string;
  state: string;
  browser_download_url: string;
};

type Release = {
  tag_name: string;
  draft: boolean;
  prerelease: boolean;
  published_at: string;
  assets: ReleaseAsset[];
};

export type DownloadResult =
  | { status: 302; url: string }
  | { status: 404 | 502 | 503; message: string };

const assetNames: Record<DesktopPlatform, RegExp> = {
  macos: /^Control-Center-[\w.+-]+-arm64\.dmg$/,
  windows: /^Control-Center-[\w.+-]+-x64-setup\.exe$/,
  // The native Windows-on-Arm installer. `windows` stays the x64 one.
  'windows-arm64': /^Control-Center-[\w.+-]+-arm64-setup\.exe$/,
  linux: /^Control-Center-[\w.+-]+-x86_64\.AppImage$/,
};

const repo = new URL(REPO_URL);
const latestReleaseApi = `https://api.github.com/repos${repo.pathname}/releases/latest`;

function isRelease(value: unknown): value is Release {
  if (typeof value !== 'object' || value === null) return false;
  const release = value as Partial<Release>;
  return typeof release.tag_name === 'string' && release.tag_name.length > 0
    && release.draft === false && release.prerelease === false
    && typeof release.published_at === 'string' && release.published_at.length > 0
    && Array.isArray(release.assets);
}

function isMatchingAsset(asset: unknown, release: Release, platform: DesktopPlatform): asset is ReleaseAsset {
  if (typeof asset !== 'object' || asset === null) return false;
  const candidate = asset as Partial<ReleaseAsset>;
  if (typeof candidate.name !== 'string' || !assetNames[platform].test(candidate.name)
    || !candidate.name.startsWith(`Control-Center-${release.tag_name.replace(/^v/, '')}-`)
    || candidate.state !== 'uploaded' || typeof candidate.browser_download_url !== 'string') return false;
  try {
    const url = new URL(candidate.browser_download_url);
    return url.origin === repo.origin && !url.search && !url.hash
      && url.pathname === `${repo.pathname}/releases/download/${encodeURIComponent(release.tag_name)}/${encodeURIComponent(candidate.name)}`;
  } catch {
    return false;
  }
}

/** Fetch only metadata; browsers fetch the actual installer from GitHub, never from this worker. */
export async function resolveDesktopDownload(platform: string, fetchRelease: typeof fetch = fetch): Promise<DownloadResult> {
  if (!Object.hasOwn(assetNames, platform)) return { status: 404, message: 'Unsupported desktop platform.' };
  const selectedPlatform = platform as DesktopPlatform;
  let response: Response;
  try {
    response = await fetchRelease(latestReleaseApi, {
      headers: {
        Accept: 'application/vnd.github+json',
        'User-Agent': 'Control-Center-Docs',
        'X-GitHub-Api-Version': '2022-11-28',
      },
      signal: AbortSignal.timeout(8000),
      // Cloudflare caches the successful GitHub metadata for at most five minutes
      // at each edge; a failed lookup is never cached. Node ignores the cf option.
      cf: { cacheEverything: true, cacheTtlByStatus: { '200-299': 300, '400-599': 0 } },
    } as RequestInit);
  } catch {
    return { status: 503, message: 'GitHub is temporarily unreachable. Please try again shortly.' };
  }
  if (response.status === 404) return { status: 404, message: 'No published desktop release is available yet.' };
  if (!response.ok) return { status: 503, message: 'GitHub release metadata is temporarily unavailable. Please try again shortly.' };

  let release: unknown;
  try {
    release = await response.json();
  } catch {
    return { status: 502, message: 'GitHub returned invalid release metadata.' };
  }
  if (!isRelease(release)) return { status: 502, message: 'GitHub returned invalid release metadata.' };
  const asset = release.assets.find((item) => isMatchingAsset(item, release, selectedPlatform));
  if (!asset) return { status: 404, message: `No ${selectedPlatform} desktop installer is available in the latest published release.` };
  return { status: 302, url: asset.browser_download_url };
}
