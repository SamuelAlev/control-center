import type { APIRoute } from 'astro';
import { resolveDesktopDownload } from '../../data/desktop-download.ts';

export const prerender = false;

const download: APIRoute = async ({ params, request }) => {
  const result = await resolveDesktopDownload(params.platform ?? '');
  if (result.status === 302) {
    return new Response(null, {
      status: 302,
      headers: { Location: result.url, 'Cache-Control': 'no-store' },
    });
  }
  return new Response(request.method === 'HEAD' ? null : result.message, {
    status: result.status,
    headers: { 'Content-Type': 'text/plain; charset=utf-8', 'Cache-Control': 'no-store' },
  });
};

export const GET = download;
export const HEAD = download;
