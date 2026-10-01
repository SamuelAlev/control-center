/**
 * Wires every `<SsoCheck>` on the page. All rendering goes through
 * textContent / DOM nodes: pasted metadata and fetched documents are
 * untrusted, so none of it ever reaches innerHTML, and only http(s) URLs
 * that passed the server's own rules become link targets.
 */
import { hasFailure, type Check, type CheckStatus } from './checks.ts';
import { HTTP_REDIRECT, defaultSpEntityId, evaluateSamlMetadata, extractMetadata, samlTestSignInUrl } from './saml.ts';
import { discoveryUrl, endpointProblem, evaluateDiscovery, fetchDiscovery, normalizeIssuer, oidcTestSignInUrl, parseDiscovery } from './oidc.ts';
import { normalizeOrigin, probeServer } from './server.ts';

const STATUS_LABEL: Record<CheckStatus, string> = { pass: 'Passed', warn: 'Warning', fail: 'Failed', info: 'Note' };
const MAX_FILE_BYTES = 1024 * 1024;
/** IdPs reject stale requests; rebuild the test link's request when it is older than this. */
const PROBE_MAX_AGE_MS = 60_000;

interface Probe {
  intro: (Node | string)[];
  build: () => Promise<string>;
}

interface Outcome {
  checks: Check[];
  probe: Probe | null;
}

const code = (text: string) => Object.assign(document.createElement('code'), { textContent: text, dir: 'ltr' });

