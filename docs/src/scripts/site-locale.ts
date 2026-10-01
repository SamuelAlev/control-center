import { isSiteLocale, localeChoiceParameter, localeFromPath, localizePath, unlocalizedPath } from '../data/locales';

function localizeLink(link: HTMLAnchorElement) {
  if (link.hasAttribute('download')) return;
  let url: URL;
  try { url = new URL(link.href); }
  catch { return; }
  if (url.origin !== location.origin) return;

  const choice = link.dataset.siteLocale;
  if (isSiteLocale(choice)) {
    // Translated pages carry their exact destination: manual slugs differ per
    // locale and only the server knows them.
    if (!('siteLocaleExact' in link.dataset)) url.pathname = localizePath(location.pathname, choice);
    url.search = location.search;
    url.searchParams.set(localeChoiceParameter, choice);
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
  const link = event.target instanceof Element ? event.target.closest<HTMLAnchorElement>('a[href]') : null;
  if (!link) return;
  localizeLink(link);
}

// Capture before disclosure menus close; also covers search results added later.
document.addEventListener('click', followLink, true);
document.addEventListener('auxclick', followLink, true);
window.addEventListener('hashchange', updateLinks);
window.addEventListener('pageshow', event => { if (event.persisted) updateLinks(); });
