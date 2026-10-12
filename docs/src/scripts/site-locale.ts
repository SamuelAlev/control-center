import { isSiteLocale, localeChoiceParameter, localeFromPath, localizePath, unlocalizedPath } from '../data/locales';

function localizeLink(link: HTMLAnchorElement) {
  if (link.hasAttribute('download')) return;
  let url: URL;
  try { url = new URL(link.href); }
  catch { return; }
  if (url.origin !== location.origin) return;

  const choice = link.dataset.siteLocale;
  if (isSiteLocale(choice)) {
    // The server supplies the exact translated article or landing destination.
    // Keep crawlable links clean; the preference marker belongs to activation.
    url.search = location.search;
    url.searchParams.delete(localeChoiceParameter);
    url.hash = location.hash;
  } else {
    // Explicit language links stay explicit; authored root links follow the reader.
    if (unlocalizedPath(url.pathname) !== url.pathname) return;
    url.pathname = localizePath(url.pathname, localeFromPath(location.pathname));
  }
  link.href = url.href;
}

function updateLinks() {
  document.querySelectorAll<HTMLAnchorElement>('a[href]').forEach(localizeLink);
}

// The Worker has already selected the language and persisted an explicit choice.
// Remove the selection marker without another request; no browser-side redirect.
const canonical = new URL(location.href);
if (isSiteLocale(canonical.searchParams.get(localeChoiceParameter))) {
  canonical.searchParams.delete(localeChoiceParameter);
  history.replaceState(history.state, '', canonical.pathname + canonical.search + canonical.hash);
}
updateLinks();

function followLink(event: MouseEvent) {
  if (event.defaultPrevented || event.button > 1) return;
  const link = event.target instanceof Element ? event.target.closest<HTMLAnchorElement>('a[href]') : null;
  if (!link) return;
  localizeLink(link);
  const choice = link.dataset.siteLocale;
  if (!isSiteLocale(choice) || link.hasAttribute('download')) return;
  const url = new URL(link.href);
  if (url.origin !== location.origin) return;
  url.searchParams.set(localeChoiceParameter, choice);
  link.href = url.href;
  // Native navigation keeps keyboard and modified clicks working. Restore the
  // clean link afterward, including when navigation opened another tab.
  setTimeout(() => localizeLink(link), 0);
}

// Capture before disclosure menus close; also covers search results added later.
document.addEventListener('click', followLink, true);
document.addEventListener('auxclick', followLink, true);
window.addEventListener('hashchange', updateLinks);
window.addEventListener('pageshow', event => { if (event.persisted) updateLinks(); });