function setUp(root: HTMLElement) {
  const kind = root.dataset.ssoCheck === 'oidc' ? 'oidc' : 'saml';
  const form = root.querySelector('form')!;
  const submit = root.querySelector<HTMLButtonElement>('[data-submit]')!;
  const summary = root.querySelector<HTMLElement>('[data-summary]')!;
  const results = root.querySelector<HTMLOListElement>('[data-results]')!;
  const probeSection = root.querySelector<HTMLElement>('[data-probe]')!;
  const probeIntro = root.querySelector<HTMLElement>('[data-probe-intro]')!;
  const probeLink = root.querySelector<HTMLAnchorElement>('[data-probe-link]')!;
  const submitLabel = submit.textContent ?? '';

  const input = (name: string) => root.querySelector<HTMLInputElement | HTMLTextAreaElement>(`[data-input="${name}"]`);
  const value = (name: string) => input(name)?.value.trim() ?? '';
  const icon = (status: CheckStatus) =>
    root.querySelector<HTMLTemplateElement>(`template[data-icon="${status}"]`)!.content.firstElementChild!.cloneNode(true) as SVGElement;

  function setError(name: string, message: string | null) {
    const field = input(name);
    const error = root.querySelector<HTMLElement>(`[data-error-for="${name}"]`);
    if (!field || !error) return;
    if (message === null) field.removeAttribute('aria-invalid');
    else field.setAttribute('aria-invalid', 'true');
    error.replaceChildren(...(message === null ? [] : [icon('fail'), message]));
    error.hidden = message === null;
  }

  root.querySelector<HTMLInputElement>('[data-file]')?.addEventListener('change', async event => {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file) return;
    if (file.size > MAX_FILE_BYTES) {
      setError('metadata', 'That file is over 1 MB, which is far larger than IdP metadata. Pick the metadata XML file.');
      return;
    }
    input('metadata')!.value = await file.text();
    setError('metadata', null);
  });

  // Errors clear as soon as the reader edits the field.
  form.addEventListener('input', event => {
    const name = (event.target as HTMLElement).dataset.input;
    if (name) setError(name, null);
  });

  let probe: Probe | null = null;
  let builtAt = 0;
  let building: Promise<void> | null = null;
  async function refreshProbeLink(force = false) {
    if (!probe || (!force && Date.now() - builtAt < PROBE_MAX_AGE_MS)) return;
    const current = probe;
    building ??= current.build().then(url => {
      if (probe !== current) return;
      probeLink.href = url;
      probeLink.removeAttribute('aria-disabled');
      builtAt = Date.now();
    }).finally(() => { building = null; });
    await building;
  }
  probeLink.addEventListener('pointerenter', () => void refreshProbeLink());
  probeLink.addEventListener('focus', () => void refreshProbeLink());

  function origin(): string | null | false {
    const raw = value('origin');
    if (!raw) return null;
    const normalized = normalizeOrigin(raw);
    if ('error' in normalized) {
      setError('origin', normalized.error);
      return false;
    }
    return normalized.origin;
  }

  async function runSaml(): Promise<Outcome | null> {
    const xml = value('metadata');
    if (!xml) setError('metadata', 'Paste your IdP metadata, or load the file.');
    const serverOrigin = origin();
    if (!xml || serverOrigin === false) return null;

    const meta = extractMetadata(new DOMParser().parseFromString(xml, 'application/xml'));
    const checks = evaluateSamlMetadata(meta, new Date());
    if (serverOrigin) checks.push(await probeServer(serverOrigin, 'saml', location.protocol));

    const ssoUrl = meta.kind === 'idp' ? meta.ssoServices.find(service => service.binding === HTTP_REDIRECT)?.location : undefined;
    const spEntityId = value('entity') || (serverOrigin ? defaultSpEntityId(serverOrigin) : '');
    if (hasFailure(checks) || !ssoUrl) return { checks, probe: null };
    if (!serverOrigin) {
      checks.push({
        status: 'info',
        title: 'Add your server address for more checks',
        detail: spEntityId
          ? 'With it, your browser also checks that it can reach the server.'
          : 'With it, your browser also checks that it can reach the server, and you can try a test sign-in at your IdP.',
      });
    }
    if (!spEntityId) return { checks, probe: null };
    return {
      checks,
      probe: {
        intro: [
          'Opens your IdP in a new tab with the same kind of request your server sends, as entity ID ',
          code(spEntityId),
          '. It shows whether the IdP recognizes Control Center before anyone tries a real login.',
        ],
        build: () => samlTestSignInUrl({ ssoUrl, spEntityId }),
      },
    };
  }

  async function runOidc(): Promise<Outcome | null> {
    const issuerResult = normalizeIssuer(value('issuer'));
    if ('error' in issuerResult) setError('issuer', issuerResult.error);
    const serverOrigin = origin();
    if ('error' in issuerResult || serverOrigin === false) return null;
    const { issuer } = issuerResult;
    const clientId = value('client');
    const confidential = root.querySelector<HTMLInputElement>('[data-input="type"]:checked')?.value === 'confidential';

    const details = root.querySelector<HTMLDetailsElement>('[data-discovery]')!;
    const discoveryLink = root.querySelector<HTMLAnchorElement>('[data-discovery-link]')!;
    discoveryLink.href = discoveryUrl(issuer);
    discoveryLink.hidden = false;

    const pasted = value('discovery');
    const result = pasted ? parseDiscovery(pasted) : await fetchDiscovery(issuer);
    const checks: Check[] = [];
    if (pasted) checks.push({ status: 'info', title: 'Checked the pasted document', detail: 'Clear the pasted document to fetch it from the issuer instead.' });
    if (!result.ok) {
      checks.push(result.check);
      if (result.unreadable) details.open = true;
    } else {
      checks.push(...evaluateDiscovery(result.doc, { issuer, confidential, groupsClaim: value('groups') }));
    }
    if (serverOrigin) checks.push(await probeServer(serverOrigin, 'oidc', location.protocol));

    if (!result.ok || hasFailure(checks)) return { checks, probe: null };
    const authorizationEndpoint = (result.doc as { authorization_endpoint?: unknown }).authorization_endpoint;
    if (typeof authorizationEndpoint !== 'string' || endpointProblem(authorizationEndpoint, issuer)) return { checks, probe: null };
    if (!serverOrigin || !clientId) {
      const missing = [!clientId && 'client ID', !serverOrigin && 'server address'].filter(Boolean).join(' and ');
      checks.push({ status: 'info', title: `Add your ${missing} to try a test sign-in`, detail: 'It opens your provider with the exact request your server sends.' });
      return { checks, probe: null };
    }
    const redirectUri = `${serverOrigin}/oidc/callback`;
    return {
      checks,
      probe: {
        intro: [
          'Opens your provider in a new tab with the request your server sends, using the redirect URI ',
          code(redirectUri),
          '. It shows whether the client is registered correctly before anyone tries a real login.',
        ],
        build: () => oidcTestSignInUrl({ authorizationEndpoint, clientId, redirectUri }),
      },
    };
  }

  function render(outcome: Outcome) {
    const count = (status: CheckStatus) => outcome.checks.filter(check => check.status === status).length;
    const plural = (n: number, one: string, many: string) => `${n} ${n === 1 ? one : many}`;
    summary.textContent = [
      `${count('pass')} passed`,
      plural(count('warn'), 'warning', 'warnings'),
      `${count('fail')} failed`,
    ].join(', ');

    results.replaceChildren(...outcome.checks.map(check => {
      const item = document.createElement('li');
      item.className = 'sso-check__result';
      item.dataset.status = check.status;
      const body = document.createElement('div');
      const title = document.createElement('p');
      title.className = 'sso-check__title';
      title.append(Object.assign(document.createElement('span'), { className: 'sso-check__status', textContent: STATUS_LABEL[check.status] }), ' ', check.title);
      body.append(title);
      if (check.detail) body.append(Object.assign(document.createElement('p'), { className: 'sso-check__detail', textContent: check.detail }));
      if (check.values?.length) {
        const list = document.createElement('dl');
        list.className = 'sso-check__values';
        for (const { label, value } of check.values) {
          list.append(
            Object.assign(document.createElement('dt'), { textContent: label }),
            Object.assign(document.createElement('dd'), { textContent: value, dir: 'ltr' }),
          );
        }
        body.append(list);
      }
      item.append(icon(check.status), body);
      return item;
    }));
    results.hidden = false;

    probe = outcome.probe;
    builtAt = 0;
    probeSection.hidden = !probe;
    probeLink.removeAttribute('href');
    probeLink.setAttribute('aria-disabled', 'true');
    if (probe) {
      probeIntro.replaceChildren(...probe.intro);
      void refreshProbeLink(true);
    }
  }

  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (submit.disabled) return;
    for (const field of root.querySelectorAll<HTMLElement>('[data-error-for]')) setError(field.dataset.errorFor!, null);
    submit.disabled = true;
    submit.textContent = 'Checking…';
    results.setAttribute('aria-busy', 'true');
    try {
      const outcome = await (kind === 'saml' ? runSaml() : runOidc());
      if (outcome) render(outcome);
      else root.querySelector<HTMLElement>('[aria-invalid="true"]')?.focus();
    } catch (error) {
      render({ checks: [{ status: 'fail', title: 'The check stopped unexpectedly', detail: String(error) }], probe: null });
    } finally {
      submit.disabled = false;
      submit.textContent = submitLabel;
      results.removeAttribute('aria-busy');
    }
  });
}

for (const root of document.querySelectorAll<HTMLElement>('[data-sso-check]')) setUp(root);
